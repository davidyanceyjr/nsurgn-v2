# nsurgn First Release Concept and Application Specification

Project: `nsurgn`  
Meaning: **namespace surgeon**  
Release scope: First release / v1  
Primary platform: Linux  
Primary interface: Command-line utility  
Core dependency posture: Linux procfs and standard Linux utilities  
Optional dependency for namespace entry: `nsenter`

---

## Document Status

This file is a v1 concept and application specification. It is not the current
operation manual and it is not a completion claim for the current executable.

For current user operation, read `README.md` and `doc/nsurgn.1.md`.

The current `0.1.0` executable implements a tested subset of this specification:
`list`, `all`, `tree`, `report`, `inspect`, `exists`, `cat`, `checksum`,
`extract`, `install`, `inject`, `remove`, and `enter` argument validation.

Commands and options in this specification that are not covered by the current
acceptance tests remain intended v1 behavior until implemented and verified.

## 1. Executive Summary

`nsurgn` is a Linux-native command-line utility for discovering, inspecting, and operating on **namespace artifacts**: groups of Linux processes related by shared namespace membership, cgroup paths, root filesystem views, mount metadata, process relationships, and supporting `/proc` metadata.

Linux does not expose “containers” as first-class kernel objects. It exposes processes, namespaces, cgroups, mounts, file descriptors, root filesystem views, signals, and process metadata. Container runtimes and orchestrators build higher-level abstractions on top of those primitives.

`nsurgn` works at the Linux substrate layer.

The tool is designed for situations where Docker, Podman, Kubernetes, containerd, CRI-O, `crictl`, `ctr`, `nerdctl`, runtime sockets, or runtime APIs are unavailable, broken, restricted, or intentionally absent.

`nsurgn` does **not** claim to detect containers as kernel objects. It detects namespace-related process artifacts and classifies some as **container-ish** when namespace isolation and runtime metadata strongly suggest container-like execution.

Intended first-release capabilities include:

- Discovering namespace-isolated, container-ish, and suspicious artifacts.
- Listing probable artifact leaders.
- Inspecting namespace, cgroup, mount, executable, process, and rootfs metadata.
- Copying files into and out of an artifact root filesystem.
- Removing files from an artifact root filesystem with strict guardrails.
- Extracting executables from running workloads.
- Sending signals to artifact leaders or explicitly to all artifact processes.
- Running an explicit command in selected namespaces of an artifact leader using `nsenter`.
- Inspecting paths inside a target root filesystem.
- Producing reports suitable for debugging and incident response.

`nsurgn` is not a Docker replacement, Kubernetes replacement, runtime client, sandbox escape tool, memory injection framework, orchestration system, or authoritative container detector.

---

## 2. Problem Statement

Modern Linux workloads are commonly managed by container runtimes and orchestration systems. Operational tooling often assumes access to one or more of:

- Docker
- Podman
- Kubernetes
- containerd
- CRI-O
- `kubectl`
- `crictl`
- `ctr`
- `nerdctl`
- runtime sockets
- JSON metadata pipelines

Those assumptions fail in real operational conditions:

- A Kubernetes node is degraded and `kubectl` is unavailable.
- Runtime sockets are inaccessible.
- Runtime metadata is corrupt or incomplete.
- The runtime daemon is crashed or wedged.
- The container image is distroless and lacks shell/debug tools.
- An incident responder has host access but not cluster credentials.
- Runtime-specific CLIs are missing from the node.
- A workload still exists as Linux processes even though the orchestrator path is broken.
- Security teams need to inspect isolated workloads without trusting runtime APIs.

At the kernel and procfs level, these workloads are still visible as Linux processes with associated metadata. The problem is that standard Linux tools expose that information in fragments.

`nsurgn` assembles those fragments into artifact-level views and carefully scoped repair operations.

---

## 3. Goals

### 3.1 Discover Namespace Artifacts

`nsurgn` should group visible processes by namespace relationships and supporting Linux metadata.

It should not dump every PID by default. Default discovery should surface artifacts that are isolated, container-ish, namespace-init-like, or suspicious.

### 3.2 Classify Honestly

The tool should use evidence-based classifications:

- `host`
- `isolated`
- `namespace-init`
- `container-ish`
- `suspicious`

It must not state that a process group is definitely a container unless the operator provides external confirmation.

### 3.3 Operate Without Runtime Tooling

Core functionality must not depend on:

- Docker
- Podman
- Kubernetes
- containerd APIs
- CRI-O APIs
- `crictl`
- `ctr`
- `nerdctl`
- `runc` APIs
- `jq`
- Python
- Go dependencies
- third-party SDKs

### 3.4 Support Surgical Filesystem Repair

The tool should support:

- copying files into an artifact root filesystem,
- extracting files from an artifact root filesystem,
- removing files with strict safety checks,
- extracting the running executable of a process,
- path inspection inside the artifact root.

### 3.5 Support Conservative Process Operations

The tool should support sending signals:

- to the artifact leader by default,
- to all artifact processes only with explicit `--all`.

### 3.6 Support Explicit Namespace Entry

The first release includes:

```bash
nsurgn enter <artifact-id|pid> [options] -- command...
```

This command is a convenience wrapper around `nsenter`. It is not required by other commands and must not become a hidden dependency for file operations, process inspection, or discovery.

### 3.7 Improve Incident Response

Reports should expose:

- namespace IDs,
- cgroup hints,
- process relationships,
- mount summaries,
- executable paths,
- target roots,
- classification reasons.

---

## 4. Non-Goals

`nsurgn` is not:

- a Docker replacement,
- a Podman replacement,
- a Kubernetes client,
- a CRI client,
- a container runtime,
- a workload scheduler,
- a container image manager,
- a sandbox,
- a privilege escalation tool,
- a memory injection tool,
- a shellcode framework,
- a ptrace injection framework,
- a general-purpose file sync system,
- a complete forensic suite,
- proof that a workload is a container.

Even with `enter`, `nsurgn` remains a Linux namespace artifact tool. `enter` only runs a command through `nsenter` in selected namespaces of the artifact leader.

---

## 5. Target Users

Primary users:

- Linux systems engineers
- SREs
- Platform engineers
- Security engineers
- Incident responders
- Kubernetes node debuggers
- Runtime engineers
- Infrastructure operators
- Linux forensic analysts

Expected familiarity:

- Linux processes
- `/proc`
- namespaces
- cgroups
- mount namespaces
- PID namespaces
- signals
- root filesystem views
- host PIDs versus namespace PIDs
- privilege boundaries

---

## 6. Core Linux Concepts

### 6.1 Processes

The fundamental unit of observation is the Linux process. Every artifact discovered by `nsurgn` is composed of one or more visible host PIDs.

### 6.2 Namespaces

Linux namespaces isolate process views of kernel resources.

Relevant namespace types:

- PID namespace
- Mount namespace
- Network namespace
- User namespace
- UTS namespace
- IPC namespace
- Cgroup namespace
- Time namespace

