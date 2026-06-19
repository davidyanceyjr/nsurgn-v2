# Current Plan

## State

- Work type: implementation slice.
- Branch: `feat/tree-nonhost-pid-namespace-rows`.
- Selected finding: `doc/nsurgn.1.md` documents non-host PID namespace rows for `nsurgn tree`, but `cmd_tree` currently prints only the host root line.
- Status: implemented and verified; child-row acceptance test is present but skipped on this host because no readable non-host PID namespace pair is visible.

## Previously Implemented Behavior

- `nsurgn --host-pid PID tree` reads the PID namespace ID from `/proc/<PID>/ns/pid`.
- It prints the documented host root line:

```text
host pid_ns <namespace-id>
```

- It exits 0 when the namespace ID is readable.
- It returns exit 4 when the selected host PID does not exist.
- It returns exit 9 when the selected host PID exists but the PID namespace cannot be read.

## Current Target Behavior

- `nsurgn tree` keeps the documented host root line.
- Each visible non-host PID namespace is printed below the host line as:

```text
A<N> pid_ns <namespace-id> leader <host-pid> ns_pid <namespace-pid> <command>
```

## Out Of Scope

- Representative leader selection for nested PID namespaces.
- Artifact grouping changes.
- `tree` output beyond the documented PID namespace row format.

## Next Smallest Action

- Review and commit the focused `tree` non-host PID namespace row change.
