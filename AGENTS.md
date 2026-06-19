# AGENTS.md

## Purpose

This repository is developed using a man-page-first, test-first workflow.

The primary goal is working Linux CLI/TUI software whose behavior is documented, tested, and reproducible from the terminal.

Agents must optimize for observable behavior, not repository appearance.

Do not create polished placeholder code, ceremonial documentation, fake completion summaries, or broad architecture plans that cannot be traced to planned or working behavior.

## Core Rule

If behavior cannot be described in the man page and verified by a shell test, do not implement it yet.

The required loop is:

```text
man page → acceptance tests → implementation → verification → review → commit
```

Not:

```text
idea → unlabeled plan → placeholder code → help output
```

Exceptions require explicit user instruction or a clear note explaining why the normal workflow does not apply.

## Specification Authority

The authoritative project specification and user-visible interface contract is
the man page:

```text
doc/<tool>.1.scd
```

or, if the project uses Markdown man-page generation:

```text
doc/<tool>.1.md
```

The man page may be broad. It is allowed to describe the useful, functioning
software the project is building, including behavior that is not implemented
yet. That breadth is not a status claim.

The man page defines the intended user-visible contract:

- command names
- subcommands
- options and flags
- arguments
- stdin behavior
- stdout behavior
- stderr behavior
- exit statuses
- files read or written
- environment variables
- examples
- versioning expectations
- known limitations

Agents must not add commands, flags, config files, output formats, dependencies, or behaviors to the implementation unless they are documented in the man page.

If implementation requires changing behavior, update the man page first.

The man page is the source for planning, implementation, and testing. The
implementation, acceptance tests, verification results, and Git history
determine project completion.

Branch names and commit messages are part of implementation progress tracking.
They should make the delivered slice, current project state, and remaining work
easier to reconstruct from Git history.

Future or not-yet-implemented behavior may be documented in the man page as
part of the project specification. Agents must distinguish specified behavior
from implemented, tested, committed behavior when reporting status.

When specified behavior graduates into implementation work, confirm the man
page contract before adding acceptance tests and code.

## Planning Policy

Persistent plans are allowed when they coordinate single-session or
multi-session documentation and implementation work.

The default persistent plan location is:

```text
.codex/plans/current.md
```

A persistent plan may:

- describe intended future behavior;
- preserve decisions, open questions, and sequencing across sessions;
- define documentation passes needed before tests and implementation;
- group related future work into reviewable implementation slices;
- reference the man page, handoff, branches, issues, and commits that will carry the work forward.
- track the currently selected narrow implementation slice.
- summarize the relevant branch and commit sequence that shows implementation
  progress.

A persistent plan must:

- state whether it is planning-only, documentation work, implementation work, or mixed coordination;
- distinguish intended future behavior from implemented behavior;
- avoid claiming completion without tests and verification;
- identify the next smallest reviewable branch or behavior slice when implementation is ready;
- be updated when work pauses, materially redirects, or spans sessions.

A persistent plan must not:

- substitute for the man page when implementing behavior;
- substitute for acceptance tests;
- substitute for Git history;
- mark behavior complete merely because it is specified;
- hide failing tests, skipped verification, or unresolved decisions;
- require agents to edit unrelated files to make the plan look complete.

For documentation-only specification work, the plan may direct agents to update
the man page before tests exist. That is an explicit exception to the
implementation loop, not evidence that the behavior works. The next
implementation slice must still follow:

```text
man page → acceptance tests → implementation → verification → review → commit
```

## Required Workflow

For every feature or behavior change:

1. Inspect the current Git state.
2. Create or use an appropriately named branch.
3. Update the man page.
4. Add or update tests that encode the documented behavior.
5. Run the tests and confirm they fail for the expected reason.
6. Implement only enough code to pass those tests.
7. Run formatting, linting, and tests.
8. Review the diff.
9. Commit with a legible message.
10. Prepare a focused pull request when appropriate.

Do not claim completion unless the relevant verification commands pass.

If a verification command cannot be run, say so plainly and explain what was not verified.

## Git Control Policy

All work must be done through small, reviewable Git changes.

