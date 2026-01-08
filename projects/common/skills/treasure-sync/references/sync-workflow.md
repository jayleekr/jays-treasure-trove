# Sync Workflow Reference

Detailed workflow for each treasure-sync mode.

## Mode 1: PULL (Remote → Local)

### Workflow Diagram
```
START
  ↓
Check Current Status
  ↓
Working Directory Clean?
  ├─ Yes → Proceed
  └─ No → Offer Backup
       ↓
    Backup?
      ├─ Yes → Create Stash/Branch
      └─ No → Abort
  ↓
Fetch from Remote
  ↓
Check for Conflicts
  ├─ No Conflicts → Fast-forward Merge
  └─ Conflicts → Show Conflicts → User Decision
                    ↓
                  Resolve
                    ↓
                  Merge
  ↓
Report Changes
  ↓
END
```

### Detailed Steps

#### Step 1: Check Current Status
```bash
cd ~/.claude-config
git status --porcelain
git fetch origin --dry-run
```

**Expected Output**:
- Empty: Clean working directory
- Non-empty: Modified/untracked files exist

**Decision**:
- Clean → Proceed to Step 3
- Dirty → Proceed to Step 2

#### Step 2: Handle Dirty Working Directory
```bash
# Show untracked/modified files
git status --short

# Offer options
echo "Working directory has uncommitted changes"
echo "Options:"
echo "1. Stash changes and continue"
echo "2. Create backup branch and continue"
echo "3. Abort pull"
```

**User Choice Handler**:
```yaml
stash:
  command: git stash push -u -m "Auto-backup before pull $(date +%Y%m%d-%H%M%S)"
  recovery: git stash pop

backup_branch:
  command: git branch backup-$(date +%Y%m%d-%H%M%S)
  recovery: git checkout backup-*

abort:
  action: exit with message "Pull aborted. Commit or stash changes first."
```

#### Step 3: Fetch from Remote
```bash
git fetch origin main
git log HEAD..origin/main --oneline --stat
```

**Output Analysis**:
- No new commits → Already up to date
- Has new commits → Show changes, proceed to Step 4

#### Step 4: Check for Conflicts
```bash
git merge-tree $(git merge-base HEAD origin/main) HEAD origin/main
```

**Conflict Detection**:
- Exit code 0 → No conflicts → Fast-forward
- Exit code 1 → Conflicts exist → Show conflicts

#### Step 5: Merge Changes
**No Conflicts**:
```bash
git merge origin/main --ff-only
```

**With Conflicts**:
```bash
git merge origin/main
# If conflicts:
git status | grep "both modified"
# Show conflicting files to user
```

#### Step 6: Report Changes
```bash
git diff --stat HEAD@{1}..HEAD
git log --oneline HEAD@{1}..HEAD
```

**Output Format**:
```markdown
✅ Pull Complete

### Changes:
- Modified: 3 files (+45/-12 lines)
- Added: 5 files
- Deleted: 1 file

### Commits:
- abc123: Add new skill
- def456: Update documentation
- ghi789: Fix bug in core script
```

---

## Mode 2: PUSH (Local → Remote)

### Workflow Diagram
```
START
  ↓
Check Git Status
  ↓
Has Changes?
  ├─ No → Already up to date
  └─ Yes → Identify Changes
       ↓
    Show Changes to User
       ↓
    Approval Checkpoint
      ├─ Approve → Proceed
      ├─ Modify → Adjust files/message
      └─ Reject → Abort
       ↓
    Stage Files
       ↓
    Generate Commit Message
       ↓
    Commit Changes
       ↓
    Check Remote Status
      ↓
    Behind Remote?
      ├─ Yes → Error: Pull first
      └─ No → Push to Remote
       ↓
    Report Success
       ↓
END
```

### Detailed Steps

#### Step 1: Check Git Status
```bash
cd ~/.claude-config
git status --porcelain
```

**Output Parsing**:
```bash
# Modified files
git diff --name-status

# Untracked files
git ls-files --others --exclude-standard

# Deleted files
git ls-files --deleted
```

#### Step 2: Categorize Changes
```yaml
modified_files:
  command: git diff --name-only
  description: Files changed since last commit

untracked_files:
  command: git ls-files --others --exclude-standard
  description: New files not yet tracked

deleted_files:
  command: git ls-files --deleted
  description: Files removed from working directory
```

