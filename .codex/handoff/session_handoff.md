# Handoff

## State

- Branch: `main`
- Status: implementation complete, verified, and merged to `main`.
- Last completed step: merged `fix/install-refuse-nonregular-host-source`.

## Changed Files

- `.codex/plans/current.md`
- `.codex/handoff/session_handoff.md`
- `lib/commands.sh`
- `tests/cli.bats`

## Verification

Commands run:

```sh
bats tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
git diff --check
```

Results:

- Passing: all final verification commands listed above.
- Failing checkpoint: `bats tests/cli.bats` failed before implementation on the new non-regular source refusal tests, as expected.
- Failing final checks: none observed.
- Skip notes: `bats tests` reported one existing environment-dependent skip: `tree prints visible non-host pid namespace rows`.

## Alignment

- Man page: `doc/nsurgn.1.md` already documents `HOST_SRC must be a regular file. Host source symlinks are refused.`
- Tests: `tests/cli.bats` covers `install` and `inject` symlink source refusal, plus directory and character-device host source refusal for `install`.
- Implementation: `cmd_install` refuses symlink and non-regular host sources before resolving or copying the target.

## Blockers

- None.

## Next Smallest Action

- Select the next documented behavior slice before implementation.

## Future Slice Candidates

- `fix/remove-directory-recursive-guard`
  - Status: not implemented.
  - Contract source: `doc/nsurgn.1.md` documents `nsurgn remove ARTIFACT_OR_PID TARGET_PATH --force [--recursive]` and says directory removal requires `--recursive`.
  - Current gap: `cmd_remove` parses `--force` but not `--recursive`.
  - First action: add Bats coverage that `remove --force` refuses a directory without `--recursive` and leaves it in place.

- `feat/extract-overwrite-option`
  - Status: not implemented.
  - Contract source: `doc/nsurgn.1.md` documents `extract --overwrite|--no-overwrite`.
  - Current gap: `cmd_extract` refuses existing host destinations and parses no extract options.
  - First action: add Bats coverage for existing `HOST_DEST` refusal by default, then `--overwrite` replacing the destination only when documented safeguards pass.

- `feat/exists-success-path`
  - Status: not implemented as a tested slice.
  - Contract source: `doc/nsurgn.1.md` documents `exists` exit 0 when the path exists and exit 1 when it does not.
  - Current gap: tests cover only the absent-path exit 1 case.
  - First action: add Bats coverage for an existing target path returning exit 0 with empty stdout.

- `docs/tighten-ls-stat-output-contract`
  - Status: documentation/specification work only.
  - Contract source: `doc/nsurgn.1.md` says the v1 specification must decide exact stdout formats for `ls` and `stat` before acceptance tests are written.
  - Current gap: output contracts are not tight enough for acceptance tests or implementation.
  - First action: update the man page with exact `ls` and `stat` stdout fields and exit behavior before adding tests.

## Do Not Touch

- Do not implement install overwrite, parents, ownership, group, mode, or backup options in this merge.
- Do not change `extract` symlink behavior or file-read command behavior in this merge.
