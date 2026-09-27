#!/usr/bin/env python3
"""Navigate a Hunk guided review from a notes file.

    hunk-review <notes.json>              open the interactive prompt

Notes file format (JSON) — same file piped to `hunk session comment apply`:

    {
      "repo": "/absolute/path",
      "units": {
        "1": "Title",
        ...
      },
      "comments": [
        {
          "filePath": "relative/path",
          "hunk": 1,
          "summary": "CU 1.1 — ...",
          "rationale": "..."
        },
        ...
      ]
    }

Commands:

    <enter>/n next                   6.3   jump to a stop
    p         previous               6     jump to a unit's first stop
    S         stage hunk, go next    .     rationale, here
    w         re-sync from Hunk      l     route     (l 6 = one unit)
    ?         help                   u     units
    r         reset to the top       q     quit

S stages the current stop's hunk into the git index (git apply --cached)
and moves on. It assumes the session reviews the worktree against a
revision (hunk diff HEAD, hunk diff main...), where staging does not
change the reviewed diff — not plain `hunk diff`, whose view it would
shrink.
"""

from dataclasses import dataclass, field
import json
import os
import re
import subprocess
import sys

CU_ARG_RE = re.compile(r"^\d+(\.\d+)?$")
CU_PREFIX_RE = re.compile(r"^CU\s+([\d.]+)\s*[—-]\s*")
HUNK_HEADER_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


@dataclass
class ReviewState:
    cursor: int = 0
    positioned: bool = False
    staged: set = field(default_factory=set)


def strip_prefix(summary):
    return CU_PREFIX_RE.sub("", summary)


def parse_label(summary):
    m = CU_PREFIX_RE.match(summary)
    return m.group(1) if m else "?"


DIM, BOLD, OFF = "\033[2m", "\033[1m", "\033[0m"
if not sys.stdout.isatty():
    DIM = BOLD = OFF = ""


def load_data(path):
    with open(path) as fh:
        data = json.load(fh)
    route = []
    for c in data["comments"]:
        label = parse_label(c["summary"])
        route.append({**c, "label": label, "unit": label.split(".")[0]})
    return data["repo"], data.get("units", {}), route


def comment_key(comment):
    body = comment["summary"]
    if comment.get("rationale"):
        body += "\n\n" + comment["rationale"]
    return comment["filePath"], comment["hunk"], body


