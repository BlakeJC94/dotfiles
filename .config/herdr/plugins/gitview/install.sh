#!/bin/sh
# Install, update, or uninstall the Herdr TUI plugin:
#
#   curl -fsSL https://raw.githubusercontent.com/ChmaraX/herdr-gitview/main/install.sh | sh
#   install.sh [--uninstall]
set -eu

repo=ChmaraX/herdr-gitview
plugin=chmarax.gitview
uninstall=

say() { printf 'gitview: %s\n' "$*"; }
die() { printf 'gitview: %s\n' "$*" >&2; exit 1; }

case "${1:-}" in
  --uninstall) uninstall=1 ;;
  -h|--help)
    printf 'Install or update the Herdr TUI plugin; use --uninstall to remove it.\n'
    exit 0
    ;;
  "") ;;
  *) die "unknown argument $1" ;;
esac
[ "$#" -le 1 ] || die "too many arguments"

command -v herdr >/dev/null 2>&1 || die "the herdr TUI is not installed (https://herdr.dev)"
plugins=$(herdr plugin list)
if entry=$(printf '%s\n' "$plugins" | grep -F -- "- $plugin "); then
  :
else
  entry=
fi

if [ -n "$uninstall" ]; then
  if [ -z "$entry" ]; then
    say "the TUI plugin is not installed"
  else
    herdr plugin uninstall "$plugin"
    say "removed the TUI plugin"
  fi
elif [ -n "$entry" ]; then
  case "$entry" in
    *"[local:"*) say "the TUI plugin is linked from a checkout; left as it is" ;;
    *)
      herdr plugin update --yes "$plugin"
      say "updated the TUI plugin"
      ;;
  esac
else
  herdr plugin install --yes "$repo"
  say "installed the TUI plugin; bind its keys in ~/.config/herdr/config.toml (see TUI.md#install)"
fi
