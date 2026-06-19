# Current Plan: Complete nsurgn v1 Specification

## Purpose

Produce a complete, precise first-version specification for a working `nsurgn` application.

This plan is documentation-only. It does not implement code, create tests, define helper files, or track feature completion with checkboxes. Its output is a man page contract that is specific enough to drive later acceptance tests and implementation.

Primary source of truth:

- `doc/nsurgn.1.md`

Supporting context:

- `nsurgn_specification_v1.0.md` is currently untracked and may be used as background for intended first-version scope.

## Scope

The v1 specification should describe the complete intended first working application, not only the current partial implementation.

The v1 contract includes:

- artifact discovery through procfs;
- artifact grouping and classification;
- read-only inspection commands;
- file read, copy, install, extract, and remove operations;
- executable extraction;
- signal operations with safeguards;
- explicit namespace entry through `nsenter`;
- precise stdout, stderr, exit status, file, dependency, and option behavior.

The man page may describe behavior that is not implemented yet, because this plan is for the complete first-version specification. Once the specification is complete, implementation progress should be tracked through Git branches and commits, not through a separate completed-work checklist in this file.

## Tracking Policy

Use Git as the implementation tracker.

The plan should not contain:

- implementation checkboxes;
- "done" markers;
- per-feature completion status;
- code ownership assignments;
- progress tables that duplicate Git history;
- claims that behavior is implemented.

Implementation progress should be represented by:

- focused branches named for observable behavior;
- commits that add man-page-aligned tests and implementation;
- commit messages tied to behavior;
- handoff updates when work pauses or redirects.

If Git is not sufficient for a later coordination need, create or update only the required handoff note at `.codex/handoff/session_handoff.md`. Do not add a separate project status tracker.

## Specification Rules

- Keep `doc/nsurgn.1.md` as the authoritative command contract.
- Prefer exact, testable statements over broad operational language.
- Every documented command must define syntax, arguments, options, stdout, stderr, exit statuses, files read/written, and limitations.
- Every command that can mutate files or processes must define safeguards before it defines success behavior.
- Unresolved ambiguity may remain only in `UNRESOLVED BEHAVIOR`, and each item must state the decision needed to complete v1.
- Examples must match the v1 contract, even if not implemented yet.
- Do not edit `bin/`, `lib/`, or `tests/` while executing this specification plan.

## Pass 1: Declare v1 Release Contract

Goal: make `doc/nsurgn.1.md` unambiguously describe the complete first working version.

Decisions to write into the man page:

- The documented command set is the target v1 contract.
- `--version` remains `nsurgn 0.1.0` until the repository intentionally bumps the version.
- `--help` must eventually list every current-contract command.
- Behavior described in `COMMANDS`, `OPTIONS`, `ARGUMENTS`, `STDOUT`, `STDERR`, `EXIT STATUS`, `FILES`, and `ENVIRONMENT` is normative for v1.

Required outcome:

- No command section reads as aspirational, optional, or "planned".
- Any behavior still undecided is moved to `UNRESOLVED BEHAVIOR` with a concrete decision question.

## Pass 2: Complete Command Inventory

Goal: ensure every v1 command has a complete specification.

Commands to specify:

- `list`
- `scout`
- `all`
- `tree`
- `report`
- `inspect`
- `map`
- `ps`
- `mounts`
- `exe`
- `install`
- `inject`
- `extract`
- `remove`
- `signal`
- `ls`
- `cat`
- `stat`
- `exists`
- `checksum`
- `enter`

Each command section must define:

- synopsis;
- purpose;
- accepted options;
- argument requirements;
- target resolution behavior;
- stdout on success;
- stderr diagnostics for common failures;
- exit statuses for common failures;
- file reads/writes or process effects;
- safety limits.

Required outcome:

- No command relies on "includes", "metadata", "details", or "summary" without exact fields or examples.

## Pass 3: Define Output Formats

Goal: make stdout contracts stable enough for acceptance tests.

Global output decisions:

- Table headers must be exact strings.
- Table row separators must be defined: two spaces, tabs, or fixed-width alignment.
- Sort order must be defined for every multi-row output.
- Missing values must use one representation, such as `-`, unless a command explicitly says otherwise.
- Text reports must define exact field labels and ordering.
- Human-facing warnings must go to stderr, not stdout.