Namespace identity is exposed through symlinks:

```text
/proc/<pid>/ns/pid
/proc/<pid>/ns/mnt
/proc/<pid>/ns/net
/proc/<pid>/ns/user
/proc/<pid>/ns/uts
/proc/<pid>/ns/ipc
/proc/<pid>/ns/cgroup
/proc/<pid>/ns/time
```

Example symlink targets:

```text
pid:[4026532891]
mnt:[4026532887]
net:[4026532894]
```

The numeric namespace identifier is central to grouping.

### 6.3 Cgroups

Cgroup paths often contain runtime or orchestrator hints, such as:

```text
kubepods
containerd
docker
crio
libpod
lxc
machine.slice
```

These hints are useful but not authoritative.

### 6.4 Root Filesystem View

A process root filesystem view is exposed as:

```text
/proc/<pid>/root
```

For artifact filesystem operations, `nsurgn` uses the leader's root filesystem view as the **target root**.

Example:

```text
/proc/18342/root/etc/nginx/nginx.conf
```

### 6.5 Mount Metadata

Mount namespace details are exposed through:

```text
/proc/<pid>/mountinfo
```

Mountinfo may reveal:

- overlay filesystems,
- bind mounts,
- tmpfs mounts,
- projected volumes,
- snapshotter paths,
- Kubernetes service account mounts,
- container-like filesystem layouts.

### 6.6 Host Profile

The host profile is the namespace profile of a known host process.

Default:

```text
host_profile = namespace profile of /proc/1
```

Processes matching the host profile are normally hidden from `nsurgn list`.

---

## 7. Terminology

### 7.1 Artifact

A group of processes related by shared namespace membership and supporting metadata.

An artifact is an inferred operational unit. It is not a kernel object.

### 7.2 Namespace Artifact

A process group inferred from:

- shared Linux namespace IDs,
- cgroup paths,
- root filesystem views,
- mount metadata,
- process relationships.

A namespace artifact may correspond to:

- a container,
- a pod component,
- a systemd service with private namespaces,
- an LXC guest,
- a build sandbox,
- a manually created `unshare` environment,
- a test harness,
- a compromised process namespace,
- something else.

### 7.3 Namespace Profile

The tuple of namespace IDs associated with a process.

Canonical tuple:

```text
pid_ns
mnt_ns
net_ns
user_ns
uts_ns
ipc_ns
cgroup_ns
time_ns
```

Example:

```text
pid_ns=4026532891
mnt_ns=4026532887
net_ns=4026532894
user_ns=4026531837
uts_ns=4026532892
ipc_ns=4026532893
cgroup_ns=4026532895
time_ns=4026531834
```

### 7.4 Leader

The best representative process for an artifact.

Leader selection order:

1. Prefer the process that is PID 1 inside a nested PID namespace.
2. Otherwise, prefer the oldest process in the artifact.
3. Otherwise, prefer the lowest host PID.

The leader is used for:

- artifact identity,
- target root selection,
- default signal delivery,
- mount inspection,
- executable inspection,
- default process metadata,
- default `enter` target.

### 7.5 Target Root

The filesystem view exposed by:

```text
/proc/<leader_pid>/root
```

All artifact filesystem operations resolve target paths relative to this root.

Example:

```text
target path: /etc/nginx/nginx.conf
resolved path: /proc/18342/root/etc/nginx/nginx.conf
```

### 7.6 Container-ish

A classification for artifacts that have namespace isolation plus cgroup, runtime, or filesystem hints such as:

- `kubepods`
- `containerd`
- `docker`
- `crio`
- `libpod`
- `lxc`
- `machine.slice`
- overlay/snapshotter metadata
- PID 1 inside a non-host PID namespace

This is a probability-oriented label, not proof.

### 7.7 Suspicious

A classification for namespace artifacts that differ from the host profile but do not have obvious runtime metadata, or that show unusual namespace/cgroup/process layout.

Examples:

- Different mount namespace but no runtime cgroup hint.
- Different PID namespace with unknown ancestry.
- Different user namespace with unexpected process ownership.
- Isolated namespace profile under normal-looking system cgroups.
- Processes with deleted executables, unusual fds, or unexpected rootfs layout.

---

## 8. Threat Model and Safety Model

### 8.1 Threat Model

`nsurgn` is useful when:

- runtime tooling cannot be trusted or accessed,
- a workload may be compromised,
- a host may contain malicious namespace-isolated processes,
- files inside an artifact may be hostile,
- environment variables may contain secrets,
- symlinks may be deceptive,
- mounts may hide or redirect paths,
- process names and command lines may lie,
- cgroup paths may be spoofed or non-standard,
- namespace grouping may be ambiguous.

### 8.2 Safety Assumptions

`nsurgn` assumes:

- target artifacts may be malicious,
- target paths may attempt traversal,
- symlinks may point outside intended locations,
- environment data may expose credentials,
- runtime hints are unreliable,
- namespace isolation is not proof of containerization,
- host PID visibility may be incomplete.

### 8.3 Safety Principles

- Destructive operations require `--force`.
- Bulk signaling requires `--all`.
- Weakly classified artifacts produce warnings.
- Dangerous target paths are refused.
- Absolute target paths are required.
- Path traversal is rejected.
- `/proc/<pid>/root/...` resolution is shown in verbose mode.
- Core commands do not require tools inside the target artifact.
- No memory injection, ptrace injection, or shellcode behavior is supported.
- `enter` is explicit and never used implicitly by other commands.

---

## 9. Namespace Artifact Discovery Model

### 9.1 Linux-Native Data Sources

Use:

```text
/proc/<pid>/ns/*
/proc/<pid>/status
/proc/<pid>/cmdline
/proc/<pid>/cgroup
/proc/<pid>/root
/proc/<pid>/exe
/proc/<pid>/fd
/proc/<pid>/mountinfo
/proc/<pid>/environ
lsns
ps
readlink
awk
sed
grep
findmnt, if available
nsenter, only for explicit enter mode
```

Do not require:

```text
docker
podman
kubectl
crictl
ctr
nerdctl
runc APIs
containerd APIs
CRI-O APIs
jq
Python
Go dependencies
third-party vendor SDKs
```

### 9.2 Discovery Steps

1. Enumerate visible numeric PIDs under `/proc`.
2. For each PID:
   - read namespace symlinks from `/proc/<pid>/ns/*`,
   - read `/proc/<pid>/status`,
   - read `/proc/<pid>/cmdline`,
   - read `/proc/<pid>/cgroup`,
   - resolve `/proc/<pid>/root`,
   - resolve `/proc/<pid>/exe`,
   - optionally read `/proc/<pid>/mountinfo`.
3. Build a namespace profile for each process.
4. Determine host namespace profile.
5. Group processes according to selected grouping strategy.
6. Select leader for each group.
7. Score each group.
8. Classify each group.
9. Hide `host` artifacts from default `list` output.
10. Display isolated, namespace-init, container-ish, or suspicious artifacts.

