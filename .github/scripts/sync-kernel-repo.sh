#!/usr/bin/env bash

set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

delete_asset_if_present() {
  local repo="$1"
  local tag="$2"
  local asset_name="$3"

  if gh release view "$tag" --repo "$repo" --json assets --jq ".assets[] | select(.name == \"$asset_name\") | .name" | grep -qx "$asset_name"; then
    gh release delete-asset "$tag" "$asset_name" --repo "$repo" -y
  fi
}

require_env GH_TOKEN
require_env SOURCE_REPO
require_env SOURCE_ASSET_PATTERN
require_env TARGET_REPO
require_env TARGET_RELEASE_TAG
require_env TARGET_REPO_DB_NAME

TARGET_ASSET_CLEANUP_PATTERN="${TARGET_ASSET_CLEANUP_PATTERN:-$SOURCE_ASSET_PATTERN}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "Fetching latest release metadata from $SOURCE_REPO"
source_release_json="$(gh api "/repos/$SOURCE_REPO/releases/latest")"
source_tag="$(jq -r '.tag_name' <<<"$source_release_json")"

if [[ -z "$source_tag" || "$source_tag" == "null" ]]; then
  echo "Could not resolve the latest release tag for $SOURCE_REPO" >&2
  exit 1
fi

mapfile -t source_assets < <(jq -r --arg re "$SOURCE_ASSET_PATTERN" '.assets[] | select(.name | test($re)) | .name' <<<"$source_release_json")

if [[ "${#source_assets[@]}" -eq 0 ]]; then
  echo "No assets matched SOURCE_ASSET_PATTERN=$SOURCE_ASSET_PATTERN in $SOURCE_REPO@$source_tag" >&2
  exit 1
fi

echo "Matched source assets:"
printf ' - %s\n' "${source_assets[@]}"

mkdir -p "$WORKDIR/repo"

for asset in "${source_assets[@]}"; do
  gh release download "$source_tag" --repo "$SOURCE_REPO" --pattern "$asset" --dir "$WORKDIR/repo"
done

if ! gh release view "$TARGET_RELEASE_TAG" --repo "$TARGET_REPO" >/dev/null 2>&1; then
  echo "Creating target release $TARGET_RELEASE_TAG in $TARGET_REPO"
  gh release create "$TARGET_RELEASE_TAG" --repo "$TARGET_REPO" --title "$TARGET_RELEASE_TAG" --notes "Pacman repo backing release for t2manjaro."
fi

echo "Fetching current target release assets from $TARGET_REPO@$TARGET_RELEASE_TAG"
target_assets_json="$(gh release view "$TARGET_RELEASE_TAG" --repo "$TARGET_REPO" --json assets)"

mapfile -t cleanup_assets < <(jq -r \
  --arg cleanup_re "$TARGET_ASSET_CLEANUP_PATTERN" \
  --arg repo_name "$TARGET_REPO_DB_NAME" \
  '.assets[]
  | select(
      (.name | test($cleanup_re))
      or (.name == ($repo_name + ".db"))
      or (.name == ($repo_name + ".db.tar.gz"))
      or (.name == ($repo_name + ".files"))
      or (.name == ($repo_name + ".files.tar.gz"))
    )
  | .name' <<<"$target_assets_json")

echo "Rebuilding pacman metadata for $TARGET_REPO_DB_NAME"
(
  cd "$WORKDIR/repo"
  rm -f \
    "$TARGET_REPO_DB_NAME.db" \
    "$TARGET_REPO_DB_NAME.db.tar.gz" \
    "$TARGET_REPO_DB_NAME.files" \
    "$TARGET_REPO_DB_NAME.files.tar.gz"

  repo-add "$TARGET_REPO_DB_NAME.db.tar.gz" ./*.pkg.tar.zst
  cp -f "$TARGET_REPO_DB_NAME.db.tar.gz" "$TARGET_REPO_DB_NAME.db"
  cp -f "$TARGET_REPO_DB_NAME.files.tar.gz" "$TARGET_REPO_DB_NAME.files"
)

if [[ "${#cleanup_assets[@]}" -gt 0 ]]; then
  echo "Removing old target assets:"
  printf ' - %s\n' "${cleanup_assets[@]}"
  for asset in "${cleanup_assets[@]}"; do
    delete_asset_if_present "$TARGET_REPO" "$TARGET_RELEASE_TAG" "$asset"
  done
fi

echo "Uploading refreshed assets to $TARGET_REPO@$TARGET_RELEASE_TAG"
gh release upload "$TARGET_RELEASE_TAG" \
  "$WORKDIR/repo"/*.pkg.tar.zst \
  "$WORKDIR/repo/$TARGET_REPO_DB_NAME.db" \
  "$WORKDIR/repo/$TARGET_REPO_DB_NAME.db.tar.gz" \
  "$WORKDIR/repo/$TARGET_REPO_DB_NAME.files" \
  "$WORKDIR/repo/$TARGET_REPO_DB_NAME.files.tar.gz" \
  --repo "$TARGET_REPO"

echo "Kernel repo sync completed from $SOURCE_REPO@$source_tag to $TARGET_REPO@$TARGET_RELEASE_TAG"
