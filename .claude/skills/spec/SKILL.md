---
name: spec
description: Brainstorm a design and file the result as a spec issue on this repository's tracker. Use before any creative work — a new widget factory, a palette or font change, anything that moves the surface an embedder touches — in place of superpowers:brainstorming, whose storage instructions do not apply in this repo.
model: Opus
effort: high
---

Design work here borrows its **method** from `superpowers:brainstorming` and
replaces its **storage**. Invoke that skill and follow it — the spike / bounded /
architectural classification, one question at a time, two or three approaches
with a recommendation, section-by-section approval, the self-review — and apply
the overrides below wherever it names a file path.

This is not a deviation upstream forbids. Its spec step reads "(User preferences
for spec location override this default)"; this file is that preference.

## What replaces what

| `superpowers:brainstorming` says | Here |
| --- | --- |
| Write the spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` | Create a spec **issue** (below) |
| Commit the design document to git | Nothing is committed — the issue is the record |
| "Spec written and committed to `<path>`" | "Spec filed as #N" |
| Invoke `superpowers:writing-plans` | Invoke this repo's `plan` skill |

`docs/superpowers/` does not exist. Every spec and plan this library has is an
issue on `AdenJustice/LibBitForgeUI` labelled `superpowers`. Do not recreate the
directory, and do not write a spec to a file "for now" — a spec on disk is a
spec nobody else can see.

**This repository has one remote.** `origin` is `AdenJustice/LibBitForgeUI`, it
is public, and it is both the tracker and the release branch's home. There is no
private mirror to file against and no filtered public branch to keep a spec out
of, so a spec here is public from the moment it is filed. Write it knowing that.

## The one thing that is worth a design at all

The library's whole reason to exist is that more than one addon embeds it, and
an embedder holds references **into** its published tables — a `Font` through
`SetFontObject`, a `ColorMixin` through every skin primitive. So the question
every spec here has to answer explicitly, whatever else it covers:

> What does an addon that has already loaded an older minor of this library see
> after this change?

A design that replaces a published table, renames a factory, drops a
`BitForgeFont<Variant>` global, or moves a media path is a design that breaks a
live embedder silently — nothing errors, the fonts simply stop tracking. If the
spec does not say what happens to the existing embedder, it is not finished.

## Filing the spec

```bash
REPO=AdenJustice/LibBitForgeUI
BODY=$(cat <<'BODY_EOF'
<the full spec markdown>
BODY_EOF
)
ISSUE=$(gh api repos/$REPO/issues \
  -f title="spec: <topic>" \
  -f body="$BODY" \
  -f 'labels[]=superpowers')
echo "spec: #$(jq -r .number <<<"$ISSUE")"
```

**A spec is a root.** It hangs off nothing — the `superpowers` label is what
marks it, and that label is what every consumer filters on. Only the plan
beneath it, and the tasks beneath that, are sub-issues.

One thing that will bite otherwise: an issue body caps at **65,536 bytes**. A
spec that does not fit is a spec covering more than one subsystem — which
upstream's own scope check already says to decompose. Split it into sibling
spec issues rather than truncating.

Title the issue `spec: <topic>`, matching the spec's own heading rather than
inventing a summary. Leave it **open** while the work it describes is unfinished;
close it when the last plan under it is done.

## Close the report the spec replaces

**A spec filed out of a reported issue closes that report**, as soon as the spec
exists rather than once the plan has landed — which is why this comes before the
hand-off below rather than after it. The spec is the record from then on, and
leaving the report open makes two places that both look like the live
description of the same work, the older one being the one that is out of date.

Close it with a comment that carries the conclusions, not a pointer: what the
discussion settled, and what was rejected and why, so the reasoning stays
findable from the report end rather than only from the spec's.

**Comment first, then close** — in that order, so the report is never even
briefly closed with nothing explaining it:

```bash
gh issue comment <number> --repo AdenJustice/LibBitForgeUI --body-file <file>
gh issue close   <number> --repo AdenJustice/LibBitForgeUI --reason "not planned"
```

Two calls rather than `gh issue close --comment`, because that flag takes a
string and not a file, and a closing comment is full of `lib.Colors` and
`SetMediaPath` — the backticked spans `CLAUDE.md` says an inline body eats.
Ordering them this way costs nothing and removes the window the one-call form
was protecting.

`not planned` rather than `completed`: nothing has shipped, and a superseded
report is the same shape as a duplicate.

Both numbers are public and both are in the same tracker, so "superseded by #N"
resolves for whoever filed the report — which is the whole reason this can be
done here at all.

Signed, per `CLAUDE.md`, which is where that rule and its reasoning live.

**Do not close a report a spec only partly covers.** Split the remainder into
its own issue first, or say in the comment which part the spec does not answer
and leave the report open for that alone.

**A report in another repository's tracker is not closed here at all.** This
library is vendored into its embedders, so a defect in it is routinely reported
against the addon a player actually installed — `AdenJustice/BitForge` and
`AdenJustice/BitForge.Private` both hold such reports, and one of them is where
issue #1 here came from. Filing a spec here is not authority to write in
somebody else's tracker. File the spec, leave that report to the repository that
owns it, and say in your report to the user which issue over there now has a
spec against it, so they can close it themselves.

## After it is filed

Run the same self-review upstream asks for — placeholders, internal
consistency, scope, ambiguity — then put the review gate to the user as:

> "Spec filed as #N. Please review it and tell me if you want changes before we
> write the implementation plan."

Wait for an explicit answer. Then invoke this repo's **`plan`** skill, and no
other.
