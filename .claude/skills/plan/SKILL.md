---
name: plan
description: Turn a spec issue into a plan issue with one sub-issue per task, rebuild the working plan file, and execute it with subagent-driven development. Use after the `spec` skill, in place of superpowers:writing-plans — its storage instructions and its execution-choice question do not apply in this repo.
model: Opus
effort: high
---

Planning borrows its **method** from `superpowers:writing-plans` and replaces
its **storage** and its **handoff**. Invoke that skill and follow it — the scope
check, the File Structure pass, bite-sized tasks, no placeholders, the
self-review — with the overrides below.

Upstream sanctions the storage half: its plan step reads "(User preferences for
plan location override this default)". The handoff half is this project's
standing decision, below.

## What replaces what

| `superpowers:writing-plans` says | Here |
| --- | --- |
| Save the plan to `docs/superpowers/plans/YYYY-MM-DD-<feature>.md` | Create a plan **issue** under its spec issue, one sub-issue per task |
| "Two execution options … Which approach?" | **Never ask.** Always subagent-driven development |
| Offer `superpowers:executing-plans` | Never. It is the fallback for sessions without subagents; this one has them |

## Execution is not a question

`superpowers:subagent-driven-development` is **mandatory** for every plan this
repo executes — a fresh subagent per task with review between tasks. The user
has settled this once and for all, so do not present the choice, do not describe
the alternative, and do not ask for confirmation of the default. Announce it and
proceed.

## Filing the plan

A plan routinely does not fit in one issue — a body caps at **65,536 bytes** and
a plan with its preamble and a dozen tasks passes that without being unusually
long. So the plan splits the way it is already structured:

```
#<spec>   spec: <topic>              body = the spec, a root issue
 └─ #<plan>   plan: <feature>        body = everything before Task 1
     ├─ #<t1>   Task 1: <title>
     ├─ #<t2>   Task 2: <title>
     └─ …
```

The plan issue's body is the preamble — Execution order, Global Constraints,
File Structure — and each `## Task N: <title>` section becomes one sub-issue.
That is the same unit `subagent-driven-development` dispatches on, so the split
costs nothing and buys a live progress count on the plan issue.

```bash
REPO=AdenJustice/LibBitForgeUI
attach() {   # attach <parent-number> <child-json>
  gh api "repos/$REPO/issues/$1/sub_issues" -F sub_issue_id="$(jq -r .id <<<"$2")" >/dev/null
}
PLAN=$(gh api repos/$REPO/issues -f title="plan: <feature>" \
         -f body="$PREAMBLE" -f 'labels[]=superpowers')
attach "$SPEC_NUM" "$PLAN"
PLAN_NUM=$(jq -r .number <<<"$PLAN")

TASK=$(gh api repos/$REPO/issues -f title="Task 1: <title>" \
         -f body="$TASK_BODY" -f 'labels[]=superpowers')
attach "$PLAN_NUM" "$TASK"
```

Two things that will bite otherwise:

- **`-F`, never `-f`, for `sub_issue_id`.** `-f` sends the id as a string and the
  API rejects it with a 422 that names no field you recognise.
- The child is addressed by its **database `id`**, not its issue number. They are
  different numbers and the wrong one silently attaches something else.

Use **one heading level** for tasks throughout a plan — `##`, matching what the
plan file assembler emits. Mixing `##` and `###`, or listing the tasks twice as
a File Map table of contents and again for real, is exactly the ambiguity a
single level avoids.

## What a task in this repo has to say

Two constraints belong in the Global Constraints section of every plan here,
because a subagent that has only its own task in front of it cannot see either:

- **Every task keeps `tests/run.sh` green.** It is the whole suite, it is
  headless, and it takes seconds — so there is no "the tests come in a later
  task". A task that changes a widget factory names the test file that covers it.
- **A published table is mutated, never replaced.** `lib.Colors`, `lib.Fonts`,
  `lib.Mixins` and `lib.Skin` are held by reference by every embedder that
  loaded an earlier minor. A task that reassigns one of them breaks a live
  embedder silently, and nothing in the suite or the game will say so.

Where a plan changes the set of files the library loads, one task owns keeping
`lib.xml`, `LibBitForgeUI.toc` and README.md's `## Embedding` listing in step.
Those three are the same list written out three times and nothing checks them
against each other.

## Handing the plan to the subagents

`subagent-driven-development` takes a `PLAN_FILE` path and keys its ledger off
it, so reassemble the issues into a file before dispatching:

```bash
PLAN_FILE=$(.claude/scripts/plan_file.sh <plan-issue-number>)
```

It writes `.superpowers/plans/issue-<N>.md`, which is gitignored. The issues stay
the record; that file is a working copy, safe to delete and rebuild at any time.
Rebuild it whenever a task issue is edited, so the subagents read the same text
the tracker shows.

As each task finishes and passes review, close its sub-issue. The plan issue's
completion count then tracks reality without anyone maintaining a checklist.

## Closing out

When the last task closes, close the plan issue, and close the spec issue if no
other plan under it is still open. Then finish the work with the `land` skill as
usual — landing is unchanged by any of this.
