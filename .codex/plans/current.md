# Current Plan

## State

- Work type: mixed coordination for one implementation slice plus one follow-up slice.
- Active slice: `fix/remove-directory-recursive-guard`.
- Planned implementation branch: `fix/remove-directory-recursive-guard`.
- Status: selected for planning; tests and implementation not started.
- Last handoff: `.codex/handoff/session_handoff.md`.
- Last completed branch: `fix/install-refuse-nonregular-host-source`.
- Last checked: 2026-06-20.
- Review findings: `.codex/plans/findings.md`. Prior findings were resolved into this plan on 2026-06-20.

## Contract Source

- Man page: `doc/nsurgn.1.md`
- Documented command: `nsurgn remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]`
- Relevant documented behavior:
  - `remove` is destructive and always requires `--force`.
  - `TARGET_PATH` must be absolute and must not contain traversal.
  - Removing a symlink removes the symlink itself, not the symlink target.
  - Directory removal requires `--recursive`.
  - Protected paths are refused.
  - Mount points are refused, including recursive removal. This remains a known documented gap for follow-up branch `fix/remove-refuse-mountpoints`.
  - Recursive removal must not cross nested mount points inside the target directory. This remains a known documented gap for follow-up branch `fix/remove-refuse-mountpoints`.

## Current Gap

- `cmd_remove` parses `--force` but not `--recursive`.
- `cmd_remove` calls `rm -- "$resolved"` for every target.
- A real directory passed with `--force` is refused only by `rm`, producing an implementation-dependent diagnostic rather than the documented `nsurgn` contract.
- `--help`/usage text does not expose the documented `--recursive` option.
- No acceptance test currently proves directory refusal without `--recursive`, recursive directory removal with `--recursive`, symlink handling for directory targets, broken symlink removal, help output, or the documented unsupported-platform behavior for recursive removal.
- No acceptance test currently proves mount-point refusal. That behavior is intentionally deferred to `fix/remove-refuse-mountpoints`.

## Scope

Implement the smallest directory-recursive guard slice:

- Parse `--recursive` for `remove`.
- Refuse real directories when `--recursive` is absent.
- Leave refused directories and their contents intact.
- Remove real directories only when both `--force` and `--recursive` are present.
- Continue removing symlinks themselves without requiring `--recursive`, including symlinks that point at directories.
- Continue removing broken symlinks themselves without requiring `--recursive`.
- Update `--help`/usage output so the implemented command surface shows `remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]`.
- Preserve existing behavior for files, missing targets, protected paths, unknown options, and `--force` refusal.
- Use `rm --one-file-system` for recursive removal only after documenting the GNU/coreutils-compatible `rm` dependency and unsupported-platform failure.

Out of scope for this slice:

- Mount-point refusal, including target mount-point refusal and nested mount-point crossing checks. Track this separately as `fix/remove-refuse-mountpoints`.
- Broader remove safeguards beyond the documented directory-recursive behavior.
- Race-specific exit `8` handling unless the man page and acceptance tests are tightened first.
- Install, extract, inject, cat, checksum, exists, ls, stat, signal, or enter behavior.

## Man Page Updates Before Tests

Update `doc/nsurgn.1.md` before adding acceptance tests:

- In `STDERR`, add exact diagnostics:

```text
error: directory removal requires --recursive: <resolved-target>
error: recursive removal requires GNU rm with --one-file-system
```

- Confirm exit status `5` is the exact status for directory refusal because exit `5` already means unsafe path refused.
- Confirm exit status `9` is the exact status for unsupported recursive removal because exit `9` already covers unsupported platform or missing command-specific dependency.
- In `FILES` or the relevant command text, document that recursive removal requires GNU/coreutils-compatible `rm` support for `--one-file-system`.
- Keep the `remove` command contract as `nsurgn remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]`.

This documentation step may be a first commit on `fix/remove-directory-recursive-guard` or a separate focused documentation branch such as `docs/remove-directory-recursive-diagnostics`. Either way, it must land before tests that assert these diagnostics.

## Planned Test Changes

Add Bats coverage in `tests/cli.bats` before implementation:

- `--help` includes `remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]`.
- `remove --force` refuses a real directory without `--recursive`.
  - Expected status: `5`.
  - Expected stdout: empty.
  - Expected stderr: `error: directory removal requires --recursive: <resolved-target>`.
  - Expected file effect: directory and contained file remain present.
