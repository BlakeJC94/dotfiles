# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-01

### Added
- Initial release.
- Automatic snapshot of `write`/`edit` tool calls, keyed to conversation entries.
- `/snapshots` command to restore the working tree to any entry's state.
- Auto-offer to restore file state on `/fork`.
- Pure, unit-tested store logic with `node:test`.
- Configurable store root via `PI_FILE_SNAPSHOTS_DIR`.

[Unreleased]: https://github.com/earendil-works/pi-file-snapshots/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/earendil-works/pi-file-snapshots/releases/tag/v0.1.0
