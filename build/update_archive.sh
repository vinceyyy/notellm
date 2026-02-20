#!/usr/bin/env bash
set -euo pipefail

#######################################
# Update archive from PyPI
# Downloads claude-code-jupyter-staging
# and extracts cc_jupyter/ to archive/
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ARCHIVE_DIR="$REPO_DIR/archive/cc_jupyter"
TMP_DIR=$(mktemp -d)

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m'

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

PACKAGE="claude-code-jupyter-staging"

# Get version arg or latest
VERSION="${1:-}"
if [ -n "$VERSION" ]; then
    echo "Downloading ${PACKAGE}==${VERSION} from PyPI..."
    pip download --no-deps --dest "$TMP_DIR" "${PACKAGE}==${VERSION}" 2>&1
else
    echo "Downloading latest ${PACKAGE} from PyPI..."
    pip download --no-deps --dest "$TMP_DIR" "${PACKAGE}" 2>&1
fi

# Find the downloaded wheel or sdist
WHL=$(find "$TMP_DIR" -name "*.whl" | head -1)
SDIST=$(find "$TMP_DIR" -name "*.tar.gz" | head -1)

if [ -n "$WHL" ]; then
    echo "Extracting wheel: $(basename "$WHL")"
    unzip -q "$WHL" -d "$TMP_DIR/extracted"
    SOURCE_DIR=$(find "$TMP_DIR/extracted" -type d -name "cc_jupyter" | head -1)
elif [ -n "$SDIST" ]; then
    echo "Extracting sdist: $(basename "$SDIST")"
    tar xzf "$SDIST" -C "$TMP_DIR/extracted" 2>/dev/null || mkdir -p "$TMP_DIR/extracted"
    SOURCE_DIR=$(find "$TMP_DIR/extracted" -type d -name "cc_jupyter" | head -1)
else
    echo -e "${RED}ERROR: No wheel or sdist found${NC}"
    exit 1
fi

if [ -z "$SOURCE_DIR" ] || [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}ERROR: cc_jupyter/ not found in package${NC}"
    echo "Contents of extracted package:"
    find "$TMP_DIR/extracted" -type f | head -20
    exit 1
fi

# Replace archive
echo "Updating archive/cc_jupyter/..."
rm -rf "$ARCHIVE_DIR"
cp -r "$SOURCE_DIR" "$ARCHIVE_DIR"

# Show version
INIT_FILE="$ARCHIVE_DIR/__init__.py"
if [ -f "$INIT_FILE" ]; then
    UPSTREAM_VERSION=$(grep -oP '__version__\s*=\s*"\K[^"]+' "$INIT_FILE" || echo "unknown")
    echo -e "${GREEN}Updated archive to upstream version: ${UPSTREAM_VERSION}${NC}"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review changes: git diff archive/"
echo "  2. Run build:      ./build/build_notellm_magic.sh"
echo "  3. Test:           uv run python -c 'from notellm_magic.cc_jupyter import __version__; print(__version__)'"
echo ""
