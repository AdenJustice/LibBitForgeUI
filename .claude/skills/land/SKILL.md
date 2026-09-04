---
name: land
description: Land finished work onto main — from a task worktree, or from the embed branch a vendoring addon commits to — verify tests, log the work under the CHANGELOG Unreleased section, audit README.md, reduce the work to one commit on main (a worktree branch is squashed and fast-forwarded; embed is squash-merged and never rewritten), remove the worktree, then push main to origin. Use when every task on the worktree is complete and reviewed and the work needs to reach main.
model: sonnet
effort: xhigh
---

Land the current task branch — or `embed` — onto `main`. This is the first step of a
two-stage pipeline: `land` moves finished work from a worktree or from `embed` onto `main`
**without touching version numbers**; `release` later stamps the version, tags, and
publishes. Follow these steps exactly.

`main` is **append-only** — it is the public branch, every merge this skill adds stays on
it forever, and nothing downstream squashes it away. That makes Step 4's commit message the
only account of this work `main` will ever carry, and it makes Step 6's push permanent. The
squash in Step 4 rewrites **the task branch only**, before it is fast-forwarded — and when
the source is `embed` it rewrites nothing at all, because that branch is squash-merged onto
`main` instead. `main` itself is never rewritten by any skill in this pipeline.

**Run this once the branch is finished, not once a task is.** A plan's tasks accumulate
on one branch and land together, so the plan reaches `main` as one commit rather than as a
run of them nothing ties together. Each task still finishes fully — implemented, reviewed,
fixed — before the next is dispatched; only the landing waits.

The unit is therefore the branch, not the task and not the commit.

Two things that follow. Reviewed work sits unlanded for longer, so the branch is the only
copy of it until this runs — do not delete a worktree you have not landed. And `main` may
have moved while the branch was in flight, which makes **Step 0's ancestor check worth
running as its own command** rather than assuming; read what it prints.

## The branch and worktree rules, since this repo has no CLAUDE.md

- **Never edit on `main` directly.** Every task starts from `main` in its own worktree:

  ```bash
  git worktree add .worktrees/<task-slug> -b <task-slug> main
  ```

  Unlike the addon that vendors this library, this repository has **no submodules**, so
  there is no `submodule update --init` to follow that line.

- **`embed` is the second place work may start.** It is a permanent branch on `origin`,
  unfiltered — every file `main` carries, it carries — and it exists so a fix found while
  working inside an addon that vendors this library can be committed from that addon's
  submodule checkout instead of being retyped in a worktree here. At rest
  `git diff main embed` is empty; it runs ahead of `main` only while such work is in
  flight. It is **not** a branch to pin a release to — releases are `main` and the `v*`
  tags on it.

  The submodule checkout is a **different clone**: its git directory lives under the
  addon's `.git/modules/`, so nothing is shared with this repository except through
  `origin`. It also starts at a detached HEAD, and `git submodule update --remote` leaves
  it there, so it has to be switched onto `embed` once before anything can be committed or
  pushed from it.

  ```bash
  # in the addon's submodule checkout, once the fix is committed on embed
  git push origin embed

  # here, before landing it
  git fetch origin embed
  git branch -f embed origin/embed
  git switch embed
  ```

  The order is not a preference: `branch -f` is refused while `embed` is checked out
  (`fatal: cannot force update the branch 'embed' used by worktree at …`), so the ref is
  moved from `main` and switched to afterwards.

  That `-f` updates a local ref this clone does not author. It publishes nothing, it is
  not a rewrite, and it is the only `-f` this skill permits.

- **Address every worktree explicitly** — `git -C /abs/path/to/worktree …` — and use
  absolute paths for file edits and **for every read**. A `cd .worktrees/<task>` that
  silently fails, or a relative path resolved from the wrong checkout, edits or reads
  `main` instead. The read is the nastier half: it looks like it worked.

- **Commits use conventional prefixes** — `feat`, `fix`, `refactor`, `perf`, `test`,
  `docs`, `build`, `ci`, `chore` — with an optional scope naming the area rather than a
  module, because this library has none: `fix(colors)`, `feat(skin)`, `fix(close)`,
  `feat(templates)`, or no scope at all for a change to the library root.

- **Never `git add -A` for a commit.** Stage explicit pathspecs. Step 4 uses a bare `-A`
  once, deliberately, and explains there why that instance is not a commit.

