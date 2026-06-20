# NSURGN(1)

## NAME

nsurgn - inspect and operate on Linux namespace artifacts through procfs

## SYNOPSIS

`nsurgn` [`--group` `profile`|`strict`|`pid`|`mnt`|`net`|`cgroup`] [`--format` `table`|`text`] [`--verbose`] [`--quiet`] [`--no-color`] [`--host-pid` PID] [`--include-host`] [`--no-runtime-hints`] [`--no-mount-scan`] COMMAND [ARGUMENTS]

`nsurgn --help`

`nsurgn --version`

## DESCRIPTION

`nsurgn` discovers Linux processes that appear to form namespace artifacts. An artifact is an inferred group of visible host processes related by namespace IDs, cgroup paths, root filesystem views, mount metadata, and process relationships. An artifact is not a kernel object and is not proof that the process group is a container.

`nsurgn` reads Linux procfs metadata and standard host utilities. It does not require Docker, Podman, Kubernetes, containerd, CRI-O, `crictl`, `ctr`, `nerdctl`, runtime sockets, `jq`, Python, Go, or runtime APIs.

Commands that inspect, copy, remove, or signal artifacts use the artifact leader as the default target. The leader is selected in this order:

1. A process that is PID 1 inside a non-host PID namespace.
2. The oldest process in the artifact.
3. The lowest host PID in the artifact.

File operations resolve artifact paths through the leader root:

`/proc/<leader-pid>/root/<target-path-without-leading-slash>`

Only `enter` runs a command through `nsenter`. No other command executes a program inside the artifact.

## ARTIFACT GROUPING

`--group profile` is the default. It groups processes by this namespace tuple:

`pid_ns + mnt_ns + net_ns`

`--group strict` groups processes by the full namespace tuple:

`pid_ns + mnt_ns + net_ns + user_ns + uts_ns + ipc_ns + cgroup_ns + time_ns`

`--group pid`, `--group mnt`, and `--group net` group by only that namespace type.

`--group cgroup` groups by the first cgroup path component that contains a runtime hint. Processes without a runtime hint are grouped by their full cgroup path.

The host namespace profile is read from `/proc/1` unless `--host-pid` is set.

## CLASSIFICATION

Each artifact receives one classification: `host`, `isolated`, `namespace-init`, `container-ish`, or `suspicious`.

When more than one classification could apply, implementations must use this precedence:

1. `host`
2. `container-ish`
3. `namespace-init`
4. `suspicious`
5. `isolated`

`host`
: The selected grouping namespace values match the host profile.

`isolated`
: The artifact differs from the host profile in at least one major namespace type: PID, mount, network, or user.

`namespace-init`
: The artifact has a process that is PID 1 inside a non-host PID namespace.

`container-ish`
: The artifact has namespace isolation and at least one runtime, cgroup, container ID, overlay, snapshotter, or Kubernetes-style hint.

`suspicious`
: The artifact has namespace isolation but no runtime hint, or has isolation with an unusual process, executable, rootfs, or cgroup layout.

Scores are integer evidence totals. Implementations must use these additive signals:

| Signal | Points |
| --- | ---: |
| PID namespace differs from host | 3 |
| Mount namespace differs from host | 3 |
| Network namespace differs from host | 2 |
| User namespace differs from host | 2 |
| UTS namespace differs from host | 1 |
| IPC namespace differs from host | 1 |
| Cgroup namespace differs from host | 1 |
| Time namespace differs from host | 1 |
| Process is PID 1 inside nested PID namespace | 4 |
| Cgroup path contains `kubepods` | 4 |
| Cgroup path contains `containerd` | 4 |
| Cgroup path contains `docker` | 4 |
| Cgroup path contains `crio` | 4 |
| Cgroup path contains `libpod` | 4 |
| Cgroup path contains `lxc` | 3 |
| Cgroup path contains `machine.slice` | 2 |
| Cgroup path contains a 12-or-more character lowercase hex token | 2 |
| Root filesystem differs from host root | 2 |
| Mountinfo contains `overlay` or `snapshotter` | 3 |
| Mountinfo contains `serviceaccount` or `projected` | 2 |
| Executable symlink target ends with ` (deleted)` | 2 |

