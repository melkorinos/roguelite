---
name: dream
description: Memory consolidation pass — compresses log.md and memory.md without losing settled decisions. Run when either file exceeds 100 lines.
---

You are running a focused memory consolidation pass. Do not do any other work during this skill.

## Step 1 — Read everything first

Read all of these before writing anything:
1. `.claude/ai-helper/memory.md`
2. `.claude/ai-helper/log.md`
3. `.claude/ai-helper/soul.md`
4. `.claude/ai-helper/goals.md`
5. `.claude/ai-helper/reflections.md`
6. Run `git log --oneline -30` for recent commit context.

## Step 2 — Rewrite memory.md

**Target: ≤ 90 lines.**

Rules (in priority order):
- **Never drop** a settled design decision, canonical rule, or ADR outcome — these are the whole point of the file.
- Drop anything directly derivable from reading the code: exact function signatures, field names that haven't changed meaning, file paths that appear in CLAUDE.md already.
- Merge sections that cover the same system into one block.
- Condense ADR references to one bullet each: date, number, one-sentence outcome. The ADR file has the detail.
- Prefer dense fragments over full sentences — grammar is optional.
- Overwrite the file in place.

## Step 3 — Rewrite log.md

**Target: ≤ 90 lines.**

Date rules (use today's date to classify):
- **Last 14 days** — keep verbatim. Do not touch these entries.
- **15–30 days old** — collapse each entry to a single bullet line: `## YYYY-MM-DD — {topic} — {one-sentence outcome with test count if notable}`.
- **Older than 30 days** — move to `.claude/ai-helper/log-archive.md` (append; create if missing). Precede the batch with a `---` separator and a line: `# Archived YYYY-MM-DD`. Remove these entries from log.md entirely.

After the moves and collapses, overwrite log.md in place.

## Step 4 — Verify

Count lines in each output file. If either is still over 100 lines, do another compression pass on the oldest remaining entries before finishing.

Do not change soul.md, goals.md, or reflections.md.
Do not commit, push, or open PRs.

## Step 5 — Report

State: old line count → new line count for each file changed. Nothing else.
