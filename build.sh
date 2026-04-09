#!/usr/bin/env bash
# =============================================================================
# Build script for devtools-derphilipp .deb package
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="${1:-1.0.0}"

echo "=== devtools-derphilipp .deb build ==="
echo "Version: $VERSION"
echo ""

# --- Check dependencies ---
if ! command -v nfpm &>/dev/null; then
    echo "nfpm not found. Install nfpm first:"
    echo ""
    echo "Option 1 (recommended): go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest"
    echo "Option 2: curl -sfL https://install.goreleaser.com/github.com/goreleaser/nfpm.sh | sh"
    echo "Option 3 (mise):        mise use -g nfpm"
    echo ""
    exit 1
fi

# --- Make scripts executable ---
chmod +x scripts/postinstall.sh
chmod +x scripts/preremove.sh

# --- Update version in nfpm.yaml ---
sed -i "s/^version: .*/version: ${VERSION}/" nfpm.yaml

# --- Build .deb ---
echo "==> Building .deb package..."
nfpm package --packager deb --target .

DEB_FILE=$(ls -t devtools-derphilipp_*.deb 2>/dev/null | head -1)

if [ -n "$DEB_FILE" ]; then
    echo ""
    echo "=== Build successful! ==="
    echo "File: $DEB_FILE"
    echo "Size: $(du -h "$DEB_FILE" | cut -f1)"
    echo ""
    echo "Install on target machine:"
    echo "  scp $DEB_FILE user@<host>:~/"
    echo "  ssh user@<host> 'sudo apt install -y ./$DEB_FILE'"
    echo ""
    echo "Uninstall:"
    echo "  sudo apt remove devtools-derphilipp"
else
    echo "ERROR: .deb file was not created."
    exit 1
fi