Evidence signals are counted once per artifact unless the signal explicitly says it is counted per process. Namespace-difference signals are counted once per artifact. The `Process is PID 1 inside nested PID namespace` signal is counted once per matching process, but leader selection still selects one leader.

Cgroup path, runtime hint, executable path, and mountinfo hint matching is ASCII case-sensitive. A cgroup or runtime hint contributes points once per artifact per hint token, even when multiple processes contain the same token. Mountinfo hints contribute points once per artifact per hint token, even when multiple mountinfo lines contain the same token.

Runtime hints are reported as `k8s`, `containerd`, `docker`, `crio`, `libpod`, `lxc`, `systemd`, or `none`. Multiple hints are joined with `/` in first-match order from that list.

`--no-runtime-hints` disables cgroup path hint scoring, runtime hint labels, container ID hint scoring, and runtime-derived `container-ish` classification. Namespace, rootfs, executable, and mountinfo evidence still apply. With `--no-runtime-hints`, runtime hint output is `none`.

`--no-mount-scan` prevents discovery from reading `/proc/<pid>/mountinfo` and disables mountinfo-derived scoring and classification evidence during discovery. It does not prevent commands that explicitly inspect mounts, such as `mounts` or `report --with-mounts`, from reading the selected leader mountinfo.

A weakly classified artifact for `signal` safeguards is any artifact classified as `suspicious` or `isolated` with a score below 6. High-impact signals to weakly classified artifacts require `--force`.

## FILE OPERATION SEMANTICS

`install`, `inject`, `extract`, and `exe --extract` copy regular file contents only unless a command explicitly documents symlink behavior. Directory copies are not supported by these commands.

Default copy behavior does not preserve owner, group, mode, timestamps, extended attributes, ACLs, or other metadata beyond what normal file creation applies. `install --mode MODE` sets the destination mode after copying. `install --owner UID` sets the destination owner after copying. `install --group GID` sets the destination group after copying. `extract --preserve` preserves mode and timestamps when the platform copy command supports them. It does not preserve owner, group, extended attributes, or ACLs.

Existing destinations are refused unless `--overwrite` is set. Overwrite behavior removes the destination path first, then creates the replacement at the same path. It does not truncate in place. `--backup` is valid only with `--overwrite`. A backup path is `<destination>.nsurgn.bak`. If the backup path already exists, the operation fails before copying.

Parent directories are never created unless `install --parents` is set. `install --parents` creates missing parent directories with mode `0755`, subject to process umask.

If a source file changes during copy, `nsurgn` fails with exit 8 when it detects the change. If the change is not detectable, the operation is subject to the live-filesystem limitation. If the leader process disappears, the target root becomes inaccessible, or the resolved source or destination changes type during an operation, `nsurgn` exits 8.

## COMMANDS

### `list`

`nsurgn list`

Lists artifacts classified as `isolated`, `namespace-init`, `container-ish`, or `suspicious`. Host-equivalent artifacts are hidden unless `--include-host` is set.

Default stdout format is a table with this header:

`ARTIFACT  CLASSIFICATION  SCORE  LEADER  NSPID  PROCS  RUNTIME_HINT  COMMAND`

The command exits 0 after a completed scan, including when no artifacts are found. When no artifacts are found, stdout is empty in `--format table` mode unless `--include-host` produces rows.

### `scout`

`nsurgn scout`

Lists probable artifact leaders and the evidence used to select them.

Default stdout format is a table with this header:

`ARTIFACT  LEADER  NSPID  CLASSIFICATION  SCORE  WHY  COMMAND`

The `WHY` column is a comma-separated list of evidence tokens such as `pidns-init`, `cgroup:k8s`, `runtime:containerd`, `overlay`, or `no-runtime-hint`.

### `all`

`nsurgn all`

Lists every visible numeric PID from `/proc` with namespace metadata. This command includes host-equivalent processes.

Default stdout format is a table with this header:

