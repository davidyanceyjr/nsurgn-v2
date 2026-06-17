# Handoff

## State

- Branch: `test/nsurgn-acceptance-contract`
- Status: paused by user; contract-gap plan approved, not implemented
- Last completed step: review found contract gaps and user approved the resolution plan

## Changed Files

- `bin/nsurgn`
- `lib/commands.sh`
- `lib/output.sh`
- `tests/cli.bats`
- `doc/nsurgn.1.md`
- Existing untracked context: `AGENTS.md`, `.codex/skills/*`, `nsurgn_specification_v1.0.md`

## Verification

Commands run before pause:

```sh
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
bats tests
./bin/nsurgn --help
./bin/nsurgn --version
git diff --check
git status --short
```

Results:

- Passing: all listed checks passed before pause
- Failing: none currently known
- Not run: no implementation checks after plan approval, because no new implementation changes were made

## Alignment

- Man page: authoritative contract exists at `doc/nsurgn.1.md`
- Tests: current tests pass but do not cover all reviewed contract gaps
- Implementation: partial; minimal tested slice works, but review found documented behavior not yet implemented

## Blockers

- Work intentionally paused until next session.
- Files are untracked, so `git diff --stat` is empty. Use `git status --short` and inspect files directly.

## Next Smallest Action

Add failing Bats coverage for protected remove path refusal:

```sh
./bin/nsurgn remove pid:$$ /etc --force
```

Expected contract: exit `5`, stderr includes `error: refusing protected path: /etc`, no removal attempted.

Then implement only that behavior and rerun the full verification gate.

## Do Not Touch

- Do not implement broader artifact discovery yet.
- Do not create extra docs.
- Do not commit `.codex/skills/*` unless explicitly intended.
- Do not rewrite the man page unless a test exposes unclear or contradictory behavior.