---

## 10. Artifact Grouping Modes

### 10.1 `--group profile`

Default.

Group by:

```text
pid_ns + mnt_ns + net_ns
```

Rationale:

This balances usefulness and noise. PID, mount, and network namespaces are strong workload-boundary signals without fragmenting too aggressively.

### 10.2 `--group strict`

Group by full namespace tuple:

```text
pid_ns + mnt_ns + net_ns + user_ns + uts_ns + ipc_ns + cgroup_ns + time_ns
```

Useful for forensic precision.

### 10.3 `--group pid`

Group by PID namespace.

Useful for understanding nested PID namespace relationships.

### 10.4 `--group mnt`

Group by mount namespace.

Useful for filesystem-focused investigation.

### 10.5 `--group net`

Group by network namespace.

Useful for network isolation mapping.

### 10.6 `--group cgroup`

Group by cgroup-derived hints.

Useful when namespace isolation is weak but cgroup structure is meaningful.

---

## 11. Artifact Classification Model

### 11.1 Labels

#### `host`

Same namespace profile as host. Hidden by default.

#### `isolated`

Differs from host in one or more major namespace types.

Major namespace types:

- PID
- mount
- network
- user

#### `namespace-init`

Has a process that is PID 1 inside a non-host PID namespace.

#### `container-ish`

Has namespace isolation plus cgroup, runtime, container ID, overlay, snapshotter, or Kubernetes-style hints.

#### `suspicious`

Has isolation but no clear runtime hint, or has unusual namespace/cgroup/process layout.

### 11.2 Suggested Scoring Model

| Signal | Points |
|---|---:|
| PID namespace differs from host | +3 |
| Mount namespace differs from host | +3 |
| Network namespace differs from host | +2 |
| User namespace differs from host | +2 |
| UTS namespace differs from host | +1 |
| IPC namespace differs from host | +1 |
| Cgroup namespace differs from host | +1 |
| Time namespace differs from host | +1 |
| Process is PID 1 inside nested PID namespace | +4 |
| Cgroup path contains `kubepods` | +4 |
| Cgroup path contains `containerd` | +4 |
| Cgroup path contains `docker` | +4 |
| Cgroup path contains `crio` | +4 |
| Cgroup path contains `libpod` | +4 |
| Cgroup path contains `lxc` | +3 |
| Cgroup path contains `machine.slice` | +2 |
| Cgroup path contains long hex container-like ID | +2 |
| Root filesystem differs from host root | +2 |
| Mountinfo contains overlay/snapshotter hints | +3 |
| Mountinfo contains Kubernetes projected/serviceaccount mounts | +2 |
| Executable path is deleted | +2 |
| Isolation without runtime hints | suspicious flag |

### 11.3 Classification Rules

Baseline:

```text
score 0-2:
  host or weakly isolated

score 3-5:
  isolated

score 6-8:
  isolated or namespace-init

score >= 9 with runtime hints:
  container-ish

score >= 6 without runtime hints:
  suspicious or isolated, depending on layout

nested PID namespace with ns pid 1:
  namespace-init

runtime hint + isolation:
  container-ish
```

### 11.4 Classification Limitation

A process group can look container-like without being a container. A process group can also be a real container while hiding runtime hints. `nsurgn` reports evidence, not certainty.

---

## 12. First Release Command Groups

### Discovery

```text
nsurgn list
nsurgn report
nsurgn scout
nsurgn all
nsurgn tree
```

### Inspection

```text
nsurgn inspect <artifact-id|pid>
nsurgn map <artifact-id|pid>
nsurgn ps <artifact-id|pid>
nsurgn mounts <artifact-id|pid>
nsurgn exe <artifact-id|pid>
```

### Filesystem Surgery

```text
nsurgn install <artifact-id|pid> <host-src> <target-path>
nsurgn inject <artifact-id|pid> <host-src> <target-path>
nsurgn extract <artifact-id|pid> <target-path> <host-dest>
nsurgn remove <artifact-id|pid> <target-path> --force
```

### Process Operations

```text
nsurgn signal <artifact-id|pid> <signal>
nsurgn signal <artifact-id|pid> <signal> --all
```

### Path Inspection

```text
nsurgn ls <artifact-id|pid> <target-path>
nsurgn cat <artifact-id|pid> <target-path>
nsurgn stat <artifact-id|pid> <target-path>
nsurgn exists <artifact-id|pid> <target-path>
nsurgn checksum <artifact-id|pid> <target-path>
```

### Namespace Entry

```text
nsurgn enter <artifact-id|pid> [options] -- command...
```

### Deferred From First Release

These are useful but should be deferred unless implementation time allows:

```text
nsurgn move-in
nsurgn move-out
nsurgn fds
nsurgn env
full report --with-fds
full report --with-env
```

Reason:

- `move-*` increases destructive-operation complexity.
- `fds` increases output complexity.
- `env` introduces serious secret-exposure risk.
- `enter` already adds enough safety surface for v1.

---

## 13. Global CLI Specification

### 13.1 Syntax

```bash
nsurgn [global-options] <command> [command-options] [arguments]
```

### 13.2 Global Options

```text
--group <mode>       Grouping mode: profile, strict, pid, mnt, net, cgroup
--format <format>    Output format: table, text, json, ndjson
--verbose            Print resolved paths and decision details
--quiet              Suppress non-critical warnings
--no-color           Disable color output
--host-pid <pid>     Use specific PID as host namespace profile reference
--include-host       Include host-classified artifacts
--no-runtime-hints   Disable runtime/cgroup hint scoring
--no-mount-scan      Do not read mountinfo during discovery
--version            Print version
--help               Show help
```

### 13.3 Artifact Identifier

Artifacts receive ephemeral IDs per command invocation:

```text
A1
A2
A3
...
```

Commands accepting `<artifact-id|pid>` should accept:

```text
A1
18342
pid:18342
```

Rules:

- `A1` means artifact ID.
- numeric value means host PID.
- `pid:18342` explicitly means host PID.

---

## 14. Discovery Command Specification

### 14.1 `nsurgn list`

List namespace-isolated, namespace-init, container-ish, or suspicious artifacts.

Default behavior:

- hide host-equivalent processes,
- hide ordinary host services with no meaningful isolation,
- do not dump every PID.

Example:

```bash
sudo nsurgn list
```

Example output:

```text
ARTIFACT  CLASSIFICATION  SCORE  LEADER  NSPID  PROCS  RUNTIME_HINT     COMMAND
A1        container-ish   13     18342   1      4      containerd/k8s   nginx -g daemon off;
A2        suspicious      7      22110   1      2      none             ./worker
A3        isolated        5      9051    -      1      systemd          systemd-resolved
```

### 14.2 `nsurgn report`

Produce a detailed report of namespace artifacts.

Example:

```bash
sudo nsurgn report
```