Branches and commits are progress records as well as review units. Use them to
show which narrow specification slice is being implemented, what has already
landed, and what remains outside the current branch.

Agents must not work directly on `main` unless explicitly instructed.

Before making changes, inspect the current state:

```sh
git status --short
git branch --show-current
```

Do not overwrite, delete, reformat, or move user-created changes unless explicitly instructed.

If the working tree is dirty, identify the existing changes before editing. Preserve them.

Do not stage unrelated files.

Do not commit unrelated files.

Do not hide broad changes inside a narrow feature branch.

## Branch Names

Use one branch per observable behavior.

Branch names must be lowercase, hyphen-separated, and specific.

Allowed prefixes:

```text
feat/
fix/
test/
docs/
refactor/
chore/
release/
```

Good branch names:

```text
feat/init-command
feat/config-search-order
feat/noninteractive-tui-snapshot
fix/missing-config-exit-code
fix/stderr-for-invalid-option
test/sync-command-golden-output
docs/update-manpage-exit-status
refactor/extract-config-loader
chore/add-shellcheck-target
release/0.2.0
```

Bad branch names:

```text
feature
update
changes
fixes
wip
codex-work
big-refactor
final
new-stuff
```

A branch must map to one clear behavioral or maintenance objective.

Do not mix unrelated changes in one branch.

## Commits

Commits must be small, legible, and tied to behavior.

Use imperative commit messages.

Preferred format:

```text
<type>: <specific change>
```

Examples:

```text
feat: add init command
fix: return exit 2 for missing config
test: cover invalid option stderr
docs: document config search order
refactor: extract argument parser
chore: add bats test target
```

The commit subject should be 72 characters or fewer when practical.

Commit bodies are required when the reason is not obvious.

Good commit body:

```text
The init command now creates the project config directory and writes the
default config file. This matches the documented FILES section and is
covered by tests in tests/cli.bats.
```

Bad commit messages:

```text
update
stuff
fix
working
changes
final
wip
codex changes
```

Do not commit generated noise, unrelated formatting, editor files, logs, caches, or temporary files.

## Commit Discipline

Before committing, run:

```sh
git diff --check
git status --short
```

Then run the project verification commands:

```sh
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
```

or the project equivalent:

```sh
make check
```

Do not commit unless the relevant verification commands pass, unless the commit is intentionally capturing a failing test before implementation.

If committing a failing test first, the commit message must say so:

```text
test: capture missing init command behavior
```

The follow-up implementation commit must make that test pass.

Do not claim a failing-test commit completes the feature.

## Pull Requests

Every pull request must be reviewable.

A pull request should contain one coherent behavior change.

Pull request title format:

```text
<type>: <specific change>
```

Good PR titles:

```text
feat: add init command
fix: report invalid options on stderr
test: add golden output coverage for sync
docs: align man page with config behavior
```

Bad PR titles:

```text
updates
misc fixes
final changes
big cleanup
codex implementation
```

Pull request description must include:

```markdown
## Summary

- What changed
- Why it changed

## Behavior

- Commands, flags, outputs, files, or exit codes affected

## Tests

- Commands run
- Result summary

## Documentation

- Man page sections updated, if applicable

## Risks / Limitations

- Known gaps
- Anything intentionally not done
```

Do not open a PR that only adds placeholder code or unsupported completion claims. A planning-only PR is allowed when explicitly requested or when it updates the persistent plan, but it must be labeled and described as planning work rather than feature completion.

Do not describe behavior as complete unless it is implemented and tested.

## Review Requirements

Before requesting review, verify:

```text
- branch name is specific
- commits are legible
- diff is focused
- man page matches behavior
- tests prove behavior
- verification commands pass
- no placeholder commands remain
- no unrelated docs were added
- no user changes were overwritten
```

Agents should explicitly call out questionable changes rather than hiding them in the diff.

## Merge Policy

Prefer squash merge for small feature branches unless the repository uses a different policy.

The final merge commit or squash message must describe the actual behavior delivered.

Do not merge documentation-only plans as feature completion. Merge them only as planning or specification updates.

Do not tag a release from a branch unless:

```text
- the man page is current
- tests pass
- version output is correct
- release notes match implemented behavior
```

