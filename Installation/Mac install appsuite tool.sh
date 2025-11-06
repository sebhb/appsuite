#!/bin/zsh

# First check OS.
OS="$(uname)"
if [[ "${OS}" == "Darwin" ]]
then
  echo "Installing..."
else
  abort "This script is only intended to be run on a Mac."
fi

URL="https://github.com/sebhb/appsuite/archive/refs/heads/main.zip"
ZIP_FILE="appsuite.zip"

echo "Downloading repository..."
if ! curl -fsSL "$URL" -o "$ZIP_FILE"; then
    echo "Download failed!" >&2
    exit 1
fi

echo "Extracting repository..."
unzip -o "$ZIP_FILE" >/dev/null

mv appsuite-main appsuite
cd appsuite

# Target Directory
BIN_DIR="$HOME/.local/bin"
# appsuite Tool
CLI_TOOL="Binaries/macOS/appsuite"

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

# Compile Applescript
cd Demo
osacompile -o "Fill Demo Account.app" ../appsuite/Applescript/Execute\ Demo.applescript

# Create alias on Desktop
osascript -e 'tell application "Finder" to make alias file to POSIX file ((POSIX path of (path to home folder)) & "appsuite/Demo/Fill Demo Account.app") at POSIX file ((POSIX path of (path to home folder)) & "Desktop")'

cd ..
rm "$ZIP_FILE"