#!/bin/bash

# --- Constants ---
readonly SCRIPT_NAME=$(basename "$0")

# --- Functions ---

print_usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [-n namespace] [-v] [--dry-run] <deployment-name> <min-replicas> <max-replicas>

Options:
  -n namespace   Specify the OpenShift namespace (defaults to current project)
  -v             Verbose mode (prints the JSON patch)
  --dry-run      Only show the patch, do not apply changes
  -h, --help     Show this help message and exit

Examples:
  $SCRIPT_NAME my-deployment 2 5
  $SCRIPT_NAME -n my-namespace -v --dry-run my-deployment 1 10
EOF
}

exit_with_error() {
    echo "Error: $1" >&2
    print_usage >&2
    exit 1
}

get_current_namespace() {
    oc project -q 2>/dev/null
}

# --- Main Script ---

# Check prerequisites
if ! command -v oc &> /dev/null; then
    exit_with_error "OpenShift CLI (oc) is not installed or not in PATH."
fi

if ! command -v jq &> /dev/null; then
    exit_with_error "jq is not installed."
fi

if ! oc whoami &> /dev/null; then
    exit_with_error "Not logged into OpenShift cluster. Please run 'oc login' first."
fi

# --- Argument Parsing ---
NAMESPACE=""
VERBOSE=false
DRY_RUN=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--namespace)
            [[ -z $2 ]] && exit_with_error "Namespace not specified."
            NAMESPACE="$2"
            shift 2
            ;;
        -v)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -* )
            exit_with_error "Unknown option: $1"
            ;;
        * )
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL_ARGS[@]} -ne 3 ]]; then
    print_usage
    exit 1
fi

DEPLOYMENT_NAME="${POSITIONAL_ARGS[0]}"
MIN_REPLICAS="${POSITIONAL_ARGS[1]}"
MAX_REPLICAS="${POSITIONAL_ARGS[2]}"

if ! [[ "$MIN_REPLICAS" =~ ^[0-9]+$ ]] || ! [[ "$MAX_REPLICAS" =~ ^[0-9]+$ ]]; then
    exit_with_error "Min and max replicas must be integers."
fi

# Default namespace if not set
if [[ -z "$NAMESPACE" ]]; then
    NAMESPACE=$(get_current_namespace)
    if [[ -z "$NAMESPACE" ]]; then
        exit_with_error "Unable to determine current namespace. Please specify with -n."
    fi
    echo "Using current namespace: $NAMESPACE"
fi

# Check if HPA exists
if ! oc get hpa "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
    exit_with_error "HPA for deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'."
fi

# Prepare patch
PATCH_BODY=$(cat <<EOF
[
  {"op": "replace", "path": "/spec/minReplicas", "value": $MIN_REPLICAS},
  {"op": "replace", "path": "/spec/maxReplicas", "value": $MAX_REPLICAS}
]
EOF
)

if $VERBOSE; then
    echo "Generated Patch Body:"
    echo "$PATCH_BODY" | jq .
fi

# Dry run mode
if $DRY_RUN; then
    echo "---"
    echo "Dry Run Mode: Patch to be applied"
    echo "$PATCH_BODY" | jq .
    exit 0
fi

# Apply patch
if ! oc patch hpa "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type=json -p="$PATCH_BODY"; then
    exit_with_error "Failed to patch HPA for deployment '$DEPLOYMENT_NAME'."
fi

echo "Successfully updated HPA for deployment '$DEPLOYMENT_NAME' with minReplicas=$MIN_REPLICAS and maxReplicas=$MAX_REPLICAS."