- `remove --force --recursive` removes a real directory and reports the file effect.
  - Expected status: `0`.
  - Expected stdout: `removed: <resolved-target>`.
  - Expected stderr: empty.
  - Expected file effect: directory no longer exists.
- `remove --force --recursive` fails clearly when `rm --one-file-system` is unsupported.
  - Expected status: `9`.
  - Expected stdout: empty.
  - Expected stderr: `error: recursive removal requires GNU rm with --one-file-system`.
  - Expected file effect: directory remains present.
  - Test setup: use an internal helper or PATH fixture to exercise the dependency check without creating a user-visible configuration or environment override.
- `remove --force` removes a symlink to a directory without requiring `--recursive`.
  - Expected status: `0`.
  - Expected stdout: `removed: <resolved-target>`.
  - Expected stderr: empty.
  - Expected file effect: symlink is removed and referent directory remains.
- `remove --force` removes a broken symlink without requiring `--recursive`.
  - Expected status: `0`.
  - Expected stdout: `removed: <resolved-target>`.
  - Expected stderr: empty.
  - Expected file effect: broken symlink is removed.

## Planned Implementation

- In `lib/commands.sh`, update `usage()` so `remove` includes `[--recursive]`.
- In `cmd_remove`, add a local `recursive=0` flag.
- Extend option parsing:
  - `--force` sets `force=1`.
  - `--recursive` sets `recursive=1`.
  - all other options remain errors with exit `2`.
- Keep `--force` validation before destructive behavior.
- Keep protected-path refusal before resolving the target.
- Resolve the target path before diagnostics that need `<resolved-target>`.
- Preserve broken symlink behavior by treating `[[ -L "$resolved" ]]` as an existing removable target even when `[[ -e "$resolved" ]]` is false.
- Add a dependency check for `rm --one-file-system` before recursive removal. If unsupported, print `error: recursive removal requires GNU rm with --one-file-system` and return `9` before touching the target.
- Detect real directories with:

```bash
[[ -d "$resolved" && ! -L "$resolved" ]]
```

- If the target is a real directory and `recursive=0`, print `error: directory removal requires --recursive: <resolved-target>` and return `5`.
- If the target is a real directory and `recursive=1`, after the dependency check passes, remove the directory with:

```bash
rm -r --one-file-system -- "$resolved"
```

- Use `--one-file-system` as a defensive backstop against crossing filesystem boundaries until explicit mount-point refusal is implemented in `fix/remove-refuse-mountpoints`.
- Treat GNU/coreutils-compatible `rm --one-file-system` as a Linux platform assumption for this slice.
- Otherwise, run the existing `rm -- "$resolved"` path for files and symlinks.
- Keep success stdout as `removed: <resolved-target>`.

## Internal Structure

Keep this slice in `lib/commands.sh`.

Add only narrow helpers if they keep `cmd_remove` readable, for example:

```bash
rm_supports_one_file_system()
```

Do not add a new source file, framework, dependency abstraction, architecture document, or broad remove subsystem.

## Verification Plan

Follow the repository loop:

1. Create or switch to `fix/remove-directory-recursive-guard`.
2. Add exact man page diagnostics before tests.
3. Add acceptance tests.
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
- `doc/nsurgn.1.md`
- `tests/cli.bats`
- `lib/commands.sh`

## Do Not Touch

- Do not implement target or nested mount-point refusal in this slice; do that in `fix/remove-refuse-mountpoints`.
- Do not modify unrelated file-operation commands.
- Do not add new required external dependencies for this behavior.
- Do not claim completion until acceptance tests and verification pass.

## Follow-Up Slice: `fix/remove-refuse-mountpoints`

Implement the documented mount-point refusal behavior after the directory-recursive guard branch lands.

- Refuse recursive removal when the target directory is a mount point.
- Refuse recursive removal when any nested directory under the target is a mount point.
- Do not cross nested mount points during deletion.
- Read `/proc/<leader-pid>/mountinfo`, not `/proc/self/mountinfo`, so mount checks are based on the selected artifact leader.
- Decode mountinfo path escapes, including `\040` for spaces.
- Compare mount targets with exact path-boundary matching so `/tmp/a` does not match `/tmp/abc`.
- Avoid a CLI-visible mountinfo override. Put mountinfo parsing in narrow helpers that accept file input internally, and test those helpers directly or through a non-user-visible test wrapper.
- Do not add an environment variable or configuration file for test fixtures unless the man page is explicitly updated first.
