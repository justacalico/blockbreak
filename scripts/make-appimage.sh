#!/usr/bin/env bash
set -euo pipefail

# Package a Flutter Linux bundle as an AppImage.
# Usage: make-appimage.sh <bundle-dir> <arch(x86_64|arm64)> <output.AppImage>

BUNDLE="$1"
ARCH="$2"
OUT="$3"

case "$ARCH" in
  x86_64) AI_ARCH=x86_64 ;;
  arm64)  AI_ARCH=aarch64 ;;
  *) echo "unsupported arch $ARCH" >&2; exit 1 ;;
esac

APPDIR="$(mktemp -d)/blockbreak.AppDir"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/pixmaps"
cp -r "$BUNDLE/." "$APPDIR/usr/bin/"

cat > "$APPDIR/usr/share/applications/blockbreak.desktop" <<'EOF'
[Desktop Entry]
Name=BlockBreak
Exec=blockbreak
Icon=blockbreak
Type=Application
Categories=Game;
EOF

cp "$APPDIR/usr/share/applications/blockbreak.desktop" "$APPDIR/blockbreak.desktop"
cp linux/assets/icon.png "$APPDIR/blockbreak.png"
cp linux/assets/icon.png "$APPDIR/usr/share/pixmaps/blockbreak.png"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
cd "$(dirname "$0")/usr/bin" || exit 1
exec ./blockbreak "$@"
EOF
chmod +x "$APPDIR/AppRun"

TOOL=/tmp/appimagetool.AppImage
curl -fsSL --retry 3 -o "$TOOL" \
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$AI_ARCH.AppImage"
chmod +x "$TOOL"

ARCH="$AI_ARCH" APPIMAGE_EXTRACT_AND_RUN=1 "$TOOL" "$APPDIR" "$OUT"