Options:

```text
--artifact <artifact-id|pid>
--all
--format text|json|ndjson
--include-host
--with-mounts
```

First-release report should include:

- artifact ID,
- classification,
- score,
- leader host PID,
- leader namespace PID,
- runtime hint,
- container ID hint,
- process count,
- target root,
- namespace IDs,
- cgroup paths,
- process table,
- mount summary.

Example:

```text
artifact: A1
  classification: container-ish
  score: 13
  leader_host_pid: 18342
  leader_ns_pid: 1
  runtime_hint: containerd/k8s
  container_id_hint: a3f91b27c8e4
  process_count: 4
  target_root: /proc/18342/root

  namespaces:
    pid:    4026532891
    mnt:    4026532887
    net:    4026532894
    user:   4026531837
    uts:    4026532892
    ipc:    4026532893
    cgroup: 4026532895
    time:   4026531834

  cgroups:
    0::/kubepods.slice/kubepods-burstable.slice/pod7f.../cri-containerd-a3f91b27c8e4.scope

  processes:
    HOSTPID  NSPID  PPID   COMMAND
    18342    1      18301  nginx -g daemon off;
    18378    32     18342  nginx: worker process
    18379    33     18342  nginx: worker process
```

### 14.3 `nsurgn scout`

Show likely artifact leaders or probable container-like entrypoints.

Example:

```bash
sudo nsurgn scout
```

Example output:

```text
ARTIFACT  LEADER  NSPID  CLASSIFICATION  SCORE  WHY                         COMMAND
A1        18342   1      container-ish   13     pidns-init,cgroup:k8s       nginx -g daemon off;
A2        22110   1      suspicious      7      pidns-init,no-runtime-hint   ./worker
```

### 14.4 `nsurgn all`

Noisy mode. List every visible PID with namespace metadata.

Example:

```bash
sudo nsurgn all
```

Suggested columns:

```text
HOSTPID
PPID
NSPID
PID_NS
MNT_NS
NET_NS
USER_NS
UTS_NS
IPC_NS
CGROUP_NS
TIME_NS
CGROUP_HINT
COMMAND
```

### 14.5 `nsurgn tree`

Show PID namespace groups and representative leaders.

Example:

```bash
sudo nsurgn tree
```

Example output:

```text
host pid_ns 4026531836
├── A1 pid_ns 4026532891 leader 18342 ns_pid 1 nginx -g daemon off;
│   ├── 18378 ns_pid 32 nginx: worker process
│   └── 18379 ns_pid 33 nginx: worker process
└── A2 pid_ns 4026533010 leader 22110 ns_pid 1 ./worker
```

---

## 15. Inspection Command Specification

### 15.1 `nsurgn inspect <artifact-id|pid>`

Show detailed metadata for an artifact or PID.

Example:

```bash
sudo nsurgn inspect A1
sudo nsurgn inspect 18342
```

Output should include:

- artifact ID,
- classification,
- score,
- leader selection reason,
- namespace profile,
- cgroup paths,
- root path,
- executable path,
- command line,
- process count,
- warnings,
- runtime/container hints.

### 15.2 `nsurgn map <artifact-id|pid>`

Show related processes and shared namespace relationships.

Example:

```bash
sudo nsurgn map A1
```

Example output:

```text
artifact: A1
leader: 18342

shared namespace relationships:
  pid_ns: 4026532891 shared by 4 processes
  mnt_ns: 4026532887 shared by 4 processes
  net_ns: 4026532894 shared by 4 processes
  user_ns: 4026531837 shared with host
  uts_ns: 4026532892 shared by 4 processes
  ipc_ns: 4026532893 shared by 4 processes

related processes:
  HOSTPID  NSPID  PID_NS      MNT_NS      NET_NS      COMMAND
  18342    1      4026532891  4026532887  4026532894  nginx -g daemon off;
  18378    32     4026532891  4026532887  4026532894  nginx: worker process
  18379    33     4026532891  4026532887  4026532894  nginx: worker process
```

### 15.3 `nsurgn ps <artifact-id|pid>`

Show processes belonging to the artifact.

Example:

```bash
sudo nsurgn ps A1
```

Example output:

```text
HOSTPID  NSPID  PPID   USER      STARTED  STAT  COMMAND
18342    1      18301  101       10:22    Ss    nginx -g daemon off;
18378    32     18342  101       10:22    S     nginx: worker process
18379    33     18342  101       10:22    S     nginx: worker process
```

### 15.4 `nsurgn mounts <artifact-id|pid>`

Show mountinfo summary.

Example:

```bash
sudo nsurgn mounts A1
```

Options:

```text
--raw       Print raw /proc/<leader>/mountinfo
--summary   Print summarized view
```

Example:

```text
artifact: A1
leader: 18342
mountinfo: /proc/18342/mountinfo

MOUNTPOINT                    FSTYPE    SOURCE        FLAGS
/                             overlay   overlay       rw,relatime
/proc                         proc      proc          rw,nosuid,nodev,noexec
/dev                          tmpfs     tmpfs         rw,nosuid
/sys                          sysfs     sysfs         ro,nosuid,nodev,noexec
/var/run/secrets/kubernetes   tmpfs     tmpfs         ro
```

### 15.5 `nsurgn exe <artifact-id|pid>`

Show or extract the running executable.

Examples:

```bash
sudo nsurgn exe A1
sudo nsurgn exe A1 --extract ~/nginx-bin
```

Default output:

```text
artifact: A1
leader: 18342
exe: /proc/18342/exe -> /usr/sbin/nginx
deleted: no
```

If executable is deleted:

```text
exe: /proc/18342/exe -> /usr/sbin/nginx (deleted)
warning: executable path has been deleted; /proc/<pid>/exe may still expose the running image
```

---

## 16. Filesystem Surgery Command Specification

### 16.1 `nsurgn install <artifact-id|pid> <host-src> <target-path>`

Copy a file or directory from the host into the artifact root filesystem.

Example:

```bash
sudo nsurgn install A1 ~/nginx.conf /etc/nginx/nginx.conf
```

Semantics:

```text
host -> artifact rootfs
copy only
host source remains
```

Resolved target:

```text
/proc/<leader_pid>/root/<target-path>
```

Requirements:

- `<target-path>` must be absolute.
- Path traversal must be rejected.
- Parent directory must exist unless `--parents` is provided.
- Target artifact must have a valid leader.
- Target root must be accessible.

Options:

```text
--parents        Create parent directories in target root
--mode <mode>    Set target permissions
--owner <uid>    Set target owner UID
--group <gid>    Set target group GID
--backup         Backup existing target first
--overwrite      Allow overwrite
--no-overwrite   Refuse if target exists
--verbose        Print resolved procfs path
```

Default overwrite policy should be conservative:

- refuse overwriting existing files unless `--overwrite` is provided.

### 16.2 `nsurgn inject <artifact-id|pid> <host-src> <target-path>`

