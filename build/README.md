# Build Scripts

## update_archive.sh

Downloads the latest `claude-code-jupyter-staging` from PyPI and updates `archive/cc_jupyter/`.

### Usage

```bash
# Latest version
./build/update_archive.sh

# Specific version
./build/update_archive.sh 0.1.39
```

## build_notellm_magic.sh (LEGACY)

Originally copied `archive/` → `src/` and applied patches. Since v0.2.0, `src/notellm_magic/cc_jupyter/` has **diverged significantly** from the archive (trio→anyio migration, SDK context manager, `add_dirs`, removed `/root/code` workaround). Running this script would **overwrite those changes**.

**Do not run this script** unless you intend to start fresh from a new archive version.

## Update Workflow

Since `src/` has diverged from `archive/`, upstream updates must be manually ported:

```bash
./build/update_archive.sh          # Pull latest from PyPI
git diff archive/                   # Review what changed upstream
# Manually apply relevant upstream changes to src/notellm_magic/cc_jupyter/
uv sync                            # Rebuild package
# Test in Jupyter
```

## Patches (applied in v0.1.0, now baked into src/)

### Decorative Header Removal

**File:** `jupyter_integration.py`

The original code adds decorative `═══` banner comments to every generated cell. This was patched for cleaner output. The patch is now directly in `src/` and no longer needs to be re-applied.
