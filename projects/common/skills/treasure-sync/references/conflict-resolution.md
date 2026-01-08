# Conflict Resolution Reference

Comprehensive conflict resolution strategies for treasure-sync.

## Conflict Types

### Type 1: Merge Conflicts
**Cause**: Same file modified in both local and remote.

**Detection**:
```bash
git merge origin/main
# Output: CONFLICT (content): Merge conflict in file.md
```

**Indicators**:
- File contains conflict markers: `<<<<<<<`, `=======`, `>>>>>>>`
- `git status` shows "both modified"

**Example**:
```markdown
<<<<<<< HEAD
# Local version
New local skill added
=======
# Remote version
Updated from remote
>>>>>>> origin/main
```

---

### Type 2: Diverged History
**Cause**: Local commits not on remote AND remote commits not on local.

**Detection**:
```bash
git rev-list HEAD..origin/main --count  # Behind: 2
git rev-list origin/main..HEAD --count  # Ahead: 1
```

**Visualization**:
```
Local:  A---B---C (local commits)
              \
Remote:        D---E (remote commits)
```

**Resolution Required**: Merge or rebase.

---

### Type 3: File Deletion Conflicts
**Cause**: File deleted locally but modified remotely (or vice versa).

**Detection**:
```bash
git status | grep "deleted by us\|deleted by them"
```

**Example**:
```
deleted by us:   old-skill.md
  (modified by them)
```

---

### Type 4: Submodule Conflicts
**Cause**: Submodule pointer differs between local and remote.

**Detection**:
```bash
git status | grep "modified.*Submodule"
```

**Note**: Less common in treasure-trove (no submodules currently).

---

## Resolution Strategies

### Strategy 1: Manual Resolution

**When to Use**:
- Complex conflicts requiring human judgment
- Critical files (skill.md, core scripts)
- Semantic conflicts (both changes needed)

**Workflow**:
```bash
# Step 1: Identify conflicting files
git status | grep "both modified"

# Step 2: Open files in editor
# Conflict markers will be visible

# Step 3: Resolve each conflict
# - Keep local version
# - Keep remote version
# - Merge both versions
# - Write new version

# Step 4: Remove conflict markers
# Delete <<<<<<<, =======, >>>>>>> lines

# Step 5: Stage resolved files
git add resolved-file.md

# Step 6: Complete merge
git commit -m "Resolve merge conflicts"
```

**Example Resolution**:

**Before** (with conflicts):
```markdown
# Skill Documentation

<<<<<<< HEAD
## Local Feature
This is the new local feature.
=======
## Remote Update
This is the remote update.
>>>>>>> origin/main

## Common Section
This part is the same.
```

**After** (manually resolved):
```markdown
# Skill Documentation

## Local Feature
This is the new local feature.

## Remote Update
This is the remote update.

## Common Section
This part is the same.
```

---

### Strategy 2: Keep Ours (Local)

**When to Use**:
- Local version is authoritative
- Remote changes are outdated
- Quick resolution needed

**Command**:
```bash
# For specific file
git checkout --ours conflicting-file.md
git add conflicting-file.md

# For all conflicts (use with caution)
git merge origin/main -X ours
```

**Approval Checkpoint**:
```markdown
⚠️ Keep Local Version

**File**: skills/my-skill/skill.md

**Local Changes**:
- Added new feature documentation
- Updated version to 2.0

**Remote Changes**:
- Fixed typo in old section

**Action**: Keep local version (discard remote changes)

**Proceed?**
- approve: Keep local version
- review: Show diff first
- manual: Resolve manually
```

---

### Strategy 3: Keep Theirs (Remote)

**When to Use**:
- Remote version is newer/better
- Local changes are experimental
- Want to match team's state

**Command**:
```bash
# For specific file
git checkout --theirs conflicting-file.md
git add conflicting-file.md

# For all conflicts (use with caution)
git merge origin/main -X theirs
```

**Approval Checkpoint**:
```markdown
⚠️ Keep Remote Version

**File**: core/framework.sh

**Remote Changes**:
- Critical bug fix
- Security update

**Local Changes**:
- Experimental optimization

**Action**: Keep remote version (discard local changes)

**Proceed?**
- approve: Keep remote version
- backup: Save local changes first
- manual: Resolve manually
```

---

### Strategy 4: Three-Way Merge Tool

**When to Use**:
- Visual diff helps understanding
- Complex conflicts with many changes
- Multiple conflict sections

**Tools**:
```bash
# Configure merge tool
git config merge.tool vimdiff
# or: git config merge.tool meld
# or: git config merge.tool kdiff3

# Launch merge tool
git mergetool conflicting-file.md
```

**Merge Tool Interface**:
```
┌─────────────┬─────────────┬─────────────┐
│   LOCAL     │    BASE     │   REMOTE    │
│  (ours)     │  (common)   │  (theirs)   │
├─────────────┴─────────────┴─────────────┤
│              MERGED                      │
│  (your resolution)                       │
└──────────────────────────────────────────┘
```

---

### Strategy 5: Rebase Instead of Merge

**When to Use**:
- Want linear history
- Local commits are private (not pushed)
- Clean commit history desired

**Workflow**:
```bash
# Instead of merge
git pull --rebase origin main

# If conflicts during rebase
git status  # Shows conflicting files

# Resolve conflicts, then
git add resolved-file.md
git rebase --continue

# Or abort rebase
git rebase --abort
```

**Comparison**:
```
Merge:
  A---B---C (local)
            \
             M (merge commit)
            /
  D---E---F (remote)

Rebase:
  D---E---F (remote)
          \
           A'---B'---C' (local rebased)
```

