#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

error() {
	printf 'error: %s\n' "$*" >&2
}

hint() {
	printf 'hint: %s\n' "$*" >&2
}
