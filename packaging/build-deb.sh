#!/usr/bin/env bash
set -euo pipefail

suite=${1:?Usage: packaging/build-deb.sh SUITE}
case "$suite" in
  jammy) suffix=ubuntu22.04.1 ;;
  noble) suffix=ubuntu24.04.1 ;;
  resolute) suffix=ubuntu26.04.1 ;;
  trixie) suffix=deb13.1 ;;
  *) echo "Unsupported suite: $suite" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."
base_version=$(dpkg-parsechangelog -S Version)
upstream_version=$(sed -n 's/^#define XSCREENSAVER_VERSION "\([^"]*\)"/\1/p' utils/version.h)
if [[ ${base_version%%-*} != "$upstream_version" ]]; then
  echo "Source version $upstream_version disagrees with changelog $base_version" >&2
  exit 1
fi

# Keep distribution changes outside the mirrored upstream files in git.
install -m 0644 packaging/xscreensaver.pam driver/xscreensaver.pam
sed -i 's/^Maintainer: .*/Maintainer: brozkeff <brozkeff@users.noreply.github.com>/' debian/control
export DEBFULLNAME=brozkeff
export DEBEMAIL=brozkeff@users.noreply.github.com
dch --newversion "${base_version}+${suffix}" --distribution "$suite" \
  "Rebuild upstream XScreenSaver for $suite."

# The mirrored configure currently contains an unexpanded gettext macro.
# Debian rules disable dh_autoreconf, so regenerate it inside CI before build.
aclocal
autoconf
autoheader
if grep -Fq 'AM_GNU_GETTEXT(external)' configure; then
  echo 'configure still contains an unexpanded gettext macro' >&2
  exit 1
fi

dpkg-buildpackage -b -us -uc -j2

deb=$(realpath "../xscreensaver_${base_version}+${suffix}_amd64.deb")
test -f "$deb"
test "$(dpkg-deb -f "$deb" Architecture)" = amd64
test "$(dpkg-deb -f "$deb" Version)" = "${base_version}+${suffix}"
validation_dir=$(mktemp -d)
readonly validation_dir
trap 'rm -rf -- "$validation_dir"' EXIT
dpkg-deb --extract "$deb" "$validation_dir"
cmp "$validation_dir/etc/pam.d/xscreensaver" packaging/xscreensaver.pam
auth_helper="$validation_dir/usr/libexec/xscreensaver/xscreensaver-auth"
test -f "$auth_helper" && test ! -L "$auth_helper"
test "$(stat -c '%u:%a' "$auth_helper")" = '0:4755'
apt-get -s install "$deb"

mkdir -p "dist/$suite"
cp "$deb" "dist/$suite/"
if [[ -n ${GITHUB_OUTPUT:-} ]]; then
  printf 'deb=%s\n' "$PWD/dist/$suite/$(basename "$deb")" >> "$GITHUB_OUTPUT"
fi
