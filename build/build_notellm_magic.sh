#!/usr/bin/env bash
set -euo pipefail

#######################################
# Build notellm_magic from archive
# Copies archive/cc_jupyter → notellm_magic/cc_jupyter
# Applies patches for compatibility
#######################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

ARCHIVE_DIR="$REPO_DIR/archive/cc_jupyter"
TARGET_DIR="$REPO_DIR/src/notellm_magic/cc_jupyter"

# Colors
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m'

echo "Building notellm_magic from archive..."
echo ""

# Check archive exists
if [ ! -d "$ARCHIVE_DIR" ]; then
    echo -e "${RED}ERROR: Archive not found at $ARCHIVE_DIR${NC}"
    exit 1
fi

# Remove existing target
if [ -d "$TARGET_DIR" ]; then
    echo "Removing existing $TARGET_DIR..."
    rm -rf "$TARGET_DIR"
fi

# Copy archive to target
echo "Copying archive to src/notellm_magic/cc_jupyter/..."
cp -r "$ARCHIVE_DIR" "$TARGET_DIR"

#######################################
# PATCH 1: Remove Decorative Headers
#######################################
patch_decorative_headers() {
    local jupyter_integration_file="$TARGET_DIR/jupyter_integration.py"

    if [ ! -f "$jupyter_integration_file" ]; then
        echo -e "${RED}[PATCH 1] SKIP - jupyter_integration.py not found${NC}"
        return 1
    fi

    # Check if already patched
    if grep -q "# No decorative header - use original code as-is" "$jupyter_integration_file"; then
        echo -e "${YELLOW}[PATCH 1] Already applied${NC}"
        return 0
    fi

    echo "[PATCH 1] Removing Decorative Headers..."

    export JUPYTER_INTEGRATION_FILE="$jupyter_integration_file"
    python3 << 'PYTHON_SCRIPT'
import os

jupyter_file = os.environ['JUPYTER_INTEGRATION_FILE']

with open(jupyter_file, 'r') as f:
    lines = f.readlines()

patched = False
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]

    # Find the start of the decorative header block
    if 'generated_cell_message = (' in line:
        # Get the indentation
        indent = len(line) - len(line.lstrip())
        base_indent = ' ' * indent

        # Find the end of the block (cell_info["marker"] = marker)
        j = i
        while j < len(lines):
            if 'cell_info["marker"] = marker' in lines[j]:
                # Found the end - replace entire block with simple version
                new_lines.append(f"{base_indent}# No decorative header - use original code as-is\n")
                new_lines.append(f"{base_indent}marked_code = original_code\n")
                new_lines.append(f'{base_indent}cell_info["code"] = marked_code\n')
                new_lines.append(f'{base_indent}cell_info["marker"] = ""\n')

                i = j + 1  # Skip past the end line
                patched = True
                break
            j += 1

        if patched:
            continue

    new_lines.append(line)
    i += 1

if patched:
    with open(jupyter_file, 'w') as f:
        f.writelines(new_lines)
    exit(0)
else:
    exit(1)
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  Applied${NC}"
        return 0
    else
        echo -e "${RED}  FAILED - Could not find target code${NC}"
        return 1
    fi
}

#######################################
# Apply Patches
#######################################
echo ""
echo "Applying patches..."

PATCHES_APPLIED=0
PATCHES_FAILED=0

patch_decorative_headers
if [ $? -eq 0 ]; then
    ((PATCHES_APPLIED++)) || true
else
    ((PATCHES_FAILED++)) || true
fi

#######################################
# Summary
#######################################
echo ""
if [ $PATCHES_FAILED -eq 0 ]; then
    echo -e "${GREEN}Build complete!${NC}"
    echo "  Source: $ARCHIVE_DIR"
    echo "  Output: $TARGET_DIR"
    echo "  Patches applied: $PATCHES_APPLIED"
else
    echo -e "${YELLOW}Build complete with warnings${NC}"
    echo "  Patches applied: $PATCHES_APPLIED"
    echo "  Patches failed: $PATCHES_FAILED"
fi
echo ""
