// Guided review: walk an agent's review notes JSON inside Hunk.
//
//   L       load a notes JSON: apply its comments, go to the first stop
//   ctrl+n  next stop            :  jump to a stop (6.3) or a unit (6)
//   ctrl+p  previous stop        P  pick a stop from the route
//   S       stage hunk, go next  U  pick a unit
//
// Rebind with `[keybindings] "review-route.next" = "..."` in config.toml.
//
// Notes JSON (the file the agent writes), path relative to the repo root:
//
//   {
//     "units": { "1": "Title", ... },
//     "comments": [
//       { "filePath": "rel/path", "hunk": 1, "summary": "CU 1.1 — ...", "rationale": "..." },
//       ...
//     ]
//   }
//
// The route follows the JSON's comment order. Loading applies only comments not
// already in the session, so pressing L again after the agent edits the file
// adds its new comments without duplicating the old ones.
//
// S stages the stop's hunk into the git index (git apply --cached). It assumes
// the session reviews the worktree against a revision (hunk diff HEAD,
// hunk diff main...), where staging does not change the reviewed diff.

import type {
  ExtensionCommandContext,
  ExtensionDiffFile,
  HunkExtensionAPI,
} from "hunkdiff/extension";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { isAbsolute, resolve } from "node:path";

const CU_PREFIX_RE = /^CU\s+([\d.]+)\s*[—-]\s*/;
const HUNK_HEADER_RE = /^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,(\d+))? @@/;
const STATUS_ID = "route";

interface NoteComment {
  filePath: string;
  hunk: number;
  summary: string;
  rationale?: string;
}

interface Notes {
  path: string;
  units: Record<string, string>;
  comments: NoteComment[];
}

interface Stop {
  label: string;
  unit: string;
  title: string;
  path: string;
  fileId: string;
  hunkIndex: number;
}

// Survives across commands for the lifetime of the Hunk process.
let notes: Notes | null = null;
let cursor = -1;
let lastRoute: Stop[] = [];
const staged = new Set<string>();

function stopKey(stop: Stop) {
  return `${stop.path}#${stop.hunkIndex}#${stop.label}`;
}

/** Resolve the loaded JSON's comments against the files Hunk shows. */
function loadRoute(ctx: ExtensionCommandContext): Stop[] {
  if (!notes) return [];
  const files = new Map(ctx.selection.files.map((f) => [f.path, f]));
  const route: Stop[] = [];
  notes.comments.forEach((c, i) => {
    const file = files.get(c.filePath);
    if (!file || !file.hunks?.[c.hunk - 1]) return;
    const label = c.summary.match(CU_PREFIX_RE)?.[1] ?? String(i + 1);
    route.push({
      label,
      unit: label.split(".")[0],
      title: c.summary.replace(CU_PREFIX_RE, ""),
      path: c.filePath,
      fileId: file.id,
      hunkIndex: c.hunk - 1,
    });
  });
  return route;
}

async function repoRoot(ctx: ExtensionCommandContext) {
  const top = await git(ctx.cwd, ["rev-parse", "--show-toplevel"]);
  if (top.code) {
    ctx.notify(`Not a git repository: ${top.err.trim()}`, "error");
    return null;
  }
  return top.out.trim();
}

/** Comments of the JSON that the session does not hold yet. */
function missingComments(ctx: ExtensionCommandContext, comments: NoteComment[]) {
  const snapshot = ctx.review.snapshot();
  if (!snapshot) return comments;
  const paths = new Map(snapshot.files.map((f) => [f.fileKey, f.path]));
  const have = new Set(
    snapshot.notes
      .filter((n) => !n.parentId && n.source !== "user")
      .map((n) => {
        const hunk = (n.anchor.ownerHunkIndex ?? n.anchor.intersectingHunkIndices[0] ?? -1) + 1;
        return JSON.stringify([paths.get(n.fileKey), hunk, n.summary, n.rationale ?? ""]);
      }),
  );
  return comments.filter(
    (c) => !have.has(JSON.stringify([c.filePath, c.hunk, c.summary, c.rationale ?? ""])),
  );
}

