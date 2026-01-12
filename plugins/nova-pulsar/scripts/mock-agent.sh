#!/bin/bash
# Mock agent for testing status file polling
# Usage: NEUTRON_TASK_ID=phase-1-test ./mock-agent.sh [duration_seconds]
#
# This script simulates a background agent to test the status file polling
# mechanism without spawning real Claude agents.

set -euo pipefail

DURATION="${1:-5}"
STATUS_DIR="./comms/status"

if [[ -z "${NEUTRON_TASK_ID:-}" ]]; then
    echo "Error: NEUTRON_TASK_ID environment variable required"
    echo "Usage: NEUTRON_TASK_ID=phase-1-test $0 [duration_seconds]"
    exit 1
fi

mkdir -p "$STATUS_DIR"

# Write running status
cat > "$STATUS_DIR/$NEUTRON_TASK_ID.status" << EOF
{
  "task_id": "$NEUTRON_TASK_ID",
  "status": "running",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tool_count": 0
}
EOF

echo "Mock agent started: $NEUTRON_TASK_ID (${DURATION}s)"

# Simulate work with periodic status updates
for ((i=1; i<=$DURATION; i++)); do
    sleep 1
    cat > "$STATUS_DIR/$NEUTRON_TASK_ID.status" << EOF
{
  "task_id": "$NEUTRON_TASK_ID",
  "status": "running",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tool_count": $i,
  "last_tool": "mock_tool_$i"
}
EOF
done

# Write completed status
cat > "$STATUS_DIR/$NEUTRON_TASK_ID.status" << EOF
{
  "task_id": "$NEUTRON_TASK_ID",
  "status": "completed",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tool_count": $DURATION
}
EOF

echo "Mock agent completed: $NEUTRON_TASK_ID"
