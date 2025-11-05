#!/bin/zsh

# Target Directory
BIN_DIR="$HOME/.local/bin"
# appsuite Tool
CLI_TOOL="./tool.sh"

# Check whether tool exists
if [ ! -e "$CLI_TOOL" ]; then
  echo "Error: Source file $CLI_TOOL not found." >&2
  exit 1
fi

# Ensure tool is executable
if [ ! -x "$CLI_TOOL" ]; then chmod +x "$CLI_TOOL"; fi

# Create directory if necessary
mkdir -p "$BIN_DIR"

# Copy tool
cp "$CLI_TOOL" "$BIN_DIR"

# Check whether $PATH already includes $BIN_DIR
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "\nexport PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.zshrc"
    source "$HOME/.zshrc"
    echo "$BIN_DIR added to PATH."
else
    echo "$BIN_DIR already in PATH."
fi
