#!/bin/bash

# --- Constants ---
readonly SCRIPT_DIR="/script/tools"

# --- Menu ---
while true; do
    echo "======================"
    echo " 🚀 OpenShift Resizer "
    echo "======================"
    echo "1) Resize Deployment"
    echo "2) Resize HPA"
    echo "3) Exit"
    echo ""
    read -rp "Choose an option [1-3]: " choice

    case "$choice" in
        1)
            echo ""
            read -rp "Enter deployment name: " deployment_name
            read -rp "Enter replicas count: " replicas
            read -rp "Enter namespace (leave empty for current): " namespace
            echo ""

            if [[ -n "$namespace" ]]; then
                "$SCRIPT_DIR/resize-deployment.sh" -n "$namespace" "$deployment_name" "$replicas"
            else
                "$SCRIPT_DIR/resize-deployment.sh" "$deployment_name" "$replicas"
            fi
            ;;
        2)
            echo ""
            read -rp "Enter deployment name (for HPA): " hpa_name
            read -rp "Enter min replicas: " min_replicas
            read -rp "Enter max replicas: " max_replicas
            read -rp "Enter namespace (leave empty for current): " namespace
            echo ""

            if [[ -n "$namespace" ]]; then
                "$SCRIPT_DIR/resize-hpa.sh" -n "$namespace" "$hpa_name" "$min_replicas" "$max_replicas"
            else
                "$SCRIPT_DIR/resize-hpa.sh" "$hpa_name" "$min_replicas" "$max_replicas"
            fi
            ;;
        3)
            echo "Bye 👋"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please choose again."
            ;;
    esac

done