## Step 0 — Confirm you are landing the right thing

Run in parallel:

- `git branch --show-current` — the task branch name
- `git worktree list` — confirm you are inside a `.worktrees/<task-slug>` worktree, **or**
  that the branch from the first check is `embed`, which is landed from this repository's
  own checkout after the fetch-and-switch above rather than from a worktree
- `git status` — what is uncommitted, if anything
- `git log main..HEAD --oneline` — the commits about to land
- `git diff main..HEAD --stat` — the files about to land
- `git merge-base --is-ancestor main HEAD` — whether `main` has moved on since the
  worktree was cut

Stop and tell the user if any of these hold:

- the current branch is `main` — there is nothing to land;
- `git log main..HEAD` is empty **and** the working tree is clean — the branch did nothing.

**A dirty working tree is not a stop, and it does not need a commit first.** Step 4 rebuilds
the branch from the working tree, so an uncommitted remainder lands exactly as a committed
one does — telling you to commit it here would only make a commit Step 4 immediately
discards. What it does need is a look: read `git status` and satisfy yourself that
everything modified or untracked is meant to land. If something is not, deal with it now.
Step 4's `DIVERGED` check is the backstop, not the first line of defence — it stops the
landing, it does not tell you which file it stopped over.

**An `embed` source reaches the same outcome by a different route:** Step 4 has you commit
the remainder on `embed` first, because a squash-merge carries commits and not a working
tree. Left uncommitted there, it does not land.

**If `git merge-base --is-ancestor main HEAD` fails, `main` is ahead of this branch** —
other work landed while this task was in flight. Do not continue to Step 4 in that state.
Merge `main` into the task branch first, resolve any conflicts, re-run `tests/run.sh`, and
only then proceed:

```bash
git merge --no-edit main
git merge-base --is-ancestor main HEAD && echo OK   # must now print OK
```

**This stop does not apply when the source is `embed`.** The reason it exists is that Step
4's `git reset --soft main` assumes `main` is an ancestor; the `embed` path in Step 4 does
not reset anything and merges for real, so a `main` that has moved on is resolved by the
merge rather than reverted by it.

This is not a formality. Step 4 rebuilds the branch from `git reset --soft main` plus the
working tree, which silently assumes `main` is an ancestor. When it is not, the working
tree is missing whatever `main` gained, so the rebuilt commit contains the **reversal** of
those commits and landing it deletes that work from the trunk.

Step 4's `$SNAPSHOT` comparison does **not** catch this. The snapshot is taken from the
same working tree, so it encodes the same missing commits: the tree hash matches, the
squash reports `IDENTICAL`, and the branch still reverts everything `main` gained. The
ancestor check is the only thing standing between that and a silent deletion, which is why
it belongs here rather than as a note further down.

## Step 1 — Verify before landing

```bash
tests/run.sh
```

Every `tests/test_*.lua` must pass. If anything fails, stop and report — do not land a red
branch. Never claim the suite passed without the output in front of you.

## Step 2 — Update CHANGELOG.md

Record the work under a `## [Unreleased]` section at the top of `CHANGELOG.md`, below the
`# Changelog` header.

- **`## [Unreleased]` exists** → merge the new bullets into it. Do not create a second one.
- **It does not exist** → insert it above the most recent version entry.

```markdown
## [Unreleased]

### Added / Changed / Fixed

- <bullet summarizing each logical change>
```

Do **not** invent, derive, or bump a version number here, and do not add a date. The
heading stays literally `## [Unreleased]` until `release` stamps it.

**Write for the addon author embedding this library, not for a player.** Nothing here is
consumer-facing on its own — the library has no UI of its own and ships inside somebody
else's addon:

- Describe what moved in the surface an embedder **touches** — a factory's name or
  signature, a palette or `lib.Fonts` key, a `BitForgeFont<Variant>` global, a media path,
  the skin bridge, the file list in `lib.xml`
- Say what embedding code has to change, where anything does
- **A change an embedder cannot observe gets no bullet.** An internal refactor, a test, a
  comment sweep, a tooling change — skip it entirely. A branch that only did those may
  legitimately add nothing.
- **A change to a published table is always a bullet, however small.** `lib.Colors`,
  `lib.Fonts`, `lib.Mixins` and `lib.Skin` are held by reference across a minor upgrade,
  so a change there reaches embedders that never rebuilt anything.