#### Step 3: Show Changes to User
```markdown
## 📤 Push to jays-treasure-trove

### Outgoing Changes:

**Modified** (3 files):
- PROJECT_CLAUDE.md (+12/-3 lines)
- core/framework.sh (+5/-2 lines)
- install.sh (+1/-1 lines)

**Added** (5 files):
- skills/treasure-sync/skill.md
- skills/treasure-sync/README.md
- skills/treasure-sync/references/sync-workflow.md
- skills/treasure-sync/references/conflict-resolution.md
- skills/treasure-sync/references/backup-strategy.md

**Deleted** (1 file):
- deprecated/old-script.sh

### Suggested Commit Message:
Add treasure-sync skill for bidirectional config sync

**Proceed with push?**
```

#### Step 4: Approval Checkpoint
```yaml
approve:
  action: proceed to staging

modify_files:
  prompt: "Which files to exclude?"
  action: unstage specified files

modify_message:
  prompt: "Enter new commit message:"
  action: update commit message

reject:
  action: abort push
```

#### Step 5: Stage Files
```bash
# Stage specific files (if user modified selection)
git add file1 file2 file3

# Or stage all (if user approved all)
git add -A
```

#### Step 6: Generate Commit Message
**Auto-generated Format**:
```
{Summary line based on changes}

{Details}:
- Category 1: specific changes
- Category 2: specific changes

{Co-authored if applicable}
```

**Example**:
```
Add treasure-sync skill and update core scripts

Skills:
- Add treasure-sync for config synchronization
- Add reference documentation

Core:
- Update framework.sh error handling
- Fix install.sh path resolution

Docs:
- Update PROJECT_CLAUDE.md with new skill
```

#### Step 7: Commit Changes
```bash
git commit -m "$COMMIT_MESSAGE"
```

#### Step 8: Check Remote Status
```bash
git fetch origin
git rev-list HEAD..origin/main --count
```

**Status Check**:
- Count > 0 → Behind remote → Error
- Count = 0 → Up to date → Proceed

#### Step 9: Push to Remote
```bash
git push origin main
```

#### Step 10: Report Success
```markdown
✅ Push Complete

**Commit**: abc123def
**Files**: 9 changed (+45/-6 lines)

Pushed to: https://github.com/jayleekr/jays-treasure-trove
Branch: main
```

---

## Mode 3: STATUS

### Workflow Diagram
```
START
  ↓
Check Local Status
  ↓
Check Remote Status
  ↓
Compare Local vs Remote
  ↓
Generate Report
  ↓
Provide Recommendation
  ↓
END
```

### Detailed Steps

#### Step 1: Local Status
```bash
# Uncommitted changes
git status --porcelain | wc -l

# Untracked files
git ls-files --others --exclude-standard | wc -l

# Last commit
git log -1 --format="%h %s"
```

#### Step 2: Remote Status
```bash
git fetch origin --quiet

# Commits ahead
git rev-list origin/main..HEAD --count

# Commits behind
git rev-list HEAD..origin/main --count

# Last remote commit
git log origin/main -1 --format="%h %s"
```

#### Step 3: Compare
```yaml
local_ahead:
  condition: ahead_count > 0
  meaning: Local commits not on remote
  action: Need to push

remote_ahead:
  condition: behind_count > 0
  meaning: Remote commits not local
  action: Need to pull

both_ahead:
  condition: ahead_count > 0 AND behind_count > 0
  meaning: Diverged history
  action: Need to pull, then push (may have conflicts)

in_sync:
  condition: ahead_count = 0 AND behind_count = 0
  meaning: Local and remote are identical
  action: No sync needed
```

#### Step 4: Generate Report
```markdown
## 📊 Repository Status

**Location**: ~/.claude-config/
**Branch**: main
**Remote**: origin/main

### Local State:
- Uncommitted changes: 2 files
- Untracked files: 5 files
- Last commit: abc123 "Add new skill"

### Remote State:
- Commits ahead: 1 (local changes not pushed)
- Commits behind: 2 (remote changes not pulled)
- Last commit: def456 "Update core framework"

### Sync Status: ⚠️ Diverged
```

#### Step 5: Recommendation
```yaml
in_sync:
  message: "✅ Repository is up to date. No action needed."

local_only:
  message: "📤 You have 1 local commit. Run 'push treasure' to upload."

remote_only:
  message: "📥 Remote has 2 new commits. Run 'pull treasure' to download."

diverged:
  message: "🔄 Repository has diverged. Run 'sync treasure' to synchronize."
  warning: "May require conflict resolution."
```

