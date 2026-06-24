# nsurgn

`nsurgn` is a Linux command-line utility for inspecting namespace-related
process artifacts through procfs.

This checkout currently provides the executable at:

```sh
./bin/nsurgn
```

There is no installed `nsurgn-v2` command in this repository. From a fresh
checkout, run the tool as `./bin/nsurgn` or put `bin/` on your `PATH`.

## Current Status

The current executable reports version `0.1.0` and implements a tested subset
of the v1 command contract.

Implemented commands:

- `list`
- `all`
- `tree`
- `report`
- `inspect`
- `exists`
- `cat`
- `checksum`
- `extract`
- `install`
- `inject`
- `remove`
- `enter` argument validation only

Commands documented as part of the broader v1 specification but not currently
implemented include `scout`, `map`, `ps`, `mounts`, `exe`, `signal`, `ls`, and
`stat`. Those commands return an unknown-command error in this checkout.

`enter` currently checks for the required `--` separator, but namespace command
execution is not implemented yet.

## Quick Start

Print usage and version:

```sh
./bin/nsurgn --help
./bin/nsurgn --version
```

List discovered non-host namespace artifacts:

```sh
./bin/nsurgn --quiet list
```

Include host-classified processes in discovery output:

```sh
./bin/nsurgn --quiet --include-host list
```

List all visible PIDs with namespace metadata:

```sh
./bin/nsurgn --quiet all
```

Print a PID namespace tree:

```sh
./bin/nsurgn --quiet tree
```

Use a specific PID as the host profile reference:

```sh
./bin/nsurgn --quiet --host-pid 1 tree
```

## Inspect A Process

Current artifact IDs are not persistent across invocations. For the implemented
read-only commands, an explicit host PID is the most predictable target form:

```sh
./bin/nsurgn inspect pid:1
./bin/nsurgn report --artifact pid:1
./bin/nsurgn report --artifact pid:1 --with-mounts
```

`inspect` and `report --artifact` exit `4` when the PID does not exist. An
unresolved artifact ID such as `A9999` exits `6` and suggests rerunning
`nsurgn list`.

## Read Files Through A Target Root

File-reading commands resolve target paths through:

```text
/proc/<pid>/root/<absolute-target-path-without-leading-slash>
```

Check whether a path exists:

```sh
./bin/nsurgn exists pid:1 /etc/hostname
```

Print file contents:

```sh
./bin/nsurgn cat pid:1 /etc/hostname
./bin/nsurgn cat pid:1 /etc/hostname --max-bytes 64
```

Write a checksum:

```sh
./bin/nsurgn checksum pid:1 /etc/hostname
./bin/nsurgn checksum pid:1 /etc/hostname --sha512
./bin/nsurgn checksum pid:1 /etc/hostname --md5
```

Relative target paths and paths containing `.` or `..` components are refused.
`cat` and `checksum` refuse symlink targets.

## Copy Files

Copy a file out of the target root:

```sh
./bin/nsurgn extract pid:1 /etc/hostname ./hostname.copy
```

The destination must not already exist.

Copy a regular host file into the target root:

```sh
./bin/nsurgn install pid:1 ./replacement.conf /tmp/replacement.conf
```

`inject` is an alias for `install` in this checkout:

```sh
./bin/nsurgn inject pid:1 ./replacement.conf /tmp/replacement.conf
```

`install` and `inject` refuse symlink sources, missing sources, and non-regular
sources. Existing targets are refused.

## Remove A File

`remove` is destructive and requires `--force`:

```sh
./bin/nsurgn remove pid:1 /tmp/replacement.conf --force
```

The command refuses protected target paths such as `/`, `/etc`, `/usr`, `/bin`,
`/proc`, `/sys`, `/dev`, and `/run`.

Directory-recursive removal is specified in the man page but is not implemented
in the current executable. Passing a directory to `remove --force` is not a
completed user-facing behavior yet.

## Reference Documentation

The command reference is in:

```text
doc/nsurgn.1.md
```

The broader v1 product specification is in:

```text
nsurgn_specification_v1.0.md
```

The specification describes intended v1 behavior. It is not a completion claim
for the current `0.1.0` executable.

## Verification

Run the acceptance tests with:

```sh
bats tests
```

The repository definition of done also uses:

```sh
shellcheck bin/* lib/*.sh tests/*.bats
shfmt -d .
./bin/nsurgn --help
./bin/nsurgn --version
```
