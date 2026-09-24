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
