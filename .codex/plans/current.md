# Current Plan

## State

- Work type: mixed coordination and implementation work.
- Target implementation branch: `fix/remove-directory-recursive-guard`.
- Target behavior: execute `nsurgn remove ARTIFACT_OR_PID TARGET_PATH --force --recursive` for real directories while preserving documented destructive-operation safeguards.
- Status: Slices 1, 2, 3, 4, and 5 are complete on `fix/remove-directory-recursive-guard`.
- Last checked: 2026-06-24.
- Current repo state: `main` contains the documented `remove --recursive` contract. On `fix/remove-directory-recursive-guard`, Slice 1 exposes `--recursive` in help, parses it, and refuses real directories without `--recursive`. Slice 2 adds regression coverage for symlink-to-directory and broken-symlink removal semantics without production code changes. Slice 3 adds the unsupported `rm --one-file-system` guard before recursive directory deletion and fixture-tested mountinfo path matching helpers. Slice 4 removes ordinary real directories with `rm -r --one-file-system` after refusing mount points at or under the target using `/proc/<leader-pid>/mountinfo`. Slice 5 final verification passes, and the stale session handoff was intentionally zeroed per user instruction.
- Next implementation slice: none; current plan slices are complete.

This file is the active coordination plan. There is no separate findings file for this slice.

## Contract Source

- Man page: `doc/nsurgn.1.md`
- Documented command:

```text
nsurgn remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]
```

- Relevant documented behavior:
  - `remove` is destructive and always requires `--force`.
  - `TARGET_PATH` must be absolute and must not contain traversal.
  - Protected paths are refused.
  - Removing a symlink removes the symlink itself, not the symlink target.
  - Directory removal requires `--recursive`.
  - Recursive directory removal refuses any mount point at or under `TARGET_PATH` before deletion.
  - Recursive directory removal requires GNU/coreutils-compatible `rm` support for `--one-file-system`.
  - Directory removal without `--recursive`, target mount-point refusal, and nested mount-point refusal exit `5`.
  - Unsupported recursive removal because `rm --one-file-system` is unavailable exits `9`.

## Current Gap

- Slice 1 resolved: `lib/commands.sh` usage now shows `remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]`.
- Slice 1 resolved: `cmd_remove` parses `--force` and `--recursive`.
- `cmd_remove` checks GNU/coreutils-compatible `rm --one-file-system` support before any recursive real-directory deletion path and still calls `rm -- "$resolved"` for non-recursive removable targets.
- Slice 1 resolved: a real directory passed with `--force` and without `--recursive` is refused by the documented `nsurgn` diagnostic and exit-status contract.
- Existing tests cover `remove` force requirements, file deletion, protected paths, help exposure for `--recursive`, directory refusal without `--recursive`, unsupported `rm --one-file-system`, successful recursive directory removal, mount-point refusal integration when bind mounts are available, mountinfo path matching helpers, symlink-to-directory removal, and broken-symlink removal.

## Implementation Branch Shape

Use one branch:

```text
fix/remove-directory-recursive-guard
```

Use small commits on that branch. Each implementation slice below should follow:

```text
man page check -> acceptance tests -> failing test checkpoint -> implementation -> verification -> commit
```

The man page already documents the selected behavior. Do not change it unless a slice intentionally changes the user-visible contract before tests are written.

## Slice 1: Expose and Guard Recursive Directory Removal

Status: complete on `fix/remove-directory-recursive-guard`.

Verification:

```sh
bats --filter "--help prints usage" tests/cli.bats
bats --filter "remove with --force refuses a directory" tests/cli.bats
bats --filter "remove with --force deletes" tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
./bin/nsurgn --help
./bin/nsurgn --version
bats tests
```

Goal:

- Make the command surface match the documented `--recursive` option.
- Refuse real directories without `--recursive` using `nsurgn`'s own documented diagnostic.

Tests first in `tests/cli.bats`:

- `--help` includes:

```text
remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]
```

- `remove --force` refuses a real directory without `--recursive`.
  - Status: `5`.
  - Stdout: empty.
  - Stderr contains:

```text
error: directory removal requires --recursive: <resolved-target>
```

  - File effect: directory and contained file remain present.

Expected failing checkpoint:

- Help output still lacks `[--recursive]`.
- Directory refusal still comes from `rm` or a different status/diagnostic.

Implementation:

- Update `usage()` in `lib/commands.sh`.
- Add `recursive=0` in `cmd_remove`.
- Parse `--recursive` as a recognized option.
- Detect real directories with `[[ -d "$resolved" && ! -L "$resolved" ]]`.
- If real directory and `recursive=0`, write the documented diagnostic to stderr and return `5`.
- Preserve existing file removal, missing target handling, protected path refusal, unknown-option handling, and `--force` refusal.

