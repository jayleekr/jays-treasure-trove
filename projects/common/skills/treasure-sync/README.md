# Treasure Sync - jays-treasure-trove Configuration Sync

Bidirectional sync tool for keeping your jays-treasure-trove configuration repository in sync with GitHub.

## Quick Start

### Basic Commands

```bash
# Pull latest configs from GitHub
"sync configs" or "pull treasure"

# Push your local changes
"push skills" or "upload configs"

# Check sync status
"treasure status" or "check config sync"

# Full bidirectional sync
"sync jays-treasure-trove" or "full sync"
```

## Features

### 🔄 Bidirectional Sync
- **Pull**: Download latest configs from GitHub
- **Push**: Upload your local changes
- **Sync**: Full bidirectional synchronization

### 🛡️ Safe Operations
- **Automatic Backup**: Creates backup before risky operations
- **Conflict Detection**: Identifies merge conflicts
- **Approval Checkpoints**: User confirmation for destructive actions
- **Rollback Support**: Restore from backup if needed

### 📊 Status Reporting
- Local vs remote changes
- Untracked files
- Commits ahead/behind
- Sync recommendations

## Usage Examples

### Example 1: Pull Latest Updates

```
User: "pull latest claude configs"

Output:
## 📥 Pull from jays-treasure-trove

**Remote**: origin/main
**Status**: ✅ Clean working directory

### Incoming Changes:
- Modified: PROJECT_CLAUDE.md (1 file)
- Added: skills/new-feature/ (5 files)

**Proceed with pull?**

User: "approve"

Output:
✅ Pull Complete
- Updated 1 file
- Added 5 files
Repository is now up to date
```

### Example 2: Push Your Skills

```
User: "push my new skills to treasure"

Output:
## 📤 Push to jays-treasure-trove

**Branch**: main

### Outgoing Changes:
- Added: skills/treasure-sync/ (4 files)
- Modified: PROJECT_CLAUDE.md

### Commit Message:
Add treasure-sync skill for config synchronization

**Proceed with push?**

User: "approve"

Output:
✅ Push Complete
Pushed 1 commit to origin/main
```

### Example 3: Full Sync with Conflicts

```
User: "sync jays-treasure-trove"

Output:
## 🔄 Syncing jays-treasure-trove

- ✅ Check repository status
- ✅ Fetch from remote
- ⚠️ Conflicts detected

### Conflicting Files:
- skills/common/skill-a.md
  Local: Added new feature
  Remote: Updated documentation

**How to resolve?**
- manual: Open for manual resolution
- ours: Keep local version
- theirs: Use remote version
- abort: Cancel sync

User: "manual"

Output:
Opening conflicting files...
After resolving, run "continue sync"
```

### Example 4: Check Status

```
User: "check treasure status"

Output:
## 📊 Repository Status

**Location**: ~/.claude-config/
**Branch**: main
**Remote**: origin/main

### Local Changes:
- Modified: 2 files
- Untracked: 5 files

### Remote Status:
- Commits ahead: 0
- Commits behind: 3

**Recommendation**: Pull first, then push
```

## Workflow Modes

### Mode 1: PULL (📥)
Download latest changes from GitHub.

**When to use**:
- Before starting work
- After teammates push updates
- To get latest skills/configs

**Safety**:
- Backs up local changes if dirty
- Shows conflicts before merging
- Requires approval for complex merges

### Mode 2: PUSH (📤)
Upload your local changes to GitHub.

**When to use**:
- After creating new skills
- After modifying configs
- To share your improvements

**Safety**:
- Shows all changes before commit
- Generates descriptive commit message
- Requires approval before push

### Mode 3: STATUS (📊)
Check repository state without changes.

**When to use**:
- Check if you're up to date
- See what changes you have locally
- Determine if pull/push needed

**Output**:
- Local changes count
- Remote changes count
- Sync recommendations

### Mode 4: SYNC (🔄)
Full bidirectional sync (pull + push).

**When to use**:
- Daily sync routine
- After major changes
- Before important work

**Process**:
1. Check status
2. Pull if remote ahead
3. Resolve conflicts if any
4. Push if local changes
5. Confirm sync complete