Alias for `install`.

Example:

```bash
sudo nsurgn inject A1 ./debug-binary /tmp/debug-binary
```

Required documentation:

```text
inject is an alias for install. It copies host files into the artifact root filesystem.
It does not perform memory injection, process injection, ptrace injection, shellcode injection, or process tampering.
```

### 16.3 `nsurgn extract <artifact-id|pid> <target-path> <host-dest>`

Copy a file or directory from the artifact root filesystem to the host.

Example:

```bash
sudo nsurgn extract A1 /usr/sbin/nginx ~/nginx-bin
```

Semantics:

```text
artifact rootfs -> host
copy only
artifact source remains
```

Requirements:

- `<target-path>` must be absolute.
- Source must exist inside target root.
- Host destination must not be overwritten unless explicitly allowed.
- Symlink behavior must be explicit.

Options:

```text
--overwrite
--no-overwrite
--preserve
--dereference
--no-dereference
--verbose
```

### 16.4 `nsurgn remove <artifact-id|pid> <target-path> --force`

Remove a file or directory from the artifact root filesystem.

Example:

```bash
sudo nsurgn remove A1 /tmp/bad-file --force
```

Semantics:

```text
delete from artifact rootfs
destructive
requires --force
```

Must refuse dangerous paths:

```text
/
/etc
/usr
/bin
/sbin
/lib
/lib64
/proc
/sys
/dev
/run
```

Also refuse:

```text
.
..
empty path
relative path
paths containing unresolved traversal
```

Directory removal should require:

```text
--recursive
```

Example:

```bash
sudo nsurgn remove A1 /tmp/bad-dir --recursive --force
```

---

## 17. File Operation Semantics

### 17.1 Path Resolution

Given:

```text
leader_host_pid = 18342
target_path = /etc/nginx/nginx.conf
```

Resolved path:

```text
/proc/18342/root/etc/nginx/nginx.conf
```

Rejected examples:

```text
etc/nginx/nginx.conf
../etc/passwd
/tmp/../../etc/passwd
/
(empty)
```

### 17.2 Symlink Policy

Default first-release posture:

- For read operations, report symlinks clearly.
- For `install`, refuse to overwrite a symlink unless an explicit symlink option is implemented.
- For `remove`, remove the symlink itself, not the symlink target.
- Do not blindly dereference symlinks for destructive writes.

Possible options:

```text
--follow-symlink
--no-follow-symlink
--replace-symlink
```

For v1, default to `--no-follow-symlink` for destructive operations.

### 17.3 Dangerous Path Refusal

Destructive operations must refuse:

```text
/
/etc
/usr
/bin
/sbin
/lib
/lib64
/proc
/sys
/dev
/run
```

The first implementation should also refuse removing mount points unless explicitly designed later.

### 17.4 Verbose Mode

With `--verbose`, print:

```text
target_root: /proc/18342/root
target_path: /etc/nginx/nginx.conf
resolved: /proc/18342/root/etc/nginx/nginx.conf
```

---

## 18. Process Operation Semantics

### 18.1 `nsurgn signal <artifact-id|pid> <signal>`

Send a signal to the artifact leader by default.

Examples:

```bash
sudo nsurgn signal A1 HUP
sudo nsurgn signal A1 SIGTERM
sudo nsurgn signal A1 15
```

Default target:

```text
leader host PID
```

Equivalent:

```bash
kill -HUP 18342
```

### 18.2 `nsurgn signal <artifact-id|pid> <signal> --all`

Send a signal to all processes in the artifact.

Example:

```bash
sudo nsurgn signal A1 TERM --all
```

Safety requirements:

- `--all` required for bulk signaling.
- Show number of target processes.
- Refuse host-classified artifact by default.
- Warn for weakly classified artifacts.

### 18.3 Signal Normalization

Accepted signal formats:

```text
HUP
SIGHUP
1
TERM
SIGTERM
15
KILL
SIGKILL
9
USR1
SIGUSR1
```

### 18.4 Signal Refusals

Refuse:

- unknown signals,
- signaling host PID 1 unless explicit override,
- signaling host-classified artifact by default,
- signaling all processes without `--all`,
- destructive signals to weakly classified artifacts unless `--force`.

High-impact signals include:

```text
KILL
TERM
STOP
QUIT
ABRT
SEGV
```

---

## 19. Namespace Entry: `nsurgn enter`

### 19.1 Purpose

`nsurgn enter` runs a command in selected namespaces of the artifact leader using `nsenter`.

It is intended for cases where:

- the operator wants an interactive shell or diagnostic command,
- the workload has usable binaries inside its filesystem view,
- `nsenter` is available on the host,
- namespace entry is safer or faster than manual `nsenter --target ...`.

It is not required for core `nsurgn` functionality. File copy, extraction, removal, inspection, reporting, and signaling must continue to work without `enter`.

### 19.2 Syntax

```bash
nsurgn enter <artifact-id|pid> [options] -- command...
```

Examples:

```bash
sudo nsurgn enter A1 -- /bin/sh
sudo nsurgn enter A1 -- /bin/bash
sudo nsurgn enter A1 -- /busybox sh
sudo nsurgn enter A1 -- /usr/bin/env
sudo nsurgn enter A1 -- /usr/sbin/nginx -t
sudo nsurgn enter A1 --root -- /bin/sh
```

The first release should require `--` before the command.

Reason:

- arguments before `--` are `nsurgn enter` options,
- arguments after `--` are passed unchanged to `nsenter`.

### 19.3 Required External Tool

`enter` requires:

```text
nsenter
```

If unavailable:

```text
error: nsenter is required for enter mode but was not found in PATH
hint: install util-linux or use nsurgn filesystem operations instead
```

This is acceptable because `enter` is explicitly optional. No other command may depend on it.

### 19.4 Default Namespace Set

Default namespace entry should use:

```text
--mount
--uts
--ipc
--net
--pid
```

Equivalent:

```bash
nsenter --target <leader_pid> --mount --uts --ipc --net --pid -- command...
```

Do **not** enter the user namespace by default.

Reason:

- user namespace entry can alter perceived privilege,
- user namespace behavior is subtle,
- rootless containers make this confusing,
- entering user namespaces can produce surprising permission behavior.

User namespace entry must be explicit:

```bash
sudo nsurgn enter A1 --user -- /bin/sh
```

### 19.5 Namespace Options

Supported v1 options:

```text
--mount        Enter mount namespace
--uts          Enter UTS namespace
--ipc          Enter IPC namespace
--net          Enter network namespace
--pid          Enter PID namespace
--user         Enter user namespace
--cgroup       Enter cgroup namespace if supported by nsenter
--time         Enter time namespace if supported by nsenter
--no-pid       Do not enter PID namespace
--no-net       Do not enter network namespace
--no-mount     Do not enter mount namespace
```

Default:

```text
--mount --uts --ipc --net --pid
```

Avoid `--all-ns` in v1 unless implementation can reliably detect support for each namespace type.

