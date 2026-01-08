# Backup Strategy Reference

Comprehensive backup and recovery strategies for treasure-sync operations.

## Backup Philosophy

### Core Principles

**1. Safety First**
- Never lose user work
- Always create backup before risky operations
- Provide multiple recovery options

**2. Minimal Disruption**
- Fast backup creation (<1 second)
- Non-blocking operations
- Automatic cleanup of old backups

**3. Clear Recovery Path**
- Easy-to-understand recovery commands
- Step-by-step recovery guides
- Verification after recovery

---

## Backup Methods

### Method 1: Git Stash

**When to Use**:
- Quick backup of uncommitted changes
- Temporary storage before pull/merge
- Working directory is dirty

**Advantages**:
- Fast (milliseconds)
- Built-in to Git
- Easy to restore
- Preserves untracked files with `-u` flag

**Disadvantages**:
- Stack-based (LIFO)
- Easy to lose track of multiple stashes
- Not visible in branch list

**Implementation**:
```bash
# Create stash with descriptive message
git stash push -u -m "Auto-backup before pull $(date +%Y%m%d-%H%M%S)"

# Verify stash created
git stash list

# Expected output:
# stash@{0}: On main: Auto-backup before pull 20260108-143022
```

**Recovery**:
```bash
# Restore most recent stash
git stash pop

# Or apply without removing from stash
git stash apply

# List all stashes
git stash list

# Apply specific stash
git stash apply stash@{1}
```

**Cleanup**:
```bash
# Remove specific stash
git stash drop stash@{0}

# Clear all stashes (dangerous!)
git stash clear
```

---

### Method 2: Backup Branch

**When to Use**:
- Before major sync operations
- Want to preserve commit history
- Need visible reference point

**Advantages**:
- Visible in branch list
- Preserves full commit history
- Easy to compare with current state
- Can push to remote for extra safety

**Disadvantages**:
- Creates branch clutter
- Requires manual cleanup
- Slightly slower than stash

**Implementation**:
```bash
# Create backup branch with timestamp
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
git branch $BACKUP_BRANCH

# Verify branch created
git branch | grep backup-

# Expected output:
# backup-20260108-143022
```

**Recovery**:
```bash
# List backup branches
git branch | grep backup-

# Compare with current state
git diff backup-20260108-143022

# Restore entire branch
git reset --hard backup-20260108-143022

# Or cherry-pick specific commits
git cherry-pick backup-20260108-143022
```

**Cleanup**:
```bash
# Delete old backup branches (older than 7 days)
git branch | grep "backup-" | while read branch; do
  TIMESTAMP=$(echo $branch | grep -oE '[0-9]{8}-[0-9]{6}')
  AGE_DAYS=$(( ($(date +%s) - $(date -j -f "%Y%m%d-%H%M%S" "$TIMESTAMP" +%s 2>/dev/null || echo 0)) / 86400 ))
  if [ $AGE_DAYS -gt 7 ]; then
    git branch -D $branch
    echo "Deleted old backup: $branch (${AGE_DAYS} days old)"
  fi
done
```

---

### Method 3: Commit Checkpoint

**When to Use**:
- Before risky rebase/reset operations
- Want permanent record in history
- Need to preserve exact state

**Advantages**:
- Part of commit history
- Can't be accidentally lost
- Easy to reference by commit hash
- Can be pushed to remote

**Disadvantages**:
- Adds to commit history
- Requires commit message
- May need cleanup later

**Implementation**:
```bash
# Create checkpoint commit
git add -A
git commit -m "CHECKPOINT: Before sync operation $(date +%Y%m%d-%H%M%S)"

# Tag for easy reference
git tag "checkpoint-$(date +%Y%m%d-%H%M%S)"
```

**Recovery**:
```bash
# List checkpoints
git tag | grep checkpoint-

# Show checkpoint details
git show checkpoint-20260108-143022

# Restore to checkpoint
git reset --hard checkpoint-20260108-143022
```

