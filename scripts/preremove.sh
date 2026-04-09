#!/usr/bin/env bash
# =============================================================================
# devtools-derphilipp: Pre-removal script
# Runs before 'sudo apt remove devtools-derphilipp'
# =============================================================================
set -euo pipefail

BASHRC_MARKER="# >>> devtools-derphilipp mise >>>"
BASHRC_MARKER_END="# <<< devtools-derphilipp mise <<<"

echo "==> devtools-derphilipp: Cleaning up..."

# Iterate over all users with UID >= 1000 and remove .bashrc entries
while IFS=: read -r username _ uid _ _ homedir _; do
    if [ "$uid" -ge 1000 ] && [ "$uid" -lt 65534 ] && [ -d "$homedir" ]; then
        bashrc="$homedir/.bashrc"
        if [ -f "$bashrc" ] && grep -qF "$BASHRC_MARKER" "$bashrc"; then
            echo "    Removing mise activation from $bashrc"
            # Remove the block between the markers
            sed -i "/$BASHRC_MARKER/,/$BASHRC_MARKER_END/d" "$bashrc"
        fi
    fi
done < /etc/passwd

echo ""
echo "  NOTE: mise itself and the installed tools were NOT removed."
echo "  To fully remove mise, run as the respective user:"
echo "    rm -rf ~/.local/share/mise ~/.local/bin/mise ~/.config/mise"
echo ""
echo "==> devtools-derphilipp: .bashrc entries removed."
