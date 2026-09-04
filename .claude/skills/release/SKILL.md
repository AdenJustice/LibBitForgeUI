---
name: release
description: Release what has landed on main — compute the version, stamp the CHANGELOG heading, commit that stamp, tag, and push main and the tag to origin to fire the packaging workflow. Never rewrites main. Retires the previous generation of tags only when the WoW game version changes. Use only on the user's explicit manual order to release or publish.
model: haiku
effort: medium
---

Version and publish what `land` put on `main`. This skill does four things: **compute the
version**, **stamp it onto the CHANGELOG heading**, **tag**, and **push `main` and that tag
to `origin`**.

There is no promotion stage here and no filtered public branch. This repository has one
remote and two branches, and only one of them is ever released from: `land` merges finished
work onto `main` and pushes it, and `release` gives the tree that is already there a version
and sends the tag after it.

The other is `embed` — unfiltered, carrying every file `main` carries, and there so a fix
found inside an addon that vendors this library can be committed from that addon's submodule
checkout. **It is never tagged and never released from.** At rest it is the same commit as
`main`, so releasing from `main` releases what it holds anyway; while work is in flight on
it, that work is precisely what has not landed yet. Step 0's `git branch --show-current`
check already refuses to run anywhere but `main`, and it stays exactly as it is.

**`main` is append-only.** This skill adds one commit to it and never rewrites it — no
`--amend`, no `reset`, no rebase, and no forced push. It is public and other clones have
already fetched it.

**Version numbers are computed and written here and nowhere else.** No other skill, commit,
or changelog entry names a version before this point.

Pushing the tag publishes the addon. `.github/workflows/release.yaml` fires on any `v*` tag
reaching `origin`, packages the library with the BigWigs packager, and creates a GitHub
release. **GitHub is the only place it goes.**

**Neither CurseForge nor Wago is part of this pipeline**, and both are kept out the same
way: the packager uploads to a site only when that site's token is in its environment, and
the workflow puts neither `CF_API_KEY` nor `WAGO_API_TOKEN` there. Do not add either, and
do not add the matching `## X-Curse-Project-ID` or `## X-Wago-ID` to the `.toc` — each half
is inert alone, which is exactly why the pair arrives by accident. Adding a distribution
channel is a decision for the user to make explicitly, not a gap to close.

Treat Step 5 as the point of no return — Steps 0–4 are local and undoable; nothing after
Step 5 is.

Run this only on an explicit manual order from the user.

## Step 0 — Preflight

Run in parallel:

- `git branch --show-current` — must be `main`
- `git status` — the working tree must be clean
- `git fetch origin` then `git log origin/main..main --oneline` — must be **empty**
- `git log main..origin/main --oneline` — must also be empty
- `grep -n '^## \[Unreleased\]' CHANGELOG.md` — the section this stamps
- `tests/run.sh`

Stop and tell the user if any of these hold:

- **`git log origin/main..main` is not empty** — work is landed locally and not pushed.
  `land` pushes; something went wrong there. Push it and re-run, rather than releasing a
  tree `origin` has never seen.
- **`git log main..origin/main` is not empty** — `origin` is ahead. Pull and re-run.
- **there is no `## [Unreleased]` heading** — nothing has landed since the last release, or
  something edited `CHANGELOG.md`. Diagnose rather than inventing a section.
- **`## [Unreleased]` exists but holds no bullets** — everything since the last release was
  invisible to an embedder, which is `land`'s Step 2 working as intended. That is a
  judgement call and not yours: ask the user whether to release an empty section or to wait.
- **`tests/run.sh` fails** — do not tag a red tree.
- **the CHANGELOG's top heading already reads `## [v…]`** with no `[Unreleased]` above it —
  this tree was already released, or a previous `release` run got partway. Do not re-tag;
  diagnose first.

## Step 1 — Compute the version

Tags are `v<wow-version>.<revision>` (e.g. `v12.1.0.1`), the same scheme the addon that
vendors this library uses.

Take the WoW game version from `LibBitForgeUI.toc`'s `## Interface:` field, which is
packed as `MMmmpp` with two digits each: `120100` is **12.1.0**, not 12.10.0. Do NOT change
that field unless a WoW patch actually dropped.

- Find the highest existing revision for that game version:
  ```bash
  git tag --sort=-v:refname | grep "^v<wow-version>"
  ```
- No tags for the current game version → start at `v<wow-version>.1`.
- Otherwise → increment the revision by 1 (`v12.1.0.1` → `v12.1.0.2`).
- Game version changed → reset the revision to 1 (`v12.0.5.17` → `v12.1.0.1`).

Note **which of those two cases you are in** — Step 4 branches on it. A revision bump keeps
every existing tag; a game-version change retires the previous generation. Compare against
the highest tag that exists, not against the one you happen to remember:

```bash
git tag --sort=-v:refname | head -1
```

Never derive the version from `CHANGELOG.md`. Note the string — it is used verbatim in every
remaining step.

## Step 2 — Stamp the CHANGELOG heading

