# Treasure Sync Skill

Bidirectional sync skill for jays-treasure-trove configuration repository.

## When to Use This Skill

Activate when user requests:
- "sync jays-treasure-trove"
- "update claude config"
- "pull latest configs"
- "push my skills"
- Keywords: "treasure sync", "config sync", "upload skills"

## Prerequisites

### Environment Setup
1. **jays-treasure-trove**: Cloned at `~/.claude-config/`
2. **Git Authentication**: GitHub credentials configured
3. **Clean Working Directory**: Recommended (skill handles dirty state)

### Repository Structure
```
~/.claude-config/
├── core/               # Core framework files
├── projects/
│   ├── common/        # Shared skills and commands
│   └── {project}/     # Project-specific configs
├── install.sh
└── README.md
```

## Core Workflow

### 1. Understand User Intent

Parse user request to determine:
- **Direction**: pull (remote → local), push (local → remote), or both (full sync)
- **Scope**: specific project, all projects, or entire repo
- **Force**: whether to force sync (handle conflicts automatically)

### 2. Execute Appropriate Mode

#### Mode 1: PULL (Remote → Local)
Fetch latest configs from GitHub.

**Execution Steps**:
1. Check current location and status
2. Backup current state (optional, if dirty)
3. Fetch from remote
4. Check for conflicts
5. **[APPROVAL CHECKPOINT]** if conflicts exist
6. Merge or rebase
7. Report changes

**Output**:
```markdown
## 📥 Pull from jays-treasure-trove

**Remote**: origin/main
**Status**: ✅ Clean working directory

### Incoming Changes:
- Modified: PROJECT_CLAUDE.md
- Added: skills/new-skill/
- Deleted: deprecated/old-command.md

**Proceed with pull?**
- approve: Pull changes
- backup: Backup first, then pull
- reject: Abort
```

Reference: `references/sync-workflow.md`

#### Mode 2: PUSH (Local → Remote)
Upload local changes to GitHub.

**Execution Steps**:
1. Check git status
2. Identify untracked/modified files
3. **[APPROVAL CHECKPOINT]** show changes
4. Stage files
5. Generate commit message
6. Commit changes
7. Push to remote

**Output**:
```markdown
## 📤 Push to jays-treasure-trove

**Branch**: main
**Remote**: origin

### Outgoing Changes:
- Modified: 3 files
- Added: 12 files (2 new skills)
- Deleted: 1 file

### Commit Message:
Add new skills and update documentation

**Proceed with push?**
- approve: Commit and push
- modify: Edit commit message
- reject: Abort
```

Reference: `references/sync-workflow.md`

#### Mode 3: STATUS
Check repository status without making changes.

**Execution Steps**:
1. Git status (local changes)
2. Git fetch (check remote changes)
3. Compare local vs remote
4. Report divergence

**Output**:
```markdown
## 📊 Repository Status

**Location**: ~/.claude-config/
**Branch**: main
**Remote**: origin/main

### Local Changes:
- Modified: 2 files
- Untracked: 5 files

### Remote Changes:
- Commits ahead: 0
- Commits behind: 3

**Recommendation**: Pull first, then push
```

Reference: `references/sync-workflow.md`

#### Mode 4: SYNC (Bidirectional)
Full sync: pull then push.

**Execution Steps**:
1. Execute Mode 3 (STATUS)
2. If remote ahead: Execute Mode 1 (PULL)
3. If local changes: Execute Mode 2 (PUSH)
4. Handle conflicts if any
5. Final status report

**Orchestration Logic**:
```
STATUS → Remote ahead? → PULL → Conflicts? → RESOLVE → PUSH
         ↓ No                      ↓ Yes
         Local changes? → PUSH     ABORT (approval)
         ↓ No
         DONE (already synced)
```

Reference: `references/sync-workflow.md`

### 3. Handle Errors Gracefully

#### Error Categories

**Merge Conflicts** (approval required):
- Show conflicting files
- Options: manual resolve, abort, force ours/theirs

**Authentication Errors** (guidance):
- Check GitHub credentials
- Provide authentication setup guide

**Network Errors** (retry):
- Retry with exponential backoff (3 attempts)
- Suggest offline mode if persistent

**Dirty Working Directory** (backup):
- Offer to backup current state
- Stash changes or commit first

Reference: `references/conflict-resolution.md`

## Tool Integration

### Git Operations
- **Status**: `git status --porcelain`
- **Fetch**: `git fetch origin`
- **Pull**: `git pull origin main`
- **Push**: `git push origin main`
- **Diff**: `git diff --stat origin/main`

### Backup Strategy
- **Stash**: `git stash push -u -m "Auto-backup before sync"`
- **Branch**: `git branch backup-$(date +%Y%m%d-%H%M%S)`
- **Restore**: `git stash pop` or `git checkout backup-*`

Reference: `references/backup-strategy.md`

## Communication Patterns

### Progress Display
```markdown
## 🔄 Syncing jays-treasure-trove

- ✅ Check repository status
- 🔄 Fetch from remote (in progress)
- ⏳ Merge changes (pending)
- ⏳ Push local changes (pending)
```

### User Decisions
```markdown
**Conflicts detected in 3 files**

### Conflicting Files:
- PROJECT_CLAUDE.md
- skills/common/skill-a.md
- core/framework.sh

**How to resolve?**
- manual: Open files for manual resolution
- ours: Keep local version
- theirs: Use remote version
- abort: Cancel sync
```

### Success Messages
```markdown
✅ Sync Complete

**Pulled**: 5 changes from remote
**Pushed**: 3 local changes

Repository is now up to date with origin/main
```

## Success Criteria

### Functional Requirements
- ✅ Pull: Fetch and merge remote changes
- ✅ Push: Upload local changes
- ✅ Status: Report sync state
- ✅ Sync: Bidirectional synchronization
- ✅ Conflict resolution with user approval
- ✅ Backup before risky operations

### Quality Standards
- ✅ Never force push without approval
- ✅ Always backup before destructive operations
- ✅ Clear conflict resolution UI
- ✅ Atomic operations (rollback on failure)

### Usability
- ✅ One command for full sync
- ✅ Clear status reporting
- ✅ Safe defaults (backup first)
- ✅ Recovery from errors

## Important Constraints

### What This Skill Can Do
- Sync jays-treasure-trove repository
- Handle merge conflicts with user approval
- Backup working directory before sync
- Report repository status

### What This Skill Cannot Do
- Sync project repositories (only ~/.claude-config/)
- Automatically resolve complex conflicts
- Work without GitHub authentication
- Recover from force-pushed remote

### Assumptions
- ~/.claude-config/ is a git repository
- Remote is named "origin"
- Main branch is "main"
- User has write access to remote

## Version History

- **1.0.0** (2026-01-08): Initial release
  - ✅ Pull, Push, Status, Sync modes
  - ✅ Conflict detection and resolution
  - ✅ Backup strategy
  - ✅ Approval checkpoints
