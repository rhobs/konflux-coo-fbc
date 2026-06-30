#!/bin/bash
# Add a new operator bundle version to the catalog.
#
# This script automates all the steps needed when a new bundle version
# is released:
#   1. Creates hack/update-catalogs-<version>.sh (the digest data file)
#   2. Adds the version to both fast and stable channels in the template
#      (with replaces + skipRange wired to the previous head)
#   3. Adds the olm.bundle image entry to the template
#
# After running this, the new version is immediately visible on the
# "fast" channel for all OCP versions. It will NOT appear on "stable"
# until you also update config/channels.yaml — see that file for details.
#
# Examples:
#
#   # Add a brand new v1.5.0 bundle:
#   ./hack/add-bundle-version.sh 1.5.0 \
#     quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:abc123
#
#   # Then regenerate catalogs:
#   make generate-catalog
#
#   # Later, promote v1.5.0 to stable for OCP 4.18+:
#   #   edit config/channels.yaml, then:
#   make generate-catalog
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$REPO_ROOT/catalog/catalog-template.yaml"

usage() {
    echo "Usage: $0 <version> <image-ref>"
    echo ""
    echo "Add a new bundle version to the catalog template and create its update script."
    echo ""
    echo "Arguments:"
    echo "  version    Bundle version (e.g. 1.5.0)"
    echo "  image-ref  Full image reference with digest (e.g. quay.io/...@sha256:abc123)"
    echo ""
    echo "Example:"
    echo "  $0 1.5.0 quay.io/redhat-user-workloads/.../cluster-observability-operator-bundle@sha256:abc123"
    exit 1
}

if [[ $# -ne 2 ]]; then
    usage
fi

VERSION="$1"
IMAGE_REF="$2"
BUNDLE_NAME="cluster-observability-operator.v${VERSION}"
UPDATE_SCRIPT="$SCRIPT_DIR/update-catalogs-${VERSION}.sh"

if [[ -f "$UPDATE_SCRIPT" ]]; then
    echo "Error: update script already exists: $UPDATE_SCRIPT"
    echo "To update an existing bundle's digest, edit the script directly."
    exit 1
fi

PREVIOUS_HEAD=$(yq eval '
    .entries[] | select(.schema == "olm.channel" and .name == "fast") |
    .entries[-1].name
' "$TEMPLATE")

if [[ -z "$PREVIOUS_HEAD" ]]; then
    echo "Error: could not determine previous fast channel head from template"
    exit 1
fi

echo "Adding bundle version ${VERSION}:"
echo "  Previous head: ${PREVIOUS_HEAD}"
echo "  New entry: ${BUNDLE_NAME}"
echo "  Image: ${IMAGE_REF}"

SKIP_RANGE=">=0.1.0 <${VERSION}"

yq eval -i '
    (.entries[] | select(.schema == "olm.channel" and .name == "fast") | .entries) +=
    [{"name": "'"$BUNDLE_NAME"'", "replaces": "'"$PREVIOUS_HEAD"'", "skipRange": "'"$SKIP_RANGE"'"}]
' "$TEMPLATE"

yq eval -i '
    (.entries[] | select(.schema == "olm.channel" and .name == "stable") | .entries) +=
    [{"name": "'"$BUNDLE_NAME"'", "replaces": "'"$PREVIOUS_HEAD"'", "skipRange": "'"$SKIP_RANGE"'"}]
' "$TEMPLATE"

yq eval -i '
    .entries += [{"image": "'"$IMAGE_REF"'", "schema": "olm.bundle"}]
' "$TEMPLATE"

cat >"$UPDATE_SCRIPT" <<EOF
#!/bin/bash
# Bundle digest for operator version ${VERSION}.
#
# This file is a data source, not meant to be executed directly.
# It is sourced by hack/generate-catalogs.sh during catalog generation.
#
# To update the digest (e.g. after a Konflux component rebuild):
#   edit the LATEST= line below, then push to main.
#   The GitHub Actions workflow will regenerate catalogs automatically.

BUNDLE_VERSION="${VERSION}"
LATEST="${IMAGE_REF}"
EOF
chmod +x "$UPDATE_SCRIPT"

echo ""
echo "Done. Created:"
echo "  - Update script: $UPDATE_SCRIPT"
echo "  - Added channel entries for ${BUNDLE_NAME} to fast and stable channels"
echo "  - Added olm.bundle entry with image ${IMAGE_REF}"
echo ""
echo "Next steps:"
echo "  1. Update config/channels.yaml if this version should be the stable head for any OCP versions"
echo "  2. Run 'make generate-catalog' to regenerate catalogs"