async function loadNotes(ctx: ExtensionCommandContext) {
  const root = await repoRoot(ctx);
  if (!root) return;
  const answer = await ctx.prompts.line({
    prefix: "notes: ",
    placeholder: "path/to/notes.json",
    initial: notes?.path,
  });
  if (!answer?.trim()) return;
  const raw = answer.trim().replace(/^~(?=\/|$)/, homedir());
  const path = isAbsolute(raw) ? raw : resolve(root, raw);

  let data: { units?: Record<string, string>; comments?: NoteComment[] };
  try {
    data = JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    ctx.notify(`Cannot read ${raw}: ${(error as Error).message}`, "error");
    return;
  }
  if (!Array.isArray(data.comments) || !data.comments.length) {
    ctx.notify(`${raw} has no comments.`, "warning");
    return;
  }

  const missing = missingComments(ctx, data.comments);
  if (missing.length) {
    const applied = await run(
      "hunk",
      ["session", "comment", "apply", "--repo", root, "--stdin"],
      root,
      JSON.stringify({ comments: missing }),
    );
    if (applied.code) {
      ctx.notify(`Applying comments failed: ${(applied.err || applied.out).trim()}`, "error");
      return;
    }
  }

  const changed = notes?.path !== raw;
  notes = { path: raw, units: data.units ?? {}, comments: data.comments };
  if (changed) {
    cursor = -1;
    staged.clear();
  }
  const route = loadRoute(ctx);
  lastRoute = route;
  const skipped = data.comments.length - route.length;
  ctx.notify(
    `${route.length} stops, ${missing.length} comments applied` +
      (skipped ? ` — ${skipped} not in this diff` : ""),
    skipped ? "warning" : "info",
  );
  if (route.length && cursor < 0) goTo(ctx, route, 0);
  else showStatus(ctx, route);
}

/**
 * Re-sync the cursor to Hunk's selection when it sits on a stop. Skipped until
 * the route has been entered: Hunk opens on the first file's first hunk, which
 * is rarely stop 1.
 */
function syncCursor(ctx: ExtensionCommandContext, route: Stop[]) {
  const { file, hunkIndex } = ctx.selection;
  if (cursor < 0 || !file || hunkIndex === null) return;
  const onSelection = (s: Stop) => s.fileId === file.id && s.hunkIndex === hunkIndex;
  if (route[cursor] && onSelection(route[cursor])) return;
  const i = route.findIndex(onSelection);
  if (i >= 0) cursor = i;
}

/** First changed line of one hunk, so the jump lands on code, not context. */
function firstChange(file: ExtensionDiffFile, hunkIndex: number) {
  let index = -1;
  let oldLine = 0;
  let newLine = 0;
  for (const line of file.patch.split("\n")) {
    if (line.startsWith("@@ ")) {
      if (index === hunkIndex) return null;
      const m = HUNK_HEADER_RE.exec(line);
      if (!m) continue;
      index++;
      oldLine = Number(m[1]);
      newLine = Number(m[2]);
    } else if (index !== hunkIndex || line.startsWith("\\")) {
      continue;
    } else if (line.startsWith("+")) {
      return { side: "new" as const, line: newLine };
    } else if (line.startsWith("-")) {
      return { side: "old" as const, line: oldLine };
    } else {
      oldLine++;
      newLine++;
    }
  }
  return null;
}

function showStatus(ctx: Pick<ExtensionCommandContext, "statusLine">, route: Stop[]) {
  const stop = route[cursor];
  if (!stop) return ctx.statusLine.clear(STATUS_ID);
  const done = staged.has(stopKey(stop)) ? " ✓" : "";
  ctx.statusLine.set({
    id: STATUS_ID,
    spans: [
      { text: `CU ${stop.label}${done}`, attributes: ["bold"] },
      { text: `  ${cursor + 1}/${route.length}`, tone: "muted" },
      ...(staged.size ? [{ text: `  staged ${staged.size}`, tone: "added" as const }] : []),
      { text: `  ${stop.title}` },
    ],
  });
}

