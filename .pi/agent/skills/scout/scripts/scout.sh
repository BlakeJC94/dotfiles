#!/usr/bin/env bash
# Scout helper — check KB status, list topics, and validate structure
set -euo pipefail

KB_DIR=".agents/knowledge"
CMD="${1:-status}"

case "$CMD" in
  status)
    if [ -d "$KB_DIR" ]; then
      echo "exists"
      if [ -f "$KB_DIR/README.md" ]; then
        echo "has_readme"
        head -5 "$KB_DIR/README.md"
      fi
      # List subdirectories (topics)
      for d in "$KB_DIR"/*/; do
        [ -d "$d" ] && echo "topic:$(basename "$d")"
      done
    else
      echo "missing"
    fi
    ;;
  check-sync)
    # Quick staleness check: compare vs. project root
    if [ ! -f "$KB_DIR/README.md" ]; then
      echo "No README.md to check"
      exit 0
    fi
    # Extract directories mentioned in KB
    echo "Checking key project files..."
    for f in package.json Cargo.toml pyproject.toml go.mod Gemfile Makefile justfile; do
      if [ -f "$f" ]; then
        echo "has:$f"
      fi
    done
    # Compare with KB listing
    if grep -q "package.json" "$KB_DIR/README.md" 2>/dev/null && [ ! -f "package.json" ]; then
      echo "WARN: README mentions package.json but file is gone"
    fi
    ;;
  suggest-topics)
    # Heuristic: list top-level dirs with meaningful code
    echo "Suggesting topics from project structure..."

    # Build a gitignore-aware filter if .gitignore exists
    IGNORE_FILTER="cat"
    if [ -f .gitignore ]; then
      # Collect gitignore patterns, skipping comments and blanks
      patterns=$(grep -v '^\s*#' .gitignore | grep -v '^\s*$' | tr '\n' '|' | sed 's/|$//')
      if [ -n "$patterns" ]; then
        IGNORE_FILTER="grep -vE '^($patterns)$'"
      fi
    fi

    for d in */; do
      name="${d%/}"
      # Skip hidden dirs and common build artifacts unconditionally
      case "$name" in
        .*|node_modules|target|dist|build|vendor|.agents) continue ;;
      esac
      # Skip directories matched by .gitignore
      if [ -f .gitignore ] && grep -q "^$name$" .gitignore 2>/dev/null; then
        continue
      fi
      if [ -n "$(find "$d" -maxdepth 3 -name '*.py' -o -name '*.rs' -o -name '*.js' -o -name '*.ts' -o -name '*.go' -o -name '*.rb' -o -name '*.java' 2>/dev/null | head -1)" ]; then
        echo "topic:modules/$name"
      fi
    done
    ;;
  *)
    echo "Usage: $0 {status|check-sync|suggest-topics}"
    exit 1
    ;;
esac