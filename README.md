# `notellm`

**Lightweight Jupyter magic extension for Claude Code integration.**

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is my favorite LLM tool, and I wanted to use it directly within Jupyter notebooks. `notellm` provides the `%cc` magic command that lets Claude work *inside* your notebook—executing code, accessing your variables, searching the web, and creating new cells:

```python
%cc Import the penguin dataset from altair. There was a change made in version 6.0. Search for the change. No comments
```

It's Claude Code in the notebook cell rather than in the command line. The `%cc` cells are used to develop and iterate code, then deleted once the code is working.

This differs from sidebar-based approaches where you chat with an LLM **outside** of the notebook. With `notellm`, code development happens iteratively from **within** the notebook cells.

I work in bioinformatics and developed `notellm` for my own research projects. Hopefully it's useful for other bioinformaticians, data scientists, or anyone wanting to use Claude Code within Jupyter.

`notellm` is adapted from a development version released by Anthropic. Any issues are my own.

**Key features:**
- Full agentic Claude Code execution within notebook cells
- Claude has access to your notebook's variables and state
- Web search and file operations without leaving the notebook
- Conversation continuity across cells
- Automatic permissions setup for common operations

**See also:** [Vizard](https://github.com/prairie-guy/vizard) — I developed Vizard as a more constrained, higher-level language for specifying Polars and Altair code. The goal was more reproducible visualizations through a stateful declarative syntax combining CAPITALIZED keywords with natural language. Vizard includes a large `CLAUDE.md` specification file that guides Claude to generate consistent, predictable code. Example:

```python
%%cc
DATA penguins.csv FILTER species == "Adelie" || PLOT violin Y body_mass_g COLOR sex
```

## Example Session

![notellm demo](docs/demo.png)

## Installation

### Prerequisites

Install [Claude Code](https://docs.anthropic.com/en/docs/claude-code):
```bash
npm install -g @anthropic-ai/claude-code
```

### Install `notellm-magic`

```bash
git clone https://github.com/prairie-guy/notellm.git
cd notellm
pip install .
```

Or for development:
```bash
uv sync
```

### Uninstall

```bash
pip uninstall notellm-magic
```

## Usage

In a Jupyter notebook:

```python
%load_ext notellm_magic
```

On load, you'll see a security warning and the Claude Code Magic banner:

```
================================================================================
WARNING: Claude has permissions for Bash, Read, Write, Edit, WebSearch, WebFetch

  Claude can execute shell commands, read/write/edit files, and access the web.
  Only use in trusted environments.

  Consider removing .claude/settings.local.json when done.
================================================================================

Claude Code Magic loaded!
```

On first load in a directory, notellm also creates `.claude/settings.local.json` with default permissions.

### Permissions

The auto-created `.claude/settings.local.json` grants Claude access to:
- **Bash** - Run shell commands
- **Glob** - Find files by pattern
- **Grep** - Search file contents
- **Read** - Read files
- **Edit** - Modify files
- **Write** - Create files
- **WebSearch** - Search the web
- **WebFetch** - Fetch web content

To customize, edit `.claude/settings.local.json` in your project directory.

### Basic Usage

```python
%cc Create a hello world script
```

Or multi-line:

```python
%%cc
Create a function that calculates fibonacci numbers
Use memoization for efficiency
```

### Magic Commands

**Basic:**
- `%cc <instructions>` - Continue conversation (one-line), inserts new cell below
- `%%cc <instructions>` - Continue conversation (multi-line), inserts new cell below
- `%cc_new` (or `%ccn`) - Start fresh conversation
- `%cc_cur` (or `%ccc`) - Like `%cc`, but replaces the prompt cell in-place
- `%cc --help` - Show all options

**Context management:**
- `%cc --import <file>` - Add file to conversation context
- `%cc --add-dir <dir>` - Add directory to Claude's accessible directories
- `%cc --mcp-config <file>` - Set path to MCP server config
- `%cc --cells-to-load <num>` - Number of cells to load into new conversation

**Output:**
- `%cc --model <name>` - Model to use (default: sonnet)
- `%cc --max-cells <num>` - Max cells Claude can create per turn (default: 3)

**Display:**
- `%cc --clean` - Replace prompt cells with Claude's code cells
- `%cc --no-clean` - Keep prompt cells (default)

### When to use each form

- **`%cc`** (single %) - Short, one-line instructions
- **`%%cc`** (double %) - Multi-line instructions or detailed prompts

### Notes

- Restart the kernel to stop the Claude session

## Project Structure

```
notellm/
├── archive/
│   └── cc_jupyter/              # Pristine copy from PyPI
├── src/
│   └── notellm_magic/
│       ├── __init__.py          # Thin wrapper + permissions setup
│       ├── py.typed             # PEP 561 type marker
│       └── cc_jupyter/          # Patched fork
├── build/
│   ├── update_archive.sh           # Pull latest upstream from PyPI
│   └── build_notellm_magic.sh      # Legacy: archive → src/ + patches
├── docs/
│   └── demo.ipynb               # Demo notebook
├── pyproject.toml
├── LICENSE
└── README.md
```

## Development

### Setup

```bash
uv sync
```

### Linting & type checking

```bash
uv run ruff check src/
uv run ruff format src/
uv run pyright src/
```

### Updating from upstream

The `archive/` directory holds the pristine upstream copy. Since v0.2.0, `src/` has diverged (trio→anyio, SDK modernization), so upstream changes must be manually ported:

```bash
./build/update_archive.sh          # Pull latest from PyPI
git diff archive/                   # Review what changed
# Manually apply relevant changes to src/notellm_magic/cc_jupyter/
```

See `build/README.md` for details.

## Attribution

This project is a fork of `claude-code-jupyter-staging` by Anthropic, released under the MIT License.

See [LICENSE](LICENSE) for details.
