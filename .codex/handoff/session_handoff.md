# Handoff

## State

- Branch: `docs/plan-install-symlink-refusal`
- Status: planning handoff only; `fix/install-refuse-host-source-symlink` is now planned in `.codex/plans/current.md` but not implemented.
- Last completed step: created the planning-only current plan for `fix/install-refuse-host-source-symlink`.

## Changed Files

- `.codex/plans/current.md`
- `.codex/handoff/session_handoff.md`

## Verification

Commands run:

```sh
git status --short
git branch --show-current
git diff --stat
git log --oneline -5
git diff --check
```

Results:

- Passing: `git diff --check`.
- Failing: none observed.
- Not run: `shellcheck`, `shfmt -d`, `bats tests`, `./bin/nsurgn --help`, and `./bin/nsurgn --version` were not rerun because this update only changes planning and handoff notes.
- Notes: prior handoff recorded `shellcheck`, `shfmt -d`, `bats tests`, `./bin/nsurgn --help`, and `./bin/nsurgn --version` as passing. That prior `bats tests` run had one environment-dependent skip: `tree prints visible non-host pid namespace rows`.

## Alignment

- Man page: `doc/nsurgn.1.md` documents a broader v1 contract than the currently implemented command surface.
- Tests: `tests/cli.bats` covers current implemented behavior; several documented commands/options still need acceptance tests before implementation.
- Implementation: `lib/commands.sh` currently dispatches `list`, `all`, `tree`, `report`, `inspect`, `exists`, `cat`, `checksum`, `extract`, `install`/`inject`, `remove`, and `enter`. Commands documented but not yet dispatched include `scout`, `map`, `ps`, `mounts`, `exe`, `signal`, `ls`, and `stat`.

## Blockers

- None for planning.
- Before implementation, create or use branch `fix/install-refuse-host-source-symlink` for the selected behavior slice.

## Next Smallest Action

- The next implementation slice is planned in `.codex/plans/current.md`: `fix/install-refuse-host-source-symlink`.
- Other recommended future candidates:
  - `fix/remove-directory-recursive-guard`: `doc/nsurgn.1.md` says directory removal requires `--recursive`; current `cmd_remove` only parses `--force`.
  - `feat/extract-overwrite-option`: `doc/nsurgn.1.md` documents `extract --overwrite|--no-overwrite`; current `cmd_extract` refuses existing destinations and parses no options.
  - `feat/exists-success-path`: implementation returns success for existing paths, but tests currently cover only the absent-path exit 1 case.
  - `docs/tighten-ls-stat-output-contract`: `doc/nsurgn.1.md` leaves exact `ls` and `stat` output unresolved; tighten the man page before acceptance tests or implementation.

## Do Not Touch

- Do not implement on `main` unless explicitly instructed.
- Do not start `enter`, `signal`, or full artifact classification as the next immediate slice without first planning their larger dependencies.
- Do not alter unrelated documentation or generated files while planning these slices.
