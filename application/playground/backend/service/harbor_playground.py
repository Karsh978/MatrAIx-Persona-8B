"""Fallback / Mock implementation for harbor_playground to prevent missing module crashes."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path


def _repo_root() -> Path:
    """Returns the repo root path dynamically."""
    return Path(__file__).resolve().parents[4]


def _default_harbor_command() -> str:
    """Default harbor command fallback."""
    return "harbor"


def _run_subprocess(cmd: list[str], cwd: Path | str | None = None) -> int:
    """Executes a subprocess command safely."""
    try:
        res = subprocess.run(cmd, cwd=cwd, check=False)
        return res.returncode
    except Exception:
        return 1
