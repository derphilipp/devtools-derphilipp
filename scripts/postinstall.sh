#!/usr/bin/env bash
# =============================================================================
# devtools-derphilipp: Post-installation script
# Runs automatically after 'sudo apt install ./devtools-derphilipp_*.deb'
# Also runs on package upgrades (apt upgrade / apt install newer version)
# =============================================================================
set -euo pipefail

MISE_CONFIG_SRC="/usr/share/devtools-derphilipp/mise.toml"
BASHRC_MARKER="# >>> devtools-derphilipp mise >>>"
BASHRC_MARKER_END="# <<< devtools-derphilipp mise <<<"

# --- Determine target user --------------------------------------------------
determine_target_user() {
    # 1. SUDO_USER is set when someone runs 'sudo apt install'
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        echo "$SUDO_USER"
        return
    fi

    # 2. Fallback: first regular user (UID >= 1000, not nobody)
    local user
    user=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }')
    if [ -n "$user" ]; then
        echo "$user"
        return
    fi

    echo ""
}

TARGET_USER=$(determine_target_user)

if [ -z "$TARGET_USER" ]; then
    echo "WARNING: No target user found. Manual setup required."
    echo "  Run as a normal user:"
    echo "    curl https://mise.run | sh"
    echo "    mkdir -p ~/.config/mise"
    echo "    cp $MISE_CONFIG_SRC ~/.config/mise/config.toml"
    echo "    mise install"
    exit 0
fi

TARGET_HOME=$(eval echo "~$TARGET_USER")
TARGET_UID=$(id -u "$TARGET_USER")
TARGET_GID=$(id -g "$TARGET_USER")

echo "==> devtools-derphilipp: Setting up for user '$TARGET_USER' (home: $TARGET_HOME)"

# --- 1. Install mise --------------------------------------------------------
echo "==> Installing mise..."
MISE_BIN="$TARGET_HOME/.local/bin/mise"

if [ -f "$MISE_BIN" ]; then
    echo "    mise is already installed, skipping."
elif command -v mise &>/dev/null; then
    MISE_BIN=$(command -v mise)
    echo "    mise found at $MISE_BIN, skipping install."
else
    # Install mise as the target user (installs to ~/.local/bin/mise)
    sudo -u "$TARGET_USER" bash -c 'curl -fsSL https://mise.run | sh' || {
        echo "ERROR: mise installation failed."
        echo "  Please install manually: curl https://mise.run | sh"
        exit 1
    }
fi

# Resolve mise binary path
if [ ! -f "$MISE_BIN" ]; then
    MISE_BIN=$(command -v mise 2>/dev/null || true)
fi

if [ -z "$MISE_BIN" ] || [ ! -f "$MISE_BIN" ]; then
    echo "WARNING: mise binary not found after installation."
    echo "  Please check manually and run 'mise install'."
    exit 0
fi

echo "    mise found: $MISE_BIN"

# --- 2. Install / update mise.toml config -----------------------------------
echo "==> Installing mise configuration..."
MISE_CONFIG_DIR="$TARGET_HOME/.config/mise"
MISE_CONFIG_DEST="$MISE_CONFIG_DIR/config.toml"

mkdir -p "$MISE_CONFIG_DIR"

if [ -f "$MISE_CONFIG_DEST" ]; then
    # Upgrade path: back up the existing config, then overwrite.
    # This is safe because users can always add their own tools via
    # 'mise use <tool>' independently of this file.
    BACKUP="$MISE_CONFIG_DEST.bak.$(date +%Y%m%d%H%M%S)"
    cp "$MISE_CONFIG_DEST" "$BACKUP"
    echo "    Existing config backed up to $(basename "$BACKUP")"
fi

cp "$MISE_CONFIG_SRC" "$MISE_CONFIG_DEST"
chown -R "$TARGET_UID:$TARGET_GID" "$MISE_CONFIG_DIR"

echo "    Config installed to $MISE_CONFIG_DEST"

# --- 3. Run mise install (install / update tools) ---------------------------
echo "==> Installing developer tools (mise install)..."
echo "    This may take a few minutes..."

sudo -u "$TARGET_USER" bash -c "
    export PATH=\"$TARGET_HOME/.local/bin:\$PATH\"
    cd \"$TARGET_HOME\"
    \"$MISE_BIN\" install --yes 2>&1
" || {
    echo "WARNING: 'mise install' partially failed."
    echo "  Please run as user '$TARGET_USER': mise install"
}

# --- 4. Activate mise in .bashrc --------------------------------------------
echo "==> Setting up mise activation in .bashrc..."
BASHRC="$TARGET_HOME/.bashrc"

# Only add if the marker does not already exist
if [ -f "$BASHRC" ] && grep -qF "$BASHRC_MARKER" "$BASHRC"; then
    echo "    mise activation already present in .bashrc, skipping."
else
    cat >> "$BASHRC" << 'MISE_BLOCK'

# >>> devtools-derphilipp mise >>>
# Added automatically by the devtools-derphilipp package.
# Remove this block to disable mise activation.
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate bash)"
fi
# <<< devtools-derphilipp mise <<<
MISE_BLOCK
    chown "$TARGET_UID:$TARGET_GID" "$BASHRC"
    echo "    mise activation added to .bashrc."
fi

# --- Done -------------------------------------------------------------------
echo ""
echo "============================================================"
echo "  devtools-derphilipp installed successfully!"
echo "  User: $TARGET_USER"
echo ""
echo "  Open a new shell or run:"
echo "    source ~/.bashrc"
echo ""
echo "  Show installed tools:"
echo "    mise list"
echo ""
echo "  Add more tools:"
echo "    mise use <tool>@<version>"
echo "============================================================"