## Skill Files

This repository may include task-specific `SKILL.md` files.

`AGENTS.md` is the repository-wide authority. Skill files provide procedures for specific tasks only.

Use a skill file when working in its area, but do not let it override the core workflow:

```text
man page → acceptance tests → implementation → verification → review → commit
```

A skill file must not permit:

- placeholder commands
- undocumented behavior
- fake success messages
- untested completion claims
- new documentation files outside the documentation policy
- direct work on `main` unless explicitly instructed
- overwriting user changes

Create or keep a `SKILL.md` only when it provides repeatable procedure, known pitfalls, and verification commands.

Do not create skill files for tiny one-off actions.

## Handoff Policy

Handoff notes are allowed because they preserve working state across interruptions.

A handoff is not a substitute for working behavior, tests, or Git history.

Use a handoff when work is interrupted, blocked, partially complete, or ready for user review.

A handoff must be factual and resumable.

Handoffs and persistent plans have different roles. The plan preserves multi-session intent and sequencing. The handoff preserves the current working state needed to resume safely.

Session handoffs must be saved to:

```text
.codex/handoff/session_handoff.md
```

When a user asks to continue from handoff, read this file before making changes and treat it as the current resume point unless the user gives newer instructions. Update this file whenever work is paused, blocked, materially redirected, or ready for the next session.

It must include:

- current branch
- relevant changed files
- commands run
- passing checks
- failing checks
- uncommitted changes
- known blockers
- next smallest action
- files or areas that should not be touched
- whether the man page, tests, and implementation are aligned

A handoff must not claim completion unless the Definition of Done is satisfied.

Do not create long narrative summaries.

Do not create roadmap-style handoffs. Put durable sequencing and future-work planning in `.codex/plans/current.md`.

Do not hide failing tests or skipped verification.

## Architecture and Design Policy

Architecture is allowed only when it supports documented, tested behavior.

Design work must be derived from the man page, acceptance tests, and existing code.

Agents must prefer the smallest structure that can satisfy the current contract.

Do not create architecture documents, diagrams, ADRs, plugin systems, frameworks, registries, dependency injection systems, or broad abstractions unless explicitly requested or clearly required by implemented behavior.

For Bash CLI/TUI projects, prefer this shape unless the repository already uses a different one:

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

The TUI must remain presentation over tested command behavior.

Architecture is not complete until behavior is implemented and verified.

Do not claim a design is complete if it has not produced or preserved passing tests.

## Documentation Policy

Documentation is subordinate to behavior except for explicitly labeled planning and future-version specification work.

Allowed documentation files by default:

```text
README.md
AGENTS.md
doc/<tool>.1.scd
.codex/plans/current.md
.codex/handoff/session_handoff.md
docs/ARCHITECTURE.md
docs/TESTING.md
docs/RELEASE.md
```

Do not create additional documentation files unless explicitly requested.

Do not create:

```text
VISION.md
DESIGN_NOTES.md
IMPLEMENTATION_PLAN.md
PROJECT_STATUS.md
CHECKLIST.md
ADR-*.md
```

unless the user explicitly asks for them or the repository already uses them.

Use `.codex/plans/current.md` instead of creating roadmap, checklist, project status, or implementation-plan files by default.

Prefer updating existing documentation over creating new files.

For every behavior-facing documentation change, include at least one of:

- a test proving the documented behavior
- an implementation change matching the documentation
- a packaging, install, or release command that uses the documentation
- an explicit planning-only note in `.codex/plans/current.md` that states tests and implementation are intentionally deferred

Do not create a documentation forest.

## README Policy

The README is for practical user orientation.

It may include:

- project summary
- installation
- quickstart
- common examples
- test instructions
- link or reference to the man page

The README must not become the authoritative command contract. That belongs in the man page.

If README examples disagree with the man page, fix both or remove the stale example.

## Man Page Requirements

The man page should include these sections when applicable:

```text
NAME
SYNOPSIS
DESCRIPTION
COMMANDS
OPTIONS
ARGUMENTS
STDIN
STDOUT
STDERR
EXIT STATUS
FILES
ENVIRONMENT
EXAMPLES
VERSIONING
BUGS
```

