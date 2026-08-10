#!/usr/bin/env python3
"""Turn hunk-review-notes.json into Neovim quickfix format.

In neovim:
:cexpr system('python3 qf.py')
:copen

Or, use the running neovim socket:
$ nvim --server "$NVIM" --remote-expr "setqflist([], 'r', {'lines': systemlist('python3 review/qf.py')})"
Note: run :terminal and print the $NVIM value from neovim
"""

import json
from pathlib import Path
import subprocess
import re
import sys


def hunk_start_lines(filepath, ref="main"):
    result = subprocess.run(
        ["git", "diff", ref, "--", filepath],
        capture_output=True,
        text=True,
    )
    return [
        int(m.group(1))
        for m in re.finditer(r"^@@ .+? \+(\d+)", result.stdout, re.MULTILINE)
    ]


def main():
    notes = sys.argv[1] if len(sys.argv) > 1 else "review/hunk-review-notes.json"
    ref = sys.argv[2] if len(sys.argv) > 2 else "main"

    with open(notes) as f:
        data = json.load(f)

    repo = data["repo"]
    cache = {}
    for c in data["comments"]:
        fp = c["filePath"]
        if fp not in cache:
            cache[fp] = hunk_start_lines(Path(repo, fp), ref)

        starts = cache[fp]
        idx = c["hunk"] - 1
        line = starts[idx] if idx < len(starts) else 1
        summary = c["summary"].replace("\n", " ")
        print(f"{fp}:{line}:0:{summary}")


if __name__ == "__main__":
    main()
