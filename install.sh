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

if ! command -v duti >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/duti ] && [ ! -x /usr/local/bin/duti ]; then
  echo "Optional but recommended for named Desktop browser login:"
  echo "  brew install duti"
  echo
fi

echo "Run: clp doctor"
echo "Then: clp add work"
echo "First Desktop login: clp desktop-login work"
