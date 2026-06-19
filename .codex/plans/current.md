# Current Plan

## State

- Work type: mixed coordination for the next implementation slice.
- Current branch: `docs/handoff-future-slices`.
- Status: no active implementation slice selected.
- Last handoff: `.codex/handoff/session_handoff.md`.
- Last completed branch: `fix/install-refuse-nonregular-host-source`.
- Last checked: 2026-06-19.

## Coordination Policy

- `.codex/plans/current.md` is the place for the current plan once a slice is selected.
- `.codex/handoff/session_handoff.md` is the last handoff from the previous session and currently records the available future slice candidates.
- Do not create or maintain handoff/current-plan copies under a `docs/` directory.

## Candidate Source

The previous-session handoff lists four future implementation/specification slices:

- `fix/remove-directory-recursive-guard`
- `feat/extract-overwrite-option`
- `feat/exists-success-path`
- `docs/tighten-ls-stat-output-contract`

These are candidates only. None is selected as the active current plan yet.

## Next Smallest Action

- Select exactly one candidate slice from `.codex/handoff/session_handoff.md`.
- Replace this coordination plan with a slice-specific plan before adding tests or implementation.
- Follow the repository loop: man page -> acceptance tests -> implementation -> verification -> review -> commit.