### 19.6 Root Filesystem Behavior

Important: entering a mount namespace does not automatically guarantee that command execution uses the target process root.

Therefore, `nsurgn enter` supports explicit root-aware entry.

#### Default: Namespace Entry Only

```bash
sudo nsurgn enter A1 -- /bin/sh
```

Behavior:

- enters selected namespaces,
- does not promise chroot-like behavior,
- does not claim to be “inside the container filesystem.”

#### Root-Aware Entry

Option:

```text
--root
```

Meaning:

- run command with root directory set to `/proc/<leader_pid>/root`,
- implemented with `nsenter --root=/proc/<leader_pid>/root` if supported,
- no ad hoc chroot fallback in v1.

Example:

```bash
sudo nsurgn enter A1 --root -- /bin/sh
```

Preferred implementation:

```bash
nsenter \
  --target <leader_pid> \
  --mount --uts --ipc --net --pid \
  --root=/proc/<leader_pid>/root \
  --wd=/ \
  -- /bin/sh
```

If unsupported:

```text
error: this nsenter version does not support --root
hint: use nsurgn install/extract operations, or run nsenter manually if you accept the risk
```

Do not implement a custom `chroot` fallback in v1.

### 19.7 Working Directory

Support:

```text
--wd <path>
```

Default with `--root`:

```text
/
```

Example:

```bash
sudo nsurgn enter A1 --root --wd /etc/nginx -- /bin/sh
```

Preferred implementation:

```bash
nsenter --target <leader_pid> ... --root=/proc/<pid>/root --wd=/etc/nginx -- /bin/sh
```

If `nsenter --wd` is unsupported:

```text
error: this nsenter version does not support --wd
```

### 19.8 Distroless Behavior

Distroless workloads may not contain a shell.

Example:

```bash
sudo nsurgn enter A1 --root -- /bin/sh
```

Expected failure:

```text
nsenter: failed to execute /bin/sh: No such file or directory
```

That is normal.

Possible emergency recovery:

```bash
sudo nsurgn install A1 ./busybox /tmp/busybox
sudo nsurgn enter A1 --root -- /tmp/busybox sh
```

This modifies the target filesystem. It may violate forensic preservation requirements. For incident response, prefer read-only inspection and extraction when possible.

### 19.9 `enter` Safety Requirements

Warn before entering weakly classified artifacts:

```text
warning: artifact A2 is suspicious and has no runtime hint
warning: entering namespaces can change command behavior and expose host resources
```

Warn for `--user`:

```text
warning: entering user namespace may change UID/GID mappings and privilege behavior
```

Warn for `--root`:

```text
warning: command will use target root: /proc/18342/root
```

With `--verbose`, print execution plan:

```text
artifact: A1
leader_host_pid: 18342
target_root: /proc/18342/root
exec:
  nsenter --target 18342 --mount --uts --ipc --net --pid --root=/proc/18342/root --wd=/ -- /bin/sh
```

Refuse by default when:

- artifact resolves to host profile,
- leader PID is host PID 1,
- `nsenter` is missing,
- selected leader no longer exists,
- namespace files are inaccessible,
- `--root` is requested but `/proc/<leader>/root` is inaccessible,
- `--root` is requested but `nsenter --root` is unsupported,
- no command is provided.

Allow host-profile override only with:

```text
--include-host --force
```

### 19.10 No Shell String Construction

Implementation must not build a shell command string.

Bad:

```bash
eval "nsenter $args $command"
```

Good:

```bash
exec nsenter "${nsenter_args[@]}" -- "${cmd[@]}"
```

---

## 20. Path Inspection Commands

All path inspection commands resolve paths relative to the target root.

### 20.1 `nsurgn ls <artifact-id|pid> <target-path>`

Example:

```bash
sudo nsurgn ls A1 /etc/nginx
```

Equivalent host-side path:

```text
/proc/<leader_pid>/root/etc/nginx
```

### 20.2 `nsurgn cat <artifact-id|pid> <target-path>`

Example:

```bash
sudo nsurgn cat A1 /etc/nginx/nginx.conf
```

Safety:

- warn for large files,
- refuse directories,
- optionally support `--max-bytes`.

### 20.3 `nsurgn stat <artifact-id|pid> <target-path>`

Example:

```bash
sudo nsurgn stat A1 /usr/sbin/nginx
```

Example output:

```text
artifact: A1
path: /usr/sbin/nginx
resolved: /proc/18342/root/usr/sbin/nginx
type: regular file
mode: 0755
uid: 0
gid: 0
size: 1260032
mtime: 2025-11-18T12:01:44Z
```

### 20.4 `nsurgn exists <artifact-id|pid> <target-path>`

Example:

```bash
sudo nsurgn exists A1 /etc/nginx/nginx.conf
```

Exit codes:

```text
0 exists
1 does not exist
2 error
```

### 20.5 `nsurgn checksum <artifact-id|pid> <target-path>`

Example:

```bash
sudo nsurgn checksum A1 /usr/sbin/nginx
```

Default hash:

```text
sha256
```

Options:

```text
--sha256
--sha512
--md5
```

`md5` should be documented as legacy/non-cryptographic.

---

## 21. Artifact Report Output

Example report format:

```text
artifact: A1
  classification: container-ish
  score: 13
  leader_host_pid: 18342
  leader_ns_pid: 1
  runtime_hint: containerd/k8s
  container_id_hint: a3f91b27c8e4
  process_count: 4
  target_root: /proc/18342/root

  namespaces:
    pid:    4026532891
    mnt:    4026532887
    net:    4026532894
    user:   4026531837
    uts:    4026532892
    ipc:    4026532893
    cgroup: 4026532895
    time:   4026531834

  processes:
    HOSTPID  NSPID  PPID   COMMAND
    18342    1      18301  nginx -g daemon off;
    18378    32     18342  nginx: worker process
    18379    33     18342  nginx: worker process
```

JSON output should be supported eventually, but shell-safe JSON generation is error-prone. For v1, text and table output are higher priority. If JSON is included in v1, escaping must be tested aggressively.

---

## 22. Example Workflows

### 22.1 Distroless Nginx Recovery

Problem:

- Nginx is running in a distroless workload.
- The config is broken.
- There is no shell inside the workload.
- Runtime CLI access is unavailable.
- Need to replace config and reload Nginx.

Workflow:

```bash
sudo nsurgn list
```

Example:

```text
ARTIFACT  CLASSIFICATION  SCORE  LEADER  NSPID  PROCS  RUNTIME_HINT     COMMAND
A1        container-ish   13     18342   1      4      containerd/k8s   nginx -g daemon off;
```

Inspect:

```bash
sudo nsurgn inspect A1
```

Install repaired config:

```bash
sudo nsurgn install A1 ~/nginx.conf /etc/nginx/nginx.conf --overwrite --verbose
```

Verbose output:

