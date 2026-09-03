#!/usr/bin/env bash
#
# Rebuild a plan's working file from its GitHub issues.
#
# Plans live as issues on this repository's only remote: the plan issue holds
# the preamble, and each of its sub-issues holds one task. subagent-driven-
# development takes a PLAN_FILE path, and its scripts key their ledger off that
# path, so the reassembled file has to land at a stable location --
# .superpowers/plans/issue-<N>.md, which is gitignored.
#
# Re-running overwrites: the issues are the record, this file is a copy.
#
# It lives under .claude/ rather than in a Scripts/ directory because this
# repository is vendored into its embedders as a submodule, and a directory at
# the root is one more path every embedder's packaging has to learn to drop.
#
# Usage: .claude/scripts/plan_file.sh <plan-issue-number>

set -euo pipefail

REPO=AdenJustice/LibBitForgeUI
num=${1:?usage: plan_file.sh <plan-issue-number>}

root=$(git rev-parse --show-toplevel)
out="$root/.superpowers/plans/issue-$num.md"
mkdir -p "$(dirname "$out")"

# Strip the migration/provenance header some bodies carry -- it is navigation
# for a human reading the issue, not part of the plan. The header is an emphasis
# line followed within a few lines by a --- rule.
#
# Buffered rather than skipped outright, and bounded to the first few lines,
# because a task body legitimately opens with **Files:** -- which looks exactly
# like a header's first line. Skipping on that alone ate whole task bodies that
# had no --- to stop at, and the plan file came out as the preamble and nothing
# else.
#
# The second pass drops the blank line the separator leaves behind.
strip_header() {
  awk '
    NR == 1 && /^\*/            { buffering = 1 }
    buffering && NR <= 5        { buf[++n] = $0
                                  if ($0 ~ /^---$/) { buffering = 0; n = 0 }
                                  next }
    buffering                   { for (i = 1; i <= n; i++) print buf[i]
                                  n = 0; buffering = 0 }
                                { print }
    END                         { for (i = 1; i <= n; i++) print buf[i] }
  ' | awk 'NF || seen {seen=1; print}'
}

gh issue view "$num" --repo "$REPO" --json body --jq .body | strip_header > "$out"

# sub_issues comes back in the order the children were attached, which is the
# order the tasks were created in. Sort by number anyway so a re-attached task
# cannot reorder the plan.
# The child's TITLE becomes the task heading, because the body does not carry
# one -- the plan skill files each task as "Task N: <title>" and holds the
# section text in the body. subagent-driven-development's task-brief finds a
# task by matching /^#+[ \t]+Task[ \t]+<n>/, so without this the assembled
# file has no headings and every brief extraction fails.
#
# One heading level for every task, which is what that skill asks for.
gh api "repos/$REPO/issues/$num/sub_issues" --jq '.[] | "\(.number)\t\(.title)"' \
  | sort -n \
  | while IFS=$'\t' read -r child title; do
      printf '\n## %s\n\n' "$title"
      gh issue view "$child" --repo "$REPO" --json body --jq .body | strip_header
    done >> "$out"

echo "$out"
