#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$ROOT_DIR/.github/package-sync-targets.json}"
REPO_DIR="$ROOT_DIR/t2manjaro"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required tool: $1" >&2
        exit 1
    fi
}

require_tool gh
require_tool jq
require_tool repo-add

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
    echo "GH_TOKEN is required to download release assets." >&2
    exit 1
fi

mkdir -p "$REPO_DIR"

delete_matching_packages() {
    local asset_pattern="$1"

    while IFS= read -r package_file; do
        [[ -z "$package_file" ]] && continue
        rm -f "$REPO_DIR/$package_file"
    done < <(
        find "$REPO_DIR" -maxdepth 1 -type f -name "*.pkg.tar.zst" -printf '%f\n' \
            | jq -Rsc --arg re "$asset_pattern" 'split("\n")[] | select(length > 0 and test($re))' -r
    )
}

sync_target() {
    local target_json="$1"
    local name repo asset_pattern latest_tag

    name="$(jq -r '.name' <<<"$target_json")"
    repo="$(jq -r '.repo' <<<"$target_json")"
    asset_pattern="$(jq -r '.asset_pattern' <<<"$target_json")"

    echo "Syncing $name packages from $repo"

    latest_tag="$(gh release view --repo "$repo" --json tagName --jq '.tagName')"
    if [[ -z "$latest_tag" ]]; then
        echo "Could not determine latest release tag for $repo" >&2
        exit 1
    fi

    mapfile -t assets < <(
        gh release view "$latest_tag" --repo "$repo" --json assets \
            --jq ".assets[] | select(.name | test(\"$asset_pattern\")) | .name"
    )

    if [[ "${#assets[@]}" -eq 0 ]]; then
        echo "No release assets matched pattern $asset_pattern in $repo@$latest_tag" >&2
        exit 1
    fi

    delete_matching_packages "$asset_pattern"

    for asset in "${assets[@]}"; do
        gh release download "$latest_tag" --repo "$repo" --pattern "$asset" --dir "$REPO_DIR"
    done
}

while IFS= read -r target; do
    sync_target "$target"
done < <(jq -c '.targets[]' "$CONFIG_FILE")

rm -f \
    "$REPO_DIR/t2manjaro.db" \
    "$REPO_DIR/t2manjaro.db.tar.gz" \
    "$REPO_DIR/t2manjaro.files" \
    "$REPO_DIR/t2manjaro.files.tar.gz"

(
    cd "$REPO_DIR"
    repo-add t2manjaro.db.tar.gz ./*.pkg.tar.zst
    cp -f t2manjaro.db.tar.gz t2manjaro.db
    cp -f t2manjaro.files.tar.gz t2manjaro.files
)
