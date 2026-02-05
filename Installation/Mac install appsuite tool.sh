#!/bin/zsh
set -euo pipefail

# --- macOS-Guard ---
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Dieses Script ist nur für macOS." >&2
  exit 1
fi

# --- Config ---
URL="https://github.com/sebhb/appsuite/archive/refs/heads/main.zip"
ZIP_NAME="appsuite.zip"

INSTALL_ROOT="$HOME/appsuite"             # Demo & Assets
DEMO_DIR="$INSTALL_ROOT/Demo"
BIN_DIR="$HOME/.local/bin"                # User bin
CLI_TOOL_REL="Binaries/macOS/appsuite"    # relative
AS_SRC_REL="appsuite/Applescript/Execute Demo.applescript"   # relative
APP_NAME="Fill Demo Account.app"
APP_DST="$DEMO_DIR/$APP_NAME"

# --- Temp dir + Cleanup ---
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "→ Loading Repository …"
curl -fsSL "$URL" -o "$WORKDIR/$ZIP_NAME"

echo "→ Unpacking …"
unzip -q "$WORKDIR/$ZIP_NAME" -d "$WORKDIR"

# GitHub delivers <repo>-main/
REPO_ROOT="$WORKDIR/appsuite-main"
if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Unexpected ZIP Layout." >&2
  exit 1
fi

# --- Install CLI tool ---
CLI_SRC="$REPO_ROOT/$CLI_TOOL_REL"
if [[ ! -e "$CLI_SRC" ]]; then
  echo "Missing: $CLI_SRC" >&2
  exit 1
fi
chmod +x "$CLI_SRC"
mkdir -p "$BIN_DIR"
cp -f "$CLI_SRC" "$BIN_DIR/"
CLI_DST="$BIN_DIR/$(basename "$CLI_SRC")"
chmod +x "$CLI_DST"
echo "✓ CLI installed: $CLI_DST"

# --- Adjust PATH (idempotent) ---
ensure_path_block() {
  local rcfile="$1"
  local line='export PATH="$HOME/.local/bin:$PATH"'
  [[ -f "$rcfile" ]] || : > "$rcfile"
  # Avoid duplicates
  if ! echo ":$PATH:" | grep -Eq ':(/Users/[^:]+/\.local/bin|\$HOME/\.local/bin):'; then
    if ! grep -Fq "$line" "$rcfile"; then
      printf '\n# Added by appsuite installer\n%s\n' "$line" >> "$rcfile"
      echo "→ ~/.local/bin added to PATH in ${rcfile}"
    fi
  fi
}
ensure_path_block "$HOME/.zprofile"
# Optionally interactive:
ensure_path_block "$HOME/.zshrc"

# For running session:
export PATH="$BIN_DIR:$PATH"

# --- Create demo structure, copy resources ---
mkdir -p "$DEMO_DIR"

# --- Compile AppleScript ---
AS_SRC="$REPO_ROOT/$AS_SRC_REL"
if [[ ! -f "$AS_SRC" ]]; then
  echo "AppleScript source missing: $AS_SRC" >&2
  exit 1
fi

echo "→ Compiling AppleScript to: $APP_DST"
osacompile -o "$APP_DST" "$AS_SRC"
echo "✓ App compiled: $APP_DST"

# --- Create Alias on Desktop ---
osascript <<OSA
set appPath to POSIX file "$APP_DST"
set desktopFolder to (path to desktop folder from user domain)

tell application "Finder"
	-- Desktop-Alias
	if not (exists alias file "Fill Demo Account" of desktopFolder) then
		make alias file to appPath at desktopFolder
	end if
end tell
OSA
echo "✓ Created Alias on Desktop"

echo "✓ Done."
echo "  You can close this window now."