def apply_comments(repo, data_path):
    with open(data_path) as fh:
        data = json.load(fh)

    listed = subprocess.run(
        [
            "hunk",
            "session",
            "comment",
            "list",
            "--repo",
            repo,
            "--type",
            "agent",
            "--json",
        ],
        capture_output=True,
        text=True,
    )
    if listed.returncode != 0:
        err = (listed.stderr or listed.stdout).strip()
        print(f"comment list failed: {err}", file=sys.stderr)
        sys.exit(listed.returncode)

    live_comments = json.loads(listed.stdout).get("comments", [])
    existing = {
        (comment["filePath"], comment["hunkIndex"] + 1, comment["body"])
        for comment in live_comments
    }
    missing = [
        comment for comment in data["comments"] if comment_key(comment) not in existing
    ]
    if not missing:
        return

    result = subprocess.run(
        [
            "hunk",
            "session",
            "comment",
            "apply",
            "--repo",
            repo,
            "--stdin",
            "--focus",
        ],
        input=json.dumps({"comments": missing}),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        err = (result.stderr or result.stdout).strip()
        print(f"comment apply failed: {err}", file=sys.stderr)
        sys.exit(result.returncode)


def fetch_ranges(repo):
    """Map (filePath, 1-based hunk index) -> worktree line range of that hunk."""
    result = subprocess.run(
        ["hunk", "session", "review", "--repo", repo, "--json"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return {}
    try:
        files = json.loads(result.stdout)["review"]["files"]
    except (json.JSONDecodeError, KeyError, TypeError):
        return {}
    ranges = {}
    for f in files:
        for h in f.get("hunks", []):
            new_range = h.get("newRange")
            if new_range:
                lo, hi = new_range
                ranges[(f["path"], h["index"] + 1)] = (lo, max(hi, lo))
    return ranges


def sync_cursor(repo, route, state, announce=False):
    result = subprocess.run(
        ["hunk", "session", "context", "--repo", repo, "--json"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        if announce:
            err = (result.stderr or result.stdout).strip()
            print(f"context failed: {err}", file=sys.stderr)
        return False

    try:
        context = json.loads(result.stdout)["context"]
        path = context["selectedFile"]["path"]
        hunk = context["selectedHunk"]["index"] + 1
    except (json.JSONDecodeError, KeyError, TypeError):
        if announce:
            print("Hunk has no selected hunk.")
        return False

    for i, stop in enumerate(route):
        if stop["filePath"] == path and stop["hunk"] == hunk:
            if announce and i != state.cursor:
                print(
                    f"{DIM}cursor re-synced: "
                    f"{route[state.cursor]['label']} -> {stop['label']}{OFF}"
                )
            state.cursor = i
            state.positioned = True
            break
    else:
        if announce:
            print(
                f"{DIM}Hunk is on {path} hunk {hunk}, "
                f"which is not a stop on the route.{OFF}"
            )
    return True


def navigate(repo, stop):
    result = subprocess.run(
        [
            "hunk",
            "session",
            "navigate",
            "--repo",
            repo,
            "--file",
            stop["filePath"],
            "--hunk",
            str(stop["hunk"]),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        err = (result.stderr or result.stdout).strip()
        print(f"navigate failed: {err}", file=sys.stderr)
        if "No active Hunk session" in err:
            print(
                "Is Hunk running? Launch it with:  hunk diff main...HEAD",
                file=sys.stderr,
            )
        return False
    return True


def git(repo, *args, input=None):
    return subprocess.run(
        ["git", "-C", repo, *args],
        input=input,
        capture_output=True,
        text=True,
    )


def slice_hunk(diff_text, lo, hi):
    """Extract the file header plus the one hunk overlapping worktree [lo, hi]."""
    header, hunks, current = [], [], None
    for line in diff_text.splitlines(keepends=True):
        if line.startswith("@@ "):
            current = [line]
            hunks.append(current)
        elif current is None:
            header.append(line)
        else:
            current.append(line)
    for hunk in hunks:
        m = HUNK_HEADER_RE.match(hunk[0])
        if not m:
            continue
        start = int(m.group(1))
        count = int(m.group(2)) if m.group(2) else 1
        end = start + count - 1 if count else start + 1
        if start <= hi and lo <= end:
            patch = "".join(header + hunk)
            return patch if patch.endswith("\n") else patch + "\n"
    return None


def stage_stop(repo, stop, ranges):
    """Stage the stop's hunk into the git index. False = stay on this stop."""
    path, hunk = stop["filePath"], stop["hunk"]
    target = ranges.get((path, hunk))
    if target is None:
        print(f"No line range for {path} hunk {hunk} — press w to re-sync.")
        return False

    if git(repo, "ls-files", "--error-unmatch", "--", path).returncode != 0:
        add = git(repo, "add", "-N", "--", path)
        if add.returncode != 0:
            err = (add.stderr or add.stdout).strip()
            print(f"git add -N failed: {err}", file=sys.stderr)
            return False

    lo, hi = target
    patch = slice_hunk(git(repo, "diff", "--", path).stdout, lo, hi)
    if patch is None:
        staged = slice_hunk(git(repo, "diff", "--staged", "--", path).stdout, lo, hi)
        if staged is not None:
            print(f"{DIM}already staged.{OFF}")
            return True
        print("Hunk not found in the worktree diff — did the file change?")
        return False

    result = git(repo, "apply", "--cached", input=patch)
    if result.returncode != 0:
        err = (result.stderr or result.stdout).strip()
        print(f"stage failed: {err}", file=sys.stderr)
        return False
    return True


def stage(repo, route, state, ranges):
    if stage_stop(repo, route[state.cursor], ranges):
        state.staged.add(state.cursor)
        print(f"{DIM}staged — {len(state.staged)}/{len(route)} stops{OFF}")
        move(repo, route, state, 1)


def show(stop, index, total):
    print(f"\n  {BOLD}CU {stop['label']}{OFF}  {DIM}({index + 1}/{total}){OFF}")
    print(f"  {strip_prefix(stop['summary'])}")
    print(f"  {DIM}{stop['filePath']}  hunk {stop['hunk']}{OFF}\n")


def wrap(text, width=76, indent="  "):
    words, line, out = text.split(), "", []
    for w in words:
        if len(line) + len(w) + 1 > width:
            out.append(indent + line)
            line = w
        else:
            line = f"{line} {w}".strip()
    if line:
        out.append(indent + line)
    return "\n".join(out)


def move(repo, route, state, delta):
    i = state.cursor + delta
    if i < 0:
        print("Already at the first stop.")
        return
    if i >= len(route):
        print(f"End of the route — all {len(route)} stops visited.")
        return
    if navigate(repo, route[i]):
        state.cursor = i
        state.positioned = True
        show(route[i], i, len(route))


def goto(repo, route, state, target):
    matches = [i for i, s in enumerate(route) if s["label"] == target]
    if not matches:
        matches = [i for i, s in enumerate(route) if s["unit"] == target]
    if not matches:
        print(f"No stop '{target}'. Try:  l")
        return
    i = matches[0]
    if navigate(repo, route[i]):
        state.cursor = i
        state.positioned = True
        show(route[i], i, len(route))


def show_list(route, state, unit_filter=None):
    cursor = state.cursor
    current_unit = None
    for i, s in enumerate(route):
        if unit_filter and s["unit"] != unit_filter:
            continue
        if s["unit"] != current_unit:
            current_unit = s["unit"]
            print()
        here = i == cursor
        mark = f"{BOLD}>{OFF}" if here else " "
        label = f"{BOLD}{s['label']:<6}{OFF}" if here else f"{s['label']:<6}"
        print(f" {mark} {label} {strip_prefix(s['summary'])[:64]}")
    print()


def show_units(route, unit_titles, state):
    seen = {}
    for s in route:
        seen.setdefault(s["unit"], []).append(s)
    cursor_unit = route[state.cursor]["unit"]
    print()
    for unit, stops in seen.items():
        here = unit == cursor_unit
        mark = f"{BOLD}>{OFF}" if here else " "
        title = unit_titles.get(unit, strip_prefix(stops[0]["summary"]))
        label = f"{BOLD}unit {unit:<3}{OFF}" if here else f"unit {unit:<3}"
        plural = "hunk " if len(stops) == 1 else "hunks"
        print(f" {mark} {label} {len(stops):>2} {plural}   {title[:52]}")
    print()


def show_note(route, state):
    s = route[state.cursor]
    print(f"\n  {BOLD}CU {s['label']}{OFF} — {strip_prefix(s['summary'])}")
    print(f"  {DIM}{s['filePath']}  hunk {s['hunk']}{OFF}\n")
    if s.get("rationale"):
        print(wrap(s["rationale"]))
    print()


def where(repo, route, state, ranges):
    fresh = fetch_ranges(repo)
    if fresh:
        ranges.clear()
        ranges.update(fresh)
    if sync_cursor(repo, route, state, announce=True):
        show(route[state.cursor], state.cursor, len(route))


def dispatch(repo, route, unit_titles, state, ranges, args):
    """Returns False to end an interactive session."""
    cmd = args[0]
    rest = args[1:]

    if CU_ARG_RE.match(cmd):
        goto(repo, route, state, cmd)
    elif cmd in ("next", "n"):
        move(repo, route, state, 1 if state.positioned else 0)
    elif cmd in ("prev", "p", "back", "b"):
        move(repo, route, state, -1)
    elif cmd in ("stage", "s", "S"):
        stage(repo, route, state, ranges)
    elif cmd in ("goto", "g", "jump"):
        if not rest:
            print("usage: 6.3")
        else:
            goto(repo, route, state, rest[0])
    elif cmd in ("list", "l", "ls"):
        show_list(route, state, rest[0] if rest else None)
    elif cmd in ("units", "u"):
        show_units(route, unit_titles, state)
    elif cmd in (".", "note", "notes", "why"):
        show_note(route, state)
    elif cmd in ("where", "w"):
        where(repo, route, state, ranges)
    elif cmd in ("r", "reset"):
        state.cursor = 0
        state.positioned = False
        move(repo, route, state, 0)
    elif cmd in ("help", "?", "h"):
        print(__doc__)
    elif cmd in ("quit", "q", "exit"):
        return False
    else:
        print(f"Unknown command '{cmd}'. Type ? for help.")
    return True


def repl(repo, route, unit_titles, state, ranges):
    try:
        import readline  # noqa: F401
    except ImportError:
        pass

    n_units = len({s["unit"] for s in route})
    i = state.cursor
    print(f"\n  Hunk guided review — {len(route)} stops, {n_units} units.")
    print(
        f"  {DIM}enter=next  p=prev  6.3=jump  S=stage  .=rationale  ?=help  q=quit{OFF}"
    )
    show(route[i], i, len(route))

    while True:
        label = route[state.cursor]["label"]
        try:
            line = input(f"{BOLD}[{label}]{OFF} ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return
        if not dispatch(repo, route, unit_titles, state, ranges, line.split() or ["next"]):
            return


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    data_path = os.path.abspath(sys.argv[1])
    repo, unit_titles, route = load_data(data_path)
    apply_comments(repo, data_path)
    state = ReviewState()
    ranges = fetch_ranges(repo)
    sync_cursor(repo, route, state)

    repl(repo, route, unit_titles, state, ranges)


if __name__ == "__main__":
    main()