Rewrite the heading only. Do not touch the bullets beneath it — `land` wrote them for an
embedder and Step 0 already checked the section is not empty.

```diff
-## [Unreleased]
+## [v<version>] — YYYY-MM-DD
```

Use today's date.

There is no generated release-notes file to rebuild afterwards. The library has no UI of
its own, so nothing reads the changelog back at runtime — `CHANGELOG.md` and the GitHub
release the workflow creates are the whole of it.

## Step 3 — Commit the stamp

`main` is append-only, so the version stamp lands as an ordinary commit on top. Never
`--amend` here — the tip you would be amending is landed, pushed work.

```bash
git add CHANGELOG.md
git commit -m "$(cat <<'COMMIT_EOF'
Release v<version>

<optional short body>

<the Co-Authored-By and session trailers this session was given>
COMMIT_EOF
)"
```

## Step 4 — Tag, and prune only across a game-version boundary

Annotated (`-a`) always, and `-f` to overwrite an existing local unpushed tag:

```bash
git tag -a -f v<version> main -m "v<version>"
```

### When to prune

Tags **accumulate within a game version**. `v12.1.0.1`, `v12.1.0.2`, `v12.1.0.3` all coexist,
and a routine revision bump deletes nothing — the release history for the WoW version
players are actually on stays browsable.

Pruning happens **only when the game version changes** (`v12.0.5.17` → `v12.1.0.1`). At that
boundary, and only then, every tag from a previous game version is retired, because a new
game version supersedes the whole generation before it.

Take the branch from Step 1. If the game version did not change, **skip the rest of this step
entirely** and go to Step 5.

### Pruning, at a boundary

```bash
# Every tag whose game version differs from the one just released. Escape every dot:
# for v12.1.0.1 the pattern is ^v12\.1\.0\. , which retains v12.1.0.2 and friends and
# matches v12.0.*, v11.*, and so on.
OLD_TAGS=$(git tag | grep -v "^v<wow-version with each dot escaped>\.")

# Bail out loudly rather than deleting nothing silently
[ -z "$OLD_TAGS" ] && echo "no previous generation to retire"

# Local, then the one remote this repository has
echo "$OLD_TAGS" | xargs -r git tag -d
echo "$OLD_TAGS" | xargs -r -I {} git push origin :refs/tags/{}

# Deleting a tag leaves its GitHub release behind as a draft
echo "$OLD_TAGS" | xargs -r -I {} gh release delete {} --yes --repo AdenJustice/LibBitForgeUI 2>/dev/null
```

Print `$OLD_TAGS` and confirm it with the user before running the deletions — the grep is
anchored on the game version, and a malformed `<wow-version>` would match everything.

> **Deleting a tag is safe; re-pushing one is not.** A tag deletion sends GitHub a `delete`
> event, and `release.yaml` listens only to `push`, so retiring old tags publishes nothing.
> But force-updating an existing tag *is* a push, and it will fire the workflow and re-upload
> whatever the packager builds. Never `push --force` a `v*` tag to `origin`; delete it first,
> then push the replacement.

## Step 5 — Push main and the tag to origin

This publishes the release. Print the version, the commit subject, and what the workflow
will do with it — build the zip and create a GitHub release, and nothing else — then get
the user's go-ahead before running it. Everything above is undoable; this is not.

```bash
git push origin main
git push origin v<version>
```

Push the branch and the tag as separate commands, in that order, so a rejected `main` push
cannot leave a published tag pointing at a commit `origin` does not have.

`main` only ever gains commits, so this is a fast-forward. If git rejects it as
non-fast-forward, something rewrote published `main` — stop and diagnose rather than
reaching for `--force`.

Then confirm the workflow actually started:

```bash
gh run list --repo AdenJustice/LibBitForgeUI --workflow=release.yaml --limit 3
```

If no run appears within a minute or so, say so rather than assuming the release published.

Watch it to completion rather than reporting on the launch alone:

```bash
gh run watch --repo AdenJustice/LibBitForgeUI <run-id>
```

A green run means the zip built and the GitHub release exists — check that the release is
actually there rather than taking the green tick for it. There is no third-party upload left
to go wrong silently, which is the other half of why nothing audits the zip here: the audit
existed because CurseForge refuses an archive out of band, after the upload returns, so the
packager prints Success! and the workflow stays green either way — that is how BitForge
shipped two releases that never arrived. Bring the check back the day this pipeline gains a
destination other than GitHub.

## Step 6 — Report

- Version tagged, and whether Step 4 pruned — say "revision bump, no tags retired" or list
  the generation that was retired. Do not report a prune that did not happen.
- The `main` release commit SHA, and confirmation that `main` matches `origin/main`
- That the push was a fast-forward, with no force used
- Release workflow run URL, and its outcome if you waited for it
- That the GitHub release exists and carries the zip — the only destination this pipeline has
- **The SHA an embedder needs.** A tag here changes nothing for an addon that vendors this
  library as a submodule until that addon bumps its pointer. Name the SHA and the tag and
  say which repository has to bump — do not go and bump it.