```text
target_root: /proc/18342/root
target_path: /etc/nginx/nginx.conf
resolved: /proc/18342/root/etc/nginx/nginx.conf
copied: /home/user/nginx.conf -> /proc/18342/root/etc/nginx/nginx.conf
```

Reload:

```bash
sudo nsurgn signal A1 HUP
```

Extract Nginx binary:

```bash
sudo nsurgn extract A1 /usr/sbin/nginx ~/nginx-bin
```

Optional validation if Nginx exists and can run:

```bash
sudo nsurgn enter A1 --root -- /usr/sbin/nginx -t
```

If no shell exists:

```bash
sudo nsurgn enter A1 --root -- /bin/sh
```

Expected failure:

```text
/bin/sh: no such file or directory
```

Emergency shell insertion:

```bash
sudo nsurgn install A1 ./busybox /tmp/busybox
sudo nsurgn enter A1 --root -- /tmp/busybox sh
```

This modifies the target filesystem.

### 22.2 Kubernetes Node Debugging Without Kubernetes Tools

```bash
sudo nsurgn scout
sudo nsurgn inspect A3
sudo nsurgn mounts A3
sudo nsurgn ps A3
```

Purpose:

- Find probable Kubernetes/containerd workloads.
- Inspect cgroups and projected mounts.
- Avoid needing `kubectl`, `crictl`, or `ctr`.

### 22.3 Runtime-Agnostic Forensics

```bash
sudo nsurgn report --with-mounts > nsurgn-report.txt
sudo nsurgn exe A2 --extract ./artifact-A2-exe
sudo nsurgn extract A2 /tmp/suspicious.bin ./suspicious.bin
```

Purpose:

- Capture artifact metadata.
- Extract binaries and suspicious files.
- Avoid runtime sockets.

### 22.4 Understanding Shared Namespace Relationships

```bash
sudo nsurgn tree
sudo nsurgn map A1
sudo nsurgn all --group net
```

Purpose:

- Understand which processes share PID, mount, or network namespaces.
- Identify processes that are related but not parent/child.

### 22.5 Removing a Bad File

```bash
sudo nsurgn exists A1 /tmp/bad.conf
sudo nsurgn stat A1 /tmp/bad.conf
sudo nsurgn remove A1 /tmp/bad.conf --force
```

Dangerous removal refused:

```bash
sudo nsurgn remove A1 /etc --force
```

Expected output:

```text
refusing to remove protected path: /etc
```

---

## 23. Error Handling

### 23.1 Error Philosophy

Errors should be specific and actionable.

Bad:

```text
failed
```

Good:

```text
error: cannot read /proc/18342/root: permission denied
hint: run as root or check ptrace/procfs restrictions
```

### 23.2 Common Error Classes

#### Permission Denied

```text
error: cannot read /proc/18342/environ: permission denied
```

#### Process Disappeared

```text
warning: pid 18379 disappeared during scan
```

#### Target Root Missing

```text
error: leader pid 18342 has no accessible /proc/18342/root
```

#### Ambiguous Artifact

```text
error: artifact A1 no longer exists in current scan
hint: rerun nsurgn list
```

#### Weak Classification Warning

```text
warning: artifact A2 is suspicious but has no runtime hint
warning: verify target before performing file, signal, or enter operations
```

#### Path Safety Refusal

```text
error: target path must be absolute: etc/passwd
error: refusing path traversal: /tmp/../../etc/passwd
error: refusing protected path: /
```

#### Destructive Operation Missing Force

```text
error: remove requires --force
```

#### Bulk Signal Missing `--all`

```text
error: refusing to signal all artifact processes without --all
```

#### Missing `nsenter`

```text
error: nsenter is required for enter mode but was not found in PATH
```

### 23.3 Exit Codes

Suggested exit codes:

```text
0   success
1   general error
2   usage error
3   permission denied
4   target not found
5   unsafe path refused
6   artifact not found
7   partial success
8   process changed/disappeared
9   unsupported platform or missing required Linux feature
```

---

## 24. Privilege Requirements

### 24.1 Read-Only Discovery

Some discovery may work unprivileged.

Likely readable:

```text
/proc/<pid>/status
/proc/<pid>/cmdline
/proc/<pid>/ns/*
```

Possibly restricted:

```text
/proc/<pid>/root
/proc/<pid>/exe
/proc/<pid>/fd
/proc/<pid>/environ
/proc/<pid>/mountinfo
```

### 24.2 Root Recommended

Most useful operations require root:

- reading all process metadata,
- accessing target root filesystems,
- reading executable links,
- copying into root-owned paths,
- extracting protected files,
- removing files,
- signaling processes owned by other users,
- entering namespaces.

Recommended message when non-root:

```text
warning: running without root; results may be incomplete
```

### 24.3 Capabilities

Some operations may work with capabilities rather than full root:

- `CAP_SYS_PTRACE`
- `CAP_DAC_READ_SEARCH`
- `CAP_DAC_OVERRIDE`
- `CAP_KILL`
- `CAP_SYS_ADMIN`

Behavior varies by kernel, procfs mount options, LSMs, and namespace configuration. Do not assume capabilities are sufficient everywhere.

---

## 25. Security Considerations

### 25.1 Environment Variables

`env` is deferred from v1 because `/proc/<pid>/environ` may expose:

- passwords,
- tokens,
- API keys,
- database URLs,
- cloud credentials,
- service account credentials.

### 25.2 Symlink Attacks

A hostile artifact may contain symlinks designed to redirect operations. `nsurgn` must avoid unsafe dereference behavior during writes and removals.

### 25.3 Mount Tricks

A path inside `/proc/<pid>/root` may cross mount boundaries. That may be intended, but it should be visible in verbose and mount inspection output.

Future option:

```text
--one-filesystem
```

### 25.4 Deleted Executables

A deleted executable exposed through `/proc/<pid>/exe` can be valuable for forensics. It can also be misleading because the original path no longer exists.

### 25.5 TOCTOU Risk

Live processes and mutable filesystems create race conditions.

Mitigations:

- resolve and validate immediately before operation,
- use file descriptors where practical,
- warn when target process exits or leader changes,
- avoid multi-step unsafe assumptions.

### 25.6 Runtime Hint Spoofing

Cgroup paths and command lines can be misleading. Runtime hints are evidence, not proof.

### 25.7 Host Damage Risk

Bugs in `/proc/<pid>/root` path handling could damage host files. Conservative validation is mandatory.

### 25.8 No In-Artifact Execution By Default

Only `enter` runs commands in selected namespaces. Other commands must not execute inside the artifact.

### 25.9 No Process Tampering

The project must avoid:

- ptrace injection,
- shellcode,
- LD_PRELOAD injection,
- writing process memory,
- executable mapping manipulation,
- fd hijacking for code execution.

---

## 26. First Release Implementation Plan

The first implementation can be Bash-oriented because Bash arrays and associative maps simplify grouping. POSIX shell is possible but more painful.