Every implemented or release-claimed command documented in the man page must have at least one acceptance test.

Every implemented or release-claimed exit status documented in the man page must have at least one test.

Every implemented or release-claimed stdout/stderr behavior must have a test unless explicitly marked as unstable human-facing output.

Future-version man-page specifications may temporarily lead tests during a documentation-only planning pass. Before any specified behavior is implemented or claimed complete, it must receive acceptance tests.

Examples in the man page should be executable or close to executable.

Use explicit language.

Good:

```text
Exits 0 when the file is created.
Exits 2 when the config file is missing.
Writes the generated path to stdout.
Writes diagnostics to stderr.
```

Bad:

```text
Handles configuration intelligently.
Provides useful output.
Supports robust error handling.
```

## Testing Policy

Behavior must be tested from the outside whenever possible.

Preferred test tools:

```text
bats
shellcheck
shfmt
make
```

Expected test structure:

```text
tests/
  cli.bats
  fixtures/
  golden/
```

Test the actual command-line interface, not only internal functions.

Required test coverage for CLI behavior:

- `--help`
- `--version`
- unknown command
- unknown option
- missing required argument
- valid command success path
- expected stdout
- expected stderr
- expected exit codes
- file creation or modification
- config discovery
- environment variable behavior
- destructive-operation safeguards

For TUI behavior, provide a non-interactive test mode.

Acceptable patterns:

```sh
TOOL_TEST_MODE=1 ./bin/<tool> menu --snapshot
```

```sh
./bin/<tool> tui --dump-screen tests/fixtures/state1
```

TUI code must not be the only way to access core behavior.

The CLI must work without the TUI.

Manual-only testing must be rare and clearly identified.

## Golden Output Policy

Golden files are allowed when output stability matters.

Use golden files for:

- machine-readable output
- structured text output
- generated config files
- snapshot-style TUI dumps

Do not use golden files to bless noisy or unstable output.

When updating golden files, explain why the output changed.

Do not update golden files merely to make failing tests pass.

## Bash Standards

Use Bash intentionally.

Start executable Bash scripts with:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

Use `set -euo pipefail` carefully. Do not assume it catches every failure.

Required practices:

- quote variables
- use arrays for argument lists
- use `mktemp` for temporary files
- use `trap` for cleanup
- validate required commands before use
- separate stdout from stderr
- return meaningful exit codes
- avoid global mutable state when practical
- keep functions small and testable

Forbidden unless explicitly justified:

```bash
eval
curl | bash
parsing ls output
silent network access
implicit destructive actions
unquoted variable expansion
hardcoded user-specific paths
writing outside the project or test temp directory
```

## CLI Output Contract

Stdout is for program output.

Stderr is for diagnostics, warnings, prompts, progress, and errors.

Do not print decorative banners by default.

Do not change output formatting unless tests and man page are updated.

Do not return exit code 0 unless the documented action succeeded.

Do not hide failures behind friendly messages.

Bad:

```text
Done!
```

when nothing was done.

Good:

```text
created: /path/to/file
```

with a verified file effect.

## Help and Version

`--help` must reflect the man page.

`--version` must print the current project version.

A command that only prints help is not an implementation.

Do not mark a command complete if its only behavior is to display usage text.

When the man page contains an explicit future-version contract, `--help` only has to reflect the implemented command surface until the corresponding behavior slice is implemented and tested.

## Implementation Policy

Implement the smallest complete behavior that satisfies the current tests.

Do not add speculative abstractions.

Do not add dependencies without updating installation documentation and tests.

Do not introduce config files, cache directories, state directories, or environment variables unless documented in the man page.

Do not silently change public behavior.

Do not replace a clear shell implementation with a framework unless the repository already uses that framework or the user explicitly requests it.

Prefer boring, inspectable code over clever code.

## Dependency Policy

Dependencies must be justified by behavior.

Before adding a dependency, document:

- why it is needed
- how it is installed
- how missing dependency errors are reported
- whether it is required or optional

The tool must fail clearly when a required dependency is missing.

Do not add network-dependent behavior unless the man page documents it.

Do not add package-manager-specific assumptions unless the project targets that environment.

