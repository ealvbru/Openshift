#!/bin/bash

# --- Constants ---
readonly SCRIPT_NAME=$(basename "$0")

# --- Functions ---

print_menu() {
    echo "Select an action:"
    echo "1) Resize Deployment Resources"
    echo "2) Resize HPA Replicas"
    echo "0) Exit"
}

prompt_variables_resize_deployment() {
    echo "--- Resize Deployment Resources ---"
    read -rp "Enter deployment name: " DEPLOYMENT_NAME
    read -rp "Enter size (PP, P, M, G, GG): " SIZE
    read -rp "Namespace (leave empty for current project): " NAMESPACE
    read -rp "Enable verbose mode? (y/N): " VERBOSE_ANSWER
    read -rp "Enable dry-run mode? (y/N): " DRY_RUN_ANSWER

    VERBOSE=""
    DRY_RUN=""

    [[ "$VERBOSE_ANSWER" =~ ^[Yy]$ ]] && VERBOSE="-v"
    [[ "$DRY_RUN_ANSWER" =~ ^[Yy]$ ]] && DRY_RUN="--dry-run"

    ./resize-deployment.sh $VERBOSE $DRY_RUN ${NAMESPACE:+-n $NAMESPACE} "$DEPLOYMENT_NAME" "$SIZE"
}

prompt_variables_resize_hpa() {
    echo "--- Resize HPA Replicas ---"
    read -rp "Enter deployment name (HPA name): " DEPLOYMENT_NAME
    read -rp "Enter minimum replicas: " MIN_REPLICAS
    read -rp "Enter maximum replicas: " MAX_REPLICAS
    read -rp "Namespace (leave empty for current project): " NAMESPACE
    read -rp "Enable verbose mode? (y/N): " VERBOSE_ANSWER
    read -rp "Enable dry-run mode? (y/N): " DRY_RUN_ANSWER

    VERBOSE=""
    DRY_RUN=""

    [[ "$VERBOSE_ANSWER" =~ ^[Yy]$ ]] && VERBOSE="-v"
    [[ "$DRY_RUN_ANSWER" =~ ^[Yy]$ ]] && DRY_RUN="--dry-run"

    ./resize-hpa.sh $VERBOSE $DRY_RUN ${NAMESPACE:+-n $NAMESPACE} "$DEPLOYMENT_NAME" "$MIN_REPLICAS" "$MAX_REPLICAS"
}

# --- Main Script ---

clear
while true; do
    print_menu
    read -rp "Enter choice: " CHOICE

    case "$CHOICE" in
        1)
            prompt_variables_resize_deployment
            ;;
        2)
            prompt_variables_resize_hpa
            ;;
        0)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1, 2, or 0."
            ;;
    esac

    echo ""
    read -rp "Press enter to continue..."
    clear

done