If `$ARGUMENTS` was provided, incorporate that context into the wording.

## Step 3 — Audit README.md and the load lists

Run these checks and fix what the branch made inaccurate:

1. **The two copies of the file list.** `lib.xml`'s `<Script file=…>` order and the fenced
   block under README's `## Embedding` are the same list written out twice, and nothing
   checks one against the other. If the branch added, removed or renamed a loaded file,
   both change together — and the README block must carry `lib.xml`'s **order**, since it
   exists for the embedder who lists the files in their own `.toc` instead of loading
   `lib.xml`. This repository's own `LibBitForgeUI.toc` is not a third copy — it names
   `lib.xml`, and nothing ever loads it: it is packaging metadata.
2. **The prose that counts files.** README says "the eight `Templates\*.lua` files" and
   "sixteen global font objects". A branch that adds a factory or a font variant makes one
   of those sentences wrong; nothing will fail if it does.
3. **`## Media paths`** — update it if the branch changed `SetMediaPath`, the default
   `Libs/LibBitForgeUI` subpath, or what happens when the vararg is unpopulated.
4. **User-facing changes** — update any section whose description is now wrong because of
   this branch (a renamed factory, a removed option, changed behaviour).

Skip a check only when this branch plainly could not have affected it.

Leave the edits from Steps 2 and 3 uncommitted. Step 4 absorbs them — except when the
source is `embed`, where Step 4 has you commit them on `embed` first, because a
squash-merge carries commits and not a working tree.

## Step 4 — Squash the branch into one commit

**If the source is `embed`, do not use this section.** Go straight to *If the source is
`embed`* below: the reset-and-rebuild here would rewrite a branch other repositories pin
commits on.

The commits on a task branch accumulate in the order the work happened — a fix, a second
fix, a test, a revert of the first fix. That order is a record of the session, not of the
change. Discard it and rebuild the branch as **exactly one commit** carrying its net diff.

**One worktree, one commit, and there is no judgement to make here** — not how many commits,
not which files belong together. A branch that touched the library root, three factories and
the test harness lands as one commit, the same as a branch that fixed a typo. What would
otherwise have been the grouping goes into the commit message body instead, where it costs
nothing and cannot drift out of step with the diff.

### Doing it

**Precondition, re-checked here because this is where the damage would happen:** `main`
must be an ancestor of `HEAD` (Step 0). If you skipped or deferred that check, run it now —
`git merge-base --is-ancestor main HEAD` — and merge `main` in before going further. The
snapshot below cannot detect the problem, because it is taken from the same working tree
that is missing `main`'s commits.

**This binds the worktree source only.** It is the reset below that needs `main` to be an
ancestor; *If the source is `embed`* does not reset anything and resolves a moved-on `main`
by merging it, which is the exemption Step 0 granted.

Snapshot the intended final state first — this is what proves the squash lost nothing:

```bash
git add -A
SNAPSHOT=$(git write-tree)
```

**Bare `-A`, deliberately, and it does not contradict the rule above.** That rule is about
what reaches a commit; nothing here does. The index this builds is discarded by the
`git restore --staged .` below and only the tree hash survives. The breadth is what makes
the check work: an unrelated file the user left modified lands in the snapshot and not in
the rebuilt commit, so the comparison at the end of this step reports `DIVERGED` and the
landing stops. A pathspec here would let that file pass unnoticed.

Collapse the branch to a single uncommitted changeset. `--soft` moves only the branch
pointer, and `restore --staged` only clears the index, so the working tree never changes:

```bash
git reset --soft main
git restore --staged .
```

**This is also what keeps a back-merge out of `main`'s history, and it only works if the
squash runs after it.** When `main` moves while a task is in flight, Step 0 has you merge
it in — and that merge is a commit on the task branch. Land without squashing and it rides
onto `main` as a `Merge branch 'main' into <task-slug>` that records nothing but the fact
that two things happened at once. `git reset --soft main` discards it along with every
other commit on the branch and rebuilds from the working tree, so it never reaches the
trunk. Never squash first and merge `main` in afterwards.

Then stage the branch's paths **by name** and commit once:

```bash
git add -A -- <every path the branch touched>
git commit -m "$(cat <<'COMMIT_EOF'
feat(templates): <what this worktree did>

<one line per concern the branch carried, in the order a reader wants them>

<the Co-Authored-By and session trailers this session was given>
COMMIT_EOF
)"
```

