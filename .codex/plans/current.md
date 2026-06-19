# Current Plan: Resolve v1 Contract Review Gaps

## Purpose

Resolve the specification documentation gaps found during review so `doc/nsurgn.1.md` becomes the contract implementation engineers follow.

This plan is documentation-only. It does not implement code, create tests, or claim feature completion. Its output is an updated man page contract. Acceptance tests and implementation must come after the man page states the behavior.

Primary source of truth:

- `doc/nsurgn.1.md`

## Scope

This review pass resolves two incomplete contract areas:

- classification and scoring semantics;
- file operation semantics.

Do not edit `bin/`, `lib/`, or `tests/` while executing this plan.

## Contract Rules

- The man page is the authoritative contract.
- Acceptance tests must be derived from the completed man page contract.
- Acceptance tests must not decide unspecified command behavior, output formats, diagnostics, or exit statuses.
- Any remaining ambiguity must be stated in `UNRESOLVED BEHAVIOR` as a concrete specification decision question, not as work deferred to tests.
- Do not describe behavior as implemented unless it is already implemented and verified.

## Review Finding 1: Classification And Scoring

Finding:

- Classification and scoring are partly specified, but the man page does not yet fully define additive signal rules, hint matching case sensitivity, `--no-runtime-hints`, `--no-mount-scan`, and weak-classification semantics for signal safeguards.

Resolution to write into `doc/nsurgn.1.md`:

- Evidence signals are counted once per artifact unless the signal explicitly says it is counted per process.
- Namespace-difference signals are counted once per artifact.
- `Process is PID 1 inside nested PID namespace` is counted once per matching process, but the leader-selection rule still selects one leader.
- Cgroup, runtime, executable, and mountinfo hint matching is ASCII case-sensitive.
- A cgroup or runtime hint contributes points once per artifact per hint token, even if multiple processes contain the same token.
- Mountinfo hints contribute points once per artifact per hint token, even if multiple mountinfo lines contain the same token.
- Runtime hints are ordered as `k8s`, `containerd`, `docker`, `crio`, `libpod`, `lxc`, `systemd`.
- `--no-runtime-hints` disables cgroup path hint scoring, runtime hint labels, container ID hint scoring, and runtime-derived `container-ish` classification. Namespace, rootfs, executable, and mountinfo evidence still apply.
- With `--no-runtime-hints`, runtime hint output is `none`.
- `--no-mount-scan` prevents discovery from reading `/proc/<pid>/mountinfo` and disables mountinfo-derived scoring and classification evidence during discovery.
- `--no-mount-scan` does not prevent commands that explicitly inspect mounts, such as `mounts` or `report --with-mounts`, from reading the selected leader mountinfo.
- A weakly classified artifact for `signal` safeguards is any artifact classified as `suspicious` or `isolated` with score below 6.
- High-impact signals to weakly classified artifacts require `--force`.

Required man-page outcome:

- A test author can compute classification, score, runtime hint output, and weak-classification signal refusal from fixed procfs-like input without guessing.

## Review Finding 2: File Operation Semantics

Finding:

- File operation semantics remain partly unresolved, especially metadata preservation, overwrite mechanics, symlink behavior, and behavior when files change during operation.

Resolution to write into `doc/nsurgn.1.md`:

- `install`, `inject`, `extract`, and `exe --extract` copy regular file contents only unless a command explicitly documents symlink behavior.
- Default copy behavior does not preserve owner, group, mode, timestamps, xattrs, ACLs, or other metadata beyond what normal file creation applies.
- `install --mode MODE` sets the destination mode after copying.
- `install --owner UID` sets the destination owner after copying.
- `install --group GID` sets the destination group after copying.
- `extract --preserve` preserves mode and timestamps when the platform copy command supports them. It does not preserve owner, group, xattrs, or ACLs.
- `--backup` is valid only with `--overwrite`.
- A backup path is `<destination>.nsurgn.bak`.
- If the backup path already exists, the operation fails before copying.
- Overwrite behavior removes the destination path first, then creates the replacement at the same path. It does not truncate in place.
- Existing destinations are refused unless `--overwrite` is set.
- Parent directories are never created unless `install --parents` is set.
- `install --parents` creates missing parent directories with mode `0755`, subject to process umask.
- `install` refuses host source symlinks by default. If symlink support is later desired, it must be specified as a new documented option before implementation.
- `extract --no-dereference` copies a source symlink as a symlink. The copied symlink target text is unchanged.
- `extract --dereference` copies the referent bytes and refuses dangling symlinks.
- `remove` removes a symlink itself, not its referent.
- `cat`, `checksum`, and `stat` do not follow symlinks unless their command section explicitly says they do. The v1 contract should state the selected behavior for each.
- Directory copies are not supported by `install`, `inject`, `extract`, or `exe --extract`.
- Directory removal requires `remove --recursive`.
- Mount points are refused for `remove`, including recursive removal.
- If a source file changes during copy, `nsurgn` fails with exit 8 when it detects the change. If the change is not detectable, the operation is subject to the live-filesystem limitation.
- If the leader process disappears, the target root becomes inaccessible, or the resolved source or destination changes type during an operation, `nsurgn` exits 8.

Required man-page outcome:

- File operation sections are explicit enough for acceptance tests using temporary files, directories, symlinks, existing destination paths, backup paths, and simulated disappearing targets.

## Review Procedure

1. Update `doc/nsurgn.1.md` with the classification and scoring decisions above.
2. Update `doc/nsurgn.1.md` with the file operation decisions above.
3. Remove or narrow `UNRESOLVED BEHAVIOR` items that these decisions satisfy.
4. Confirm no wording says acceptance tests decide unspecified behavior.
5. Confirm `COMMANDS`, `OPTIONS`, `ARGUMENTS`, `STDERR`, `EXIT STATUS`, `FILES`, and `LIMITATIONS` agree with the updated contract.

## Documentation Verification

Run:

```sh
git diff --check
git status --short
```

Manual review checklist:

- Classification score calculation is deterministic.
- Hint matching and option effects are deterministic.
- Weak-classification signal safeguards are deterministic.
- File copy metadata behavior is deterministic.
- Overwrite and backup behavior is deterministic.
- Symlink behavior is deterministic per command.
- File-change and disappearing-process behavior maps to exit 8.
- `UNRESOLVED BEHAVIOR` contains no item that blocks acceptance-test authoring for these review findings.

## Next Smallest Action

Apply this plan to `doc/nsurgn.1.md` in one documentation-only change, then review the man page diff against the checklist above.