Commands needing exact output formats:

- `list`
- `scout`
- `all`
- `tree`
- `report`
- `inspect`
- `map`
- `ps`
- `mounts`
- `exe`
- `ls`
- `stat`
- `checksum`
- `install`
- `extract`
- `remove`
- `signal`

Required outcome:

- The current `UNRESOLVED BEHAVIOR` items for table spacing, `ls`, and `stat` output are resolved or rewritten as concrete remaining decision questions.

## Pass 4: Define Artifact Discovery

Goal: make discovery, grouping, scoring, classification, and leader selection deterministic.

Decisions to specify:

- Which `/proc` paths are read during discovery.
- Which missing or unreadable `/proc` files are warnings, skipped rows, partial success, or hard failures.
- How numeric PIDs are enumerated and sorted.
- How artifact IDs are assigned.
- Whether artifact IDs are stable only within one command invocation.
- How `pid:<number>` targets interact with artifact discovery.
- How `--include-host` affects discovery output and target selection.
- How leaders are selected and how ties are broken.
- How namespace IDs are parsed from `/proc/<pid>/ns/*`.
- How namespace PID is parsed from `/proc/<pid>/status`.
- How command names are rendered from `/proc/<pid>/cmdline` or fallback fields.

Required outcome:

- A test author can build deterministic host-PID and fixture expectations without guessing how artifacts are discovered.

## Pass 5: Define Classification And Scoring

Goal: make evidence scoring and classification literal.

Decisions to specify:

- Exact classification precedence.
- Exact score contribution of every evidence signal.
- Whether evidence signals are additive once or per occurrence.
- Case sensitivity for cgroup, runtime, mount, and executable hints.
- How multiple runtime hints are ordered and joined.
- How `--no-runtime-hints` affects classification and score.
- How `--no-mount-scan` affects classification and score.
- What `suspicious` means in deterministic evidence terms.
- What "weakly classified artifact" means for signal safeguards.

Required outcome:

- Classification labels and scores can be verified from fixed procfs-like input.

## Pass 6: Define Global Options

Goal: every global option has a command-by-command effect.

Options to specify:

- `--group`
- `--format`
- `--verbose`
- `--quiet`
- `--no-color`
- `--host-pid`
- `--include-host`
- `--no-runtime-hints`
- `--no-mount-scan`
- `--help`
- `--version`

Decisions to specify:

- Which commands honor each option.
- Which option and command combinations are usage errors.
- Whether no-op global options are allowed for commands where they do not matter.
- Exact diagnostics for invalid option values.
- Whether `--format text` applies to all commands or only discovery/reporting commands.
- What `--verbose` writes for file operations and discovery.
- Which warnings `--quiet` suppresses.
- Whether color is ever emitted in v1.

Required outcome:

- The `OPTIONS` section maps each option to observable behavior.

## Pass 7: Define Target And Path Semantics

Goal: make ARTIFACT_OR_PID and path handling consistent across commands.

Target decisions:

- Accepted forms: `A<N>`, `<number>`, `pid:<number>`.
- Exit status and diagnostics for invalid targets.
- Exit status and diagnostics for missing host PIDs.
- Exit status and diagnostics for stale artifact IDs.

Path decisions:

- Empty path handling.
- Relative path handling.
- `.` and `..` component handling.
- Repeated slash handling.
- Trailing slash handling.
- Symlink handling per command.
- Directory handling per command.
- File-not-found and destination-exists diagnostics.
- Permission-denied diagnostics.

Required outcome:

- The `ARGUMENTS` section and each file command agree.

## Pass 8: Define File Operation Semantics

Goal: make file commands complete and safe.

Commands to specify:

- `ls`
- `cat`
- `stat`
- `exists`
- `checksum`
- `install`
- `inject`
- `extract`
- `remove`
- `exe --extract`

Decisions to specify:

