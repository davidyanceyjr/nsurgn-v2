setup() {
	PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
	TOOL="$PROJECT_ROOT/bin/nsurgn"
	TEST_TMPDIR="$(mktemp -d)"
	STDOUT_FILE="$TEST_TMPDIR/stdout"
	STDERR_FILE="$TEST_TMPDIR/stderr"
}

teardown() {
	rm -rf "$TEST_TMPDIR"
}

run_cli() {
	"$TOOL" "$@" >"$STDOUT_FILE" 2>"$STDERR_FILE"
}

captured_stdout() {
	cat "$STDOUT_FILE"
}

captured_stderr() {
	cat "$STDERR_FILE"
}

@test "--help prints usage to stdout and exits 0" {
	run run_cli --help

	[ "$status" -eq 0 ]
	[[ "$(captured_stdout)" == *"nsurgn"* ]]
	[[ "$(captured_stdout)" == *"list"* ]]
	[ "$(captured_stderr)" = "" ]
}

@test "--version prints documented version and exits 0" {
	run run_cli --version

	[ "$status" -eq 0 ]
	[ "$(captured_stdout)" = "nsurgn 0.1.0" ]
	[ "$(captured_stderr)" = "" ]
}

@test "unknown command writes an error to stderr and exits 2" {
	run run_cli no-such-command

	[ "$status" -eq 2 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == error:* ]]
}

@test "unknown option writes an error to stderr and exits 2" {
	run run_cli --no-such-option

	[ "$status" -eq 2 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == error:* ]]
}

@test "missing required inspect target writes an error and exits 2" {
	run run_cli inspect

	[ "$status" -eq 2 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == error:* ]]
}

@test "list completes a quiet scan without stderr diagnostics" {
	run run_cli --quiet list

	[ "$status" -eq 0 ]
	[ "$(captured_stderr)" = "" ]
	if [ -n "$(captured_stdout)" ]; then
		[[ "$(captured_stdout)" == *"ARTIFACT  CLASSIFICATION  SCORE  LEADER  NSPID  PROCS  RUNTIME_HINT  COMMAND"* ]]
	fi
}

@test "list with include-host shows the current host process" {
	run run_cli --quiet --include-host list

	[ "$status" -eq 0 ]
	[[ "$(captured_stdout)" == *"ARTIFACT  CLASSIFICATION  SCORE  LEADER  NSPID  PROCS  RUNTIME_HINT  COMMAND"* ]]
	awk -v pid="$$" '
		$4 == pid && $2 == "host" && $3 == "0" && $6 == "1" && $7 == "none" {
			found = 1
		}
		END {
			exit found ? 0 : 1
		}
	' "$STDOUT_FILE"
	[ "$(captured_stderr)" = "" ]
}

@test "all prints the documented process table header and exits 0" {
	run run_cli --quiet all

	[ "$status" -eq 0 ]
	[[ "$(captured_stdout)" == *"HOSTPID  PPID  NSPID  PID_NS  MNT_NS  NET_NS  USER_NS  UTS_NS  IPC_NS  CGROUP_NS  TIME_NS  CGROUP_HINT  COMMAND"* ]]
	[ "$(captured_stderr)" = "" ]
}

@test "all includes the current process with namespace metadata" {
	run run_cli --quiet all

	[ "$status" -eq 0 ]
	awk -v pid="$$" '
		$1 == pid {
			found = 1
			for (field = 1; field <= 12; field++) {
				if ($field == "") {
					exit 2
				}
			}
		}
		END {
			exit found ? 0 : 1
		}
	' "$STDOUT_FILE"
	[ "$(captured_stderr)" = "" ]
}

@test "inspect of a visible host pid prints metadata and exits 0" {
	run run_cli --include-host inspect "pid:$$"

	[ "$status" -eq 0 ]
	[[ "$(captured_stdout)" == *"classification"* ]]
	[[ "$(captured_stdout)" == *"target root"* ]]
	[ "$(captured_stderr)" = "" ]
}

@test "inspect of a missing host pid exits 4 with stderr diagnostic" {
	run run_cli inspect pid:999999999

	[ "$status" -eq 4 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == error:* ]]
}

