#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKER_DIR="$ROOT_DIR/.workers"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$WORKER_DIR" "$LOG_DIR"

ensure_gemini() {
  command -v gemini >/dev/null 2>&1 || {
    echo "gemini CLI not found" >&2
    return 1
  }
  gemini -p "Reply with exactly READY" >"$LOG_DIR/gemini-health.log" 2>&1 || {
    echo "gemini CLI auth/execution check failed" >&2
    return 1
  }
  grep -q "READY" "$LOG_DIR/gemini-health.log" || {
    echo "gemini CLI health check response missing READY" >&2
    return 1
  }
}

ensure_worktree() {
  local branch="$1"
  local path="$2"

  if [ -d "$path/.git" ] || [ -f "$path/.git" ]; then
    return
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$path" "$branch"
  else
    git worktree add -b "$branch" "$path" main
  fi
}

start_worker() {
  local id="$1"
  local path="$2"
  local prompt_file="$3"
  local pid_file="$4"
  local log_file="$LOG_DIR/${id}.log"
  (
    cd "$path"
    {
      echo "[$(date '+%F %T')] start $id"
      gemini -y -p "$(cat "$prompt_file")"
      echo "[$(date '+%F %T')] end $id"
    } >"$log_file" 2>&1
  ) &
  local pid=$!
  echo "$pid" > "$pid_file"
  echo "$pid"
}

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "must run inside git repository" >&2
  exit 1
fi

ensure_gemini

echo "Preparing worktrees..."
ensure_worktree worker1-impl-a "$WORKER_DIR/worker1"
ensure_worktree worker2-impl-b "$WORKER_DIR/worker2"
ensure_worktree worker3-test "$WORKER_DIR/worker3"

echo "Launching workers..."
start_worker worker1 "$WORKER_DIR/worker1" "$ROOT_DIR/orchestration/worker1.prompt.txt" "$LOG_DIR/worker1.pid" >/dev/null
start_worker worker2 "$WORKER_DIR/worker2" "$ROOT_DIR/orchestration/worker2.prompt.txt" "$LOG_DIR/worker2.pid" >/dev/null
start_worker worker3 "$WORKER_DIR/worker3" "$ROOT_DIR/orchestration/worker3.prompt.txt" "$LOG_DIR/worker3.pid" >/dev/null

PID1="$(cat "$LOG_DIR/worker1.pid")"
PID2="$(cat "$LOG_DIR/worker2.pid")"
PID3="$(cat "$LOG_DIR/worker3.pid")"

echo "PIDs: worker1=$PID1 worker2=$PID2 worker3=$PID3"

echo "Waiting for workers to finish..."
set +e
wait "$PID1"; S1=$?
wait "$PID2"; S2=$?
wait "$PID3"; S3=$?
set -e

cat > "$LOG_DIR/status.txt" <<STATUS
worker1_exit=$S1
worker2_exit=$S2
worker3_exit=$S3
STATUS

echo "Completed. Statuses written to $LOG_DIR/status.txt"
