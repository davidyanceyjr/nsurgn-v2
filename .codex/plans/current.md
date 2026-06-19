# Current Plan

## State

- Work type: implementation slice.
- Branch: `feat/list-include-host-table`.
- Selected finding: `lib/commands.sh` implements `list` as placeholder success behavior while `doc/nsurgn.1.md` documents discovery table output, including host-classified artifacts when `--include-host` is set.
- Status: implemented and verified for the selected slice.

## Intended Behavior

- `nsurgn list` without `--include-host` keeps host-classified processes hidden.
- `nsurgn --include-host list` scans visible numeric `/proc` entries.
- It prints the documented `list` table header.
- It prints one host-classified row per readable visible process.
- Each row includes an ephemeral artifact ID, classification `host`, score `0`, leader host PID, namespace PID, process count `1`, runtime hint `none`, and command text.
- PIDs that disappear during the scan are skipped.

## Out Of Scope

- Non-host artifact grouping and classification.
- Runtime evidence scoring.
- Runtime hint detection for host rows.
- `scout`, `tree`, `report`, `map`, `ps`, `mounts`, `exe`, `signal`, `ls`, and `stat` implementation.
- Stable artifact ID reuse across command invocations.

## Next Smallest Action

- Review and commit the focused `list --include-host` table change.