---

## Conflict Resolution UI

### Interactive Conflict Resolver

**Prompt Structure**:
```markdown
## ⚠️ Merge Conflicts Detected

**Conflicts**: 3 files

### File 1: skills/skill-a/skill.md
**Conflict Type**: Content conflict
**Size**: 12 lines conflicting

**Preview**:
<<<<<<< Local
Local version line 1
Local version line 2
=======
Remote version line 1
Remote version line 2
>>>>>>> Remote

**Options**:
1. manual - Open for manual resolution
2. ours - Keep local version
3. theirs - Keep remote version
4. diff - Show full diff

**Choice**: _____

---

### File 2: core/framework.sh
**Conflict Type**: Content conflict
**Size**: 5 lines conflicting

**Options**: [same as above]

---

**Global Options**:
- all-ours: Keep local for ALL conflicts
- all-theirs: Keep remote for ALL conflicts
- all-manual: Resolve all manually
- abort: Cancel merge
```

### Response Handler
```yaml
manual:
  action: open_in_editor
  files: [conflicting_file_1, conflicting_file_2, ...]
  post_action: wait_for_user_commit

ours:
  action: git checkout --ours {file}
  confirmation: required

theirs:
  action: git checkout --theirs {file}
  confirmation: required

diff:
  action: git diff HEAD...origin/main {file}
  display: show_in_terminal

abort:
  action: git merge --abort
  confirmation: required
  rollback: restore_to_pre_merge_state
```

---

## Advanced Scenarios

### Scenario 1: Multiple Conflicting Files

**Batch Resolution**:
```bash
# List all conflicts
git diff --name-only --diff-filter=U

# Resolve all with local
git checkout --ours .
git add .

# Resolve all with remote
git checkout --theirs .
git add .

# Selective resolution
for file in $(git diff --name-only --diff-filter=U); do
  echo "File: $file"
  # Show conflict
  git diff $file
  # Ask user choice
  read -p "Keep [o]urs, [t]heirs, or [m]anual? " choice
  case $choice in
    o) git checkout --ours $file ;;
    t) git checkout --theirs $file ;;
    m) ${EDITOR:-vim} $file ;;
  esac
  git add $file
done
```

---

### Scenario 2: Deleted File Conflicts

**Resolution**:
```bash
# File deleted locally, modified remotely
git rm deleted-file.md  # Confirm deletion
# or
git add deleted-file.md # Keep remote version

# File modified locally, deleted remotely
git rm modified-file.md # Accept deletion
# or
git add modified-file.md # Keep local version
```

**UI Prompt**:
```markdown
⚠️ File Deletion Conflict

**File**: old-skill.md

**Local**: File deleted
**Remote**: File modified with updates

**Options**:
- delete: Confirm deletion (discard remote changes)
- keep: Restore and keep remote version
- review: Show remote changes before deciding
```

---

### Scenario 3: Binary File Conflicts

**Challenge**: Binary files can't be merged textually.

**Detection**:
```bash
git diff --numstat | grep "^-.*-"
```

**Resolution**:
```bash
# Must choose one version
git checkout --ours binary-file.pdf
# or
git checkout --theirs binary-file.pdf

git add binary-file.pdf
```

**UI Prompt**:
```markdown
⚠️ Binary File Conflict

**File**: docs/diagram.pdf
**Type**: PDF document

Binary files cannot be merged automatically.

**Options**:
- local: Keep local version (123 KB)
- remote: Keep remote version (145 KB)
- review: Download both for comparison
```

---

## Conflict Prevention

### Best Practices

**1. Pull Before Push**
```bash
# Always sync before working
git pull origin main
# Work on files
# Then push
```

**2. Communicate Changes**
```markdown
# In commit messages, note major changes
git commit -m "BREAKING: Refactor skill structure

This changes the skill.md format.
Coordinate with team before pulling.
"
```

**3. Use Feature Branches** (for major changes)
```bash
git checkout -b feature/major-refactor
# Make changes
git push origin feature/major-refactor
# Create PR for review
```

**4. Regular Small Commits**
```bash
# Instead of one large commit
git add skill-part1.md
git commit -m "Add skill documentation part 1"

git add skill-part2.md
git commit -m "Add skill documentation part 2"

# Easier to merge than one huge change
```

---

## Rollback Strategies

### Level 1: Abort Merge
```bash
git merge --abort
# Returns to pre-merge state
```

### Level 2: Reset to Pre-Merge
```bash
# If merge was committed but has issues
git reset --hard HEAD~1
# Removes merge commit, returns to before merge
```

### Level 3: Restore from Backup
```bash
# If auto-backup was created
git stash pop
# or
git checkout backup-20260108-143022
```

### Level 4: Force Reset to Remote
```bash
# Nuclear option: discard all local changes
git fetch origin
git reset --hard origin/main
# WARNING: Loses all local commits!
```

---

## Conflict Resolution Metrics

Track resolution patterns to improve workflow:

```yaml
conflict_stats:
  total_conflicts: 15
  auto_resolved: 8 (53%)
  manual_resolved: 6 (40%)
  aborted: 1 (7%)

resolution_time:
  avg_time: 3.5 minutes
  max_time: 12 minutes
  min_time: 30 seconds

conflict_types:
  content: 10 (67%)
  deletion: 3 (20%)
  binary: 2 (13%)
```

Use metrics to identify:
- Common conflict patterns
- Files that conflict often
- Opportunities for better coordination
