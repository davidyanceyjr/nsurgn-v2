---
name: design
description: Use when translating documented CLI/TUI behavior and acceptance tests into the smallest maintainable internal structure, including command layout, config/output boundaries, TUI separation, or refactoring needed to make documented behavior testable without speculative architecture.
---

# Design Skill

## Authority

`AGENTS.md` is the repository-wide authority.

This skill applies only when translating documented behavior and tests into the smallest maintainable internal structure.

If this skill conflicts with `AGENTS.md`, follow `AGENTS.md`.

This skill must not permit:

- placeholder commands
- undocumented behavior
- fake success messages
- untested completion claims
- direct work on `main` unless explicitly instructed
- overwriting user changes
- creating new documentation files outside the documentation policy
- architecture documents, diagrams, ADRs, frameworks, or plugin systems unless explicitly requested or required by implemented behavior

## Purpose

Use this skill to fill architecture and design gaps without drifting into architecture theater.

Design is implementation scaffolding. It exists to make documented behavior testable, maintainable, and safe.

Design is not a separate deliverable unless the user explicitly asks for one.

## When To Use

Use this skill when:

- a new command needs an internal file/function layout
- CLI behavior must be separated from TUI presentation
- config, output, command dispatch, or file effects need clear boundaries
- existing code is becoming hard to test
- a refactor is required to satisfy documented behavior safely

Do not use this skill for ordinary edits that already have an obvious location.

Do not use this skill to create broad plans, roadmaps, diagrams, or speculative architecture.

## Required Inputs

Before proposing design, inspect or identify:

- the relevant man page sections
- acceptance tests or expected tests
- existing file layout
- current command behavior
- stdout, stderr, and exit-status contract
- file reads/writes
- config and environment behavior
- TUI constraints, if applicable

If these inputs are missing, tighten the man page and tests before designing internals.

## Design Rules

Design only after the user-visible contract is known.

Prefer the smallest structure that can satisfy the current contract.

Prefer boring, inspectable Bash over clever abstractions.

Separate command behavior from presentation.

Keep TUI code as a wrapper over tested command behavior.

Do not introduce abstractions before at least two real use cases exist.

Do not add a framework when functions and files are enough.

Do not create a plugin system unless the man page documents plugin behavior and tests prove it.

Do not split files merely to make the repository look larger.

Do not hide business logic inside menu handlers.

## Preferred Bash CLI/TUI Shape

Use this shape unless the project already has a better established layout:

```text
bin/<tool>
lib/
  commands.sh
  config.sh
  output.sh
  tui.sh
tests/
  cli.bats
  fixtures/
  golden/
doc/
  <tool>.1.scd
```

Responsibilities:

```text
bin/<tool>
  entrypoint, argument dispatch, top-level error handling

lib/commands.sh
  command behavior and command-level functions

lib/config.sh
  config path discovery, parsing, validation, defaults

lib/output.sh
  stdout/stderr helpers and formatting boundaries

lib/tui.sh
  interactive presentation only

tests/cli.bats
  outside-in command behavior tests
```

Add more files only when behavior justifies the split.

## Design Output

The normal output of this skill is a short implementation note, not a new documentation file.

Preferred format:

```text
Design note:
- Put command dispatch in bin/<tool>.
- Put config search order in lib/config.sh.
- Put init behavior in lib/commands.sh.
- Keep stdout/stderr helpers in lib/output.sh.
- Add Bats coverage in tests/cli.bats.
```

Do not create `docs/ARCHITECTURE.md` unless the user asks or the implementation is complex enough to require durable architecture documentation.

## Refactoring Rules

Refactor only when it supports documented behavior, testability, safety, or maintainability.

Before refactoring, identify the behavior that must remain unchanged.

After refactoring, run the relevant tests.

Do not mix broad refactors with feature behavior unless the refactor is required for that feature.

Do not claim maintainability improvements without showing the concrete simplification.

## TUI Design Rules

The CLI must work without the TUI.

The TUI may call tested command functions, but command behavior must not depend on interactive UI state.

Every TUI behavior should have one of:

- a non-interactive snapshot test
- a command-level test for the behavior behind the TUI
- a clearly documented manual test when automation is not practical

Manual-only testing must be rare.

## Anti-Patterns

Reject these outcomes:

```text
Architecture appears complete but commands do nothing.
A new framework replaces a simple shell function.
A TUI menu contains all business logic.
A design note invents commands not in the man page.
A refactor changes output without updating tests.
Files are split before there is behavior to justify the split.
Docs are created instead of tests or implementation.
```

## Completion Standard

Design work is complete only when it leads to or preserves verified behavior.

At minimum, the final response or handoff must state:

- what structure was chosen
- why it is the smallest useful structure
- what tests prove or will prove the behavior
- what was intentionally not abstracted

Do not call architecture complete until the behavior is implemented and verified.
