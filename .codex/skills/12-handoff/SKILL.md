---
name: 12-handoff
description: Use when preserving, resuming, or transferring bounded technical work across interruptions, agents, sessions, or reviewers. Use this only when continuity is the main task. Do not use it as a substitute for implementation, testing, review, release, or durable documentation.
---

# Work Handoff and Continuity

## Authority

`AGENTS.md` is the repository-wide authority.

This skill applies only when preserving or restoring work state.

If this skill conflicts with `AGENTS.md`, follow `AGENTS.md`.

This skill must not permit:

- placeholder commands
- undocumented behavior
- fake success messages
- untested completion claims
- direct work on `main` unless explicitly instructed
- overwriting user changes
- creating new documentation files outside the documentation policy

## Purpose

Create concise, factual handoffs that allow the user or another agent to resume work after interruption.

A handoff is a checkpoint, not a progress report, roadmap, or readiness claim.

The handoff must preserve working state:

- where the work is
- what changed
- what was verified
- what failed
- what remains
- what should not be touched
- the next smallest action

## When To Use

Use this skill when:

- work is interrupted
- the user asks to pause
- the task is blocked
- the branch is ready for review
- research changed the implementation direction
- the working tree contains meaningful uncommitted changes
- another agent or session needs to resume the work

Do not create handoffs for trivial completed tasks.

Do not use handoff notes to avoid doing the engineering work that should be done now.

## Required Inspection

Before writing a handoff, inspect the current repository state when a repository is available:

```sh
git status --short
git branch --show-current
git diff --stat
```

If useful and available:

```sh
git log --oneline -5
```

Run or report the most recent verification commands relevant to the work.

Do not invent command results.

Do not claim a command passed unless it was run and passed.

If a command was not run, list it under `Not run`.

## Handoff Format

Use this format:

```markdown
# Handoff

## State

- Branch:
- Status:
- Last completed step:

## Changed Files

-

## Verification

Commands run:

```sh
```

Results:

- Passing:
- Failing:
- Not run:

## Alignment

- Man page:
- Tests:
- Implementation:

## Blockers

-

## Next Smallest Action

-

## Do Not Touch

-
```

## Rules

Be factual.

Be brief.

Use concrete file paths.

Use concrete command names.

State what is known, unknown, passing, failing, and not run.

Do not claim completion unless the Definition of Done in `AGENTS.md` is satisfied.

Do not write roadmap content.

Do not summarize intentions as accomplishments.

Do not hide failing tests.

Do not assign owners unless the owner is established by the user, repository, or source artifact.

If ownership is unknown, write:

```text
Owner: Unknown
```

Do not create new documentation files just to store handoff notes unless the user asks.

If a handoff file is requested, prefer:

```text
HANDOFF.md
```

or:

```text
docs/HANDOFF.md
```

only if the repository already stores operational notes in `docs/`.

## Good Handoff Language

Good:

```text
bats tests currently fail because ./bin/foo init is not implemented.
```

Good:

```text
Man page documents --dry-run, but no test covers it yet.
```

Good:

```text
Next smallest action: add Bats coverage for missing config exit code.
```

Bad:

```text
The project is mostly complete.
```

Bad:

```text
Core architecture is ready.
```

Bad:

```text
Only minor implementation remains.
```

## Completion Standard

A handoff is complete when another engineer can answer:

- what branch to use
- what changed
- what still fails
- what commands to run
- what to do next
- what not to touch
- whether the man page, tests, and implementation are aligned
