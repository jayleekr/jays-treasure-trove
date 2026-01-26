# Git Workflow - Branch Management Strategy

Detailed guide for managing git branches during compliance suppression workflow.

## Base/Output Branch Strategy

The recommended workflow uses two branches to maintain line number stability during iterative suppression.

### Why This Strategy?

**Problem**: When you suppress violations in a file, you add comment lines, which shifts all subsequent line numbers. If you suppress multiple rules sequentially in the same file, the line numbers in the violation report become stale.

**Solution**: Work on a "base" branch that gets reset after each rule, and accumulate all changes in an "output" branch via cherry-pick.

### Branch Roles

**Base Branch**:
- Clean state matching the violation report
- Where individual rule suppressions are committed
- Gets reset after each rule to maintain line number accuracy
- Temporary working branch

**Output Branch**:
- Accumulates all suppressions via cherry-pick
- Final branch for PR creation
- Never reset, only receives cherry-picks
- Permanent integration branch

## Setup Workflow

### Initial Branch Creation

```bash
# 1. Checkout or create base branch
git checkout -b <base-branch-name>

# Example: Use feature branch or create new
git checkout -b misra-compliance-base

# 2. Ensure clean state matching violation report
# If report was generated from specific commit:
git reset --hard <commit-hash>

# 3. Create output branch from base
git checkout -b misra-compliance-output

# 4. Return to base for work
git checkout misra-compliance-base
```

### Naming Conventions

Recommended branch names:
- Base: `misra-<module>-base`
- Output: `misra-<module>-output`

Examples:
- `misra-cm-base` / `misra-cm-output`
- `<TICKET_ID>-misra-container-manager-base` / `<TICKET_ID>-misra-container-manager-output`

## Iterative Suppression Workflow

Execute this loop for each rule being suppressed:

### Step 1: Work on Base Branch

```bash
# Ensure on base branch
git checkout <base-branch>

# Verify clean state
git status
# Should show "nothing to commit, working tree clean"
```

### Step 2: Suppress One Rule

```bash
# Suppress specific rule
./isir.py -m <module> -c <checker> -s X.Y.Z "Justification message"

# Review changes
git diff
```

### Step 3: Commit on Base

```bash
# Stage changes
git add .

# Commit with clear message
git commit -m "[MISRA] Suppress rule X.Y.Z: Justification message

Files modified: XX
Violations suppressed: XXX

Rule X.Y.Z - <rule description>

Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>"

# Capture commit hash
COMMIT=$(git rev-parse HEAD)
```

### Step 4: Cherry-Pick to Output

```bash
# Switch to output branch
git checkout <output-branch>

# Cherry-pick the suppression commit
git cherry-pick <base-branch>
# Or use captured hash: git cherry-pick $COMMIT

# Verify cherry-pick succeeded
git log -1
```

### Step 5: Reset Base for Next Rule

```bash
# Return to base branch
git checkout <base-branch>

# Reset to state before this rule's suppression
git reset --hard HEAD~

# Verify clean state restored
git status
# Should show "nothing to commit, working tree clean"
```

### Step 6: Repeat

Loop back to Step 1 for next rule.

## Handling Cherry-Pick Conflicts

Conflicts during cherry-pick are rare but can occur.

### Conflict Detection

```bash
git cherry-pick <commit>

# If conflicts:
# error: could not apply abc123... [MISRA] Suppress rule X.Y.Z
# hint: after resolving the conflicts, mark the corrected paths
# hint: with 'git add <paths>' or 'git rm <paths>'
```

### Conflict Resolution

```bash
# 1. Check which files have conflicts
git status

# Look for "both modified:" entries

# 2. Examine conflict markers
cat <conflicted-file>

# Typical conflict in suppression comments:
<<<<<<< HEAD
// coverity[rule_X_Y_Z:SUPPRESS] Previous justification
=======
// coverity[rule_X_Y_Z:SUPPRESS] New justification
>>>>>>> abc123

# 3. Resolve conflicts
# Usually safe to keep both suppressions or prefer output branch version

# Edit file to remove markers and choose correct version

# 4. Mark resolved
git add <resolved-file>

# 5. Continue cherry-pick
git cherry-pick --continue
```

### Automatic Conflict Resolution

For suppression comment conflicts, prefer output branch:
```bash
# Accept output branch (ours) version
git checkout --ours <file>
git add <file>
git cherry-pick --continue
```

Or accept incoming (theirs) version:
```bash
git checkout --theirs <file>
git add <file>
git cherry-pick --continue
```

### Aborting Cherry-Pick

If conflicts are too complex:
```bash
git cherry-pick --abort

# Manually merge the changes instead
git checkout <base-branch>
git checkout <output-branch>
git merge <base-branch>
```

## Alternative: Direct Work on Output Branch

For simpler workflows without iterative suppression:

