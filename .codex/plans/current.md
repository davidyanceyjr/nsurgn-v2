# Current Plan

## State

- Work type: mixed coordination for one implementation slice.
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
  - Recursive directory removal refuses any mount point at or under `TARGET_PATH` before deletion.
  - Recursive removal must not cross nested mount points inside the target directory.

## Current Gap

- `cmd_remove` parses `--force` but not `--recursive`.
- `cmd_remove` calls `rm -- "$resolved"` for every target.
- A real directory passed with `--force` is refused only by `rm`, producing an implementation-dependent diagnostic rather than the documented `nsurgn` contract.
- `--help`/usage text does not expose the documented `--recursive` option.
- No acceptance test currently proves directory refusal without `--recursive`, recursive directory removal with `--recursive`, symlink handling for directory targets, broken symlink removal, help output, or the documented unsupported-platform behavior for recursive removal.
- No acceptance test currently proves target or nested mount-point refusal.
- The mount-point implementation plan must keep path domains separate: `/proc/<leader-pid>/mountinfo` reports artifact namespace paths, while `resolve_target_path` returns host-visible procfs paths under `/proc/<leader-pid>/root`.
- The man page must not imply a separate non-recursive mount-point refusal path unless that behavior is also tested and implemented.

## Scope

Implement the smallest directory-recursive guard slice:

- Parse `--recursive` for `remove`.
- Refuse real directories when `--recursive` is absent.
- Leave refused directories and their contents intact.
- Refuse recursive removal when the target directory itself is a mount point.
- Refuse recursive removal when any nested directory under the target is a mount point.
- Do not remove or cross any mount point during recursive deletion.
- Remove real directories only when both `--force` and `--recursive` are present.
- Continue removing symlinks themselves without requiring `--recursive`, including symlinks that point at directories.
- Continue removing broken symlinks themselves without requiring `--recursive`.
- Update `--help`/usage output so the implemented command surface shows `remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]`.
- Preserve existing behavior for files, missing targets, protected paths, unknown options, and `--force` refusal.
- Use `rm --one-file-system` for recursive removal only after documenting the GNU/coreutils-compatible `rm` dependency and unsupported-platform failure.

Out of scope for this slice:

- Broader remove safeguards beyond the documented directory-recursive behavior.
- Non-recursive mount-point-specific diagnostics; without `--recursive`, real directories are refused by the directory-recursive guard.
- Race-specific exit `8` handling unless the man page and acceptance tests are tightened first.
- Install, extract, inject, cat, checksum, exists, ls, stat, signal, or enter behavior.

## Man Page Updates Before Tests

Update `doc/nsurgn.1.md` before adding acceptance tests:

- In `STDERR`, add exact diagnostics:

```text
error: directory removal requires --recursive: <resolved-target>
error: refusing mount point: <resolved-target>
error: recursive removal requires GNU rm with --one-file-system
```

- Confirm exit status `5` is the exact status for directory refusal because exit `5` already means unsafe path refused.
- Confirm exit status `5` is the exact status for target and nested mount-point refusal because exit `5` already means unsafe path refused.
- Confirm exit status `9` is the exact status for unsupported recursive removal because exit `9` already covers unsupported platform or missing command-specific dependency.
- Remove or replace broad wording that says all mount points are refused unless this slice expands to test and implement non-recursive mount-point-specific refusal.
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
- `remove --force --recursive` refuses a target directory that is a mount point.
  - Expected status: `5`.
  - Expected stdout: empty.
  - Expected stderr: `error: refusing mount point: <resolved-target>`.
  - Expected file effect: mount point and mounted contents remain present.
  - Test setup: prefer a temporary bind mount when the test environment has the required privilege. If unavailable, exercise the internal mount-point detection helper with fixture input and keep the privileged integration test skipped with an explicit reason.
- `remove --force --recursive` refuses a directory tree containing a nested mount point.
  - Expected status: `5`.
  - Expected stdout: empty.
  - Expected stderr: `error: refusing mount point: <nested-resolved-mount-point>`.
  - Expected file effect: target directory, ordinary contents, mount point, and mounted contents remain present.
  - Test setup: prefer a temporary bind mount when the test environment has the required privilege. If unavailable, exercise the internal mount-point detection helper with fixture input and keep the privileged integration test skipped with an explicit reason.
  - Helper fixture coverage must prove namespace-path comparison, including a target such as `/tmp/a`, a non-match such as `/tmp/abc`, and a nested mount such as `/tmp/a/mnt`.
