#!/bin/bash
# Neutron Status Update Hook v2
# Compact status format with tool diversity tracking
#
# Updates ./comms/status/{TASK_ID}.status after each tool use
#
# New format (KISS, token-efficient):
#   id    - Task identifier
#   s     - Status: run|done|err
#   t     - Last updated timestamp
#   n     - Tool count
#   tools - Last 5 tools (for diversity/loop detection)
#   file  - Last file touched
#   stage - Inferred: explore|impl|test|clean
#
# Environment:
#   NEUTRON_TASK_ID - Task identifier (e.g., "phase-1-plan-20260110-1430")
#   NEUTRON_HOOK_EVENT - Set to "stop" when called from Stop hook
#   NEUTRON_PROJECT_DIR - Optional: override project directory

set -euo pipefail

# Exit silently if not a tracked task
if [[ -z "${NEUTRON_TASK_ID:-}" ]]; then
    exit 0
fi

# Status file location (project-relative)
PROJECT_DIR="${NEUTRON_PROJECT_DIR:-$(pwd)}"
STATUS_DIR="${PROJECT_DIR}/comms/status"
STATUS_FILE="${STATUS_DIR}/${NEUTRON_TASK_ID}.status"
TMP_FILE="${STATUS_FILE}.tmp"

mkdir -p "$STATUS_DIR"

# Handle Stop hook - mark as completed
if [[ "${NEUTRON_HOOK_EVENT:-}" == "stop" ]]; then
    if [[ -f "$STATUS_FILE" ]]; then
        jq '.s = "done"' "$STATUS_FILE" > "$TMP_FILE"
        mv "$TMP_FILE" "$STATUS_FILE"
    fi
    exit 0
fi

# Read input from stdin
input=$(cat)

# Extract tool info
tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')
tool_input=$(echo "$input" | jq -c '.tool_input // {}')

# Extract file path (varies by tool)
file=$(echo "$tool_input" | jq -r '
    .file_path //
    .path //
    .notebook_path //
    (if .command then
        (.command | capture("(?<f>/[^\\s]+\\.[a-z]+)") | .f) // null
    else null end) //
    null
')

# Current timestamp
t=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read existing or initialize
if [[ -f "$STATUS_FILE" ]]; then
    existing=$(cat "$STATUS_FILE")
    n=$(echo "$existing" | jq -r '.n // 0')
    tools=$(echo "$existing" | jq -c '.tools // []')
else
    n=0
    tools="[]"
fi

# Increment tool count
n=$((n + 1))

# Append tool to array, keep last 5
tools=$(echo "$tools" | jq -c --arg t "$tool_name" '(. + [$t])[-5:]')

# Infer stage from tool distribution
stage=$(echo "$tools" | jq -r '
    (map(select(. == "Read" or . == "Grep" or . == "Glob")) | length) as $read |
    (map(select(. == "Bash")) | length) as $bash |
    (map(select(. == "Edit" or . == "Write")) | length) as $edit |
    if $read >= 4 then "explore"
    elif $bash >= 3 then "test"
    elif $edit >= 2 then "impl"
    else "impl"
    end
')

# Build compact status JSON
jq -n \
    --arg id "$NEUTRON_TASK_ID" \
    --arg s "run" \
    --arg t "$t" \
    --argjson n "$n" \
    --argjson tools "$tools" \
    --arg file "$file" \
    --arg stage "$stage" \
    '{
        id: $id,
        s: $s,
        t: $t,
        n: $n,
        tools: $tools,
        file: (if $file == "null" or $file == "" then null else $file end),
        stage: $stage
    }' > "$TMP_FILE"

# Atomic write
mv "$TMP_FILE" "$STATUS_FILE"

exit 0
