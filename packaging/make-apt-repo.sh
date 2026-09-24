#!/usr/bin/env bash
set -euo pipefail

packages=${1:?Usage: packaging/make-apt-repo.sh PACKAGES_DIR OUTPUT_DIR}
output=${2:?Usage: packaging/make-apt-repo.sh PACKAGES_DIR OUTPUT_DIR}
: "${APT_SIGNING_KEY:?APT_SIGNING_KEY must contain an ASCII-armored private key}"

mkdir -p "$output"
output=$(realpath "$output")
packages=$(realpath "$packages")
cd "$output"
umask 022
export GNUPGHOME
GNUPGHOME=$(mktemp -d)
chmod 700 "$GNUPGHOME"

# GitHub Actions provides a fresh machine; do not persist the imported key.
printf '%s\n' "$APT_SIGNING_KEY" | gpg --batch --import
fingerprint=$(gpg --batch --with-colons --list-secret-keys | awk -F: '$1 == "fpr" { print $10; exit }')
test -n "$fingerprint"
gpg --batch --armor --export "$fingerprint" > xscreensaver-archive-key.asc
touch .nojekyll

for suite in jammy noble resolute trixie; do
  mkdir -p "pool/$suite" "dists/$suite/main/binary-amd64"
  cp "$packages/$suite/"*.deb "pool/$suite/"
  dpkg-scanpackages "pool/$suite" /dev/null > "dists/$suite/main/binary-amd64/Packages"
  gzip -9n -c "dists/$suite/main/binary-amd64/Packages" > \
    "dists/$suite/main/binary-amd64/Packages.gz"
  apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=brozkeff \
    -o APT::FTPArchive::Release::Label='XScreenSaver builds' \
    -o APT::FTPArchive::Release::Suite="$suite" \
    -o APT::FTPArchive::Release::Codename="$suite" \
    -o APT::FTPArchive::Release::Architectures=amd64 \
    -o APT::FTPArchive::Release::Components=main \
    release "dists/$suite" > "dists/$suite/Release"
  gpg --batch --yes --local-user "$fingerprint" --clearsign \
    --output "dists/$suite/InRelease" "dists/$suite/Release"
  gpg --batch --yes --local-user "$fingerprint" --armor --detach-sign \
    --output "dists/$suite/Release.gpg" "dists/$suite/Release"
done
