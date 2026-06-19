# Current Plan

## State

- Work type: implementation completed for the selected slice.
- Current branch: `fix/install-refuse-nonregular-host-source`.
- Selected slice: `fix/install-refuse-nonregular-host-source`.
- Status: implemented, verified, and ready to merge.
- Last completed branch: `fix/install-refuse-nonregular-host-source`.
- Last checked: 2026-06-19.

## Slice Goal

Make `nsurgn install` and its `inject` alias refuse any host source path that is not a regular file, matching the documented `HOST_SRC` contract. This includes symlinks and other non-regular filesystem objects.

## Man Page Alignment

- `doc/nsurgn.1.md` documents:
  - `nsurgn install ARTIFACT_OR_PID HOST_SRC TARGET_PATH [...]`.
  - `inject` is an alias for `install`.
  - `HOST_SRC must be a regular file. Host source symlinks are refused.`
- No man page change is expected for this slice unless the acceptance test exposes an ambiguity in the diagnostic or exit status.
- The planned behavior must not add symlink install support. The man page says any future symlink install support requires a new documented option before implementation.

## Implemented Behavior

- `lib/commands.sh` `cmd_install` refuses host source symlinks before the missing-source check.
- `cmd_install` refuses host source paths that are not regular files before resolving or copying the target.
- Because `inject` dispatches to `cmd_install`, the same validation covers both command names.

## Acceptance Tests Added

- `tests/cli.bats` covers `install` refusing a symlink host source.
- `tests/cli.bats` covers `inject` refusing a symlink host source.
- `tests/cli.bats` covers `install` refusing a directory host source.
- `tests/cli.bats` covers `install` refusing `/dev/null` as a character-device host source when available.
- The failing-test checkpoint was run before implementation and failed for the expected non-regular source behavior.

## Implementation Notes

- `[[ -L "$host_src" ]]` runs before the existing missing-source check:
  - a dangling symlink should still be treated as a source symlink refusal if the symlink path itself exists as a symlink;
  - a non-existent ordinary path should keep the existing `source path not found` behavior.
- `[[ -f "$host_src" ]]` runs after the symlink check so directories, devices, and other non-regular sources are refused under the documented `HOST_SRC must be a regular file` contract.
- Diagnostics follow existing CLI error style: `error: source path is a symlink: <path>` and `error: source path is not a regular file: <path>`.
- Tests assert non-zero status and stable diagnostic substrings, not exact exit statuses.
- Target path validation, existing-target refusal, parent-directory behavior, output format, and overwrite-related future behavior were left unchanged.

## Verification Plan

Failing-test checkpoint after adding tests:

```sh
bats tests/cli.bats
```

Result: failed as expected on the new non-regular source tests before implementation.

Final verification after implementation:

```sh
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
```

Result: all passed. `bats tests` reported 33 tests with one existing environment-dependent skip: `tree prints visible non-host pid namespace rows`.

## Out Of Scope

- Adding install support for symlink sources.
- Implementing `install --parents`, `--mode`, `--owner`, `--group`, `--backup`, `--overwrite`, or `--no-overwrite`.
- Changing `extract` symlink behavior.
- Changing target-path symlink refusal for `cat`, `checksum`, or other file-read commands.
- Refactoring copy helpers unless the test-driven fix needs a small local helper.

## Next Smallest Action

- Merge `fix/install-refuse-nonregular-host-source` to `main`.
- Delete the local implementation branch after merge.