## Configuration Policy

Configuration behavior must be explicit.

If the tool reads config, the man page must document:

- config file path
- search order
- environment variable overrides
- default behavior when config is missing
- behavior for malformed config
- exit status for config errors

Tests must cover the config search order and failure modes.

Do not invent hidden config paths.

Do not write user-level config during tests unless using a temporary home directory.

## File Safety Policy

Any command that writes, modifies, or deletes files must be documented and tested.

Destructive operations require safeguards.

Acceptable safeguards include:

- explicit `--force`
- confirmation prompt
- dry-run default
- backup behavior
- refusing to operate outside an expected directory

Tests must not write outside a temporary directory.

Use temporary directories for test isolation.

Do not assume the current working directory is safe.

## TUI Policy

The TUI is presentation, not the core application.

Core behavior must live outside TUI handlers.

Preferred structure:

```text
bin/<tool>
lib/
  commands.sh
  config.sh
  output.sh
  tui.sh
tests/
```

The TUI may call command functions, but command behavior must be testable without launching an interactive UI.

Every TUI feature should have either:

- a non-interactive snapshot test
- a command-level test for the behavior behind the TUI
- a documented manual test when automation is not practical

Manual-only testing must be rare and clearly identified.

Do not let menu code become the application.

## Versioning Policy

Versions are tied to documented behavior.

Do not bump the version unless:

- the man page is updated
- tests pass
- behavior exists
- release notes or changelog entries match actual changes, if the project uses them

Suggested version model before 1.0:

```text
0.1.0  first usable CLI contract
0.2.0  additional command behavior
0.3.0  TUI wrapper over tested commands
0.x.0  new documented behavior
0.x.y  bug fixes only
```

Do not ship a TUI before the underlying CLI behavior works.

## Definition of Done

A change is done only when all applicable commands pass:

```sh
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/<tool> --help
./bin/<tool> --version
```

If the project uses `make`, prefer:

```sh
make check
```

or:

```sh
make test
```

A completion report must include:

- changed files
- tests added or updated
- commands run
- command output summary
- known limitations
- anything intentionally not done

Do not claim that tests pass unless they were run.

Do not claim behavior works unless it was exercised from the command line.

## Agent Prompting Contract

When working in this repository, follow this instruction:

```text
Implement only the behavior documented in the man page.

For planning-only work, update `.codex/plans/current.md` and any explicitly
requested specification documents without claiming implementation completion.

Before implementation:
1. inspect git status and the current branch;
2. create or use a specific branch for the behavior;
3. update the man page if the behavior is not documented;
4. add acceptance tests for the documented behavior;
5. run the tests and confirm they fail for the expected reason.

Then:
1. implement only enough code to pass the tests;
2. run shellcheck, shfmt, and bats, or the project equivalent;
3. review the diff;
4. commit with a specific imperative commit message;
5. prepare a focused pull request when appropriate.

Do not create new documentation files unless explicitly requested.
Do not create placeholder commands.
Do not create fake success messages.
Do not add undocumented flags or behavior.
Do not return exit code 0 unless the documented action occurred.
Do not overwrite user changes.
Do not work directly on main unless explicitly instructed.
```

## Anti-Patterns

Reject these outcomes:

```text
The repository looks complete but commands do nothing.
The help output is polished but implementation is missing.
The docs describe future behavior as implemented behavior.
Tests only check that files exist.
Tests only check that --help prints.
The TUI contains all business logic.
The agent creates many documents instead of working code.
The agent claims success without running commands.
The agent hides errors behind friendly output.
The agent commits unrelated formatting changes.
The agent works directly on main without being told to.
The agent uses vague branch names or vague commit messages.
The PR contains unlabeled plans and presents them as feature completion.
```

## Preferred Agent Behavior

Be boring.

Be literal.

Be test-driven.

Prefer small diffs.

Prefer observable behavior.

Prefer explicit contracts.

Prefer clear Git history.

Prefer deleting unsupported claims.

Prefer failing loudly over pretending success.

When uncertain during implementation, do not invent behavior. Tighten the man page and tests first. During planning, record future behavior as intended or unresolved until it becomes a tested contract.