**Cleanup**:
```bash
# Delete checkpoint tags older than 7 days
git tag | grep "checkpoint-" | while read tag; do
  TIMESTAMP=$(echo $tag | grep -oE '[0-9]{8}-[0-9]{6}')
  AGE_DAYS=$(( ($(date +%s) - $(date -j -f "%Y%m%d-%H%M%S" "$TIMESTAMP" +%s 2>/dev/null || echo 0)) / 86400 ))
  if [ $AGE_DAYS -gt 7 ]; then
    git tag -d $tag
    echo "Deleted old checkpoint: $tag"
  fi
done
```

---

### Method 4: Filesystem Copy

**When to Use**:
- Ultimate safety for critical operations
- Want complete backup outside Git
- Paranoid safety mode

**Advantages**:
- Independent of Git state
- Complete working directory copy
- Can recover from Git corruption

**Disadvantages**:
- Slowest method
- Disk space intensive
- Manual management required

**Implementation**:
```bash
# Create backup directory
BACKUP_DIR="$HOME/.claude-config-backup-$(date +%Y%m%d-%H%M%S)"
cp -r ~/.claude-config "$BACKUP_DIR"

# Verify backup
du -sh "$BACKUP_DIR"
```

**Recovery**:
```bash
# List backups
ls -lh ~/.claude-config-backup-*

# Restore from backup
rm -rf ~/.claude-config
cp -r ~/.claude-config-backup-20260108-143022 ~/.claude-config
```

**Cleanup**:
```bash
# Remove old backups (older than 7 days)
find ~/ -maxdepth 1 -name ".claude-config-backup-*" -mtime +7 -exec rm -rf {} \;
```

---

## Backup Decision Matrix

### Operation Risk Assessment

```yaml
low_risk:
  operations: [status, fetch, pull (clean working dir)]
  backup_method: none
  reason: No data loss possible

medium_risk:
  operations: [pull (dirty dir), push]
  backup_method: git_stash
  reason: Quick recovery needed

high_risk:
  operations: [merge with conflicts, rebase]
  backup_method: backup_branch
  reason: Preserve commit history

critical_risk:
  operations: [force push, hard reset, major refactor]
  backup_method: filesystem_copy + backup_branch
  reason: Maximum safety required
```

### Automated Backup Selection

```bash
function auto_backup() {
  local operation=$1
  local risk_level=$2

  case $risk_level in
    low)
      echo "No backup needed"
      ;;
    medium)
      git stash push -u -m "Auto-backup before $operation $(date +%Y%m%d-%H%M%S)"
      echo "Created stash backup"
      ;;
    high)
      git branch "backup-$operation-$(date +%Y%m%d-%H%M%S)"
      echo "Created branch backup"
      ;;
    critical)
      # Both branch and filesystem backup
      git branch "backup-$operation-$(date +%Y%m%d-%H%M%S)"
      cp -r ~/.claude-config "$HOME/.claude-config-backup-$(date +%Y%m%d-%H%M%S)"
      echo "Created branch + filesystem backup"
      ;;
  esac
}
```

---

## Recovery Procedures

### Scenario 1: Restore Uncommitted Changes

**Problem**: Accidentally discarded uncommitted work.

**Solution**:
```bash
# If stash exists
git stash list
git stash pop

# If no stash, check reflog
git reflog
# Look for "WIP" or recent changes
git checkout <reflog-entry>
```

---

### Scenario 2: Undo Bad Merge

**Problem**: Merge created conflicts or broke something.

**Solution**:
```bash
# If merge not committed yet
git merge --abort

# If merge was committed
git reset --hard HEAD~1

# Or restore from backup branch
git reset --hard backup-20260108-143022
```

---

### Scenario 3: Recover Lost Commits

**Problem**: Accidentally reset and lost commits.

