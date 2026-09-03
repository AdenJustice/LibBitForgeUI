---
name: issues
description: Work everything reported against this library — Lua errors BugGrabber captured in-game, then open GitHub issues on this repository — identifying the root cause of each and suggesting a fix. Use when the user reports an error or bug, asks what is broken, or wants the issue queue triaged.
model: Opus
effort: high
---

Triage what has been reported against this library. There are two sources, handled **in this order** — a crash the user just hit outranks a written report:

1. **BugGrabber** — `~/Game/World of Warcraft/_retail_/WTF/Account/*/SavedVariables/!BugGrabber.lua`
2. **GitHub** — open issues on `AdenJustice/LibBitForgeUI` (remote `origin`, this repository's only remote)

```bash
gh issue list --repo AdenJustice/LibBitForgeUI --state open
gh issue view <number> --repo AdenJustice/LibBitForgeUI --comments
```

Sweep both, then report the findings grouped by source in that order, naming the source of each. A source being empty is worth one line, not silence — if both are empty, say so and stop. Never pad a thin queue by reporting problems nobody filed.

If `$ARGUMENTS` names a source, an issue number, or pastes an error, that is the whole job — work it alone and skip the sweep. Otherwise `$ARGUMENTS` is extra context for the analysis.

## Filtering BugGrabber

The log collects errors from every installed addon, and this library ships inside other people's addons rather than as one of its own. It has no `AddOns/LibBitForgeUI` of its own to match on in the normal case — its files are at `Interface/AddOns/<HostAddon>/Libs/LibBitForgeUI/`. Filter mechanically **before** reading a single stack:

```bash
ACCOUNTS=~/"Game/World of Warcraft/_retail_/WTF/Account"
FIND=(find "$ACCOUNTS" -path '*/SavedVariables/!BugGrabber.lua')

"${FIND[@]}"                                              # which logs exist at all
"${FIND[@]}" -exec grep -h '\["message"\]' {} + | wc -l   # how many entries they hold
"${FIND[@]}" -exec grep -nE 'Libs/LibBitForgeUI/' {} +    # which of them touch this library
```

`find` rather than a glob, for two reasons. The account directory is not named, because
this repository is public and the path then works across accounts and machines. And an
unmatched glob is a hard error in zsh, whereas **no log at all is the ordinary case** —
BugGrabber may not be installed, or may not have saved yet. An empty first line means
there is nothing to sweep here; say so and move to GitHub.

`Libs/LibBitForgeUI/` is the whole test. `Interface/AddOns/BitForge/BitForge/view.lua` is the **host's** file and is not ours, however much of this library it is calling at the time — that is the mirror image of the rule the vendoring addon's own triage runs, and the two must not both claim the same entry. **No match means no in-scope entry** — report the entry count as discarded, move to GitHub, and do not open the log for a second opinion.

Two things loosen that filter, and both are the embedder's choice rather than yours:

- **A differently vendored copy.** `Libs/LibBitForgeUI` is what README tells an embedder to use and what the default media path assumes, but nothing enforces it. If the user says an addon vendors the library elsewhere, grep for that path too — and say in the report that you did.
- **A standalone install.** Once this library is published on its own, a player can install it as `Interface/AddOns/LibBitForgeUI/`, with no `Libs/` segment at all. `grep -nE '(Libs/)?LibBitForgeUI/'` covers both, at the cost of also matching the host addon named `LibBitForgeUI` — which is this library, so that is not a false positive.

A match is a candidate, not a verdict. Confirm it by mapping the path back into this repository — `Interface/AddOns/BitForge/Libs/LibBitForgeUI/Templates/Dropdown.lua` → `Templates/Dropdown.lua` — and checking the file is here. BugGrabber truncates long paths with a leading `...`, and this library's paths are long enough for that to happen routinely, so a match whose `AddOns/` prefix was eaten stays ambiguous until that mapping resolves it.

Taint reports (`ADDON_ACTION_BLOCKED`) name an addon, and the addon they name is the host, never this library — a library has no addon identity of its own to be blamed by name. Judge those by the frames and locals they state, and expect most of them to belong to the host.

### Discarding is untouching

Do not diagnose a discarded entry, do not read the host addon's source to work out what it was doing, and do not go through `Interface/AddOns/` working out whose it is. Frame names and locals in an out-of-scope entry can confirm an entry is not ours; they can never pull one into scope.

Report discards as a count plus, at most, whatever owner the entries already name themselves — "6 entries, none in scope (4 are BitForge's own files, 2 are Blizzard-only)". That line exists to show the sweep happened. It is not a bug report for another project, so never expand it into one.

If an in-scope entry's stack passes through the host addon or a Blizzard frame, that frame is still evidence worth reading. The rule is about whose bug it is, not which files you may consult.

### Stale entries, and the version trap

An entry that survives the filter can still be irrelevant, and this library has an extra way for that to happen that a normal addon does not.

**The host pins this library by submodule SHA, so an in-game error came from whatever revision that host shipped — not from the working tree in front of you.** A line number that lands in the middle of an unrelated function, or a function name that does not exist here, usually means the host is behind rather than that the traceback is corrupt. Establish which revision before diagnosing: `lib.minor`, the host's own version, and `git log --oneline` over the file are what settle it. Diagnosing today's source against an error raised by an older minor produces a confident, wrong answer.

Beyond that, the ordinary rules hold. If the entry's `time` predates the current source, or the cited line holds nothing resembling the error, say so and skip it. Entries repeat across sessions, and `counter` is the occurrence count, so one defect is reported once however many entries carry it.

## Scope on GitHub

An issue is in scope if it describes behaviour of this library — a factory, a palette or font, a skin primitive, the media path, the embed contract. Feature requests, questions, and support requests are in scope as issues, but they are not defects — answer them as what they are instead of inventing a root cause.

**A report against the host addon's behaviour is out of scope even when this library is in the stack.** It belongs in that addon's tracker. Say so and leave it; see *Reporting* below for what you may and may not do about it.

**The `superpowers` label is out of scope, whatever the issue says.** That label marks this project's specs and plans, which live here as issues rather than as files — every spec, every plan, and every task beneath them carries it. An open one is work queued or in flight, not a report, and a task issue reads exactly like a defect report if you take it for one. Filter the label out before counting the queue:

```bash
gh issue list --repo AdenJustice/LibBitForgeUI --state open --search '-label:superpowers'
```

The `spec` and `plan` skills own that tree. Triage never opens, closes, or comments on an issue carrying the label.

### Sub-issues

This repository uses GitHub sub-issues, and `gh issue list` flattens them — a parent and its children come back as sibling rows with nothing marking which is which. Reconstruct the tree before reading a single body:

```bash
gh issue list --repo AdenJustice/LibBitForgeUI --state open --limit 50 \
  --json number,title,parent \
  --jq '.[] | "\(.number)\tparent=\(.parent.number // "-")\t\(.title)"' | sort -n
```

`gh issue view <number>` prints the relation from either end — a `parent:` line and a `sub-issues:` line with its completion count — and `gh api repos/<owner>/<repo>/issues/<number>/sub_issues` lists the children alone. The REST body's `sub_issues_summary` counts the issue's *own* children, so it reads `total: 0` on a child and is never how you find a parent.

A parent that has children is the umbrella, not the report: the defects are the children, and the parent's body is the shared spec they were written against. Read it either way — a child is routinely one line that means nothing without it — but do not diagnose an umbrella as a report of its own, and do not let it take a second place in the queue count.

## Diagnosing — here, not in subagents

**The whole library fits in one context**, and that is the deciding fact. `LibBitForgeUI.lua`, `Skin.lua` and eight `Templates/*.lua` files are the entire surface, and the palette, the fonts and the skin primitives are shared by every one of the factories — which is exactly where a root cause common to two reports hides. Splitting that across agents pays a full re-exploration per agent to lose the one view that finds it.

So diagnose the reports here, in this context, however many there are. The sibling project fans out one agent per module because it has modules that do not call each other; this library is one module and the rule does not carry over.

Read the sources the stack or the description points at before naming a cause. A plausible-sounding guess from the error text alone is not a diagnosis, and a named gap is a better result than one: where a report does not carry enough to reach a cause, say what is missing, named precisely enough to act on — the command that would settle it, or the question whose answer would. "Needs more information" is not an answer; "needs the host's `lib.minor` and its submodule SHA" is.

Where a report is genuinely about the host addon calling this library wrongly, name that — a factory used with arguments it never accepted is a defect in the caller, and reporting it as one here saves the wrong fix being made in the wrong repository.

## Reporting

Report grouped by source, in the order at the top of this file.

Report a tree as a tree — children under their parent, in the shape they were filed — rather than as a flat run of numbers. The parent earns its heading by holding its children, not by carrying a finding of its own.

Two reports landing on one defect in the palette or the skin primitives are a single finding, named once, with both symptoms under it.

**Labelling, closing, and reopening happen only on the user's explicit order** for that issue.

That order is per issue, not per tree. GitHub propagates nothing: closing a parent leaves its children open, and closing the last child leaves the parent open. An order that names a parent covers the parent — ask before reading it as the whole tree.

**Another repository's tracker is never written to at all.** A defect that turns out to belong to the host addon gets named in your report to the user, and stops there. Filing or commenting over there is a separate order.

### Asking the user for something — comment on the issue

A terminal report scrolls away and a chat summary is a wall to come back to. Anything the user has to *act on* therefore goes on the issue it concerns, where it sits beside the report that raised it and waits until they get to it.

Post a comment when triage produces either:

- **A question only the user can answer** — an ambiguity in the report, a choice between two defensible designs, a term that could mean two things. Give the readings and what each would produce, so the reply can be one line rather than an essay.
- **A task only the user can do** — an in-game capture, a setting to check, a behaviour to eyeball. Write it as a markdown checklist with the exact command or steps, so it can be worked through and ticked off.

```bash
gh issue comment <number> --repo AdenJustice/LibBitForgeUI --body-file <file>
```

Written to a file and passed with `--body-file`, per `CLAUDE.md` — a comment here is full of `lib.Colors` and `Templates\Dropdown.lua`, which is exactly what an inline `--body` eats. Signed, per the same file.

Rules that keep this from becoming noise:

- **This tracker is public.** The user is not necessarily the reporter. Ask *them* for a capture; never ask a stranger who filed an issue to run a debug command, edit a saved variable, or reproduce anything — that is a different conversation and it needs its own explicit order.
- **One comment per issue, not one per question.** Everything you need from the user about that issue goes in a single comment.
- **On the sub-issue that raised it, not the parent.** An ask belongs beside the report that produced it. Only a question about the umbrella itself goes on the parent.
- **Only what the user must do.** A finding they need to *know* belongs in the terminal report; a finding they need to *answer* or *fetch* belongs here. Never post a comment that merely restates the diagnosis.
- **An ask with no issue behind it stays in the terminal.** A BugGrabber entry, or anything the user raised in conversation, has nothing to comment on. Do not open an issue to have somewhere to put it.
- **The terminal report still happens.** This does not replace it — it lifts the actionable part out of it so it does not scroll away.

### Closing an issue

When the order is to close one, comment first and close second, so it is never briefly closed with nothing explaining it:

```bash
gh issue comment <number> --repo AdenJustice/LibBitForgeUI --body-file <file>
gh issue close   <number> --repo AdenJustice/LibBitForgeUI --reason completed
```

Two calls rather than `gh issue close --comment`, because that flag takes a string rather than a file.

**What the comment may claim depends on how far the fix has actually travelled, and this library has one more stage than an addon does.** Its history is public from the first commit, so any SHA on `main` is citable — but a tag here puts nothing in a player's hands. The addon that vendors this library has to bump its submodule pointer and cut its own release before anyone is running the fix.

- **Landed on `main`, not yet tagged** — name the commit, say it is unreleased.
- **Tagged here** — name the commit and the tag, and say plainly that it reaches players when the embedding addon bumps its submodule and releases. Do not let "fixed in v12.1.0.2" stand unqualified; for a reporter who found this through an addon, that reads as "go update", and updating will not get them the fix.
- **Shipped by an embedder** — name that addon and its version. This is the only case where a reporter can act on the answer today.
- **Closing for any other reason** — not reproducible, working as intended, duplicate, out of scope, belongs to the host addon — there are no commits to name, so the comment says why instead. The rule is that a closed issue explains itself, and commits are the usual way it does.

## Applying a fix

**If the user then asks for the fix to be applied**, follow the worktree workflow the `land` skill states, but name the branch `issue-<slug>` so a fix traced back from a report is recognizable at a glance in `git worktree list` and `git branch`:

```bash
git worktree add .worktrees/issue-<slug> -b issue-<slug> main
```

The `<slug>` names the defect, not the source — `issue-dropdown-nil-anchor`, not `issue-buggrabber`. For a GitHub issue, lead with its number: `issue-7-palette-minor-upgrade`. Diagnosis alone needs no worktree; create one only once there is an edit to make.
