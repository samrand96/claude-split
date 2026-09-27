#!/bin/bash
set -euo pipefail
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin/clp"

# Never leave claude:// pointing at a helper whose launcher is about to vanish.
if [ -x "$BIN" ]; then
  "$BIN" handler reset >/dev/null 2>&1 || true
fi

rm -f "$PREFIX/bin/clp" "$PREFIX/bin/claude-split"
rm -rf "$HOME/Applications/Claude Split"

echo "Removed launchers and Claude Split URL-router apps."
echo "Profile data was NOT deleted."
echo "Data remains under:"
echo "  $HOME/.local/share/claude-split"
echo "  $HOME/Library/Application Support/Claude-Split"