`HOSTPID  PPID  NSPID  PID_NS  MNT_NS  NET_NS  USER_NS  UTS_NS  IPC_NS  CGROUP_NS  TIME_NS  CGROUP_HINT  COMMAND`

PIDs that disappear during the scan are skipped and produce a warning on stderr unless `--quiet` is set.

### `tree`

`nsurgn tree`

Prints a text tree of PID namespace groups and representative leaders. Stdout starts with one host PID namespace line:

`host pid_ns <namespace-id>`

Each discovered non-host PID namespace is printed below it as:

`A<N> pid_ns <namespace-id> leader <host-pid> ns_pid <namespace-pid> <command>`

### `report`

`nsurgn report` [`--artifact` ARTIFACT_OR_PID] [`--all`] [`--with-mounts`]

Prints a text report for discovered artifacts. By default, host-equivalent artifacts are omitted. `--all` includes all artifact classifications. `--artifact` limits output to one artifact or host PID.

Each artifact report includes:

- artifact ID
- classification
- score
- leader host PID
- leader namespace PID, or `-` when unavailable
- runtime hint, or `none`
- container ID hint, or `none`
- process count
- target root
- namespace IDs
- cgroup paths
- process table
- mount summary when `--with-mounts` is set

### `inspect`

`nsurgn inspect` ARTIFACT_OR_PID

Prints metadata for one artifact or host PID. Stdout includes the artifact ID, classification, score, leader selection reason, namespace profile, cgroup paths, target root, executable path, command line, process count, warnings, and runtime or container hints.

The command exits 6 when an artifact ID cannot be resolved in the current scan. It exits 4 when a host PID target does not exist.

### `map`

`nsurgn map` ARTIFACT_OR_PID

Prints shared namespace relationships and related processes for one artifact or PID. Stdout includes an artifact line, leader line, shared namespace summary, and a related process table with this header:

`HOSTPID  NSPID  PID_NS  MNT_NS  NET_NS  COMMAND`

### `ps`

`nsurgn ps` ARTIFACT_OR_PID

Lists processes belonging to the artifact.

Default stdout format is a table with this header:

`HOSTPID  NSPID  PPID  USER  STARTED  STAT  COMMAND`

### `mounts`

`nsurgn mounts` ARTIFACT_OR_PID [`--summary`|`--raw`]

Prints mount metadata from `/proc/<leader-pid>/mountinfo`.

`--summary` is the default and writes this table header to stdout:

`MOUNTPOINT  FSTYPE  SOURCE  FLAGS`

`--raw` writes the raw mountinfo file contents exactly as read, except that read errors are reported on stderr.

### `exe`

`nsurgn exe` ARTIFACT_OR_PID [`--extract` HOST_DEST] [`--overwrite`]

Without `--extract`, prints the leader executable symlink target:

`exe: /proc/<leader-pid>/exe -> <path>`

When the executable path is deleted, stdout appends ` (deleted)` and stderr includes:

`warning: executable path has been deleted`

With `--extract`, copies the regular-file bytes exposed by `/proc/<leader-pid>/exe` to HOST_DEST. Existing HOST_DEST paths are refused unless `--overwrite` is set.

### `install`

`nsurgn install` ARTIFACT_OR_PID HOST_SRC TARGET_PATH [`--parents`] [`--mode` MODE] [`--owner` UID] [`--group` GID] [`--backup`] [`--overwrite`|`--no-overwrite`]

Copies HOST_SRC from the host into the artifact target root at TARGET_PATH. HOST_SRC is not removed.

TARGET_PATH must be absolute. Relative paths, empty paths, `.` and `..` components, and traversal attempts are refused before copying.

The parent directory must already exist unless `--parents` is set. Existing targets are refused unless `--overwrite` is set. `--backup` is valid only with `--overwrite` and writes a sibling backup before overwrite using the suffix `.nsurgn.bak`.

HOST_SRC must be a regular file. Host source symlinks are refused. If symlink install support is added later, it must be specified as a new documented option before implementation.

On success, stdout is:

`copied: <host-src> -> <resolved-target>`