**Enumerate the pathspecs. Do not stage with a bare `git add -A` here.** Under a squash it
is tempting — everything is going into one commit anyway — and that is exactly what makes
it dangerous. A bare `-A` restages whatever the snapshot staged, so the tree can never
differ from `$SNAPSHOT`, the check below always passes, and it is checking nothing. The
stray file it exists to catch — something the user left modified in this worktree, unrelated
to the branch — rides into the commit unseen. Listing the paths is what keeps the
verification real.

Use `-A` **with** those pathspecs, so deletions and new files are picked up and not just
modifications.

Use this repo's conventional prefixes — `feat`, `fix`, `refactor`, `perf`, `test`, `docs`,
`build`, `ci`, `chore` — with an optional scope naming the area. Where the branch genuinely
spans areas, drop the scope rather than inventing a compound one; the body is where the
spread gets described.

### Verify the squash

Two checks, both mandatory:

```bash
# 1. Nothing left behind: no modified, staged, or untracked file remains
git status --porcelain

# 2. The net change is bit-identical to what you started with
[ "$(git rev-parse HEAD^{tree})" = "$SNAPSHOT" ] && echo IDENTICAL || echo DIVERGED
```

The first must print nothing and the second must print `IDENTICAL`. `DIVERGED` means the
pathspecs missed a file, or caught one the snapshot did not — do not merge until you know
which.

`IDENTICAL` proves the squash preserved the working tree you started Step 4 with. It does
**not** prove that tree is the right one: if `main` was not an ancestor, both the snapshot
and the squash encode the same missing commits and this check passes anyway. That is the
Step 0 ancestor check's job, not this one's. Recover with `git reset --soft <the SHA from
Step 0's git log>` to get back to the original tip, then start Step 4 over.

Note that the commit is tested as a whole, which is what it is — one verified end state,
not a run of checkpoints. That is one thing the squash costs nothing to be honest about.

### If the source is `embed`

Do not use the reset-and-rebuild above. `embed` is long-lived and other repositories pin
commits on it, so it is never rewritten. Squash-merge it onto `main` instead, then merge
`main` back so the two agree again.

**Land from a quiet branch.** A commit pushed to `embed` after Step 0's fetch is not in the
squash and surfaces as the next landing's diff. If one arrives mid-landing, stop and start
over from the fetch.

**The Steps 2 and 3 edits are committed on `embed` first, not left in the working tree.**
`git merge --squash` carries commits; an uncommitted CHANGELOG entry is simply left behind,
and the `git diff main embed --stat` below still prints nothing, so nothing else catches it.

All of this runs in the main checkout — the one Step 0 confirmed you are in, with `embed`
checked out — which is why the calls are bare rather than `git -C`:

```bash
git add -A -- CHANGELOG.md README.md   # whatever Steps 2 and 3 touched, by name
git commit -m "docs: log this work in the CHANGELOG"
git status --porcelain                 # must print nothing before you leave embed

git switch main
git merge --squash embed
git diff --name-only --diff-filter=U   # must print nothing — a conflict stops the landing
tests/run.sh                           # re-run when main had moved on: nothing has tested
                                       # this tree yet, on either branch
git commit -m "$(cat <<'COMMIT_EOF'
feat(templates): <what this work did>

<one line per concern the work carried, in the order a reader wants them>

<the Co-Authored-By and session trailers this session was given>
COMMIT_EOF
)"
git switch embed
git merge --no-edit main
```

The `git status --porcelain` there is check 1 of *Verify the squash*, which applies on this
path unchanged: nothing may be left in the working tree, because nothing left there lands.
The two lines between the merge and the commit are what stand in for the ancestor stop this
source is exempt from — a conflicted merge committed here would put conflict markers on an
append-only public branch, and when `main` has moved on the merged tree has been tested on
neither branch.

`main` gains exactly one ordinary commit and no merge commit — the same shape a worktree
branch lands as. The back-merge costs one merge commit on `embed` and nothing else, and
after it the two branches hold the same tree again.

That last part is what replaces the `$SNAPSHOT` comparison, which has nothing to compare
here:

```bash
git diff main embed --stat
```

It must print nothing. Empty means the squash carried everything `embed` had; anything
printed means the merge lost something, and you stop.

