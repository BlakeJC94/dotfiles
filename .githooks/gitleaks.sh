#!/bin/sh

if [ ! -f "$HOME/.dotfiles.activate" ]; then
    exit 0
fi

if ! command -v gitleaks >/dev/null 2>&1; then
    echo "ERROR: gitleaks not found"
    exit 1
fi

gitleaks git
