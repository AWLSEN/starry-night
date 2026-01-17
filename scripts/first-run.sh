#!/bin/bash
# first-run.sh - First-time setup for Starry Night plugin
#
# Runs automatically on first session via SessionStart hook (once: true)
# - Creates folder structure
# - Checks for optional dependencies (OpenCode, Codex)
# - Logs availability status (doesn't block if missing)

set -e

COMMS_BASE="$HOME/comms/plans"
PROJECT_NAME="${CLAUDE_PROJECT_NAME:-$(basename "$PWD")}"
PROJECT_DIR="$COMMS_BASE/$PROJECT_NAME"
STATUS_FILE="$COMMS_BASE/.starry-night-status.json"

# Colors (may not render in all contexts)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo "[starry-night] $1"
}

# Create folder structure
setup_folders() {
    mkdir -p "$COMMS_BASE"
    mkdir -p "$PROJECT_DIR/queued/background"
    mkdir -p "$PROJECT_DIR/queued/interactive"
    mkdir -p "$PROJECT_DIR/active"
    mkdir -p "$PROJECT_DIR/review"
    mkdir -p "$PROJECT_DIR/archived"
    mkdir -p "$PROJECT_DIR/logs"

    # Create project config if needed
    if [ ! -f "$PROJECT_DIR/config.json" ]; then
        cat > "$PROJECT_DIR/config.json" << EOF
{
  "projectName": "$PROJECT_NAME",
  "projectPath": "$PWD",
  "createdAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    fi

    log "Folder structure ready: $PROJECT_DIR"
}

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies and write status
check_dependencies() {
    local opencode_available=false
    local codex_available=false
    local claude_available=false

    # Check Claude CLI (required)
    if has_command "claude"; then
        claude_available=true
        log "Claude CLI: available"
    else
        log "Claude CLI: NOT FOUND (required)"
    fi

    # Check OpenCode (optional - for GLM)
    if has_command "opencode"; then
        opencode_available=true
        log "OpenCode: available (GLM models enabled)"
    else
        log "OpenCode: not installed (GLM models disabled)"
        log "  Install: npm i -g opencode-ai@latest"
    fi

    # Check Codex (optional - for architectural analysis)
    if has_command "codex"; then
        codex_available=true
        log "Codex: available (architectural analysis enabled)"
    else
        log "Codex: not installed (architectural analysis disabled)"
        log "  Install: npm i -g @openai/codex"
    fi

    # Write status file
    cat > "$STATUS_FILE" << EOF
{
  "initialized": true,
  "initializedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "dependencies": {
    "claude": $claude_available,
    "opencode": $opencode_available,
    "codex": $codex_available
  },
  "features": {
    "glm_models": $opencode_available,
    "architectural_analysis": $codex_available,
    "native_anthropic": true
  }
}
EOF

    log "Status written to: $STATUS_FILE"
}

# Make plugin scripts executable
setup_scripts() {
    local plugin_root="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"

    chmod +x "$plugin_root/scripts/"*.sh 2>/dev/null || true
    chmod +x "$plugin_root/hooks/"*.sh 2>/dev/null || true

    log "Scripts marked executable"
}

# Main
main() {
    log "First-run setup starting..."

    setup_folders
    check_dependencies
    setup_scripts

    log "Setup complete!"
    log ""
    log "Available commands:"
    log "  /nova  - Create a plan"
    log "  /pulsar - Execute a plan"
    log ""
}

main

# Output empty JSON for hook API
echo '{}'
