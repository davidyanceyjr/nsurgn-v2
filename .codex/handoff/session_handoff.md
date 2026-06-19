# Handoff

## State

- Branch: `main`
- Status: planning handoff only; no implementation slice is active.
- Last completed step: reviewed project state and identified recommended upcoming implementation slices for the next session to plan.

## Changed Files

- `.codex/handoff/session_handoff.md`

## Verification

Commands run:

```sh
git status --short
git branch --show-current
git diff --stat
git log --oneline -5
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
```

Results:

- Passing: `shellcheck`, `shfmt -d`, `bats tests`, `./bin/nsurgn --help`, `./bin/nsurgn --version`.
- Failing: none observed.
- Not run: no implementation-specific failing-test checkpoint because this handoff is for next-session planning.
- Notes: `bats tests` passed with one environment-dependent skip: `tree prints visible non-host pid namespace rows`.

## Alignment

- Man page: `doc/nsurgn.1.md` documents a broader v1 contract than the currently implemented command surface.
- Tests: `tests/cli.bats` covers current implemented behavior; several documented commands/options still need acceptance tests before implementation.
- Implementation: `lib/commands.sh` currently dispatches `list`, `all`, `tree`, `report`, `inspect`, `exists`, `cat`, `checksum`, `extract`, `install`/`inject`, `remove`, and `enter`. Commands documented but not yet dispatched include `scout`, `map`, `ps`, `mounts`, `exe`, `signal`, `ls`, and `stat`.

## Blockers

- None for planning.
- Before implementation, create or use a specific non-`main` branch for the selected behavior slice.

## Next Smallest Action

- Plan the next implementation slices, starting from these recommended candidates:
  - `fix/install-refuse-host-source-symlink`: `doc/nsurgn.1.md` says `install` refuses host source symlinks, but `cmd_install` currently only checks source existence before `cp -P`.
  - `fix/remove-directory-recursive-guard`: `doc/nsurgn.1.md` says directory removal requires `--recursive`; current `cmd_remove` only parses `--force`.
  - `feat/extract-overwrite-option`: `doc/nsurgn.1.md` documents `extract --overwrite|--no-overwrite`; current `cmd_extract` refuses existing destinations and parses no options.
  - `feat/exists-success-path`: implementation returns success for existing paths, but tests currently cover only the absent-path exit 1 case.
  - `docs/tighten-ls-stat-output-contract`: `doc/nsurgn.1.md` leaves exact `ls` and `stat` output unresolved; tighten the man page before acceptance tests or implementation.

## Do Not Touch

- Do not implement on `main` unless explicitly instructed.
- Do not start `enter`, `signal`, or full artifact classification as the next immediate slice without first planning their larger dependencies.
- Do not alter unrelated documentation or generated files while planning these slices.
