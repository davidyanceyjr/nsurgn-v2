# Plan Review Findings

Last reviewed: 2026-06-20
Reviewed plan: `.codex/plans/current.md`
Review status: open findings

## Open Findings

1. `.codex/plans/current.md` proposes a test-only mountinfo file override, but `doc/nsurgn.1.md` says `nsurgn` reads no environment variables for configuration. If that override is exposed through environment or configuration, it creates hidden undocumented behavior. Prefer testing a helper without adding CLI-visible override behavior, or explicitly update the man page if the override is a supported interface.

2. `.codex/plans/current.md` makes `rm --one-file-system` part of the behavior, but the man page does not document that GNU/coreutils-compatible `rm` is required or what happens when unsupported. Tie the unsupported-platform behavior to the documented exit status and dependency contract before tests assert it.

3. `.codex/plans/current.md` expands the slice into target mount-point refusal, nested mount-point scanning, mountinfo escape decoding, path-boundary matching, and recursive deletion behavior. This is defensible because `doc/nsurgn.1.md` says mount points are refused, but it is broader than the `fix/remove-directory-recursive-guard` slice name implies. Consider renaming the slice or splitting it into one `--recursive` directory guard slice and a follow-up mount-point refusal slice.

## Review Procedure

For plan review requests, check this file first.

- If this file has open findings and they still apply, report these findings instead of performing a fresh review.
- If this file is cleared, missing, or stale relative to `.codex/plans/current.md`, perform a fresh review and update this file with the result.
- Clear findings only after the plan or contract has been updated enough that the finding no longer applies.