## Conflict Resolution

### Conflict Types

**Merge Conflicts**:
- Both local and remote modified same file
- Requires manual or automatic resolution

**Diverged History**:
- Local commits not on remote
- Remote commits not on local
- Requires merge or rebase

### Resolution Options

**Manual Resolution**:
1. Skill opens conflicting files
2. User resolves conflicts manually
3. User commits resolved changes
4. Skill continues sync

**Automatic Resolution**:
- **Keep Ours**: Use local version
- **Keep Theirs**: Use remote version
- **Abort**: Cancel sync operation

### Best Practices

✅ **Do**:
- Pull before starting work
- Commit frequently with clear messages
- Resolve conflicts promptly
- Backup before risky operations

❌ **Don't**:
- Force push without approval
- Ignore conflicts
- Skip backups
- Commit sensitive data

## Error Recovery

### Common Errors

**Authentication Failed**:
```
❌ Authentication Error

GitHub credentials not configured.

**Setup**:
1. Generate GitHub token: https://github.com/settings/tokens
2. Configure git: git config --global credential.helper store
3. Retry sync
```

**Merge Conflicts**:
```
⚠️ Merge Conflicts Detected

3 files have conflicts that need resolution.

**Options**:
- manual: Resolve conflicts manually
- abort: Cancel and rollback
```

**Network Error**:
```
❌ Network Error

Failed to connect to GitHub (3 retries).

**Suggestions**:
- Check internet connection
- Verify GitHub status: https://www.githubstatus.com/
- Try again later
```

### Rollback Procedures

**Rollback from Stash**:
```bash
git stash pop
```

**Rollback from Backup Branch**:
```bash
git checkout backup-20260108-143022
```

**Complete Reset** (destructive):
```bash
git reset --hard origin/main
```

## Configuration

### Repository Settings

**Default Remote**:
```bash
origin: https://github.com/jayleekr/jays-treasure-trove.git
```

**Default Branch**:
```bash
main
```

### Backup Settings

**Auto-backup**: Before risky operations
**Backup Method**: Git stash or branch
**Retention**: Manual cleanup

## Advanced Usage

### Selective Sync

Sync specific project only:
```
"sync container-manager configs only"
```

### Dry Run

Check what would happen without making changes:
```
"dry run treasure sync"
```

### Force Sync

Force sync with conflict resolution strategy:
```
"force sync treasure, keep local"
"force sync treasure, use remote"
```

## Troubleshooting

### Sync Stuck

**Symptom**: Sync operation hangs
**Solution**:
```bash
cd ~/.claude-config
git reset --hard HEAD
git fetch origin
git reset --hard origin/main
```

### Untracked Files

**Symptom**: Too many untracked files
**Solution**:
```bash
# Review .gitignore
cd ~/.claude-config
cat .gitignore

# Add patterns to ignore
echo "pattern-to-ignore" >> .gitignore
```

### Detached HEAD

**Symptom**: Not on any branch
**Solution**:
```bash
cd ~/.claude-config
git checkout main
git pull origin main
```

## Integration

### With Other Skills

**jira-workflow-agent**:
- Syncs skills after creating new workflow

**snt-ccu2-yocto**:
- Pushes Yocto configs after build

**misra-compliance-agent**:
- Uploads compliance reports

### With Commands

Works seamlessly with:
- `/git`: Git operations
- Custom hooks for auto-sync

## FAQ

**Q: How often should I sync?**
A: Pull daily before work, push after creating/modifying skills.

**Q: What if I have local changes and remote changes?**
A: Skill will pull first, resolve conflicts, then push.

**Q: Can I sync just one skill?**
A: Yes, use selective sync: "sync skill-name only"

**Q: What happens to .env files?**
A: .env files are gitignored and never synced (security).

**Q: How do I see what changed?**
A: Use "treasure status" or "show recent changes"

## Support

**Issues**: https://github.com/jayleekr/jays-treasure-trove/issues
**Documentation**: `~/.claude-config/README.md`
**Skill Location**: `~/.claude-config/projects/common/skills/treasure-sync/`
