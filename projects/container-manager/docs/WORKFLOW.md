# Development Workflow with Claude Code

## Overview
container-manager development workflow with jays-treasure-trove integration, optimized for Normal session (no build/test execution).

## Session Context
**Current Session**: Normal (jaylee-mac)
- ✅ Code review and editing
- ✅ JIRA integration
- ✅ Git operations
- ✅ Documentation
- ❌ Build execution (use Jenkins CI/CD)
- ❌ Test execution (use Jenkins CI/CD)

## Typical Development Cycle

### 1. Start New Feature
```bash
# Check current branch
git status
git branch

# Create feature branch
git checkout -b feature/CCU2-12345-new-feature
```

### 2. Review Build Configuration (No Execution)
```bash
# Show build configuration info
/yocto

# Show MISRA rules configuration
/misra
```

These commands provide information only. Actual builds must be done via:
- **Jenkins CI/CD** (recommended) - Automatic on PR creation
- **Builder Environment** - SSH to builder-kr-4

### 3. Code Development
```bash
# Make code changes
vi src/container_lifecycle.cpp

# Review changes
git diff

# Stage changes
git add src/container_lifecycle.cpp
```

### 4. Commit Changes
```bash
# Create JIRA-aware commit
/jira-commit CCU2-12345

# Or manual commit with JIRA format
git commit -m "[CCU2-12345] Add container health check feature

Implements periodic health check for container lifecycle management.

JIRA: https://jira.company.com/browse/CCU2-12345"
```

### 5. Push and Create Pull Request
```bash
# Push branch
git push -u origin feature/CCU2-12345-new-feature

# Create JIRA-linked PR
/jira-pr CCU2-12345
```

This automatically creates a PR with:
- JIRA ticket link and details
- Commit summaries
- Testing checklist
- Build information

## Quality Checks

### ⚠️ Build/Test Execution Blocked in This Session

Quality checks must be done via:

#### 1. Jenkins CI/CD (Automatic)
When you create a PR, Jenkins automatically runs:
- **MISRA compliance check** - Static analysis with fatal rules
- **Build verification** - All tiers (LGE, MOBIS) and ECUs (CCU2, CCU2_LITE, BCU)
- **Unit tests** - If applicable
- **Integration tests** - If applicable

#### 2. Builder Environment (Manual)
If you need to test locally:
```bash
# SSH to builder server
ssh builder-kr-4

# Navigate to project
cd /path/to/container-manager

# Run build
./build.sh LGE CCU2

# Run tests (if available)
./build.sh --test

# Run MISRA check
./build.sh --misra-check
```

## What This Session Can Do

### ✅ Code Review
- Review code changes
- Identify potential issues
- Suggest improvements
- Check coding standards

### ✅ JIRA Integration
- Create commits with JIRA references
- Generate PRs with JIRA linking
- Validate ticket format
- Fetch ticket information

### ✅ Git Operations
- Branch management
- Commit creation
- Push to remote
- PR creation

### ✅ Documentation
- Generate documentation
- Update README files
- Create code comments
- Write technical docs

### ✅ Build Configuration Analysis
- Review build.toml
- Analyze CMakeLists.txt
- Check MISRA rules
- Understand tier/ECU setup

## Example Workflows

### Workflow 1: Bug Fix
```bash
# 1. Create branch
git checkout -b fix/CCU2-12346-container-crash

# 2. Fix code
vi src/container_manager.cpp

# 3. Review changes
git diff

# 4. Commit with JIRA
/jira-commit CCU2-12346

# 5. Push and create PR
git push -u origin fix/CCU2-12346-container-crash
/jira-pr CCU2-12346

# 6. Jenkins will run checks automatically:
#    - python3 build.py --tier LGE --ecu CCU2
#    - python3 build.py --tier MOBIS --ecu CCU2_LITE
#    - MISRA compliance check
#    - Unit tests (if applicable)
# 7. Review Jenkins results in PR
# 8. Merge when all checks pass
```

### Workflow 2: New Feature
```bash
# 1. Create feature branch
git checkout -b feature/CCU2-12347-health-monitoring

# 2. Review existing code
/analyze src/container_lifecycle.cpp

# 3. Implement feature
vi src/container_lifecycle.cpp
vi include/container_lifecycle.h

# 4. Review build configuration
/yocto  # Shows build info
/misra  # Shows MISRA rules

# 5. Commit changes
/jira-commit CCU2-12347 --smart-message

# 6. Create PR
git push -u origin feature/CCU2-12347-health-monitoring
/jira-pr CCU2-12347

# 7. Wait for Jenkins checks
# 8. Address any MISRA violations or build failures via code review
# 9. Merge when ready
```

### Workflow 3: Code Review Only
```bash
# 1. Review changes from others
git fetch origin
git checkout origin/feature/some-feature

# 2. Analyze code quality
/analyze src/

# 3. Check for potential issues
# - MISRA violations (code review)
# - Coding standards
# - Best practices

# 4. Provide feedback in PR comments
```

## Command Reference

### JIRA Commands
| Command | Purpose | Session |
|---------|---------|---------|
| `/jira-commit CCU2-XXXXX` | Create JIRA commit | ✅ Normal |
| `/jira-pr CCU2-XXXXX` | Create JIRA PR | ✅ Normal |

### Build Commands (Info Only)
| Command | Purpose | Session |
|---------|---------|---------|
| `/yocto` | Show build info | ℹ️ Info only |
| `/misra` | Show MISRA config | ℹ️ Info only |

### Execution Availability
| Operation | Normal Session | Builder Session | Tester Session |
|-----------|---------------|-----------------|----------------|
| Code editing | ✅ | ✅ | ✅ |
| Git operations | ✅ | ✅ | ✅ |
| JIRA integration | ✅ | ✅ | ✅ |
| Build execution | ❌ | ✅ | ❌ |
| Test execution | ❌ | ✅ | ✅ |
| MISRA analysis | ❌ | ✅ | ❌ |

## Tips

### Tip 1: Use Jenkins for All Builds
Don't try to work around build blocking. Jenkins provides:
- Consistent build environment
- Automated testing
- MISRA compliance checks
- Build artifacts
- Log history

### Tip 2: Review Before Pushing
Always review your changes before pushing:
```bash
git diff HEAD
```

### Tip 3: Keep Commits Focused
One commit per logical change:
- Bug fixes: Single commit
- Features: May need multiple commits
- Refactoring: Separate from feature commits

### Tip 4: Update JIRA Tickets
After creating PR:
- Update JIRA ticket status
- Add PR link to JIRA comments
- Move ticket to "In Review" status

## Troubleshooting

### Build Command Blocked
**Symptom**: "🚫 EXECUTION BLOCKED" message
**Solution**: This is expected. Use Jenkins CI/CD or switch to Builder environment.

### JIRA Integration Fails
**Symptom**: JIRA commands fail
**Solution**: Check `~/.env` has correct `JIRA_URL` and `JIRA_TOKEN`.

### PR Creation Fails
**Symptom**: `gh pr create` fails
**Solution**: Ensure GitHub CLI is authenticated: `gh auth status`.

## Resources
- [SETUP.md](./SETUP.md) - Installation and configuration
- Jenkins: Check your organization's Jenkins URL
- JIRA: https://jira.your-company.com
- Project documentation: `docs/` directory