Commit:

```text
fix: require recursive remove for directories
```

## Slice 2: Preserve Symlink Removal Semantics

Status: complete on `fix/remove-directory-recursive-guard`.

Verification:

```sh
bats --filter "remove with --force removes a symlink to a directory" tests/cli.bats
bats --filter "remove with --force removes a broken symlink" tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
./bin/nsurgn --help
./bin/nsurgn --version
bats tests
```

Implementation note:

- Current behavior already passed the Slice 2 acceptance tests, so this slice is regression coverage only.

Goal:

- Prove that adding directory guards does not make symlinks follow directory behavior.

Tests first in `tests/cli.bats`:

- `remove --force` removes a symlink to a directory without requiring `--recursive`.
  - Status: `0`.
  - Stdout:

```text
removed: <resolved-target>
```

  - Stderr: empty.
  - File effect: symlink is removed; referent directory remains.

- `remove --force` removes a broken symlink without requiring `--recursive`.
  - Status: `0`.
  - Stdout:

```text
removed: <resolved-target>
```

  - Stderr: empty.
  - File effect: broken symlink is removed.

Expected failing checkpoint:

- If current behavior already passes, record that as a non-failing regression-coverage checkpoint and commit only the tests.
- If the new directory guard breaks symlink behavior, fix it before moving on.

Implementation:

- Treat `[[ -L "$resolved" ]]` as removable even when `[[ -e "$resolved" ]]` is false.
- Keep symlinks out of the real-directory branch.
- Keep success stdout unchanged.

Commit:

```text
test: cover remove symlink directory targets
```

Use `fix:` instead if implementation changes are required.

## Slice 3: Execute Recursive Directory Removal

Status: complete on `fix/remove-directory-recursive-guard`.

Verification:

```sh
bats --filter "remove with --force --recursive fails before deletion when rm lacks one-file-system support|mountinfo helper" tests/cli.bats
bats --filter "remove" tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
./bin/nsurgn --help
./bin/nsurgn --version
bats tests
```

Implementation note:

- This slice intentionally does not add a successful recursive directory deletion path. It only adds the pre-delete unsupported-`rm` guard and helper-level fixture coverage for mountinfo matching.

Goal:

- Add the safety helpers required before any successful recursive directory deletion path exists.
- Fail before deletion when GNU/coreutils-compatible `rm --one-file-system` support is unavailable.
- Prove mountinfo path matching with deterministic fixture tests.

Tests first in `tests/cli.bats`:

- Recursive removal fails clearly when `rm --one-file-system` is unsupported.
  - Use a temporary `PATH` directory containing an `rm` shim for this one `run_cli remove ... --recursive` invocation.
  - The shim must fail the capability probe for `--one-file-system`.
  - Test setup and teardown must keep using the normal system `rm`.
  - Status: `9`.
  - Stdout: empty.
  - Stderr:

```text
error: recursive removal requires GNU rm with --one-file-system
```

  - File effect: directory remains present.

- Helper-level fixture coverage for mountinfo path matching:
  - Source `lib/output.sh` and `lib/commands.sh` directly from Bats for pure helper tests.
  - Run helper tests in subshells so sourcing `lib/commands.sh` cannot affect later CLI tests.
  - Pass fixture mountinfo through function input or temporary files, not through CLI-visible flags, config files, or persistent environment variables.
  - `/tmp/a` matches `/tmp/a`.
  - `/tmp/a` matches `/tmp/a/mnt`.
  - `/tmp/a` does not match `/tmp/abc`.
  - repeated slash and trailing slash inputs normalize consistently, such as `/tmp//a` and `/tmp/a/`.
  - mountinfo octal escapes such as `\040` decode for comparison.

Expected failing checkpoint:

- `--recursive` is parsed after Slice 1, but unsupported `rm` is not detected before deletion.
- Mount-point helper tests fail because no helper exists.

Implementation:

- Add a narrow helper in `lib/commands.sh`:

```bash
rm_supports_one_file_system()
```

- Add narrow mountinfo helpers in `lib/commands.sh`, for example:

```bash
normalize_artifact_path_for_mountinfo()
decode_mountinfo_path()
mount_points_under_target()
procfs_path_for_artifact_path()
```

- Call the helper before recursive deletion.
- If unsupported, return `9` before touching the target.
- Do not add a successful recursive deletion path in this slice.

Commit:

```text
fix: prepare recursive remove safety checks
```

## Slice 4: Refuse Mount Points and Execute Recursive Directory Removal