@test "inspect of an unresolved artifact id exits 6 and suggests rerunning list" {
	run run_cli inspect A9999

	[ "$status" -eq 6 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == *"artifact A9999"* ]]
	[[ "$(captured_stderr)" == *"hint: rerun nsurgn list"* ]]
}

@test "relative target paths are refused before reading files" {
	run run_cli cat "pid:$$" relative/path

	[ "$status" -eq 5 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == *"error: target path must be absolute: relative/path"* ]]
}

@test "exists returns 1 and empty stdout when the target path is absent" {
	missing_path="$TEST_TMPDIR/missing"

	run run_cli exists "pid:$$" "$missing_path"

	[ "$status" -eq 1 ]
	[ "$(captured_stdout)" = "" ]
}

@test "cat writes file contents from the target root to stdout" {
	target_path="$TEST_TMPDIR/example.txt"
	printf 'abcdef\n' >"$target_path"

	run run_cli cat "pid:$$" "$target_path" --max-bytes 3

	[ "$status" -eq 0 ]
	[ "$(captured_stdout)" = "abc" ]
	[ "$(captured_stderr)" = "" ]
}

@test "checksum writes the default sha256 digest to stdout" {
	target_path="$TEST_TMPDIR/checksum.txt"
	printf 'payload' >"$target_path"
	expected_digest="$(sha256sum "$target_path" | awk '{print $1}')"

	run run_cli checksum "pid:$$" "$target_path"

	[ "$status" -eq 0 ]
	[ "$(captured_stdout)" = "sha256  $expected_digest  $target_path" ]
	[ "$(captured_stderr)" = "" ]
}

@test "extract copies a target-root file to a host destination" {
	source_path="$TEST_TMPDIR/source.txt"
	dest_path="$TEST_TMPDIR/extracted.txt"
	printf 'extract me\n' >"$source_path"

	run run_cli extract "pid:$$" "$source_path" "$dest_path"

	[ "$status" -eq 0 ]
	[ "$(cat "$dest_path")" = "extract me" ]
	[[ "$(captured_stdout)" == "copied: "* ]]
	[[ "$(captured_stdout)" == *" -> $dest_path" ]]
	[ "$(captured_stderr)" = "" ]
}

@test "install copies a host file into the target root" {
	source_path="$TEST_TMPDIR/install-source.txt"
	target_path="$TEST_TMPDIR/installed.txt"
	printf 'install me\n' >"$source_path"

	run run_cli install "pid:$$" "$source_path" "$target_path"

	[ "$status" -eq 0 ]
	[ "$(cat "$target_path")" = "install me" ]
	[[ "$(captured_stdout)" == "copied: $source_path -> "* ]]
	[ "$(captured_stderr)" = "" ]
}

@test "remove without --force is refused and leaves the target file in place" {
	target_path="$TEST_TMPDIR/remove-without-force.txt"
	printf 'keep me\n' >"$target_path"

	run run_cli remove "pid:$$" "$target_path"

	[ "$status" -eq 2 ]
	[ -f "$target_path" ]
	[ "$(cat "$target_path")" = "keep me" ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == *"error: remove requires --force"* ]]
}

@test "remove with --force deletes the target path and reports the file effect" {
	target_path="$TEST_TMPDIR/remove-me.txt"
	printf 'delete me\n' >"$target_path"

	run run_cli remove "pid:$$" "$target_path" --force

	[ "$status" -eq 0 ]
	[ ! -e "$target_path" ]
	[[ "$(captured_stdout)" == "removed: "* ]]
	[ "$(captured_stderr)" = "" ]
}

@test "remove with --force refuses protected target paths" {
	run run_cli remove "pid:$$" /etc --force

	[ "$status" -eq 5 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == *"error: refusing protected path: /etc"* ]]
}

@test "enter without required separator exits 2 with stderr diagnostic" {
	run run_cli enter "pid:$$" /bin/true

	[ "$status" -eq 2 ]
	[ "$(captured_stdout)" = "" ]
	[[ "$(captured_stderr)" == error:* ]]
}
