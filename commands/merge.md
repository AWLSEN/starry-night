---
name: merge
description: Merge a completed plan's worktree into the main branch and clean up.
arguments:
  - name: plan-id
    description: The plan ID to merge (e.g., plan-20260105-1530)
    required: true
---

# Merge - Worktree Merge Command

Merges a completed plan's worktree into main and cleans up.

## Workflow

### Step 1: Validate

1. Find plan in `~/comms/plans/review/` or `~/comms/plans/active/`
2. Verify worktree exists at path in board.json
3. Confirm with user before merging

### Step 2: Merge

```bash
cd {project-root}
git checkout main || git checkout master
git pull origin main || git pull origin master
git merge plan/{plan-id} --no-ff -m "Merge plan/{plan-id}: {title}

Phases:
- Phase 1: {desc}
- Phase 2: {desc}
...

Co-Authored-By: Pulsar <noreply@anthropic.com>"
```

### Step 3: Handle Conflicts

If conflicts:
1. List conflicted files
2. Ask user how to proceed:
   - Attempt auto-resolve
   - Abort and let user resolve manually

### Step 4: Cleanup

```bash
git worktree remove ../worktree-{plan-id}
git branch -d plan/{plan-id}
```

### Step 5: Update board.json

```json
{
  "status": "archived",
  "mergedAt": "{timestamp}",
  "worktree": null
}
```

### Step 6: Move Plan

Move from `review/` or `active/` to `archived/`

### Step 7: Notify User

```
Plan {id} merged successfully!
- Branch: plan/{id} → main
- Worktree: Removed
- Plan: Archived

Run 'git push' to push to remote.
```

## Error Handling

- **Worktree not found**: Check if already merged
- **Branch not found**: May have been manually merged
- **Conflicts**: Offer resolution options
