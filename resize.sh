#!/bin/bash

# --- Constants ---
readonly SCRIPT_NAME=$(basename "$0")
readonly SUPPORTED_SIZES="PP, P, M, G, GG"

# --- Functions ---

# Print usage information
print_usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [-n namespace] [-v] [--dry-run] <deployment-name> <size>

Options:
  -n namespace   Specify the OpenShift namespace (defaults to current project)
  -v, --verbose  Print the generated JSON patch
  --dry-run      Only show the patch without applying
  -h, --help     Show this help message

Size options:
  PP  (Extra Small)  -> CPU: 2000m/4000m, Memory: 4Gi/8Gi
  P   (Small)        -> CPU: 1000m/2000m, Memory: 2Gi/4Gi
  M   (Medium)       -> CPU: 500m/1000m,  Memory: 1Gi/2Gi
  G   (Large)        -> CPU: 250m/500m,   Memory: 512Mi/1Gi
  GG  (Extra Large)  -> CPU: 100m/200m,   Memory: 256Mi/512Mi

Examples:
  $SCRIPT_NAME my-deployment M
  $SCRIPT_NAME -n my-namespace my-deployment GG
  $SCRIPT_NAME -v --dry-run my-deployment G
EOF
}

# Exit with an error message
exit_with_error() {
    echo "Error: $1" >&2
    print_usage >&2
    exit 1
}

# Validate size parameter
validate_size() {
    local size=$1
    case "$size" in
        PP|P|M|G|GG) return 0 ;;
        *) return 1 ;;
    esac
}

# Get current namespace if not specified
get_current_namespace() {
    oc project -q 2>/dev/null
}

# --- Main Script ---

# Check if oc is installed
if ! command -v oc &> /dev/null; then
    exit_with_error "OpenShift CLI (oc) is not installed or not in PATH."
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    exit_with_error "Not logged in to OpenShift cluster. Please run 'oc login' first."
fi

# --- Argument Parsing ---
NAMESPACE=""
DRY_RUN=false
VERBOSE=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--namespace)
            [[ -z $2 ]] && exit_with_error "Namespace not specified."
            NAMESPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            exit_with_error "Unknown option: $1"
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Validate we have exactly 2 positional arguments
if [[ ${#POSITIONAL_ARGS[@]} -ne 2 ]]; then
    print_usage
    exit 1
fi

DEPLOYMENT_NAME="${POSITIONAL_ARGS[0]}"
SIZE="${POSITIONAL_ARGS[1]}"

# Validate size parameter
if ! validate_size "$SIZE"; then
    exit_with_error "Invalid size '$SIZE'. Available sizes: $SUPPORTED_SIZES"
fi

# Set default namespace if not specified
if [[ -z "$NAMESPACE" ]]; then
    NAMESPACE=$(get_current_namespace)
    if [[ -z "$NAMESPACE" ]]; then
        exit_with_error "Unable to determine current namespace. Please specify with -n."
    fi
    echo "Using current namespace: $NAMESPACE"
fi

# --- Resource Definitions ---
declare -A RESOURCES

case "$SIZE" in
    PP)
        RESOURCES=(
            [cpu_request]="2000m"
            [cpu_limit]="4000m"
            [mem_request]="4Gi"
            [mem_limit]="8Gi"
        )
        ;;
    P)
        RESOURCES=(
            [cpu_request]="1000m"
            [cpu_limit]="2000m"
            [mem_request]="2Gi"
            [mem_limit]="4Gi"
        )
        ;;
    M)
        RESOURCES=(
            [cpu_request]="500m"
            [cpu_limit]="1000m"
            [mem_request]="1Gi"
            [mem_limit]="2Gi"
        )
        ;;
    G)
        RESOURCES=(
            [cpu_request]="250m"
            [cpu_limit]="500m"
            [mem_request]="512Mi"
            [mem_limit]="1Gi"
        )
        ;;
    GG)
        RESOURCES=(
            [cpu_request]="100m"
            [cpu_limit]="200m"
            [mem_request]="256Mi"
            [mem_limit]="512Mi"
        )
        ;;
esac

# --- Deployment Validation ---
if ! oc get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &> /dev/null; then
    exit_with_error "Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'."
fi

# Get container count and names
CONTAINER_INFO=$(oc get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o json | jq -r '.spec.template.spec.containers[] | .name')
readarray -t CONTAINER_NAMES <<< "$CONTAINER_INFO"
CONTAINER_COUNT=${#CONTAINER_NAMES[@]}

if [[ $CONTAINER_COUNT -eq 0 ]]; then
    exit_with_error "No containers found in deployment '$DEPLOYMENT_NAME'."
fi

# --- Prepare Patch ---
PATCHES='['
for ((i=0; i<CONTAINER_COUNT; i++)); do
    PATCHES+=$(cat <<EOF
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/$i/resources/requests/cpu",
        "value": "${RESOURCES[cpu_request]}"
    },
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/$i/resources/limits/cpu",
        "value": "${RESOURCES[cpu_limit]}"
    },
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/$i/resources/requests/memory",
        "value": "${RESOURCES[mem_request]}"
    },
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/$i/resources/limits/memory",
        "value": "${RESOURCES[mem_limit]}"
    },
EOF
)
done

# Remove last comma and close array
PATCHES="${PATCHES%,}]"

# --- Logging Info ---
echo "Updating deployment '$DEPLOYMENT_NAME' in namespace '$NAMESPACE' to size '$SIZE':"
echo "  CPU Requests/Limits: ${RESOURCES[cpu_request]}/${RESOURCES[cpu_limit]}"
echo "  Memory Requests/Limits: ${RESOURCES[mem_request]}/${RESOURCES[mem_limit]}"
echo "  Affected containers: ${CONTAINER_NAMES[*]}"
echo

# --- Verbose Mode ---
if [[ "$VERBOSE" == true ]]; then
    echo "Generated JSON patch:"
    echo "$PATCHES" | jq .
    echo
fi

# --- Dry Run Mode ---
if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run mode: Patch NOT applied."
    exit 0
fi

# --- Apply Changes ---
if ! oc patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type=json -p="$PATCHES"; then
    exit_with_error "Failed to update resources for '$DEPLOYMENT_NAME'."
fi

echo "Successfully updated deployment '$DEPLOYMENT_NAME'."
