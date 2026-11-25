# herdr-gitview

[![CI](https://github.com/ChmaraX/herdr-gitview/actions/workflows/ci.yml/badge.svg)](https://github.com/ChmaraX/herdr-gitview/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/ChmaraX/herdr-gitview)](https://github.com/ChmaraX/herdr-gitview/releases/latest)
[![License](https://img.shields.io/github/license/ChmaraX/herdr-gitview)](LICENSE)

A **Herdr TUI plugin** for reviewing and managing Git changes. Browse staged,
unstaged, and branch-scope diffs; stage, discard, and commit; edit in a real
nvim; and send review notes to an agent pane.

## Install

Install the plugin from GitHub:

```bash
herdr plugin install ChmaraX/herdr-gitview
```

For a local checkout, build and link it:

```bash
cargo build --release
herdr plugin link "$PWD"
```

Bind `chmarax.gitview.toggle` or `chmarax.gitview.toggle-tab` in
`~/.config/herdr/config.toml`. See [TUI.md](TUI.md) for keybindings, setup,
configuration, and feature details.

## Requirements

- Herdr TUI 0.7.0 or newer.
- Git; nvim is needed for the editor features.
- macOS or Linux.

## Attribution

The structured diff renderer and highlighting approach are ported, in
simplified form, from [herdr-reviewr](https://github.com/persiyanov/herdr-reviewr)
(MIT).

## License

[MIT](LICENSE)
