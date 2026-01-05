---
name: archive
description: Archive a plan without merging. Discards the worktree and branch.
arguments:
  - name: plan-id
    description: The plan ID to archive (e.g., plan-20260105-1530)
    required: true
---

# Archive - Plan Archive Command

Archives a plan without merging. Removes worktree and branch.

## Workflow

### Step 1: Validate

1. Find plan in board.json
2. Confirm with user:
   ```
   "This will DISCARD all changes in plan {id}. Are you sure?"
   Options: Yes / No
   ```

### Step 2: Remove Worktree

```bash
git worktree remove ../worktree-{plan-id} --force
git branch -D plan/{plan-id}
```

### Step 3: Update board.json

```json
{
  "status": "archived",
  "archivedAt": "{timestamp}",
  "worktree": null,
  "discarded": true
}
```

### Step 4: Move Plan

Move from current location to `archived/`

Add note to plan:
```markdown
## Archive Note
- Archived: {timestamp}
- Reason: Discarded without merge
- Changes: Not merged
```

### Step 5: Notify User

```
Plan {id} archived.
- Worktree: Removed
- Branch: Deleted
- Changes: Discarded
```

## Use Cases

- Plan was experimental
- Requirements changed
- Implementation approach was wrong
- Want to start fresh