### `inject`

`nsurgn inject` ARTIFACT_OR_PID HOST_SRC TARGET_PATH [OPTIONS]

Alias for `install`. It copies host files into the artifact root filesystem. It does not perform memory injection, process injection, ptrace injection, shellcode injection, or process tampering.

### `extract`

`nsurgn extract` ARTIFACT_OR_PID TARGET_PATH HOST_DEST [`--overwrite`|`--no-overwrite`] [`--preserve`] [`--dereference`|`--no-dereference`]

Copies TARGET_PATH from the artifact target root to HOST_DEST on the host. The artifact source is not removed.

TARGET_PATH must be absolute. HOST_DEST is refused when it exists unless `--overwrite` is set. The default symlink behavior is `--no-dereference`, which copies a source symlink as a symlink. The copied symlink target text is unchanged. `--dereference` copies the referent bytes and refuses dangling symlinks.

On success, stdout is:

`copied: <resolved-source> -> <host-dest>`

### `remove`

`nsurgn remove` ARTIFACT_OR_PID TARGET_PATH `--force` [`--recursive`]

Removes TARGET_PATH from the artifact target root. This command is destructive and always requires `--force`.

TARGET_PATH must be absolute. Relative paths, empty paths, `.` and `..` components, and traversal attempts are refused. The command removes a symlink itself, not the symlink target.

Directory removal requires `--recursive`.

Recursive directory removal refuses any mount point at or under TARGET_PATH before deletion. Recursive directory removal requires GNU/coreutils-compatible `rm` support for `--one-file-system`.

Directory removal without `--recursive`, target mount-point refusal, and nested mount-point refusal exit 5. Unsupported recursive removal because GNU/coreutils-compatible `rm --one-file-system` is unavailable exits 9.

The following target paths are always refused:

`/`, `/etc`, `/usr`, `/bin`, `/sbin`, `/lib`, `/lib64`, `/proc`, `/sys`, `/dev`, `/run`

On success, stdout is:

`removed: <resolved-target>`

### `signal`

`nsurgn signal` ARTIFACT_OR_PID SIGNAL [`--all`] [`--force`]

Sends SIGNAL to the artifact leader by default. With `--all`, sends SIGNAL to every process in the artifact.

Accepted SIGNAL forms include names with or without `SIG` and numeric signal numbers, for example `HUP`, `SIGHUP`, `1`, `TERM`, `SIGTERM`, and `15`.

The command refuses unknown signals, host PID 1, host-classified artifacts unless `--include-host --force` is set, and weakly classified artifacts receiving high-impact signals unless `--force` is set.

High-impact signals are `KILL`, `TERM`, `STOP`, `QUIT`, `ABRT`, and `SEGV`.

On success, stdout is:

`signaled: <count> process(es) with <normalized-signal>`

### `ls`

`nsurgn ls` ARTIFACT_OR_PID TARGET_PATH

Lists TARGET_PATH inside the artifact target root. TARGET_PATH must be absolute. The command writes directory entries or a single file entry to stdout and writes diagnostics to stderr.

### `cat`

`nsurgn cat` ARTIFACT_OR_PID TARGET_PATH [`--max-bytes` BYTES]

Writes file contents from TARGET_PATH inside the artifact target root to stdout. Directories and symlinks are refused. When `--max-bytes` is set, at most BYTES bytes are written.

### `stat`

`nsurgn stat` ARTIFACT_OR_PID TARGET_PATH

Prints metadata for TARGET_PATH inside the artifact target root. `stat` uses symlink metadata and does not follow symlinks. Stdout includes:

- artifact ID
- original target path
- resolved procfs path
- type
- mode
- uid
- gid
- size
- mtime in UTC ISO-8601 format

### `exists`

`nsurgn exists` ARTIFACT_OR_PID TARGET_PATH

Checks whether TARGET_PATH exists inside the artifact target root. Stdout is empty.

Exit status is 0 when the path exists, 1 when the path does not exist, and 2 for usage or runtime errors.

### `checksum`

