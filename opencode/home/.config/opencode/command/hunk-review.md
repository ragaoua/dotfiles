---
description: |-
  Annotate hunks in a Hunk session with why they changed, grouped into change
  units. Produces a data file for walking through the change units in an order
  that makes sense.
---

# Hunk guided review

Hunk is an interactive terminal diff viewer. Your task is to generate notes
to help the user review the current diff inside the Hunk TUI.

## Preconditions

The user must have a Hunk session running. If `hunk session list` returns
nothing, ask them to launch one. Do not launch the session for them.

## Workflow

### 1. Census hunks

```sh
hunk session review --repo . --json
```

Then `git diff` to read patches one by one.

### 2. Group hunks into change units

**A change unit (CU) is a group of hunks that together accomplish one thing.**

For instance, updating a function's signature will require that all call sites
be updated as well, resulting in a number of hunks accomplishing that in
different files. A change unit could therefore consist of the "essential"
change (the function's signature being changed), plus all the impacts that has
on how the function is called, plus possible tests that might need updating.

Another example is imports: changes in imports will almost never be a primary
source of change. Rather, imports are ususally updated as a result of a change
made to the code. Those (the code change and the imports being updated) must
belong to the same change unit.

### 3. Order change units as a narative

**Order change units in a way that helps the reviewer understand the narative,
rationale and intent behind the overall diff**. The ordering must be
accomplished by assigning a number to each change unit (CU 1 -> CU 2 -> CU 3).

**Within a change unit, order hunks to show cause before consequence.** The
code change comes first. Import additions/removals, as well as call site, tests
and doc updates are mechanical follow-ups and come after the code they serve.
Hunks within a change unit as identified by the CU's number, followed by the
hunk rank (CU 1.1 -> CU 1.2 -> CU 1.3)

**Order units by causation** — the trigger for the whole diff first (dep bump,
schema change), then producers, consumers, shared test machinery, new coverage,
mechanical repeats, docs. A doc hunk that belongs to an earlier unit goes
there, not in a docs group.

A hunk serving two units stays in its primary unit; the rationale says where
the other unit is. Cross-reference by change unit number (`see CU 4.1`), not hunk
index.

### 4. Write notes for each hunk

A note consist of:

- A **summary**: `CU N.M — one-line claim`. Carries the point on its own.
- A **rationale**: why the change exists, what to check. Must be to-the-point,
  easy to read and understand. Explain why, not what — the diff shows what.

Specifics:

- Regarding mechanical repeats: one terse line ("same swap as CU 2.1").
- Flag gaps: weaker assertions, missing tests, unchecked migrations.
- Distinguish verified from read — don't assert what you haven't run.
- Generated hunks/files (`uv.lock`, `package.lock` etc) will have only one
  summary per file.

### 5. Write the notes file

To apply the notes to Hunk, write a file to the scratchpad or a temporary
directory:

```json
{
  "repo": "/absolute/path",
  "units": { "1": "Human-readable unit title", "2": "..." },
  "comments": [
    {
      "filePath": "relative/path",
      "hunk": 1,
      "summary": "CU 1.1 — short title",
      "rationale": "..."
    }
  ]
}
```

- `comments` order must honor the `CU N.M` prefix of each note's summary. This
  will allow the reviewer to walk through the notes in the right order.
- `units` titles must describe the theme of each change unit.
- `hunk` is 1-based. Target with `hunk`, not line numbers. Comments always
  anchor to the top/start of the hunk so the reviewer sees the note before
  reading the diff.
- Hunk reads `comments` and ignores `repo`/`units`. Those will be used by the
  reviewer to walk through the diff.

When done, give me the absolute file path.