- `remove --force --recursive` fails clearly when `rm --one-file-system` is unsupported.
  - Expected status: `9`.
  - Expected stdout: empty.
  - Expected stderr: `error: recursive removal requires GNU rm with --one-file-system`.
  - Expected file effect: directory remains present.
  - Test setup: exercise a narrow internal `rm_supports_one_file_system` helper so the failure branch is proven before any deletion path can run. Do not use a PATH fake that can intercept both the capability probe and the destructive `rm` call.
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
- Parse the target leader pid before mountinfo checks so the implementation can read `/proc/<leader-pid>/mountinfo` and build `/proc/<leader-pid>/root/...` diagnostic paths from matching namespace mount points.
- Resolve the target path before diagnostics that need `<resolved-target>`. Keep this procfs path for file effects and user-facing diagnostics; do not use it as the mountinfo comparison key.
- Preserve broken symlink behavior by treating `[[ -L "$resolved" ]]` as an existing removable target even when `[[ -e "$resolved" ]]` is false.
- Add a narrow `rm_supports_one_file_system` helper for the dependency check. `cmd_remove` must call this helper before recursive deletion; if unsupported, print `error: recursive removal requires GNU rm with --one-file-system` and return `9` before touching the target.
- Derive a separate normalized artifact namespace target path from `TARGET_PATH` for mountinfo matching with a narrow helper, for example:

```bash
normalize_artifact_path_for_mountinfo()
```

  This helper should preserve a single leading `/`, collapse repeated `/` characters, and strip trailing `/` except for `/`. Keep `/` protected before this path can reach recursive deletion.
- Detect real directories with:

```bash
[[ -d "$resolved" && ! -L "$resolved" ]]
```

- If the target is a real directory and `recursive=0`, print `error: directory removal requires --recursive: <resolved-target>` and return `5`.
- If the target is a real directory and `recursive=1`, inspect `/proc/<leader-pid>/mountinfo` for the selected artifact leader before deletion, comparing decoded mountinfo mount-point paths against the normalized artifact namespace target path.
- If the target itself is a mount point, print `error: refusing mount point: <resolved-target>` and return `5`.
- If any nested directory under the target is a mount point, map the matching namespace mount point back to a procfs diagnostic path under `/proc/<leader-pid>/root` and print `error: refusing mount point: <nested-resolved-mount-point>`, then return `5`.
- If the target is a real directory, `recursive=1`, and no target or nested mount point is present, after the dependency check passes, remove the directory with:

```bash
rm -r --one-file-system -- "$resolved"
```

- Use `--one-file-system` as a defensive backstop, not as the primary mount-point refusal mechanism.
- Treat GNU/coreutils-compatible `rm --one-file-system` as a Linux platform assumption for this slice.
- Otherwise, run the existing `rm -- "$resolved"` path for files and symlinks.
- Keep success stdout as `removed: <resolved-target>`.

## Internal Structure

Keep this slice in `lib/commands.sh`.

Add narrow helpers to keep `cmd_remove` readable, for example:

```bash
rm_supports_one_file_system()
normalize_artifact_path_for_mountinfo()
mount_points_under_target()
procfs_path_for_artifact_path()
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

- Do not remove or cross mount points during recursive deletion.
- Do not modify unrelated file-operation commands.
- Do not add new required external dependencies for this behavior.
- Do not claim completion until acceptance tests and verification pass.

## Mount-Point Detection Requirements

- Read `/proc/<leader-pid>/mountinfo`, not `/proc/self/mountinfo`, so mount checks are based on the selected artifact leader.
- Decode the fifth mountinfo field, the mount point path in the artifact mount namespace, including octal escapes such as `\040` for spaces.
- Compare decoded mountinfo mount-point paths against the normalized artifact namespace target path, not against `/proc/<leader-pid>/root/...`.
- Use exact path-boundary matching so `/tmp/a` matches `/tmp/a` and `/tmp/a/mnt`, but not `/tmp/abc`.
- Include helper coverage for trailing slash and repeated slash inputs, such as `/tmp/a/` and `/tmp//a`, so mountinfo comparison uses one normalized artifact path.
- Refuse the first matching mount point at or under the normalized artifact namespace target path before recursive deletion.
- Convert the refused namespace mount point to a procfs diagnostic path with `/proc/<leader-pid>/root/${mount_point#/}`. For the target mount point itself, this should equal `<resolved-target>`.
- Avoid a CLI-visible mountinfo override. Put mountinfo parsing in narrow helpers that accept file input internally, and test those helpers directly or through a non-user-visible test wrapper.
- Do not add an environment variable or configuration file for test fixtures unless the man page is explicitly updated first.