function goTo(ctx: ExtensionCommandContext, route: Stop[], i: number) {
  const stop = route[i];
  const file = ctx.selection.files.find((f) => f.id === stop.fileId);
  if (!file) {
    ctx.notify(`${stop.path} is not visible (filtered?)`, "warning");
    return;
  }
  const target = firstChange(file, stop.hunkIndex);
  if (target) ctx.navigation.revealLine(stop.fileId, target.side, target.line);
  else ctx.navigation.selectHunk(stop.fileId, stop.hunkIndex);
  cursor = i;
  showStatus(ctx, route);
}

function withRoute(fn: (ctx: ExtensionCommandContext, route: Stop[]) => unknown) {
  return async (ctx: ExtensionCommandContext) => {
    if (!notes) {
      ctx.notify("No review notes loaded — press L.", "warning");
      return;
    }
    const route = loadRoute(ctx);
    if (!route.length) {
      ctx.notify(`No stop of ${notes.path} is in this diff.`, "warning");
      return;
    }
    if (cursor >= route.length) cursor = -1;
    lastRoute = route;
    syncCursor(ctx, route);
    await fn(ctx, route);
  };
}

function move(ctx: ExtensionCommandContext, route: Stop[], delta: number) {
  const i = cursor < 0 ? 0 : cursor + delta;
  if (i < 0) return ctx.notify("Already at the first stop.");
  if (i >= route.length) return ctx.notify(`End of the route — all ${route.length} stops visited.`);
  goTo(ctx, route, i);
}

function jump(ctx: ExtensionCommandContext, route: Stop[], target: string) {
  let i = route.findIndex((s) => s.label === target);
  if (i < 0) i = route.findIndex((s) => s.unit === target);
  if (i < 0) return ctx.notify(`No stop '${target}'.`, "warning");
  goTo(ctx, route, i);
}

// --- staging -----------------------------------------------------------------

function run(cmd: string, args: string[], cwd: string, input?: string) {
  return new Promise<{ code: number; out: string; err: string }>((done) => {
    const child = execFile(cmd, args, { cwd, maxBuffer: 64 << 20 }, (error, out, err) =>
      done({ code: error ? Number(error.code ?? 1) || 1 : 0, out, err }),
    );
    if (input !== undefined) child.stdin?.end(input);
  });
}

function git(cwd: string, args: string[], input?: string) {
  return run("git", ["-C", cwd, ...args], cwd, input);
}

/** File header plus the one hunk overlapping new-side lines [lo, hi]. */
function sliceHunk(diff: string, lo: number, hi: number) {
  const header: string[] = [];
  const hunks: string[][] = [];
  for (const line of diff.split(/(?<=\n)/)) {
    if (line.startsWith("@@ ")) hunks.push([line]);
    else if (!hunks.length) header.push(line);
    else hunks[hunks.length - 1].push(line);
  }
  for (const hunk of hunks) {
    const m = HUNK_HEADER_RE.exec(hunk[0]);
    if (!m) continue;
    const start = Number(m[2]);
    const count = m[3] === undefined ? 1 : Number(m[3]);
    const end = count ? start + count - 1 : start + 1;
    if (start <= hi && lo <= end) {
      const patch = [...header, ...hunk].join("");
      return patch.endsWith("\n") ? patch : patch + "\n";
    }
  }
  return null;
}

async function stageStop(ctx: ExtensionCommandContext, stop: Stop) {
  const file = ctx.selection.files.find((f) => f.id === stop.fileId);
  const range = file?.hunks?.[stop.hunkIndex]?.newRange;
  if (!range) {
    ctx.notify(`No line range for ${stop.path} hunk ${stop.hunkIndex + 1}.`, "warning");
    return false;
  }
  const repo = await repoRoot(ctx);
  if (!repo) return false;

  if ((await git(repo, ["ls-files", "--error-unmatch", "--", stop.path])).code) {
    const add = await git(repo, ["add", "-N", "--", stop.path]);
    if (add.code) {
      ctx.notify(`git add -N failed: ${add.err.trim()}`, "error");
      return false;
    }
  }

  const [lo, hi] = range;
  const patch = sliceHunk((await git(repo, ["diff", "--", stop.path])).out, lo, Math.max(hi, lo));
  if (!patch) {
    const already = sliceHunk((await git(repo, ["diff", "--staged", "--", stop.path])).out, lo, Math.max(hi, lo));
    if (already) return true;
    ctx.notify("Hunk not found in the worktree diff — did the file change?", "warning");
    return false;
  }
  const applied = await git(repo, ["apply", "--cached"], patch);
  if (applied.code) {
    ctx.notify(`Stage failed: ${applied.err.trim()}`, "error");
    return false;
  }
  return true;
}

