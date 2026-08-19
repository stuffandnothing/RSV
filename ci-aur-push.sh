#!/bin/sh
# ci-aur-push.sh
#
# Mirrors PKGBUILD from this repo to the AUR git repo
# (aur.archlinux.org/rsv-ng.git) whenever PKGBUILD changes on main.
#
# rsv-ng is a VCS (-git style) AUR package: its pkgver() pulls this repo's
# HEAD at build time via `source=("$pkgname::git+$url")`, so users always
# get current code without any push here. This job only needs to run when
# PKGBUILD's own content changes (deps, description, install steps, etc.)
# - the .gitlab-ci.yml rule that calls this script gates on that already.
#
# makepkg refuses to run as root, so the clone/makepkg/push work happens
# as an unprivileged "builder" user created here. Values interpolated into
# builder-step.sh below happen in this (root) shell, before the script is
# handed to `su`, to avoid the nested-quoting escaping issues called out
# in .gitlab-ci.yml's top comment.
#
# Required CI/CD variable (Settings > CI/CD > Variables, masked+protected):
#   AUR_SSH_PRIVATE_KEY_B64 - base64 of the private half of an SSH key
#     added to your AUR account's "My Account > SSH Public Key". GitLab's
#     masked-variable rule rejects multi-line/whitespace values, which a
#     PEM private key is, so it's stored base64'd (same trick as
#     SIGN_PRIVKEY_B64 above) and decoded below. Generate one dedicated
#     to CI with:
#       ssh-keygen -t ed25519 -f aur_deploy -N ""
#       base64 -w0 aur_deploy   -> paste as AUR_SSH_PRIVATE_KEY_B64
#     then add aur_deploy.pub to your AUR account.
#
# Optional CI/CD variables:
#   AUR_GIT_NAME/AUR_GIT_EMAIL - commit author for the AUR push, defaults
#     to the PKGBUILD's "# Maintainer:" line.
set -e

: "${AUR_SSH_PRIVATE_KEY_B64:?AUR_SSH_PRIVATE_KEY_B64 CI/CD variable not set}"

maintainer_line="$(sed -n 's/^# Maintainer: //p' "$CI_PROJECT_DIR/PKGBUILD" | head -n1)"
AUR_GIT_EMAIL="${AUR_GIT_EMAIL:-${maintainer_line##* }}"
AUR_GIT_NAME="${AUR_GIT_NAME:-${maintainer_line% *}}"

useradd -m builder

install -d -m 700 -o builder -g builder /home/builder/.ssh
echo "$AUR_SSH_PRIVATE_KEY_B64" | base64 -d >/home/builder/.ssh/id_ed25519
chmod 600 /home/builder/.ssh/id_ed25519
chown builder:builder /home/builder/.ssh/id_ed25519
ssh-keyscan -H aur.archlinux.org >/home/builder/.ssh/known_hosts 2>/dev/null
chown builder:builder /home/builder/.ssh/known_hosts

cat >/tmp/builder-step.sh <<EOF
set -e
cd /tmp
git clone ssh://aur@aur.archlinux.org/rsv-ng.git aur-rsv-ng
cp "$CI_PROJECT_DIR/PKGBUILD" aur-rsv-ng/PKGBUILD
cd aur-rsv-ng
makepkg --printsrcinfo >.SRCINFO
git config user.name "$AUR_GIT_NAME"
git config user.email "$AUR_GIT_EMAIL"
git add PKGBUILD .SRCINFO
if git diff --cached --quiet; then
	echo "AUR package already up to date, nothing to push."
else
	git commit -m "Update PKGBUILD from $CI_PROJECT_URL@$CI_COMMIT_SHORT_SHA"
	git push origin master
fi
EOF
chown builder:builder /tmp/builder-step.sh

su builder -c 'sh /tmp/builder-step.sh'
