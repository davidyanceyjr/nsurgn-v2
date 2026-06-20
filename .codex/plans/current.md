# Current Plan

## State

- Work type: implementation planning for one documented behavior slice.
- Active slice: `fix/remove-directory-recursive-guard`.
- Planned implementation branch: `fix/remove-directory-recursive-guard`.
- Status: selected for planning; tests and implementation not started.
- Last handoff: `.codex/handoff/session_handoff.md`.
- Last completed branch: `fix/install-refuse-nonregular-host-source`.
- Last checked: 2026-06-20.

## Contract Source

- Man page: `doc/nsurgn.1.md`
- Documented command: `nsurgn remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]`
- Relevant documented behavior:
  - `remove` is destructive and always requires `--force`.
  - `TARGET_PATH` must be absolute and must not contain traversal.
  - Removing a symlink removes the symlink itself, not the symlink target.
  - Directory removal requires `--recursive`.
  - Protected paths are refused.
  - Mount points are refused, including recursive removal.

## Current Gap

- `cmd_remove` parses `--force` but not `--recursive`.
- `cmd_remove` calls `rm -- "$resolved"` for every target.
- A real directory passed with `--force` is refused only by `rm`, producing an implementation-dependent diagnostic rather than the documented `nsurgn` contract.
- No acceptance test currently proves directory refusal without `--recursive` or recursive directory removal with `--recursive`.

## Scope

Implement the smallest directory-recursive guard slice:

- Parse `--recursive` for `remove`.
- Refuse real directories when `--recursive` is absent.
- Leave refused directories and their contents intact.
- Remove real directories only when both `--force` and `--recursive` are present.
- Continue removing symlinks themselves without requiring `--recursive`, including symlinks that point at directories.
- Preserve existing behavior for files, missing targets, protected paths, unknown options, and `--force` refusal.

Out of scope for this slice:

- Mount-point refusal. Track separately as `fix/remove-refuse-mountpoints`.
- Broader remove safeguards beyond the documented directory-recursive behavior.
- Install, extract, inject, cat, checksum, exists, ls, stat, signal, or enter behavior.

## Planned Test Changes

Add Bats coverage in `tests/cli.bats` before implementation:

- `remove --force` refuses a real directory without `--recursive`.
  - Expected status: nonzero, preferably `5` for refused unsafe target/path operation.
  - Expected stdout: empty.
  - Expected stderr: documented `error:` diagnostic for missing `--recursive`.
  - Expected file effect: directory and contained file remain present.
- `remove --force --recursive` removes a real directory and reports the file effect.
  - Expected status: `0`.
  - Expected stdout: `removed: <resolved-target>`.
  - Expected stderr: empty.
  - Expected file effect: directory no longer exists.
- `remove --force` removes a symlink to a directory without requiring `--recursive`.
  - Expected status: `0`.
  - Expected stdout: `removed: <resolved-target>`.
  - Expected stderr: empty.
  - Expected file effect: symlink is removed and referent directory remains.

If the current man page stderr examples are not specific enough for the new refusal case, update `doc/nsurgn.1.md` before adding the tests with an explicit diagnostic such as:

```text
error: directory removal requires --recursive: <path>
```

## Planned Implementation

- In `lib/commands.sh`, add a local `recursive=0` flag inside `cmd_remove`.
- Extend option parsing:
  - `--force` sets `force=1`.
  - `--recursive` sets `recursive=1`.
  - all other options remain errors with exit `2`.
- Keep `--force` validation before destructive behavior.
- Keep protected-path refusal before resolving the target.
- After resolving and confirming the target exists, detect real directories with:

```bash
[[ -d "$resolved" && ! -L "$resolved" ]]
```

- If the target is a real directory and `recursive=0`, print the documented diagnostic and return the selected refusal status.
- If the target is a real directory and `recursive=1`, run `rm -r -- "$resolved"`.
- Otherwise, run the existing `rm -- "$resolved"` path for files and symlinks.
- Keep success stdout as `removed: <resolved-target>`.

## Verification Plan

Follow the repository loop:

1. Create or switch to `fix/remove-directory-recursive-guard`.
2. Add or tighten the man page diagnostic if needed.
3. Add the acceptance tests.
4. Run `bats tests/cli.bats` and confirm the new tests fail for the expected reason.
5. Implement only enough code to pass the tests.
6. Run:

```sh
bats tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
git diff --check
```

7. Review the diff.
8. Commit with:

```text
fix: require recursive remove for directories
```

## Expected Changed Files

- `.codex/plans/current.md`
- `doc/nsurgn.1.md` only if the new refusal diagnostic must be specified
- `tests/cli.bats`
- `lib/commands.sh`

## Do Not Touch

- Do not implement mount-point refusal in this slice; use later slice `fix/remove-refuse-mountpoints`.
- Do not modify unrelated file-operation commands.
- Do not claim completion until acceptance tests and verification pass.