**Solution**:
```bash
# Find lost commits in reflog
git reflog

# Reflog shows:
# abc123 HEAD@{0}: reset: moving to origin/main
# def456 HEAD@{1}: commit: My important work

# Restore lost commit
git cherry-pick def456

# Or reset to that point
git reset --hard def456
```

---

### Scenario 4: Complete Repository Corruption

**Problem**: Git repository is broken, commands fail.

**Solution**:
```bash
# Restore from filesystem backup
rm -rf ~/.claude-config
cp -r ~/.claude-config-backup-20260108-143022 ~/.claude-config

# Or re-clone from remote
cd ~
rm -rf .claude-config
git clone https://github.com/jayleekr/jays-treasure-trove.git .claude-config

# Then restore local changes from backup
```

---

## Backup Validation

### Pre-Operation Validation

**Checklist**:
```bash
# 1. Verify backup was created
if [ $BACKUP_METHOD == "stash" ]; then
  git stash list | head -1 | grep "Auto-backup"
elif [ $BACKUP_METHOD == "branch" ]; then
  git branch | grep "backup-"
fi

# 2. Verify backup contains expected changes
git diff HEAD backup-branch --stat

# 3. Verify backup is accessible
git show backup-branch:important-file.md
```

### Post-Recovery Validation

**Checklist**:
```bash
# 1. Verify working directory is clean
git status

# 2. Verify expected files exist
ls -la skills/my-skill/

# 3. Verify content integrity
git diff HEAD origin/main

# 4. Verify repository is functional
git log --oneline -5
```

---

## Backup Retention Policy

### Automatic Cleanup

**Stashes**:
```bash
# Keep only last 5 stashes
STASH_COUNT=$(git stash list | wc -l)
if [ $STASH_COUNT -gt 5 ]; then
  # Drop oldest stashes
  for i in $(seq 5 $((STASH_COUNT - 1))); do
    git stash drop stash@{$i}
  done
fi
```

**Backup Branches**:
```bash
# Delete branches older than 7 days
git branch | grep "backup-" | while read branch; do
  TIMESTAMP=$(echo $branch | grep -oE '[0-9]{8}-[0-9]{6}')
  if [ -n "$TIMESTAMP" ]; then
    AGE_DAYS=$(( ($(date +%s) - $(date -j -f "%Y%m%d-%H%M%S" "$TIMESTAMP" +%s 2>/dev/null || echo 0)) / 86400 ))
    if [ $AGE_DAYS -gt 7 ]; then
      git branch -D $branch
    fi
  fi
done
```

**Filesystem Backups**:
```bash
# Delete backups older than 7 days
find ~/ -maxdepth 1 -name ".claude-config-backup-*" -mtime +7 -exec rm -rf {} \;
```

### Manual Cleanup

User-initiated cleanup:
```markdown
## 🧹 Cleanup Old Backups

**Stashes**: 8 found
**Branches**: 12 backup branches
**Filesystem**: 3 backup directories (2.4 GB)

**Recommendation**: Delete backups older than 7 days

**Actions**:
- auto: Automatic cleanup (7-day retention)
- custom: Choose retention period
- manual: Review each backup
- skip: Keep all backups
```

---

## Backup Monitoring

### Health Checks

**Daily Check**:
```bash
# Count backups
STASH_COUNT=$(git stash list | wc -l)
BRANCH_COUNT=$(git branch | grep -c "backup-")
FILESYSTEM_BACKUPS=$(find ~/ -maxdepth 1 -name ".claude-config-backup-*" | wc -l)

# Disk usage
BACKUP_SIZE=$(du -sh ~/.claude-config-backup-* 2>/dev/null | awk '{sum+=$1} END {print sum}')

# Report
echo "Backup Status:"
echo "- Stashes: $STASH_COUNT"
echo "- Branches: $BRANCH_COUNT"
echo "- Filesystem: $FILESYSTEM_BACKUPS ($BACKUP_SIZE)"
```

