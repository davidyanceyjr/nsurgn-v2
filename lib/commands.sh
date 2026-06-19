#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

NSURGN_VERSION="0.1.0"

usage() {
	cat <<'EOF'
nsurgn - inspect and operate on Linux namespace artifacts through procfs

Usage:
  nsurgn [OPTIONS] COMMAND [ARGUMENTS]
  nsurgn --help
  nsurgn --version

Commands:
  list
  all
  inspect ARTIFACT_OR_PID
  cat ARTIFACT_OR_PID TARGET_PATH [--max-bytes BYTES]
  checksum ARTIFACT_OR_PID TARGET_PATH [--sha256|--sha512|--md5]
  exists ARTIFACT_OR_PID TARGET_PATH
  extract ARTIFACT_OR_PID TARGET_PATH HOST_DEST
  install ARTIFACT_OR_PID HOST_SRC TARGET_PATH
  remove ARTIFACT_OR_PID TARGET_PATH --force
  enter ARTIFACT_OR_PID [OPTIONS] -- COMMAND [ARGS...]
EOF
}

version() {
	printf 'nsurgn %s\n' "$NSURGN_VERSION"
}

require_arg() {
	local value="${1-}"
	local name="$2"

	if [[ -z "$value" ]]; then
		error "missing required argument: $name"
		return 2
	fi
}

parse_target_pid() {
	local target="$1"

	case "$target" in
	pid:[0-9]*)
		printf '%s\n' "${target#pid:}"
		;;
	[0-9]*)
		printf '%s\n' "$target"
		;;
	A[0-9]*)
		error "artifact $target no longer exists in current scan"
		hint "rerun nsurgn list"
		return 6
		;;
	*)
		error "invalid target: $target"
		return 2
		;;
	esac
}

target_root_for() {
	local target="$1"
	local pid

	pid="$(parse_target_pid "$target")" || return "$?"
	if [[ ! -d "/proc/$pid" ]]; then
		error "target pid not found: $pid"
		return 4
	fi
	printf '/proc/%s/root\n' "$pid"
}

validate_target_path() {
	local path="$1"

	if [[ "$path" != /* ]]; then
		error "target path must be absolute: $path"
		return 5
	fi
	if [[ "$path" == *"/../"* || "$path" == *"/./"* || "$path" == */.. || "$path" == */. ]]; then
		error "refusing path traversal: $path"
		return 5
	fi
}

refuse_protected_remove_path() {
	local path="$1"

	case "$path" in
	/ | /etc | /usr | /bin | /sbin | /lib | /lib64 | /proc | /sys | /dev | /run)
		error "refusing protected path: $path"
		return 5
		;;
	esac
}

resolve_target_path() {
	local target="$1"
	local path="$2"
	local root

	validate_target_path "$path" || return "$?"
	root="$(target_root_for "$target")" || return "$?"
	printf '%s/%s\n' "$root" "${path#/}"
}

namespace_id_for() {
	local pid="$1"
	local name="$2"
	local link

	link="$(readlink "/proc/$pid/ns/$name" 2>/dev/null)" || return 1
	link="${link#*[}"
	link="${link%]}"
	printf '%s\n' "$link"
}

status_values_for() {
	local pid="$1"

	awk '
		/^PPid:/ {
			ppid = $2
		}
		/^NSpid:/ {
			nspid = $NF
		}
		END {
			if (ppid == "") {
				exit 1
			}
			if (nspid == "") {
				nspid = "-"
			}
			printf "%s\n%s\n", ppid, nspid
		}
	' "/proc/$pid/status" 2>/dev/null
}

