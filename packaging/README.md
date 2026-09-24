# Debian and Ubuntu packages

The intended targets are Ubuntu 22.04 (`jammy`), 24.04 (`noble`), 26.04
(`resolute`), and Debian 13 (`trixie`), on amd64. The current test stage builds
only `jammy`. Add one target at a time after the preceding target passes;
builds must remain serial (`max-parallel: 1`). Each build runs inside its
corresponding distribution container, checks the PAM file and setuid
authentication helper, and asks APT to simulate installation. The source is
the checked-out commit of this fork; syncing the fork updates the source used
by the next build.

The mirrored `configure` currently has an unexpanded gettext macro. The CI
build regenerates it with Autotools before packaging; nothing is regenerated
on the local workstation.

The build overlays the distribution PAM policy from `packaging/xscreensaver.pam`
and changes package maintainer metadata during CI. These changes are kept out
of upstream files so later fork syncs can merge cleanly. Upstream's package
combines the binaries and display modes and declares that it replaces the
older distribution `xscreensaver-data` and `xscreensaver-gl` packages. The
first install on a real machine still needs a manual lock/unlock test.

## Build and publish

The `Build Debian packages` workflow currently runs only the Ubuntu 22.04
build on pushes to `master`, pull requests, and manual dispatch. Successful
builds upload DEBs as workflow artifacts for inspection. Publishing is
disabled during staged validation. Once all four targets pass serially,
re-enable the manual publish job and review the resulting packages.

When all target builds pass, enable publishing:

1. Retain an encrypted offline backup of the dedicated archive signing key.
2. Add its ASCII-armored private key as the repository secret
   `APT_SIGNING_KEY`. The build checks that it matches the committed public
   key at `packaging/xscreensaver-archive-key.asc`, fingerprint
   `6EFF 589C 3E04 7675 3521 1806 4F16 B127 AAA5 9C6D`.
3. In the fork's GitHub Pages settings, choose **GitHub Actions** as the
   publishing source.
4. Dispatch the workflow from the reviewed `master` commit with `publish`
   enabled.

The published site is an APT repository with `dists/{jammy,noble,resolute,trixie}`
and a public key at `xscreensaver-archive-key.asc`. Verify that public key's
fingerprint before trusting the repository. A client uses its own suite:

```sh
curl -fsSL https://brozkeff.github.io/xscreensaver/xscreensaver-archive-key.asc \
  | sudo tee /usr/share/keyrings/xscreensaver-archive-key.asc >/dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/xscreensaver-archive-key.asc] https://brozkeff.github.io/xscreensaver jammy main' \
  | sudo tee /etc/apt/sources.list.d/brozkeff-xscreensaver.list
sudo apt update
sudo apt install xscreensaver
```

Replace `jammy` with the matching suite on the other distributions. These
commands apply only after a signed repository has been published. Existing
XScreenSaver users should verify their unlock method immediately after an
upgrade while they still have an active session.
