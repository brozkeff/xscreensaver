# XScreenSaver package build fork

This fork maintains Debian and Ubuntu package build automation for XScreenSaver.
The parent repository mirrors Jamie Zawinski's upstream source. Work in this
fork is limited to packaging, CI, APT repository metadata, and documentation
needed to operate those builds. Do not submit changes from this fork upstream
unless the user explicitly requests it.

## Working on builds

- Keep fork-specific files in `packaging/` and `.github/` where practical so
  future syncs from the parent repository remain straightforward.
- Build from a reviewed source commit. Do not silently fetch a moving source
  branch inside a release job.
- Build each distribution package in its own target distribution environment.
  The current targets are Ubuntu 22.04, 24.04, 26.04, and Debian 13 on amd64.
- Check package dependencies, PAM configuration, the setuid authentication
  helper, and an APT install simulation before publishing.
- Keep the APT signing private key in GitHub Actions secrets. Never commit it
  or print it in build logs.
- Publishing and installing are separate from building. Publish only reviewed
  packages; test locking and unlocking on a target desktop after installation.

Keep documentation and scripts in English unless the user requests another
language. Preserve upstream files when syncing the fork.

## Workflow dependency pins

The following versions and immutable SHA-256/commit pins were checked on
2026-09-24. The workflow in `.github/workflows/deb-packages.yml` is the source
of truth for active pins; update this ledger whenever its pins change. The
Ubuntu 24.04, Ubuntu 26.04, and Debian 13 image pins were prepared on that
date but removed from the active matrix for serial, one-suite-at-a-time
validation. Recheck their digests before restoring those targets.

| Dependency | Version/tag | Pinned SHA |
| --- | --- | --- |
| `actions/checkout` | `v7.0.1` | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `actions/upload-artifact` | `v7.0.1` | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |
| `actions/download-artifact` | `v8.0.1` | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` |
| `actions/configure-pages` | `v6.0.0` | `45bfe0192ca1faeb007ade9deae92b16b8254a0d` |
| `actions/upload-pages-artifact` | `v5.0.0` | `fc324d3547104276b827a68afc52ff2a11cc49c9` |
| `actions/deploy-pages` | `v5.0.1` | `368f82528645a54fb793d4d04e342629a3f51346` |
| `ubuntu` image | `22.04` | `sha256:b8b6ee6aa931ecd9d0d952abc34dc0e5f7c6a30c6bb71b079fe399fde0329c02` |
| `ubuntu` image | `24.04` | `sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3` |
| `ubuntu` image | `26.04` | `sha256:da6fc2be547864451aa253836dd926da33623312df4a9a243e35dc877c378a78` |
| `debian` image | `trixie` | `sha256:9cc080028c43b27d2074d63a5f9caf7166d731494965616c1a6d2827a004585c` |

For future work, check the official action releases and image registries for
newer compatible versions and their exact SHAs. Ask the user whether to
modernize the workflow before changing these pins. Do not replace immutable
pins with moving tags. Package builds and repository generation belong in
GitHub Actions, not on the local workstation.