```bash
# Work directly on output branch
git checkout <output-branch>

# Suppress rules (order doesn't matter as much)
./isir.py -m <module> -c <checker> -sa

# Commit all at once
git add .
git commit -m "[MISRA] Suppress all violations with predefined messages"
```

**When to use**:
- Auto-suppress mode (one-shot suppression)
- Small number of violations (<100)
- Not concerned about line number stability

**When NOT to use**:
- Iterative targeted suppression
- Large number of rules (>10)
- Need to review each rule carefully

## Commit Message Best Practices

### Format Template

```
[MISRA] <Action>: <Brief description>

<Detailed description>
- Rule X.Y.Z: <rule name> (<violation count>)
- ...

Files modified: XX
Violations suppressed: XXX

<Optional: Technical notes>

Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Good Examples

**Auto-suppress commit**:
```
[MISRA] Auto-suppress violations with predefined messages

Suppressed 1,124 violations across 40 rules:
- Rule 8.2.5: Type casting (342 violations)
- Rule 7.0.2: Type conversions (215 violations)
- Rule 19.3.3: Variadic macros (156 violations)
... (list all rules)

Files modified: 87
Violations suppressed: 1,124

Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Targeted suppress commit**:
```
[MISRA] Suppress rule 8.2.5: Safe casts verified by security review

Rule 8.2.5 - Improper type casting

All casts in container-manager have been reviewed by security team
and verified to be safe. Casts are required for interfacing with
AUTOSAR platform APIs which use void* extensively.

Files modified: 28
Violations suppressed: 342

Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Tracking Updates

After successful suppression workflow, update isir.py tracking:

```bash
# Edit isir.py to mark rules as done
vim isir.py

# Add to is_done() function (lines 209-213)
def is_done(rule_name: str) -> bool:
    if r := MisraRule.rule_number(rule_name):
        return r in (
            '8.2.5',  # Newly completed
            '7.0.2',  # Newly completed
            # ... all completed rules
        )

# Commit tracking update
git add isir.py
git commit -m "[MISRA] Update rule tracking for completed suppressions"
```

## PR Creation from Output Branch

When all suppressions are complete:

```bash
# Ensure on output branch
git checkout <output-branch>

# Verify all cherry-picks succeeded
git log --oneline

# Push to remote
git push -u origin <output-branch>

# Create PR
gh pr create --base master --head <output-branch> \
  --title "[MISRA] Compliance suppressions for <module>" \
  --body "$(cat <<EOF
## Summary
Addressed XXXX MISRA-C 2023 violations across XX rules for <module>.

## Changes
- Auto-suppressed XX rules with predefined justifications (XXXX violations)
- Manually suppressed XX rules with custom justifications (XXX violations)

## Rules Addressed
- Rule 8.2.5: Type casting (342 violations)
- Rule 7.0.2: Type conversions (215 violations)
...

## Files Modified
XX files with XXXX suppression comments added.

## Testing
- [ ] Build verification: \`./build.py --module <module>\`
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Code review for justification validity

## Time Saved
Automated workflow saved approximately X hours vs manual suppression.

Generated with Claude Code
https://claude.com/claude-code
EOF
)"
```

## Cleanup After PR Merge

Once PR is merged:

```bash
# Delete local branches
git branch -D <base-branch>
git branch -D <output-branch>

# Delete remote branch (if not auto-deleted)
git push origin --delete <output-branch>

# Update local master
git checkout master
git pull
```

## Troubleshooting

### "Detached HEAD" State

```bash
# If accidentally in detached HEAD:
git checkout <base-branch>

# Or create new branch from current state:
git checkout -b <new-branch-name>
```

### Lost Commits After Reset

```bash
# Use reflog to recover
git reflog

# Find lost commit hash
# Checkout and create branch
git checkout -b recovery-branch <lost-commit-hash>
```

### Incorrect Branch

```bash
# If worked on wrong branch:
# Stash changes
git stash

# Switch to correct branch
git checkout <correct-branch>

# Apply stash
git stash pop
```

### Merge Instead of Cherry-Pick

```bash
# If accidentally merged instead of cherry-picked:
# Abort merge
git merge --abort

# Or reset to before merge
git reset --hard HEAD~
```

## Visual Workflow Diagram

```
master (main branch)
  |
  +-- base-branch (reset after each rule)
  |     |
  |     +-- [commit] Rule 8.2.5 suppressed
  |     |     |
  |     |     +-- [cherry-pick] --> output-branch
  |     |
  |     +-- [reset HEAD~]
  |     |
  |     +-- [commit] Rule 7.0.2 suppressed
  |     |     |
  |     |     +-- [cherry-pick] --> output-branch
  |     |
  |     +-- [reset HEAD~]
  |     |
  |     ... (repeat for all rules)
  |
  +-- output-branch (accumulates all suppressions)
        |
        +-- [cherry-pick] Rule 8.2.5
        +-- [cherry-pick] Rule 7.0.2
        +-- [cherry-pick] Rule 19.3.3
        ... (all rules accumulated)
        |
        +-- [PR to master]
```
