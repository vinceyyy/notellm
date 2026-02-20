"""
notellm IPython Extension

Fork of claude-code-jupyter-staging (MIT License, Anthropic)
Provides %cc magic for Claude Code integration in Jupyter notebooks.
"""

from __future__ import annotations

import json
from pathlib import Path

DEFAULT_PERMISSIONS = {
    "permissions": {"allow": ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "WebSearch", "WebFetch"]}
}


def _ensure_claude_settings() -> bool:
    """Create .claude/settings.local.json if not present in cwd."""
    cwd = Path.cwd()
    claude_dir = cwd / ".claude"
    settings_file = claude_dir / "settings.local.json"

    if not settings_file.exists():
        claude_dir.mkdir(exist_ok=True)
        settings_file.write_text(json.dumps(DEFAULT_PERMISSIONS, indent=2))
        print(f"Created {settings_file.relative_to(cwd)}")
        return True
    return False


def load_ipython_extension(ipython: object) -> None:
    """Load the cc_jupyter extension."""
    # Create settings file first if needed
    created = _ensure_claude_settings()

    # Show security warning
    print("")
    print("\033[1;31m" + "=" * 80 + "\033[0m")
    print("\033[1;31mWARNING: Claude has permissions for Bash, Read, Write, Edit, WebSearch, WebFetch\033[0m")
    print("")
    print("  Claude can execute shell commands, read/write/edit files, and access the web.")
    print("  Only use in trusted environments.")
    print("")
    if created:
        print("  Created .claude/settings.local.json with default permissions.")
    print("  Consider removing .claude/settings.local.json when done.")
    print("\033[1;31m" + "=" * 80 + "\033[0m")
    print("")

    from .cc_jupyter import load_ipython_extension as load_cc

    load_cc(ipython)
