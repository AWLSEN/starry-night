# Nova-Pulsar

Planning and execution framework for Claude Code with intelligent scheduling.

## Overview

Nova-Pulsar is a Claude Code plugin that separates planning from execution:

- **Nova** (`/nova`) - Intelligent planning agent that researches your codebase, asks clarifying questions, and creates structured execution plans
- **Pulsar** (`/pulsar`) - Execution agent that implements plans with maximum parallelization
- **Orbiter** - Background scheduler that intelligently picks which plan to execute next
- **Merge** (`/merge`) - Merges completed worktrees into main
- **Archive** (`/archive`) - Discards plans without merging

## Installation

1. Clone this repo to `~/.claude/plugins/nova-pulsar`
2. Add to `~/.claude/plugins/installed_plugins.json`:
```json
"nova-pulsar": [{
  "scope": "user",
  "installPath": "/path/to/.claude/plugins/nova-pulsar",
  "version": "2.0.0",
  "isLocal": true
}]
```
3. Enable in `~/.claude/settings.json`:
```json
"enabledPlugins": {
  "nova-pulsar": true
}
```
4. Restart Claude Code

## Commands

### `/nova` - Create a Plan

Nova is a planning-only agent that:
- Uses inner monologue to predict what research is needed
- Launches dynamic number of explore agents (not hardcoded)
- Iterates research until ready to plan
- Asks clarifying questions using AskUserQuestion
- Creates structured plans with parallelization analysis

### `/pulsar [plan-id]` - Execute a Plan

Pulsar executes plans with:
- Intelligent parallelization (analyzes dependencies, maximizes parallel execution)
- Quality gates after each round (Dead Code Agent + Test Agent in parallel)
- TDD approach (write tests if none exist)
- Git worktree isolation
- Autonomous execution (no user interaction mid-execution)

### `/merge <plan-id>` - Merge Completed Plan

Merges the worktree branch into main and cleans up.

### `/archive <plan-id>` - Discard Plan

Archives a plan without merging, removes worktree and branch.

## Folder Structure

Plans are stored in `~/comms/plans/`:

```
~/comms/plans/
├── board.json          # Central tracking
├── queued/
│   ├── auto/           # Auto-execute plans
│   └── manual/         # Manual trigger plans
├── active/             # Currently executing
├── review/             # Completed, awaiting review
├── archived/           # Done or discarded
└── logs/               # Execution logs
```

## Execution Flow

```
/nova
  ↓
Inner Monologue → Predict questions
  ↓
Launch Explore Agents (dynamic, parallel)
  ↓
Review Reports → Need more? Loop back
  ↓
Ask User Questions
  ↓
Create Plan with Parallelization Analysis
  ↓
Save to queued/auto or queued/manual

/pulsar
  ↓
Load Plan → Analyze for parallelism
  ↓
Create Worktree
  ↓
Round 1: Phase 1 + Phase 2 (parallel)
  ↓
Quality Gate: Dead Code + Test Agent (parallel)
  ↓
Round 2: Phase 3
  ↓
Quality Gate: Dead Code + Test Agent (parallel)
  ↓
Finalize → Move to review

/merge plan-id
  ↓
Merge worktree → main
  ↓
Cleanup → Archive
```

## Auto-Execution

For background execution, use the watcher daemon:

```bash
# Start watcher (polls every 5 minutes)
~/comms/scripts/pulsar-watcher.sh &

# Plans in queued/auto/ will be picked up automatically
```

## License

MIT
