#!/bin/sh
# ci-sign.sh
#
# Indexes and signs each arch's repo dir under public/. Run from the
# project root ($CI_PROJECT_DIR) with SIGN_PRIVKEY_B64 and SIGN_NAME set.
set -e

echo "$SIGN_PRIVKEY_B64" | base64 -d > /tmp/privkey.pem
openssl rsa -in /tmp/privkey.pem -pubout -out /tmp/pubkey.pem

for arch in x86_64 x86_64-musl; do
	d="public/$arch"
	[ -d "$d" ] || continue
	# shellcheck disable=SC2012
	[ -n "$(ls -A "$d"/*.xbps 2>/dev/null)" ] || continue

	XBPS_ARCH="$arch" xbps-rindex -a "$d"/*.xbps
	XBPS_ARCH="$arch" xbps-rindex -S "$d"/*.xbps --privkey /tmp/privkey.pem
	XBPS_ARCH="$arch" xbps-rindex -s "$d" --signedby "$SIGN_NAME" --privkey /tmp/privkey.pem
	cp /tmp/pubkey.pem "$d/pubkey.pem"
done