`nsurgn checksum` ARTIFACT_OR_PID TARGET_PATH [`--sha256`|`--sha512`|`--md5`]

Writes a checksum for TARGET_PATH inside the artifact target root. Directories and symlinks are refused. The default algorithm is SHA-256. `--md5` is supported only as a legacy non-cryptographic checksum.

Stdout format is:

`<algorithm>  <hex-digest>  <target-path>`

### `enter`

`nsurgn enter` ARTIFACT_OR_PID [`--mount`] [`--uts`] [`--ipc`] [`--net`] [`--pid`] [`--user`] [`--cgroup`] [`--time`] [`--no-pid`] [`--no-net`] [`--no-mount`] [`--root`] [`--wd` TARGET_DIR] `--` COMMAND [ARGS...]

Runs COMMAND through `nsenter` using the artifact leader as the `--target` PID. The `--` separator is required. Arguments after `--` are passed unchanged to `nsenter`.

Default namespace entry uses mount, UTS, IPC, network, and PID namespaces. User namespace entry is not used unless `--user` is set.

`--root` sets the command root to `/proc/<leader-pid>/root` using `nsenter --root`. No custom `chroot` fallback is provided. When `--root` is set, default working directory is `/`. `--wd` sets the working directory passed to `nsenter --wd`.

The command exits 9 when `nsenter` is missing or when the installed `nsenter` does not support a requested namespace, `--root`, or `--wd` option. No other command may fail merely because `nsenter` is missing.

## OPTIONS

`--group` MODE
: Select artifact grouping. MODE is one of `profile`, `strict`, `pid`, `mnt`, `net`, or `cgroup`. Default is `profile`.

`--format` FORMAT
: Select output format. FORMAT is `table` or `text`. Discovery tables default to `table`; detailed commands default to `text`.

`--verbose`
: Write resolved paths and decision details to stderr. For file operations, verbose output includes `target_root`, `target_path`, and `resolved`.

`--quiet`
: Suppress non-critical warnings. Errors are still written to stderr.

`--no-color`
: Disable color output. Color is never emitted when stdout is not a terminal.

`--host-pid` PID
: Use PID as the host namespace profile reference instead of PID 1.

`--include-host`
: Include host-classified artifacts in discovery output and allow host-classified targets to be selected for read-only commands.

`--no-runtime-hints`
: Disable cgroup path hint scoring, runtime hint labels, container ID hint scoring, and runtime-derived `container-ish` classification. Namespace, rootfs, executable, and mountinfo evidence still apply. Runtime hint output is `none`.

`--no-mount-scan`
: Do not read `/proc/<pid>/mountinfo` during discovery. Commands that directly inspect mounts still read the selected leader mountinfo.

`--help`
: Print usage to stdout and exit 0.

`--version`
: Print `nsurgn <version>` to stdout and exit 0.

## ARGUMENTS

ARTIFACT_OR_PID accepts:

- `A<N>` for an artifact ID from the current command scan
- `<number>` for a host PID
- `pid:<number>` for an explicit host PID

Artifact IDs are ephemeral and assigned per command invocation. A previous `list` result is a selection aid, not persistent state.

TARGET_PATH values are artifact-root paths. They must be absolute, must not be empty, and must not contain `.` or `..` path components.

HOST_SRC and HOST_DEST are host filesystem paths.

## STDIN

`nsurgn` does not read stdin for command input. Commands that run through `enter` leave stdin attached to the executed command.

## STDOUT

Stdout is reserved for command output:

- discovery tables
- reports
- copied, removed, and signaled success records
- file contents for `cat`
- checksums
- command output from `enter`

Warnings, errors, hints, and verbose execution details are written to stderr.

## STDERR

Stderr is used for diagnostics. Error messages start with `error:`. Warnings start with `warning:`. Hints start with `hint:`.

Common diagnostics include:

`error: target path must be absolute: <path>`

`error: refusing path traversal: <path>`

`error: refusing protected path: <path>`

`error: remove requires --force`

`error: directory removal requires --recursive: <resolved-target>`

`error: refusing mount point: <resolved-target>`