Status: complete on `fix/remove-directory-recursive-guard`.

Verification:

```sh
bats --filter "remove with --force --recursive deletes an ordinary directory|remove with --force --recursive refuses|remove with --force --recursive fails before deletion when rm lacks one-file-system support|mountinfo helper" tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
./bin/nsurgn --help
./bin/nsurgn --version
bats tests
```

Environment note:

- The bind-mount integration tests for target and nested mount-point refusal are present and skipped in the current environment with `temporary bind mounts unavailable`.

Goal:

- Refuse recursive deletion when `TARGET_PATH` is itself a mount point.
- Refuse recursive deletion when any nested path under `TARGET_PATH` is a mount point.
- Keep mountinfo comparisons in artifact namespace paths, not host procfs paths.
- Make `remove --force --recursive` remove an ordinary real directory only after `rm --one-file-system` support and mount-point refusal checks pass.

Tests first in `tests/cli.bats`:

- `remove --force --recursive` removes a real directory with no mount point at or under the target.
  - Status: `0`.
  - Stdout:

```text
removed: <resolved-target>
```

  - Stderr: empty.
  - File effect: directory no longer exists.

- Integration coverage where the test environment permits a temporary bind mount:
  - `remove --force --recursive` refuses a target directory that is a mount point.
  - `remove --force --recursive` refuses a directory tree containing a nested mount point.
  - Status: `5`.
  - Stdout: empty.
  - Stderr:

```text
error: refusing mount point: <resolved-target-or-nested-resolved-mount-point>
```

  - File effect: target directory, ordinary contents, mount point, and mounted contents remain present.

If bind mounts are unavailable, keep the privileged integration tests skipped with explicit reasons and rely on helper fixture coverage for the path-domain logic.

Expected failing checkpoint:

- Recursive directory removal still cannot succeed, or mount-point refusal is missing.
- Privileged integration tests either fail for missing refusal logic or skip for missing mount privileges.

Implementation:

- Read `/proc/<leader-pid>/mountinfo`, not `/proc/self/mountinfo`.
- Compare decoded mountinfo mount-point paths against normalized artifact namespace `TARGET_PATH`.
- Use exact path-boundary matching.
- Convert refused namespace mount points back to `/proc/<leader-pid>/root/...` for diagnostics.
- Refuse the first mount point at or under the target before running `rm`.
- For ordinary directories after all safety checks pass, run:

```bash
rm -r --one-file-system -- "$resolved"
```

- Use `--one-file-system` as a defensive backstop, not as the only mount-point safeguard.

Commit:

```text
fix: remove directories with recursive mount guard
```

## Slice 5: Final Verification and Branch Handoff

Status: complete on `fix/remove-directory-recursive-guard`.

Verification:

```sh
bats tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
git diff --check
```

Environment note:

- `bats tests/cli.bats` and `bats tests` passed with the expected skips for unavailable temporary bind mounts and no visible non-host PID namespace pair.
- `.codex/handoff/session_handoff.md` was stale and was zeroed rather than updated per user instruction.

Goal:

- Confirm the complete branch matches the documented behavior and is review-ready.

Run:

```sh
bats tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
git diff --check
```

Review:

- `doc/nsurgn.1.md` still matches implemented behavior.
- `tests/cli.bats` proves the implemented command surface, stdout, stderr, exit statuses, and file effects.
- No new environment variables, config files, or hidden fixture overrides were introduced.
- No unrelated commands were changed.
- Mount-point tests clearly distinguish helper fixture coverage from privileged integration coverage.

Update handoff:

- Update `.codex/handoff/session_handoff.md` with branch, changed files, commands run, passing checks, skipped checks, blockers, and next action.

Final commit if only handoff/status changes are needed:

```text
docs: hand off recursive remove guard branch
```

## Expected Changed Files on Implementation Branch

- `lib/commands.sh`
- `tests/cli.bats`
- `.codex/handoff/session_handoff.md` when pausing or handing off

Expected unchanged unless the contract changes:

- `doc/nsurgn.1.md`
- `README.md`
- `nsurgn_specification_v1.0.md`

## Do Not Touch

- Do not implement unrelated `extract`, `install`, `inject`, `cat`, `checksum`, `exists`, `ls`, `stat`, `signal`, or `enter` behavior.
- Do not add a new source file unless `lib/commands.sh` becomes unreasonably hard to review.
- Do not add a CLI-visible mountinfo fixture flag, environment variable, or config file.
- Do not rely on `rm --one-file-system` alone to discover mount points after deletion has begun.
- Do not claim recursive remove is complete until the acceptance tests and final verification commands pass.