---

## Mode 4: SYNC (Bidirectional)

### Workflow Diagram
```
START
  ↓
Execute STATUS
  ↓
Analyze Sync Requirements
  ↓
In Sync? ─Yes→ Report "Already synced" → END
  ↓ No
Behind Remote?
  ├─ Yes → Execute PULL
  │         ↓
  │       Success?
  │         ├─ Yes → Continue
  │         └─ No → Error & Rollback → END
  └─ No → Continue
  ↓
Has Local Changes?
  ├─ Yes → Execute PUSH
  │         ↓
  │       Success?
  │         ├─ Yes → Report Success
  │         └─ No → Error & Rollback
  └─ No → Already Synced
  ↓
Final Status Check
  ↓
Report Summary
  ↓
END
```

### Detailed Steps

#### Step 1: Status Check
Execute Mode 3 (STATUS) workflow completely.

**Decision Matrix**:
```yaml
scenario_1_in_sync:
  behind: 0
  ahead: 0
  dirty: false
  action: skip_sync
  message: "✅ Already synced"

scenario_2_pull_only:
  behind: >0
  ahead: 0
  dirty: false
  action: execute_pull

scenario_3_push_only:
  behind: 0
  ahead: >0
  dirty: false
  action: execute_push

scenario_4_bidirectional:
  behind: >0
  ahead: >0
  dirty: false
  action: execute_pull_then_push
  warning: "May require conflict resolution"

scenario_5_dirty:
  dirty: true
  action: backup_then_sync
  checkpoint: require_approval
```

#### Step 2: Execute PULL (if needed)
If `behind_count > 0`:
1. Execute Mode 1 (PULL) workflow
2. Handle conflicts if any
3. Verify success
4. If failed → Rollback & abort sync

#### Step 3: Execute PUSH (if needed)
If `ahead_count > 0` (after pull):
1. Execute Mode 2 (PUSH) workflow
2. Handle remote ahead scenario
3. Verify success
4. If failed → Keep local commits, report error

#### Step 4: Final Verification
```bash
git fetch origin
git diff HEAD origin/main --stat
```

**Expected**: No diff (HEAD = origin/main)

#### Step 5: Summary Report
```markdown
✅ Sync Complete

### Operations Performed:
- 📥 Pulled: 3 commits from remote
- 📤 Pushed: 1 commit to remote

### Changes:
- Downloaded: 5 files modified (+34/-12 lines)
- Uploaded: 9 files added (+156 lines)

**Repository Status**: ✅ In Sync
**Last Sync**: 2026-01-08 14:30:22
```

---

## Error Handling Patterns

### Pattern 1: Network Timeout
```bash
# Retry with exponential backoff
for i in 1 2 3; do
  git fetch origin && break
  sleep $((2 ** i))
done
```

### Pattern 2: Authentication Failure
```bash
git fetch origin 2>&1 | grep -q "Authentication failed"
if [ $? -eq 0 ]; then
  echo "❌ GitHub authentication failed"
  echo "Setup: https://github.com/settings/tokens"
fi
```

### Pattern 3: Detached HEAD
```bash
if ! git symbolic-ref HEAD 2>/dev/null; then
  echo "⚠️ Detached HEAD detected"
  git checkout main
fi
```

### Pattern 4: Merge Abort
```bash
# If merge fails
git merge --abort
git reset --hard HEAD
echo "Merge aborted, working directory restored"
```

---

## Performance Optimization

### Caching Strategy
```bash
# Cache remote status (5 min TTL)
if [ ! -f ~/.claude-cache/treasure-remote-status ] || \
   [ $(($(date +%s) - $(stat -f %m ~/.claude-cache/treasure-remote-status))) -gt 300 ]; then
  git fetch origin --quiet
  git rev-list HEAD..origin/main --count > ~/.claude-cache/treasure-remote-status
fi
```

### Parallel Operations
```bash
# Fetch and local status in parallel
(
  git fetch origin &
  git status --porcelain > /tmp/local-status &
  wait
)
```

### Minimal Network Usage
```bash
# Fetch only metadata, not full objects
git fetch origin --dry-run

# Check remote without downloading
git ls-remote origin main
```