### 26.1 Phase 1: Discovery MVP

Commands:

```text
list
all
inspect
ps
```

Features:

- enumerate `/proc/[0-9]*`,
- read namespace IDs,
- read status/cmdline/cgroup,
- build host profile,
- group by default profile mode,
- select leader,
- score artifacts,
- hide host by default.

Core functions:

```text
read_ns_id(pid, ns_name)
read_cmdline(pid)
read_status_field(pid, field)
read_cgroup(pid)
read_ns_pid(pid)
read_start_time(pid)
```

Leader selection:

1. namespace PID equals `1` and PID namespace differs from host,
2. lowest process start time,
3. lowest host PID.

### 26.2 Phase 2: Classification and Reporting

Commands:

```text
report
map
tree
scout
mounts
```

Features:

- detailed artifact reports,
- namespace relationship maps,
- PID namespace tree,
- mountinfo summary,
- runtime hint extraction.

Runtime hint extraction patterns:

```text
kubepods
containerd
docker
crio
cri-containerd
libpod
lxc
machine.slice
```

### 26.3 Phase 3: Read-Only Path Inspection

Commands:

```text
ls
cat
stat
exists
checksum
exe
```

Features:

- target root path resolver,
- absolute path validation,
- symlink-aware inspection,
- executable extraction.

### 26.4 Phase 4: Filesystem Surgery

Commands:

```text
install
inject
extract
remove
```

Features:

- copy in,
- copy out,
- protected path refusal,
- overwrite policy,
- force policy,
- verbose resolved path printing.

### 26.5 Phase 5: Signal Operations

Command:

```text
signal
```

Features:

- signal normalization,
- leader default,
- `--all` bulk behavior,
- host artifact protection,
- weak classification warning.

### 26.6 Phase 6: Explicit Namespace Entry

Command:

```text
enter
```

Features:

- require `nsenter`,
- require `-- command...`,
- default to mount, UTS, IPC, net, PID namespaces,
- user namespace only on explicit `--user`,
- support `--root` only when `nsenter --root` is available,
- support `--wd` only when `nsenter --wd` is available,
- no chroot fallback,
- no shell string construction.

### 26.7 Phase 7: Hardening

- shellcheck,
- bats tests,
- real namespace integration tests,
- path safety regression tests,
- procfs race handling,
- compatibility tests across distributions.

---

## 27. Testing Strategy

### 27.1 Unit Tests

Test parsing functions using fixtures:

```text
fixtures/proc/<pid>/status
fixtures/proc/<pid>/cmdline
fixtures/proc/<pid>/cgroup
fixtures/proc/<pid>/mountinfo
fixtures/proc/<pid>/ns/*
```

Test cases:

- namespace ID parsing,
- cgroup hint parsing,
- cmdline null-byte handling,
- namespace profile creation,
- leader selection,
- score calculation,
- classification,
- path validation,
- signal normalization,
- `enter` argument parsing.

### 27.2 Integration Tests

Use Linux tools:

```text
unshare
nsenter
mount
ip netns
systemd-run
```

Scenarios:

1. Plain host process.
2. Process in new PID namespace.
3. Process in new mount namespace.
4. Process in new network namespace.
5. Process in PID + mount + UTS + IPC namespaces.
6. Process with cgroup path containing fake runtime hint.
7. Process with no runtime hint but namespace isolation.
8. Process that exits during scan.
9. Process with deleted executable.
10. Process with symlink traps.
11. `enter` into namespaces with a known command.
12. `enter --root` when supported.
13. `enter --root` unsupported behavior.
14. `enter --user` warning behavior.

### 27.3 Filesystem Operation Tests

Test:

- install file,
- install directory,
- extract file,
- extract directory,
- remove file,
- refuse remove `/`,
- refuse remove `/etc`,
- refuse relative paths,
- refuse traversal paths,
- refuse symlink overwrite by default.

### 27.4 Permission Tests

Run as:

- root,
- non-root,
- user with partial procfs visibility,
- systems with `hidepid`,
- systems with AppArmor/SELinux restrictions where available.

### 27.5 Compatibility Matrix

Target:

- Debian
- Ubuntu
- Fedora
- Rocky / Alma / RHEL-like systems
- Arch
- Alpine
- cgroup v1 systems
- cgroup v2 systems
- Kubernetes worker nodes

---

## 28. Future Enhancements

Deferred features:

```text
move-in
move-out
fds
env
bundle
diff
policy profiles
cache/index mode
```

Potential future commands:

```bash
nsurgn diff A1 A2
nsurgn bundle A1 ./case-A1
```

Potential future options:

```text
--one-filesystem
--show-mount-boundaries
--refuse-cross-mount
```

Possible runtime hint expansion:

- systemd-nspawn,
- rootless Podman,
- Buildah,
- Kata Containers,
- gVisor,
- Firecracker jailers,
- Nomad task cgroups.

Still no runtime API dependency.

---

## 29. README-Oriented Summary

```text
Discovery:
  nsurgn list
  nsurgn report
  nsurgn scout
  nsurgn all
  nsurgn tree

Inspection:
  nsurgn inspect <artifact-id|pid>
  nsurgn map <artifact-id|pid>
  nsurgn ps <artifact-id|pid>
  nsurgn mounts <artifact-id|pid>
  nsurgn exe <artifact-id|pid>

Filesystem surgery:
  nsurgn install <artifact-id|pid> <host-src> <target-path>
  nsurgn inject <artifact-id|pid> <host-src> <target-path>
  nsurgn extract <artifact-id|pid> <target-path> <host-dest>
  nsurgn remove <artifact-id|pid> <target-path> --force

Process operations:
  nsurgn signal <artifact-id|pid> <signal>
  nsurgn signal <artifact-id|pid> <signal> --all

Path inspection:
  nsurgn ls <artifact-id|pid> <target-path>
  nsurgn cat <artifact-id|pid> <target-path>
  nsurgn stat <artifact-id|pid> <target-path>
  nsurgn exists <artifact-id|pid> <target-path>
  nsurgn checksum <artifact-id|pid> <target-path>

Namespace entry:
  nsurgn enter <artifact-id|pid> [options] -- command...
```

---

## 30. Design Position

Correct framing:

```text
This artifact shares namespaces and metadata commonly associated with containerized workloads.
```

Incorrect framing:

```text
This is definitely a Docker container.
```

Correct framing:

```text
target_root is /proc/18342/root
```

Incorrect framing:

```text
entered the container filesystem
```

Correct framing:

```text
inject is an alias for filesystem copy
```

Incorrect framing:

```text
inject code into the container
```

Correct framing:

```text
enter runs a command in selected namespaces of the artifact leader using nsenter.
```

Incorrect framing:

```text
open a container shell
```

The value of `nsurgn` is not pretending Linux has first-class containers. Its value is making the actual Linux substrate visible, inspectable, and carefully operable when higher-level runtime tooling is missing, broken, restricted, or untrusted.
