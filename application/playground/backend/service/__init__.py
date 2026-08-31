"""Service-layer utilities for Playground."""

from __future__ import annotations

import sys
from pathlib import Path

# Self-bootstrap application path before any service dependencies execute
_CURRENT = Path(__file__).resolve()
_APP = _CURRENT.parents[2]       # application directory
_ROOT = _CURRENT.parents[3]      # repository root

for _p in [str(_APP), str(_ROOT)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

__all__ = ["ensure_recbot_importable"]


def ensure_recbot_importable() -> str:
    """Compatibility shim for older API startup code.

    The RecAI sidecar and task tree are no longer shipped, so there is no
    task-owned ``recbot`` package to inject into ``sys.path``.
    """
    return str(Path(__file__).resolve().parents[4])