- Whether copy operations preserve metadata by default.
- Exact effect of `--preserve`.
- Exact effect of `--mode`, `--owner`, and `--group`.
- Whether `--backup` requires `--overwrite`.
- Backup filename and overwrite rules.
- Parent directory behavior for destination paths.
- Whether overwrite unlinks first, truncates in place, or copies over.
- Symlink behavior for source and destination paths.
- Directory copy and directory removal behavior.
- Mount-point refusal behavior.
- Behavior when files change during operation.

Required outcome:

- File operation sections are explicit enough to test with temporary directories and controlled symlink fixtures.

## Pass 9: Define Destructive Safeguards

Goal: make file deletion and process signaling refusal rules deterministic.

`remove` decisions:

- Required `--force` behavior.
- Exact protected path list.
- Whether descendants of protected paths are refused.
- Directory refusal without `--recursive`.
- Recursive removal semantics.
- Mount-point detection and refusal semantics.
- Symlink deletion semantics.

`signal` decisions:

- Accepted signal names and numbers.
- Normalized signal display.
- Host PID 1 refusal.
- Host-classified artifact refusal.
- Required flags for host-classified targets.
- High-impact signal list.
- Weak-classification high-impact signal refusal.
- `--all` partial success behavior.

Required outcome:

- Destructive actions cannot succeed through ambiguous wording.

## Pass 10: Define Dependency And Platform Contract

Goal: define required platform capabilities and command dependencies.

Decisions to specify:

- Required shell/runtime assumptions.
- Required `/proc` features.
- Required standard utilities.
- Whether GNU coreutils are required.
- Which checksum programs are required for each algorithm.
- `nsenter` dependency scope.
- Exit status and diagnostic for missing command-specific dependencies.
- Behavior on unsupported kernels or unavailable namespace types.

Required outcome:

- The `DESCRIPTION`, `FILES`, `ENVIRONMENT`, `LIMITATIONS`, and `EXIT STATUS` sections agree on dependencies and failure modes.

## Pass 11: Align Exit Statuses And Diagnostics

Goal: every documented failure mode has one exit status and one diagnostic shape.

Decisions to specify:

- Usage error: exit `2`.
- Unsafe path refusal: exit `5`.
- Target/path/source/destination missing: exit `4`, except `exists` path absence if v1 keeps exit `1`.
- Permission denied: exit `3`.
- Stale artifact ID: exit `6`.
- Partial success: exit `7`.
- Process changed or disappeared: exit `8`.
- Unsupported platform or missing command dependency: exit `9`.
- General error boundaries for exit `1`.

Required outcome:

- `STDERR` lists common diagnostics by shape.
- `EXIT STATUS` explains command-specific exceptions.

## Pass 12: Align Examples

Goal: examples demonstrate the complete v1 contract without ambiguity.

Decisions to specify:

- Whether examples use artifact IDs such as `A1`, host PIDs, or both.
- When examples use `sudo`.
- Which examples demonstrate safeguards.
- Which examples demonstrate read-only inspection.
- Which examples demonstrate file mutation.
- Which examples demonstrate namespace entry.

Required outcome:

- Every example corresponds to a precisely specified v1 command behavior.

## Completion Criteria

This specification plan is complete when `doc/nsurgn.1.md` contains a complete v1 contract with:

- every v1 command listed in `COMMANDS`;
- exact syntax for every command and option;
- exact stdout format for every command;
- exact stderr diagnostic shapes for common failures;
- exact exit statuses for every documented success and failure class;
- exact target, path, symlink, directory, overwrite, backup, metadata, and mount-point semantics;
- exact discovery, grouping, classification, scoring, runtime-hint, and leader-selection rules;
- exact dependency and platform assumptions;
- examples aligned with the v1 contract;
- no unresolved item that blocks acceptance-test authoring.

## Documentation Verification

For this documentation-only plan, run:

```sh
git diff --check
git status --short
```

Then manually review:

- every command in `COMMANDS` has a complete contract;
- every global option has an observable effect or a usage-error rule;
- every example maps to a specified command behavior;
- `UNRESOLVED BEHAVIOR` is empty or contains only explicitly accepted non-blocking limitations;
- no line claims implementation completion.

Implementation tests are not evidence for completing this specification plan. Later implementation work must use Git branches and commits to track progress against the completed man page contract.
