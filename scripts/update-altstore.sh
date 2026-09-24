#!/usr/bin/env bash
set -euo pipefail

# Regenerate altstore/apps.json from the freshly synced GitLab release and
# commit it back to main with ci.skip. The IPA download URL points at the
# package-registry link which never expires.
#
# Runs inside the github-release-sync job (glab + git + deploy key present).

RELEASE_TAG="${RELEASE_TAG:-}"
PROJECT_DIR="${CI_PROJECT_DIR:-$PWD}"
cd "$PROJECT_DIR"

# Only versioned releases update the source; nightly is not an app update.
case "$RELEASE_TAG" in
  v*) ;;
  *) echo "Skipping AltStore update for tag '$RELEASE_TAG'"; exit 0 ;;
esac

VERSION="${RELEASE_TAG#v}"
IPA_NAME="blockbreak-ios-arm64-unsigned.ipa"
PKG_ID=$(glab api "projects/$CI_PROJECT_ID/packages?package_name=release-assets&package_version=$RELEASE_TAG" \
  | jq -r '.[0].id // empty')
SIZE=0
if [ -n "$PKG_ID" ]; then
  SIZE=$(glab api "projects/$CI_PROJECT_ID/packages/$PKG_ID/package_files" \
    | jq -r --arg f "$IPA_NAME" '.[] | select(.file_name == $f) | .size' \
    | head -n1)
fi
SIZE=${SIZE:-0}
DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ICON_URL="https://gitlab.com/$CI_PROJECT_PATH/-/raw/main/assets/icon/icon-1024.png"
DL_URL="https://gitlab.com/api/v4/projects/$CI_PROJECT_ID/packages/generic/release-assets/$RELEASE_TAG/$IPA_NAME"

git config user.name "GitLab CI"
git config user.email "ci@gitlab.com"
git remote add gitlab-ssh "git@gitlab.com:$CI_PROJECT_PATH.git" 2>/dev/null || true
git fetch gitlab-ssh main
git checkout -B main gitlab-ssh/main

mkdir -p altstore
cat > /tmp/new-version.json <<EOF
{
  "version": "$VERSION",
  "date": "$DATE",
  "downloadURL": "$DL_URL",
  "size": $SIZE,
  "minOSVersion": "12.0"
}
EOF

if [ -f altstore/apps.json ]; then
  # Prepend the new version, dropping any stale entry for the same tag.
  jq --argjson v "$(cat /tmp/new-version.json)" \
    '.apps[0].versions = ([$v] + [.apps[0].versions[] | select(.version != $v.version)])' \
    altstore/apps.json > /tmp/apps.json
  mv /tmp/apps.json altstore/apps.json
else
  cat > altstore/apps.json <<EOF
{
  "name": "BlockBreak",
  "identifier": "com.httpanimations.blockbreak.source",
  "iconURL": "$ICON_URL",
  "apps": [
    {
      "name": "BlockBreak",
      "bundleIdentifier": "com.httpanimations.blockbreak",
      "developerName": "HttpAnimations",
      "iconURL": "$ICON_URL",
      "tintedIconURL": "$ICON_URL",
      "versions": [$(cat /tmp/new-version.json)],
      "news": []
    }
  ]
}
EOF
fi

git add altstore/apps.json
if git diff --cached --quiet; then
  echo "AltStore source already up to date"
  exit 0
fi
git commit -m "chore: 更新 AltStore 源"
git push -o ci.skip gitlab-ssh HEAD:main
echo "AltStore source updated for $RELEASE_TAG"
