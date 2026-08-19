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
xbps-install -y bash git perl libarchive file curl

git clone --depth 1 https://github.com/void-linux/void-packages.git
cp -r "$CI_PROJECT_DIR"/srcpkgs/. void-packages/srcpkgs/

# srcpkgs/rsv-ng/template pins an exact _commit/version/checksum (xbps-src
# has no VCS-package concept like AUR's pkgver()), so without this it
# would silently keep building whatever commit it last named instead of
# the commit actually being tested/deployed. Rewrite those three fields
# to the current commit on every build instead. GIT_DEPTH=0 in
# .gitlab-ci.yml ensures the count below reflects full history, not a
# shallow clone.
tmpl=void-packages/srcpkgs/rsv-ng/template
commit="$CI_COMMIT_SHA"
version="$(git -C "$CI_PROJECT_DIR" rev-list --count HEAD)"
archive_url="${CI_PROJECT_URL}/-/archive/${commit}/${CI_PROJECT_NAME}-${commit}.tar.gz"
checksum="$(curl -fsSL "$archive_url" | sha256sum | cut -d' ' -f1)"
[ -n "$checksum" ] || { echo "Failed to fetch/checksum $archive_url" >&2; exit 1; }
sed -i \
	-e "s/^_commit=.*/_commit=${commit}/" \
	-e "s/^version=.*/version=${version}/" \
	-e "s/^revision=.*/revision=1/" \
	-e "s/^checksum=.*/checksum=${checksum}/" \
	"$tmpl"

cd void-packages

# Ethereal chroot-style requires XBPS_MASTERDIR symlinked to /, which makes
# `cp -f /etc/resolv.conf $XBPS_MASTERDIR/etc` copy the file onto itself -
# GNU cp errors on that. Make it non-fatal instead.
patch_target=common/xbps-src/shutils/chroot.sh
sed -i.bak 's@cp -f /etc/resolv.conf \$XBPS_MASTERDIR/etc@cp -f /etc/resolv.conf \$XBPS_MASTERDIR/etc 2>/dev/null || true@' "$patch_target"
rm -f "$patch_target.bak"

ln -s / masterdir

echo "IN_CHROOT_PREP_DONE"