cgroup_hint_for() {
	local pid="$1"
	local cgroup=""
	local hints=()
	local hint

	cgroup="$(cat "/proc/$pid/cgroup" 2>/dev/null)" || {
		printf 'none\n'
		return 0
	}

	[[ "$cgroup" == *"kubepods"* ]] && hints+=("k8s")
	[[ "$cgroup" == *"containerd"* ]] && hints+=("containerd")
	[[ "$cgroup" == *"docker"* ]] && hints+=("docker")
	[[ "$cgroup" == *"crio"* ]] && hints+=("crio")
	[[ "$cgroup" == *"libpod"* ]] && hints+=("libpod")
	[[ "$cgroup" == *"lxc"* ]] && hints+=("lxc")
	[[ "$cgroup" == *"machine.slice"* ]] && hints+=("systemd")

	if ((${#hints[@]} == 0)); then
		printf 'none\n'
		return 0
	fi

	local IFS=/
	hint="${hints[*]}"
	printf '%s\n' "$hint"
}

command_for() {
	local pid="$1"
	local command=""

	command="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null || true)"
	command="${command% }"
	if [[ -z "$command" && -r "/proc/$pid/comm" ]]; then
		IFS= read -r command <"/proc/$pid/comm" || true
	fi
	if [[ -z "$command" ]]; then
		command="-"
	fi
	printf '%s\n' "$command"
}

cmd_list() {
	local include_host="${NSURGN_INCLUDE_HOST:-0}"
	local proc_path
	local pid
	local status_values
	local nspid
	local command
	local artifact_index=1

	if ((include_host == 0)); then
		return 0
	fi

	printf 'ARTIFACT  CLASSIFICATION  SCORE  LEADER  NSPID  PROCS  RUNTIME_HINT  COMMAND\n'

	for proc_path in /proc/[0-9]*; do
		[[ -d "$proc_path" ]] || continue
		pid="${proc_path#/proc/}"

		status_values="$(status_values_for "$pid")" || continue
		nspid="${status_values##*$'\n'}"
		command="$(command_for "$pid")"

		printf 'A%s  host  0  %s  %s  1  none  %s\n' \
			"$artifact_index" "$pid" "$nspid" "$command"
		artifact_index=$((artifact_index + 1))
	done
}

cmd_all() {
	local quiet="${NSURGN_QUIET:-0}"
	local proc_path
	local pid
	local status_values
	local ppid
	local nspid
	local pid_ns
	local mnt_ns
	local net_ns
	local user_ns
	local uts_ns
	local ipc_ns
	local cgroup_ns
	local time_ns
	local cgroup_hint
	local command

	printf 'HOSTPID  PPID  NSPID  PID_NS  MNT_NS  NET_NS  USER_NS  UTS_NS  IPC_NS  CGROUP_NS  TIME_NS  CGROUP_HINT  COMMAND\n'

	for proc_path in /proc/[0-9]*; do
		[[ -d "$proc_path" ]] || continue
		pid="${proc_path#/proc/}"

		if ! status_values="$(status_values_for "$pid")"; then
			if ((quiet == 0)); then
				printf 'warning: skipped disappeared pid: %s\n' "$pid" >&2
			fi
			continue
		fi
		ppid="${status_values%%$'\n'*}"
		nspid="${status_values##*$'\n'}"

		if ! pid_ns="$(namespace_id_for "$pid" pid)" ||
			! mnt_ns="$(namespace_id_for "$pid" mnt)" ||
			! net_ns="$(namespace_id_for "$pid" net)" ||
			! user_ns="$(namespace_id_for "$pid" user)" ||
			! uts_ns="$(namespace_id_for "$pid" uts)" ||
			! ipc_ns="$(namespace_id_for "$pid" ipc)" ||
			! cgroup_ns="$(namespace_id_for "$pid" cgroup)" ||
			! time_ns="$(namespace_id_for "$pid" time)"; then
			if ((quiet == 0)); then
				printf 'warning: skipped disappeared pid: %s\n' "$pid" >&2
			fi
			continue
		fi

		cgroup_hint="$(cgroup_hint_for "$pid")"
		command="$(command_for "$pid")"
		printf '%s  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s  %s\n' \
			"$pid" "$ppid" "$nspid" "$pid_ns" "$mnt_ns" "$net_ns" "$user_ns" \
			"$uts_ns" "$ipc_ns" "$cgroup_ns" "$time_ns" "$cgroup_hint" "$command"
	done
}

cmd_inspect() {
	local target="${1-}"
	local root
	local pid

	require_arg "$target" "ARTIFACT_OR_PID" || return "$?"
	root="$(target_root_for "$target")" || return "$?"
	pid="$(parse_target_pid "$target")" || return "$?"

	cat <<EOF
artifact: pid:$pid
classification: host
score: 0
leader: $pid
target root: $root
process count: 1
runtime hint: none
EOF
}

cmd_exists() {
	local target="${1-}"
	local target_path="${2-}"
	local resolved

	require_arg "$target" "ARTIFACT_OR_PID" || return "$?"
	require_arg "$target_path" "TARGET_PATH" || return "$?"
	resolved="$(resolve_target_path "$target" "$target_path")" || return "$?"
	[[ -e "$resolved" ]]
}

cmd_cat() {
	local target="${1-}"
	local target_path="${2-}"
	local max_bytes=""
	local resolved

	require_arg "$target" "ARTIFACT_OR_PID" || return "$?"
	require_arg "$target_path" "TARGET_PATH" || return "$?"
	shift 2
	while (($#)); do
		case "$1" in
		--max-bytes)
			shift
			require_arg "${1-}" "BYTES" || return "$?"
			max_bytes="$1"
			;;
		*)
			error "unknown option for cat: $1"
			return 2
			;;
		esac
		shift
	done

	resolved="$(resolve_target_path "$target" "$target_path")" || return "$?"
	if [[ ! -e "$resolved" ]]; then
		error "target path not found: $target_path"
		return 4
	fi
	if [[ -d "$resolved" ]]; then
		error "target path is a directory: $target_path"
		return 1
	fi
	if [[ -n "$max_bytes" ]]; then
		head -c "$max_bytes" "$resolved"
	else
		cat "$resolved"
	fi
}

cmd_checksum() {
	local target="${1-}"
	local target_path="${2-}"
	local algorithm="sha256"
	local resolved
	local digest

	require_arg "$target" "ARTIFACT_OR_PID" || return "$?"
	require_arg "$target_path" "TARGET_PATH" || return "$?"
	shift 2
	while (($#)); do
		case "$1" in
		--sha256)
			algorithm="sha256"
			;;
		--sha512)
			algorithm="sha512"
			;;
		--md5)
			algorithm="md5"
			;;
		*)
			error "unknown option for checksum: $1"
			return 2
			;;
		esac
		shift
	done

	resolved="$(resolve_target_path "$target" "$target_path")" || return "$?"
	if [[ ! -e "$resolved" ]]; then
		error "target path not found: $target_path"
		return 4
	fi

	case "$algorithm" in
	sha256)
		digest="$(sha256sum "$resolved" | awk '{print $1}')"
		;;
	sha512)
		digest="$(sha512sum "$resolved" | awk '{print $1}')"
		;;
	md5)
		digest="$(md5sum "$resolved" | awk '{print $1}')"
		;;
	esac
	printf '%s  %s  %s\n' "$algorithm" "$digest" "$target_path"
}

