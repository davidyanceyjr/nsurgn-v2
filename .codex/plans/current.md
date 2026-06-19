# Current Plan

## State

- Work type: implementation slice.
- Branch: `feat/procfs-all-process-table`.
- Selected finding: `lib/commands.sh` implements `all` as header-only placeholder behavior while `doc/nsurgn.1.md` documents a completed `/proc` scan with namespace metadata.
- Status: implemented and verified for the selected slice.

## Intended Behavior

- `nsurgn all` scans visible numeric `/proc` entries.
- It prints the documented header.
- It prints one row per process that remains readable during the scan.
- It includes host-equivalent processes.
- PIDs that disappear during the scan are skipped.
- Disappeared PID warnings are suppressed when `--quiet` is set.

## Out Of Scope

- Artifact grouping and classification.
- `list`, `scout`, `tree`, `report`, `map`, `ps`, `mounts`, `exe`, `signal`, `ls`, and `stat` implementation.
- Runtime evidence scoring.
- Stable alignment decisions beyond the documented `all` table columns.

## Next Smallest Action

- Review and commit the focused `all` procfs table change.
