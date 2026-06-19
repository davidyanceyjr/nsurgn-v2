# Current Plan

## State

- Work type: implementation work.
- Last completed branch: `fix/refuse-symlink-file-reads`.
- Selected slice: make `nsurgn cat` and `nsurgn checksum` refuse symlink target paths.
- Status: implemented and verified.
- Implementation commit: `256da3c fix: refuse symlink file reads`.
- Last checked: 2026-06-19.

## Why This Slice

- The behavior is already documented in `doc/nsurgn.1.md`.
- The existing implementation partially enforces the documented contract: `cat` refuses directories, but neither `cat` nor `checksum` currently refuses symlinks.
- The slice is small enough to complete with shell acceptance tests using `pid:$$` and temporary files.
- It does not require nested PID namespaces, privileged runtime APIs, or broad discovery changes.

## Man Page Alignment

- `doc/nsurgn.1.md` documents `nsurgn cat ARTIFACT_OR_PID TARGET_PATH [--max-bytes BYTES]`.
- The `cat` section says directories and symlinks are refused.
- `doc/nsurgn.1.md` documents `nsurgn checksum ARTIFACT_OR_PID TARGET_PATH [--sha256|--sha512|--md5]`.
- The `checksum` section says directories and symlinks are refused.
- No man page contract change is expected before implementation unless acceptance-test wording exposes an ambiguity.

## Test Alignment

- Existing tests cover:
  - `cat` success with `--max-bytes`.
  - `checksum` success with default SHA-256 output.
  - target path safety for relative paths.
- Added acceptance tests:
  - `cat` refuses a symlink target path, writes no stdout, writes an error diagnostic to stderr, and exits non-zero.
  - `checksum` refuses a symlink target path, writes no stdout, writes an error diagnostic to stderr, and exits non-zero.
- The new tests were first run against the pre-fix implementation and failed because both commands exited 0.

## Implementation Alignment

- `cmd_cat` resolves the target path and refuses missing paths and directories, then reads the path.
- `cmd_checksum` resolves the target path and refuses missing paths, then hashes the path.
- `cmd_cat` and `cmd_checksum` now refuse symlink target paths after resolution and before reading or hashing.
- The implementation did not change checksum output, `cat --max-bytes`, missing-path behavior, directory behavior, or target path validation.

## Verification

- Failing-test checkpoint was run before implementation:

```sh
bats tests/cli.bats
```

- Result: failed only the new `cat` and `checksum` symlink refusal tests because both commands exited 0.

- Final verification passed:

```sh
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
```

- `bats tests` passed with one environment-dependent skip: `tree prints visible non-host pid namespace rows`.

## Out Of Scope

- Implementing `ls` or `stat`.
- Changing extract/install symlink behavior.
- Changing artifact discovery, namespace grouping, or file copy semantics.
- Broad normalization of file-operation error messages beyond the new symlink refusal diagnostic.

## Next Smallest Action

- No active implementation slice is selected.