**Skip Step 5's fast-forward for this source** — `main` already has the commit — and go
straight to Step 6.

## Step 5 — Fast-forward main and clean up

The merge happens in the main checkout — the first entry of the `git worktree list` from
Step 0 — because `main` is already checked out there and cannot be switched to from inside
a linked worktree:

```bash
git -C <main-checkout> switch main
git -C <main-checkout> merge --ff-only <branch-slug>
```

**Always `--ff-only`, and there is nothing to decide.** Step 4 left exactly one commit and
Step 0 established that `main` is its parent, so a fast-forward always applies and `main`
gains that one commit and nothing else. No merge commit, no `--no-ff`, no counting.

`--ff-only` rather than a bare `merge` is the guard, not a preference: if git refuses, one
of those two facts stopped being true — `main` moved after Step 0, or Step 4 produced
something other than a single commit on top of it. Stop and find out which. Do not fall
back to a merge commit to get past it; that buries the problem in `main` instead of
reporting it.

**`embed` is never removed and never deleted.** The removal below is for a task branch,
which exists for one plan and is finished when that plan lands; `embed` outlives every
landing and stays checked out in whatever addon is using it.

Then remove the worktree and the branch — the plan is done, which is why this ran at all:

```bash
git worktree remove .worktrees/<branch-slug>
git -C <main-checkout> branch -d <branch-slug>
```

If the fast-forward is refused, stop and report — do not resolve the situation and continue
landing in the same breath without telling the user.

`git branch -d` (safe delete) is deliberate: if it refuses, the branch was not fully
merged, which means something went wrong above. Do not reach for `-D`.

## Step 6 — Push `main` to `origin`

Landing is only half done while the work exists on one machine. Push as soon as the merge
is clean:

```bash
git -C <main-checkout> push origin main
```

When the source was `embed`, push it as well — the back-merge in Step 4 leaves it ahead of
`origin/embed` by one merge commit, so this is a fast-forward and the no-`--force` rule in
the notes below applies here unchanged:

```bash
git -C <main-checkout> push origin embed
```

Still for that source, the addon's submodule checkout is then brought back into line, in
that checkout — **only when it is clean**, because the reset discards uncommitted work in a
repository that is the user's rather than this skill's:

```bash
git status --porcelain    # must print nothing first
git fetch && git reset --hard origin/embed
```

If it prints anything, leave that checkout untouched and hand the resync to the user in
Step 7, the way the pointer bump is already handed over.

Notes on why this is written the way it is:

- **No `--force`, ever.** `land` only adds commits on top of `main`, so this is always a
  fast-forward. A rejection means the remote has commits this checkout does not — someone
  pushed, or a `release` ran elsewhere. Stop and report it; do not reach for `--force` or
  `--force-with-lease`, which would discard whatever is on the remote. `main` is public and
  append-only, and a force here is what breaks every clone that already fetched it.
- **No tag is pushed here.** A `v*` tag reaching `origin` fires
  `.github/workflows/release.yaml` and publishes. That is `release`'s job, on the user's
  manual order.

If the push fails for any reason, say so plainly and leave the merge in place — the work is
safely on local `main` either way, and the report must not claim it reached the remote.

## Step 7 — Report

Print a short summary:

- The commit as squashed — its subject, and what its body records about the concerns the
  branch carried
- Confirmation that `git status` was empty and the tree hash matched `$SNAPSHOT` — or, for
  an `embed` source, that `git diff main embed --stat` printed nothing
- Test result (`tests/run.sh` — pass), and that it covers the branch tip only
- Whether CHANGELOG/README were updated, and if not, why not
- The merge commit SHA, and either confirmation that the worktree and task branch are gone
  or a statement that they were kept because more tasks in this plan remain — for an
  `embed` source, the SHA of the commit `main` gained, and that nothing was removed
- That `main` was pushed to `origin`, and the remote SHA it now points at — and, for an
  `embed` source, that `embed` was pushed too, plus whether its submodule checkout was
  resynced or left to the user because it was dirty
- **The SHA an embedder needs.** This library is vendored as a git submodule, so nothing
  that landed here reaches an addon until that addon bumps its pointer at it. Name the SHA
  and say which repository has to bump — do not go and bump it. That is a change in
  somebody else's repository and it needs its own worktree, its own tests and its own
  landing over there.

Do NOT bump a version or create a tag — that is `release`, on the user's manual order.