cmd_extract() {
	local target="${1-}"
	local target_path="${2-}"
	local host_dest="${3-}"
	local resolved

	require_arg "$target" "ARTIFACT_OR_PID" || return "$?"
	require_arg "$target_path" "TARGET_PATH" || return "$?"
	require_arg "$host_dest" "HOST_DEST" || return "$?"
	resolved="$(resolve_target_path "$target" "$target_path")" || return "$?"
	if [[ ! -e "$resolved" ]]; then
		error "target path not found: $target_path"
		return 4
	fi
	if [[ -e "$host_dest" ]]; then
		error "destination path already exists: $host_dest"
		return 1
	fi

	cp -P "$resolved" "$host_dest"
	printf 'copied: %s -> %s\n' "$resolved" "$host_dest"
}

cmd_install() {
	local target="${1-}"
	local host_src="${2-}"
	local target_path="${3-}"
	local resolved

	require_arg "$target" "ARTIFACT_OR_PID" || return "$?"
	require_arg "$host_src" "HOST_SRC" || return "$?"
	require_arg "$target_path" "TARGET_PATH" || return "$?"
	if [[ ! -e "$host_src" ]]; then
		error "source path not found: $host_src"
		return 4
	fi
	resolved="$(resolve_target_path "$target" "$target_path")" || return "$?"
	if [[ -e "$resolved" ]]; then
		error "target path already exists: $target_path"
		return 1
	fi

	cp -P "$host_src" "$resolved"
	printf 'copied: %s -> %s\n' "$host_src" "$resolved"
}

