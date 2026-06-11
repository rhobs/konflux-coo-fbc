#!/bin/bash
# Generate per-OCP-version FBC catalogs from the catalog template.
#
# This script is the core of the catalog build. It:
#   1. Sources all hack/update-bundle-*.sh files to get bundle digests
#   2. Injects those digests into the template
#   3. For each OCP version, truncates the stable channel to the head
#      configured in config/channels.yaml
#   4. Renders the template with opm into per-OCP output directories
#
# The fast channel is never modified — it always contains the full
# upgrade graph (i.e., the latest bundle is always the fast head).
#
# Usage:
#   make generate-catalog          # normal path (Makefile passes OPM=)
#   OPM=./opm ./hack/generate-catalogs.sh  # standalone
#
# Prerequisites:
#   - opm binary (installed via `make tools`)
#   - yq (https://github.com/mikefarah/yq)
#   - Authenticated to registry.redhat.io (opm needs to pull bundle images)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$REPO_ROOT/config/channels.yaml"
TEMPLATE="$REPO_ROOT/catalog/catalog-template.yaml"
OPM="${OPM:-${REPO_ROOT}/.tmp/bin/opm}"

OCP_VERSIONS=(4.12 4.13 4.14 4.15 4.16 4.17 4.18 4.19 4.20 4.21 4.22)

QUAY_REF="quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle"
PROD_REF="registry.redhat.io/cluster-observability-operator/cluster-observability-operator-bundle"

needs_migrate() {
    local version="$1"
    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    [[ "$major" -eq 4 && "$minor" -ge 17 ]]
}

get_stable_head() {
    local ocp_version="$1"
    yq eval ".stable[] | select(.versions[] == \"$ocp_version\") | .head" "$CONFIG"
}

inject_bundle_digests() {
    local template="$1"
    for update_script in "$SCRIPT_DIR"/update-catalogs-*.sh; do
        [[ -f "$update_script" ]] || continue

        BUNDLE_VERSION=""
        LATEST=""
        # shellcheck source=/dev/null
        source "$update_script"

        if [[ -z "$BUNDLE_VERSION" || -z "$LATEST" ]]; then
            echo "Warning: skipping $update_script (missing BUNDLE_VERSION or LATEST)"
            continue
        fi

        local bundle_name="cluster-observability-operator.v${BUNDLE_VERSION}"
        local channel_entries
        channel_entries=$(yq eval '
            .entries[] | select(.schema == "olm.channel" and .name == "fast") |
            .entries[].name
        ' "$template")

        local index=0
        local found=false
        while IFS= read -r entry_name; do
            if [[ "$entry_name" == "$bundle_name" ]]; then
                found=true
                break
            fi
            index=$((index + 1))
        done <<<"$channel_entries"

        if [[ "$found" == "true" ]]; then
            local bundle_entry_offset
            bundle_entry_offset=$(yq eval '
                [.entries[] | select(.schema == "olm.channel" or .schema == "olm.package")] | length
            ' "$template")
            local absolute_index=$((bundle_entry_offset + index))
            VALUE="$LATEST" yq eval -i ".entries[$absolute_index].image = strenv(VALUE)" "$template"
        else
            echo "Warning: bundle $bundle_name not found in channel entries, skipping digest injection"
        fi
    done
}

truncate_stable_channel() {
    local template="$1"
    local stable_head="$2"

    local channel_entries
    channel_entries=$(yq eval '
        .entries[] | select(.schema == "olm.channel" and .name == "stable") |
        .entries[].name
    ' "$template")

    local keep_count=0
    while IFS= read -r entry_name; do
        keep_count=$((keep_count + 1))
        if [[ "$entry_name" == "$stable_head" ]]; then
            break
        fi
    done <<<"$channel_entries"

    if [[ "$keep_count" -eq 0 ]]; then
        echo "Error: stable head $stable_head not found in stable channel entries"
        exit 1
    fi

    yq eval -i "
        (.entries[] | select(.schema == \"olm.channel\" and .name == \"stable\") | .entries) |=
        .[:$keep_count]
    " "$template"
}

echo "Injecting bundle digests into template..."
WORK_TEMPLATE=$(mktemp)
cp "$TEMPLATE" "$WORK_TEMPLATE"
inject_bundle_digests "$WORK_TEMPLATE"

for V in "${OCP_VERSIONS[@]}"; do
    OUTPUT_DIR="$REPO_ROOT/catalog/coo-product-v${V}"
    mkdir -p "$OUTPUT_DIR"

    STABLE_HEAD=$(get_stable_head "$V")
    if [[ -z "$STABLE_HEAD" ]]; then
        echo "Error: no stable head configured for OCP $V in $CONFIG"
        exit 1
    fi

    OCP_TEMPLATE=$(mktemp)
    cp "$WORK_TEMPLATE" "$OCP_TEMPLATE"

    echo "Generating catalog for OCP $V (stable head: $STABLE_HEAD)..."
    truncate_stable_channel "$OCP_TEMPLATE" "$STABLE_HEAD"

    MIGRATE_FLAG=""
    if needs_migrate "$V"; then
        MIGRATE_FLAG="--migrate-level bundle-object-to-csv-metadata"
    fi

    # shellcheck disable=SC2086
    $OPM alpha render-template basic --output yaml $MIGRATE_FLAG "$OCP_TEMPLATE" >"$OUTPUT_DIR/catalog.yaml"

    sed -i "s|${QUAY_REF}|${PROD_REF}|g" "$OUTPUT_DIR/catalog.yaml"

    rm "$OCP_TEMPLATE"
done

rm "$WORK_TEMPLATE"
echo "Done. Generated catalogs for ${#OCP_VERSIONS[@]} OCP versions."
