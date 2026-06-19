# Handoff

## State

- Branch: `feat/list-include-host-table`
- Status: `list --include-host` implementation for the selected `lib/commands.sh` Finding is complete and committed.
- Last completed step: Committed `feat: list host processes with include-host` (`38cc8ba`).

## Selected Finding

- Finding: `lib/commands.sh` had placeholder-level discovery behavior for `cmd_list`, returning success without emitting the documented `list` table when `--include-host` should include host-classified artifacts.
- Resolution: `cmd_list` now scans visible numeric `/proc` entries when `--include-host` is set and emits host-classified one-process rows with the documented table header.
- Scope boundary: this resolves only the `list --include-host` host row slice. It does not implement non-host artifact grouping, classification, scoring, runtime hints, or other v1 commands.

## Changed Files

- Committed:
  - `.codex/plans/current.md`
  - `lib/commands.sh`
  - `tests/cli.bats`
- Uncommitted:
  - `.codex/handoff/session_handoff.md`

## Verification

Commands run:

```sh
bats --filter 'list with include-host shows the current host process' tests/cli.bats
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
./bin/nsurgn --quiet --include-host list | head -n 5
git diff --check
```

Results:

- Passing: focused `list --include-host` Bats test; `shellcheck`; `shfmt -d .`; full `bats tests` with 22/22 tests passing; `./bin/nsurgn --help`; `./bin/nsurgn --version`; sample `list --include-host` output; `git diff --check`.
- Failing: None observed.
- Not run: Pull request creation.

## Alignment

- Man page: Existing `list` contract in `doc/nsurgn.1.md` already documents host-classified artifacts being included when `--include-host` is set.
- Tests: Added acceptance coverage that `nsurgn --quiet --include-host list` emits a host-classified row for the current test process.
- Implementation: `cmd_list` now scans numeric `/proc` entries for `--include-host` instead of returning placeholder success only.

## Blockers

- None for the selected `list --include-host` slice.
- Broader v1 artifact grouping, non-host classification, runtime scoring, runtime hints, and additional commands remain out of scope.

## Next Smallest Action

- Review commit `38cc8ba` and decide whether to open a focused PR for `feat/list-include-host-table`.

## Do Not Touch

- Do not fold broader discovery/classification work into this branch unless explicitly requested.
- Do not treat non-host artifacts, runtime scoring, or runtime hint detection as implemented by this slice.
