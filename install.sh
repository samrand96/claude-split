#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"

mkdir -p "$BIN_DIR"
install -m 0755 "$REPO_DIR/bin/claude-split" "$BIN_DIR/claude-split"
ln -sf "$BIN_DIR/claude-split" "$BIN_DIR/clp"

echo "Installed:"
echo "  $BIN_DIR/claude-split"
echo "  $BIN_DIR/clp -> claude-split"
echo

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo "Add this to your shell profile if $BIN_DIR is not already on PATH:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    echo
    ;;
esac

echo "Run: clp doctor"
echo "Then: clp add work"
