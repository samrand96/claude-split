#!/bin/bash
set -euo pipefail
PREFIX="${PREFIX:-$HOME/.local}"
rm -f "$PREFIX/bin/clp" "$PREFIX/bin/claude-split"
echo "Removed launchers from $PREFIX/bin."
echo "Profile data was NOT deleted."
echo "Data remains under:"
echo "  $HOME/.local/share/claude-split"
echo "  $HOME/Library/Application Support/Claude-Split"