// --- registration ------------------------------------------------------------

function pad(text: string, width: number) {
  return text.length >= width ? text : text + " ".repeat(width - text.length);
}

export default function (hunk: HunkExtensionAPI) {
  // Keep the status line on the stop under the selection when moving by hand.
  hunk.on("selection_changed", ({ fileId, hunkIndex }, ctx) => {
    if (cursor < 0) return;
    const onSelection = (s: Stop) => s.fileId === fileId && s.hunkIndex === hunkIndex;
    if (lastRoute[cursor] && onSelection(lastRoute[cursor])) return;
    const i = lastRoute.findIndex(onSelection);
    if (i < 0) return;
    cursor = i;
    showStatus(ctx, lastRoute);
  });

  hunk.registerCommand(
    { id: "load", title: "Review route: load notes JSON", key: "L" },
    loadNotes,
  );

  hunk.registerCommand(
    { id: "next", title: "Review route: next stop", key: "ctrl+n" },
    withRoute((ctx, route) => move(ctx, route, 1)),
  );

  hunk.registerCommand(
    { id: "previous", title: "Review route: previous stop", key: "ctrl+p" },
    withRoute((ctx, route) => move(ctx, route, -1)),
  );

  hunk.registerCommand(
    { id: "jump", title: "Review route: jump to stop or unit", key: ":" },
    withRoute(async (ctx, route) => {
      const target = await ctx.prompts.line({ prefix: "CU ", placeholder: "6.3 or 6" });
      if (target?.trim()) jump(ctx, route, target.trim());
    }),
  );

  hunk.registerCommand(
    { id: "list", title: "Review route: pick a stop", key: "P" },
    withRoute(async (ctx, route) => {
      const options = route.map((s, i) => {
        const mark = i === cursor ? ">" : staged.has(stopKey(s)) ? "✓" : " ";
        return `${mark} ${pad(s.label, 6)} ${s.title}`;
      });
      const choice = await ctx.dialogs.select({ title: `Route — ${route.length} stops`, options });
      if (choice !== null) goTo(ctx, route, options.indexOf(choice));
    }),
  );

  hunk.registerCommand(
    { id: "units", title: "Review route: pick a unit", key: "U" },
    withRoute(async (ctx, route) => {
      const units = new Map<string, Stop[]>();
      for (const s of route) units.set(s.unit, [...(units.get(s.unit) ?? []), s]);
      const current = route[cursor]?.unit;
      const entries = [...units.entries()];
      const options = entries.map(([unit, stops]) => {
        const mark = unit === current ? ">" : " ";
        const count = `${stops.length} ${stops.length === 1 ? "hunk " : "hunks"}`;
        return `${mark} unit ${pad(unit, 3)} ${pad(count, 9)} ${notes?.units[unit] ?? stops[0].title}`;
      });
      const choice = await ctx.dialogs.select({ title: `Units — ${units.size}`, options });
      if (choice !== null) jump(ctx, route, entries[options.indexOf(choice)][0]);
    }),
  );

  hunk.registerCommand(
    { id: "stage", title: "Review route: stage hunk and go next", key: "S" },
    withRoute(async (ctx, route) => {
      if (cursor < 0) return ctx.notify("Not on a stop yet — press ctrl+n.", "warning");
      const stop = route[cursor];
      if (!(await stageStop(ctx, stop))) return;
      staged.add(stopKey(stop));
      if (cursor + 1 < route.length) goTo(ctx, route, cursor + 1);
      else {
        showStatus(ctx, route);
        ctx.notify(`Staged — end of the route (${staged.size}/${route.length}).`);
      }
    }),
  );
}
