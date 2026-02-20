# CLAUDE.md

## Commands

```bash
uv sync                        # Install all dependencies
uv run ruff check src/ --fix   # Lint (auto-fix)
uv run ruff format src/        # Format
uv run pyright src/            # Type check (warnings OK, errors not)
uv run pytest                  # Run tests
uv build                       # Build wheel/sdist
```

## Update Upstream

The `archive/` directory holds the pristine upstream from PyPI. The `src/notellm_magic/cc_jupyter/`
files have **diverged significantly** from the archive (trio→anyio, SDK context manager, `add_dirs`,
removed `/root/code` workaround). The build script only applies one patch (header removal) and
**cannot reproduce** the current `src/` state.

To incorporate a new upstream version:

```bash
./build/update_archive.sh         # Pull latest claude-code-jupyter-staging from PyPI
git diff archive/                  # Review upstream changes
# Manually port relevant changes into src/notellm_magic/cc_jupyter/
# Do NOT run build_notellm_magic.sh — it would overwrite the anyio migration
uv sync                           # Reinstall
```

## Project Structure

```
notellm/
├── archive/cc_jupyter/              # Pristine upstream (from PyPI)
├── src/notellm_magic/
│   ├── __init__.py                  # Extension entry point, permissions setup
│   ├── py.typed                     # PEP 561 marker
│   └── cc_jupyter/                  # Patched fork (generated — do NOT edit directly)
│       ├── magics.py                # Core: %cc, %cc_new, %cc_cur magic commands, MCP server setup
│       ├── claude_client.py         # SDK client lifecycle, streaming, interrupt handling
│       ├── config_manager.py        # CLI options (--model, --add-dir, --import, etc.)
│       ├── prompt_builder.py        # System prompt construction per environment
│       ├── jupyter_integration.py   # Cell creation, queue management, env detection
│       ├── history_manager.py       # IPython cell history tracking
│       ├── variable_tracker.py      # Session variable change detection
│       ├── capture_helpers.py       # Image extraction from cell outputs
│       ├── cell_watcher.py          # "Run All" detection via timing heuristics
│       └── constants.py             # Tool names, help text
│                                    # ⚠ cc_jupyter/ has diverged from archive/ — see "Update Upstream"
├── build/
│   ├── update_archive.sh           # Downloads from PyPI → archive/
│   └── build_notellm_magic.sh      # archive/ → src/ + patches
├── pyproject.toml                   # uv_build backend, deps, tool config
└── uv.lock                         # Pinned dependency versions
```

## Architecture

### Extension Lifecycle

1. `%load_ext notellm_magic` → `__init__.py:load_ipython_extension()`
2. Creates `.claude/settings.local.json` with default permissions (Bash, Read, Write, etc.)
3. Registers `ClaudeCodeMagics` and `CellWatcher` hooks

### Query Flow

1. `%cc <prompt>` → `magics.py:_execute_prompt()`
2. Builds enhanced prompt with variables, history, imported files, images
3. Creates `ClaudeAgentOptions` with MCP server, allowed tools, `add_dirs`
4. Runs in a thread (to avoid event loop nesting): `anyio.run(query)`
5. `claude_client.py`: `async with ClaudeSDKClient(options) as client:` — one client per query
6. Streams responses, displays messages/tool calls, extracts session ID for continuity
7. Tool calls to `create_python_cell` → creates new notebook cells for user approval

### Key Patterns

- **Session continuity**: `session_id` stored on `ClaudeClientManager`, passed via `options.resume`
- **Interrupt handling**: SIGINT → `client.interrupt()` via separate thread + anyio task group
- **Cell queue**: Tool calls create cells that get queued; `post_run_cell` hook processes them in order
- **Image support**: `capture_helpers.py` extracts base64 images from cell output for multimodal prompts

## Constraints

- `src/notellm_magic/cc_jupyter/` originated from `archive/` but has **diverged** — edit directly, do not regenerate
- Uses `anyio` for async (not trio). SDK v0.1.39+ uses anyio internally
- `ClaudeSDKClient` as context manager, fresh client per query
- Python >=3.13, line-length 120
- `cc_jupyter/` files have relaxed linting (E501, F841 suppressed) due to upstream style