cmd_remove() {
	local target="${1-}"
	local target_path="${2-}"
	local force=0
	local resolved

	require_arg "$target" "ARTIFACT_OR_PID" || return "$?"
	require_arg "$target_path" "TARGET_PATH" || return "$?"
	shift 2
	while (($#)); do
		case "$1" in
		--force)
			force=1
			;;
		*)
			error "unknown option for remove: $1"
			return 2
			;;
		esac
		shift
	done

	if ((force == 0)); then
		error "remove requires --force"
		return 2
	fi
	refuse_protected_remove_path "$target_path" || return "$?"
	resolved="$(resolve_target_path "$target" "$target_path")" || return "$?"
	if [[ ! -e "$resolved" && ! -L "$resolved" ]]; then
		error "target path not found: $target_path"
		return 4
	fi
	rm -- "$resolved"
	printf 'removed: %s\n' "$resolved"
}

cmd_enter() {
	local found_separator=0

	require_arg "${1-}" "ARTIFACT_OR_PID" || return "$?"
	shift
	while (($#)); do
		if [[ "$1" == "--" ]]; then
			found_separator=1
			break
		fi
		shift
	done
	if ((found_separator == 0)); then
		error "enter requires -- before COMMAND"
		return 2
	fi
	error "enter execution is not implemented by this minimal contract"
	return 9
}

dispatch_command() {
	local command="${1-}"

	require_arg "$command" "COMMAND" || return "$?"
	shift
	case "$command" in
	list)
		cmd_list "$@"
		;;
	all)
		cmd_all "$@"
		;;
	inspect)
		cmd_inspect "$@"
		;;
	exists)
		cmd_exists "$@"
		;;
	cat)
		cmd_cat "$@"
		;;
	checksum)
		cmd_checksum "$@"
		;;
	extract)
		cmd_extract "$@"
		;;
	install | inject)
		cmd_install "$@"
		;;
	remove)
		cmd_remove "$@"
		;;
	enter)
		cmd_enter "$@"
		;;
	*)
		error "unknown command: $command"
		return 2
		;;
	esac
}

nsurgn_main() {
	local include_host=0
	local quiet=0

	if (($# == 0)); then
		usage
		return 2
	fi

	while (($#)); do
		case "$1" in
		--help)
			usage
			return 0
			;;
		--version)
			version
			return 0
			;;
		--include-host)
			include_host=1
			;;
		--quiet)
			quiet=1
			;;
		--no-color | --verbose | --no-runtime-hints | --no-mount-scan)
			:
			;;
		--group | --format | --host-pid)
			shift
			require_arg "${1-}" "$1 value" || return "$?"
			;;
		--*)
			error "unknown option: $1"
			return 2
			;;
		*)
			NSURGN_INCLUDE_HOST="$include_host" NSURGN_QUIET="$quiet" dispatch_command "$@"
			return "$?"
			;;
		esac
		shift
	done

	error "missing required argument: COMMAND"
	return 2
}
