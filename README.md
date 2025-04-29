# Openshift
A lightweight and user-friendly Bash script to resize container resources (CPU and Memory) for an OpenShift Deployment based on predefined sizes.

🚀 Features
Resize deployments quickly using simple size codes (PP, P, M, G, GG).

Supports multiple containers within a single deployment.
Dry Run Mode (--dry-run) — preview the JSON patch without applying changes.
Verbose Mode (-v) — print the generated JSON patch body for review.
Auto-detect namespace if not explicitly provided.
Clear error handling and helpful usage output.

🛠 Size Options
PP	Extra Large	2000m / 4000m	4Gi / 8Gi
P	Large	1000m / 2000m	2Gi / 4Gi
M	Medium	500m / 1000m	1Gi / 2Gi
G	Small	250m / 500m	512Mi / 1Gi
GG	Extra Small	100m / 200m	256Mi / 512Mi

📋 Usage

./resize.sh [-n namespace] [-v] [--dry-run] <deployment-name> <size>

Options:
-n, --namespace — Specify the OpenShift namespace (defaults to current project if not provided).
-v — Enable verbose mode (prints the generated JSON patch).
--dry-run — Perform a dry run without applying changes.
-h, --help — Show usage help.

📚 Examples
Resize my-deployment to Medium size in the current namespace:
./resize.sh my-deployment M

Resize another-deployment in a specific namespace and preview changes without applying:
./resize.sh -n custom-namespace --dry-run -v another-deployment P

⚡ Requirements
OpenShift CLI (oc)
jq (for JSON processing)
