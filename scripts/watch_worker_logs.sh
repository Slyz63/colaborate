#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

touch "$LOG_DIR/worker1.log" "$LOG_DIR/worker2.log" "$LOG_DIR/worker3.log"

tail -n 40 -F "$LOG_DIR/worker1.log" | sed -u 's/^/[worker1] /' &
P1=$!
tail -n 40 -F "$LOG_DIR/worker2.log" | sed -u 's/^/[worker2] /' &
P2=$!
tail -n 40 -F "$LOG_DIR/worker3.log" | sed -u 's/^/[worker3] /' &
P3=$!

cleanup() {
  kill "$P1" "$P2" "$P3" >/dev/null 2>&1 || true
}
trap cleanup INT TERM EXIT

wait
