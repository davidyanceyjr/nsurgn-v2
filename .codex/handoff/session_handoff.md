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

## Do Not Touch

- Do not implement install overwrite, parents, ownership, group, mode, or backup options in this merge.
- Do not change `extract` symlink behavior or file-read command behavior in this merge.
