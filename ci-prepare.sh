#!/bin/sh
# ci-prepare.sh
#
# Prepares an ethereal xbps-src build inside a void-linux/void-*-full
# container. Run from the project root ($CI_PROJECT_DIR).
set -e

mkdir -p /build
cd /build

xbps-install -Suy xbps
xbps-install -S
xbps-install -y bash git perl libarchive file

git clone --depth 1 https://github.com/void-linux/void-packages.git
cp -r "$CI_PROJECT_DIR"/srcpkgs/. void-packages/srcpkgs/

cd void-packages

# Ethereal chroot-style requires XBPS_MASTERDIR symlinked to /, which makes
# `cp -f /etc/resolv.conf $XBPS_MASTERDIR/etc` copy the file onto itself -
# GNU cp errors on that. Make it non-fatal instead.
patch_target=common/xbps-src/shutils/chroot.sh
sed -i.bak 's@cp -f /etc/resolv.conf \$XBPS_MASTERDIR/etc@cp -f /etc/resolv.conf \$XBPS_MASTERDIR/etc 2>/dev/null || true@' "$patch_target"
rm -f "$patch_target.bak"

ln -s / masterdir

echo "IN_CHROOT_PREP_DONE"
