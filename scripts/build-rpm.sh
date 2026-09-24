#!/usr/bin/env bash
set -euo pipefail

# Package a Flutter Linux bundle as an RPM.
# Usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output.rpm> <release>

BUNDLE="$1"
VERSION="$2"
ARCH="$3"
OUT="$4"
RELEASE="${5:-1}"

TOP="$(mktemp -d)"
trap 'rm -rf "$TOP"' EXIT
mkdir -p "$TOP"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

STAGE="$TOP/BUILD/stage"
mkdir -p "$STAGE/opt/blockbreak" "$STAGE/usr/bin"
cp -r "$BUNDLE/." "$STAGE/opt/blockbreak/"
ln -sf /opt/blockbreak/blockbreak "$STAGE/usr/bin/blockbreak"

cat > "$TOP/SPECS/blockbreak.spec" <<EOF
Name: blockbreak
Version: $VERSION
Release: $RELEASE
Summary: Incremental idle mining game
License: AGPL-3.0
BuildArch: $ARCH

%description
Tap to swing your pickaxe, shatter blocks, craft stronger pickaxes
and dig through every biome from the Plains to The End.

%install
mkdir -p %{buildroot}/opt/blockbreak %{buildroot}/usr/bin
cp -r "$STAGE/opt/blockbreak/." %{buildroot}/opt/blockbreak/
ln -sf /opt/blockbreak/blockbreak %{buildroot}/usr/bin/blockbreak

%files
/opt/blockbreak
/usr/bin/blockbreak

%changelog
* $(date '+%a %b %d %Y') CI <ci@gitlab.com> - $VERSION-$RELEASE
- Automated build
EOF

rpmbuild --define "_topdir $TOP" -bb "$TOP/SPECS/blockbreak.spec"
cp "$TOP/RPMS/$ARCH/blockbreak-$VERSION-$RELEASE.$ARCH.rpm" "$OUT"
