# Current Plan

## State

- Work type: planning-only for the next implementation slice.
- Current branch: `docs/plan-install-symlink-refusal`.
- Selected slice: `fix/install-refuse-nonregular-host-source`.
- Status: planned, not implemented.
- Last completed branch: `fix/refuse-symlink-file-reads`.
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

## Current Implementation Gap

- `lib/commands.sh` `cmd_install` currently checks `[[ ! -e "$host_src" ]]` before copying.
- `cmd_install` then runs `cp -P "$host_src" "$resolved"`.
- With a source symlink, `cp -P` can preserve the symlink instead of refusing it, which conflicts with the documented regular-file-only contract.
- Directories, FIFOs, devices, and other non-regular host source paths are also outside the documented `HOST_SRC` contract and need acceptance coverage if this slice adds a regular-file check.
- Because `inject` dispatches to `cmd_install`, one implementation fix should cover both command names.

## Acceptance Tests To Add First

- Add Bats tests near the existing install coverage in `tests/cli.bats`.
- For `install` symlink refusal:
  - create a regular source file in `$TEST_TMPDIR`;
  - create a symlink host source pointing to that file;
  - run `run_cli install "pid:$$" "$source_link" "$target_path"`;
  - assert non-zero exit;
  - assert target path was not created;
  - assert stdout is empty;
  - assert stderr includes a stable substring identifying the source path as a symlink, such as `source path is a symlink`.
- For `inject` symlink refusal, add either:
  - a second focused test using the same symlink setup; or
  - a single parameterized/helper-based test pattern if it stays readable in Bats.
- For broader regular-file enforcement:
  - add a test that `install` refuses a directory host source;
  - add a test that `install` refuses one additional non-regular source, preferably a FIFO created with `mkfifo`, with a portability skip if `mkfifo` is unavailable;
  - for each refusal, assert non-zero exit, no target creation, empty stdout, and stderr includes a stable substring identifying the host source as non-regular, such as `source path is not a regular file`.
- Do not assert exact full stderr lines or exact exit codes for these new failures unless `doc/nsurgn.1.md` is updated first to make those details part of the public contract.
- Run the new tests before implementation and confirm they fail because the current implementation does not refuse the covered non-regular sources.

## Implementation Plan

- Update `cmd_install` in `lib/commands.sh`.
- After required-argument validation and before resolving or copying the destination, reject host source symlinks with `[[ -L "$host_src" ]]`.
- Keep missing-source behavior unchanged:
  - a dangling symlink should still be treated as a source symlink refusal if the symlink path itself exists as a symlink;
  - a non-existent ordinary path should keep the existing `source path not found` behavior.
- Require a regular file with `[[ -f "$host_src" ]]` after the symlink check so directories, FIFOs, devices, and other non-regular sources are refused under the documented `HOST_SRC must be a regular file` contract.
- Keep diagnostics consistent with existing CLI error style, for example `error: source path is a symlink: <path>` and `error: source path is not a regular file: <path>`.
- Use existing failure-code conventions from nearby install validation, but have tests assert only non-zero unless the man page is updated to document an exact exit status for these specific failures.
- Do not change target path validation, existing-target refusal, parent-directory behavior, output format, or overwrite-related future behavior in this slice.

## Verification Plan

Run the failing-test checkpoint after adding tests:

```sh
bats tests/cli.bats
```

Expected checkpoint result: the new install/inject non-regular-source test coverage fails against the current implementation.

Run final verification after implementation:

```sh
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
```

Only claim completion if the final verification passes. Preserve any environment-dependent skip notes from `bats tests`.

## Out Of Scope

- Adding install support for symlink sources.
- Implementing `install --parents`, `--mode`, `--owner`, `--group`, `--backup`, `--overwrite`, or `--no-overwrite`.
- Changing `extract` symlink behavior.
- Changing target-path symlink refusal for `cat`, `checksum`, or other file-read commands.
- Refactoring copy helpers unless the test-driven fix needs a small local helper.

## Next Smallest Action

- Create or switch to branch `fix/install-refuse-nonregular-host-source`.
- Add the acceptance test coverage described above.
- Run `bats tests/cli.bats` and confirm the expected failing-test checkpoint before changing implementation.