`error: recursive removal requires GNU rm with --one-file-system`

`error: artifact <id> no longer exists in current scan`

`hint: rerun nsurgn list`

`error: nsenter is required for enter mode but was not found in PATH`

## EXIT STATUS

0
: Success.

1
: General error, including `exists` path-not-found.

2
: Usage error.

3
: Permission denied.

4
: Target PID, target path, source path, or destination path not found.

5
: Unsafe path refused.

6
: Artifact not found or artifact ID could not be resolved in the current scan.

7
: Partial success.

8
: Process changed or disappeared during the requested operation.

9
: Unsupported platform, missing required Linux procfs feature, or missing command-specific dependency such as `nsenter` for `enter`.

## FILES

`/proc/<pid>/ns/*`
: Namespace identity symlinks read during discovery.

`/proc/<pid>/status`
: Process status and namespace PID metadata.

`/proc/<pid>/cmdline`
: Command line metadata.

`/proc/<pid>/cgroup`
: Cgroup paths and runtime hints.

`/proc/<pid>/root`
: Leader target root for artifact file operations.

`/proc/<pid>/exe`
: Leader executable symlink and executable extraction source.

`/proc/<pid>/mountinfo`
: Mount metadata for scoring, reports, `mounts`, and recursive `remove` mount-point refusal. Discovery does not read this file when `--no-mount-scan` is set.

`nsurgn` does not read or write a configuration file.

## ENVIRONMENT

`nsurgn` does not read environment variables for configuration.

## EXAMPLES

List probable namespace artifacts:

```sh
sudo nsurgn list
```

Inspect a listed artifact:

```sh
sudo nsurgn inspect A1
```

Copy a repaired file into an artifact root filesystem:

```sh
sudo nsurgn install A1 ./nginx.conf /etc/nginx/nginx.conf --overwrite --verbose
```

Extract a binary from an artifact root filesystem:

```sh
sudo nsurgn extract A1 /usr/sbin/nginx ./nginx-bin
```

Remove a bad file with the required destructive-operation guard:

```sh
sudo nsurgn remove A1 /tmp/bad.conf --force
```

Reload the artifact leader with SIGHUP:

```sh
sudo nsurgn signal A1 HUP
```

Run a command in selected namespaces with root set to the artifact root:

```sh
sudo nsurgn enter A1 --root -- /usr/sbin/nginx -t
```

## VERSIONING

`--version` prints:

`nsurgn 0.1.0`

Version changes are tied to documented, tested behavior. New commands, flags, output formats, file writes, environment variables, and exit statuses require man page and acceptance test updates.

## LIMITATIONS

`nsurgn` observes live host process metadata through procfs. It does not provide a stable snapshot of a workload, and results can change while a command runs.

Artifact IDs are not persistent. They are assigned during each command invocation and can change between runs.

Runtime hints, cgroup paths, command lines, mount metadata, and executable paths are evidence only. They can be absent, stale, spoofed, or misleading.

File operations use `/proc/<leader-pid>/root` and are subject to normal Linux permission checks, procfs mount options, Linux security modules, namespace configuration, and race conditions in mutable filesystems.

Only `enter` uses `nsenter` to execute a command in selected namespaces. `nsurgn` does not provide a shell, runtime client, memory injection, ptrace injection, orchestration, image management, or proof that an artifact is a container.

## UNRESOLVED BEHAVIOR

The v1 specification must decide the exact table spacing for human-readable table output before acceptance tests are written for table output.

The v1 specification must decide the exact stdout format for `ls` directory entries and `stat` metadata fields before acceptance tests are written for those commands.

## BUGS

`nsurgn` reports evidence, not certainty. Runtime hints can be spoofed or absent. A real container may not have recognizable runtime metadata, and a non-container workload can look container-like.

Live `/proc` data can change while commands run. `nsurgn` warns or fails when selected processes disappear, leader metadata changes, or target roots become inaccessible during an operation.

Privilege requirements vary by kernel, procfs mount options, Linux security modules, capabilities, and namespace configuration. Root is recommended for complete results and for file, signal, and namespace-entry operations.