### Alerts

```yaml
warning_thresholds:
  stash_count: 10
  branch_count: 20
  filesystem_backups: 5
  total_size_gb: 5

actions:
  stash_count_exceeded:
    message: "Too many stashes (${count}). Run cleanup?"

  branch_count_exceeded:
    message: "Too many backup branches (${count}). Run cleanup?"

  disk_usage_high:
    message: "Backup disk usage is ${size}GB. Run cleanup?"
```

---

## Best Practices

### 1. Always Backup Before Risky Operations
```bash
# Good
git branch backup-before-rebase-$(date +%Y%m%d-%H%M%S)
git rebase origin/main

# Bad
git rebase origin/main  # No backup!
```

### 2. Use Descriptive Backup Names
```bash
# Good
git stash push -m "Before pulling skill updates"
git branch backup-before-major-refactor-20260108

# Bad
git stash
git branch backup-temp
```

### 3. Verify Backup Before Proceeding
```bash
# Good
git branch backup-sync-$(date +%Y%m%d-%H%M%S)
git branch | grep backup-  # Verify created
git pull origin main

# Bad
git branch backup
git pull  # Don't verify
```

### 4. Clean Up Regularly
```bash
# Run weekly
git branch | grep "backup-" | while read branch; do
  echo "Review: $branch"
  git log $branch -1
  read -p "Delete? (y/n) " choice
  [ "$choice" = "y" ] && git branch -D $branch
done
```

### 5. Document Recovery Procedures
```markdown
# In skill documentation
## Recovery Procedures

If sync fails:
1. Check for backup: `git branch | grep backup-`
2. Restore: `git reset --hard backup-YYYYMMDD-HHMMSS`
3. Verify: `git status`
4. Retry sync
```

---

## Emergency Recovery Guide

### Quick Reference Card

```markdown
## 🆘 Emergency Recovery

**Lost uncommitted changes?**
→ git stash pop

**Bad merge?**
→ git merge --abort

**Need to undo last commit?**
→ git reset --hard HEAD~1

**Lost commits?**
→ git reflog (find commit hash)
→ git cherry-pick <hash>

**Repository corrupted?**
→ Restore from ~/.claude-config-backup-*

**Need help?**
→ Run "treasure recovery help"
```

### Panic Mode Recovery

```bash
#!/bin/bash
# Ultra-safe recovery mode

echo "🆘 Entering Panic Recovery Mode"

# 1. Create emergency backup
echo "Creating emergency backup..."
cp -r ~/.claude-config ~/.claude-config-EMERGENCY-$(date +%Y%m%d-%H%M%S)

# 2. Check Git integrity
echo "Checking Git integrity..."
git fsck --full

# 3. Show recent activity
echo "Recent Git activity:"
git reflog -10

# 4. Show backup options
echo ""
echo "Available backups:"
git branch | grep backup-
git stash list
ls -lh ~/.claude-config-backup-* 2>/dev/null

# 5. Prompt for action
echo ""
echo "Recovery options:"
echo "1. Restore from stash"
echo "2. Restore from backup branch"
echo "3. Restore from filesystem backup"
echo "4. Re-clone from remote (destructive!)"
echo "5. Exit (manual recovery)"
```

---

## Metrics and Reporting

### Backup Statistics

Track backup usage to improve strategy:

```yaml
backup_metrics:
  total_backups_created: 127
  stashes_created: 89 (70%)
  branches_created: 32 (25%)
  filesystem_copies: 6 (5%)

  recoveries_performed: 8
  stash_restored: 6 (75%)
  branch_restored: 2 (25%)

  disk_usage:
    stashes: minimal (~0 MB)
    branches: minimal (~0 MB)
    filesystem: 1.8 GB

  avg_backup_age: 2.3 days
  oldest_backup: 14 days
```

Use metrics to:
- Identify backup patterns
- Optimize retention policies
- Improve user experience
