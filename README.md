OpenShift Deployment Resizer

A lightweight and user-friendly Bash script to resize container resources (CPU and Memory) for an OpenShift Deployment based on predefined sizes.

Features

Resize deployments easily using simple size codes: PP, P, M, G, GG

Dry Run Mode (--dry-run): Preview the generated JSON patch without applying changes

Verbose Mode (-v): Print the full JSON patch body for detailed inspection

Auto-detects the current namespace if not provided

Clear error handling and informative usage instructions

Size Options

Code

Description

CPU Request/Limit

Memory Request/Limit

PP

Extra Large

2000m / 4000m

4Gi / 8Gi

P

Large

1000m / 2000m

2Gi / 4Gi

M

Medium

500m / 1000m

1Gi / 2Gi

G

Small

250m / 500m

512Mi / 1Gi

GG

Extra Small

100m / 200m

256Mi / 512Mi

Usage

./resize.sh [-n namespace] [-v] [--dry-run] <deployment-name> <size>

Options

-n, --namespace   : Specify the OpenShift namespace (defaults to current project if omitted)

-v                  : Enable verbose mode (prints the generated JSON patch)

--dry-run           : Show the patch without applying it to the cluster

-h, --help        : Display usage information

Examples

Resize a deployment to Medium size in the current namespace:

./resize.sh my-deployment M

Resize a deployment in a specified namespace and preview the patch without applying it:

./resize.sh -n custom-namespace --dry-run -v another-deployment P

Requirements

OpenShift CLI (oc)

jq (command-line JSON processor)

Install them with:

# On Fedora / RHEL / CentOS
sudo dnf install -y jq

# On Ubuntu / Debian
sudo apt-get install -y jq

Ensure oc is installed and that you are logged into your OpenShift cluster:

oc login https://your-cluster-url

License

This project is licensed under the MIT License.

Contributing

Contributions, issues, and feature requests are welcome!
Feel free to open an issue or submit a pull request.

Author
Bruno Almeida
