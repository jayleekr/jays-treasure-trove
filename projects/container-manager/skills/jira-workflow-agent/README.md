# JIRA Workflow Agent - Usage Guide

Complete guide for using the JIRA Workflow Agent skill.

## Quick Start

### Prerequisites

1. **JIRA Credentials** - Configure in `~/.env`:
   ```bash
   JIRA_BASE_URL=https://sonatus.atlassian.net/
   JIRA_EMAIL=your.email@sonatus.com
   JIRA_API_TOKEN=your_api_token_here
   ```

2. **GitHub CLI** - Authenticated and ready:
   ```bash
   gh auth status
   ```

3. **Git Repository** - Initialized with remote configured

### Basic Usage

Simply provide a JIRA ticket URL or ID:

```
https://sonatus.atlassian.net/browse/CCU2-17741
```

Or:

```
CCU2-17741
```

The agent will automatically:
1. ✅ Analyze the ticket
2. ⚠️ **[Approval 1]** Ask for implementation approval
3. ✅ Implement code changes
4. ✅ Run build & tests
5. ⚠️ **[Approval 2]** Ask for PR approval
6. ✅ Create pull request

---

## Workflow Modes

### Mode 1: ANALYZE (Automatic)

**Purpose**: Analyze JIRA ticket and generate execution plan

**Example Request**:
```
Analyze this JIRA ticket: CCU2-17741
```

**Output**:
```markdown
## 📋 Execution Plan

**JIRA**: CCU2-17741 - Add config parameter for daemon startup
**Work Type**: Feature
**Priority**: High
**Complexity**: Medium

### Affected Files:
- src/daemon/main.cpp
- include/config.h

### Acceptance Criteria:
- [ ] Parameter configurable via config file
- [ ] Invalid values rejected
- [ ] Applied on daemon startup

### Estimated Effort: 15-20 minutes
```

---

### Mode 2: IMPLEMENT (Approval Required ⚠️)

**Purpose**: Create feature branch and implement code

**Approval Checkpoint 1**:
```markdown
## 🔍 Implementation Plan Review

**Proceed with code implementation?**
- approve - Continue
- modify - Adjust plan
- reject - Abort
```

**User Response**: `approve`

**Actions**:
- Creates feature branch: `CCU2-17741-add-config-parameter`
- Implements code changes based on plan
- Updates affected files

---

### Mode 3: VERIFY (Automatic)

**Purpose**: Run build and tests

**Output**:
```markdown
## ✅ Verification Report

- ✅ Build: PASSED (0 errors, 0 warnings)
- ✅ Tests: PASSED (15/15 tests)
- ✅ MISRA: PASSED (0 violations)
- ✅ Quality: Grade A

Ready for submission.
```

---

### Mode 4: SUBMIT (Approval Required ⚠️)

**Purpose**: Create commit and pull request

**Approval Checkpoint 2**:
```markdown
## 📤 Pull Request Review

**Verification Results**:
- ✅ All checks passed

**Create pull request?**
- approve - Create PR
- modify - Edit details
- reject - Commit only
```

**User Response**: `approve`

**Actions**:
- Creates commit using `/jira-commit`
- Creates PR using `/jira-pr`
- Links JIRA ticket

---

### Mode 5: COMPLETE (Orchestrator)

**Purpose**: Execute full pipeline end-to-end

**Example Request**:
```
Complete workflow for CCU2-17741
```

**Process**:
```
ANALYZE → IMPLEMENT (approval) → VERIFY → SUBMIT (approval) → COMPLETE
```

---

## Usage Scenarios

### Scenario 1: Full Automation

**User Request**:
```
Implement this JIRA ticket: https://sonatus.atlassian.net/browse/CCU2-17741
```

**Agent Actions**:
1. Analyzes ticket
2. Shows implementation plan → **[User approves]**
3. Implements code
4. Runs verification
5. Shows PR details → **[User approves]**
6. Creates PR

**Result**: PR created and ready for review

---

### Scenario 2: Analysis Only

**User Request**:
```
Analyze CCU2-17741 and create a plan
```

**Agent Actions**:
1. Fetches ticket data
2. Classifies work type
3. Generates execution plan
4. Shows checklist

**Result**: Implementation plan for manual execution

---

### Scenario 3: Resume from Interruption

**User Request** (after session restart):
```
Continue working on CCU2-17741
```

**Agent Actions**:
1. Lists memories: `list_memories()`
2. Finds existing plan: `plan_CCU2-17741`
3. Checks last completed phase
4. Asks: "Resume from [last phase]?"
5. **[User confirms]**
6. Continues workflow

**Result**: Seamless continuation from where you left off

---

### Scenario 4: Build/Test Only

**User Request**:
```
Run verification for CCU2-17741
```

**Agent Actions**:
1. Detects build system
2. Runs build
3. Runs tests
4. Runs static analysis
5. Generates report

**Result**: Verification report without code changes

---

## Approval Checkpoints

### Checkpoint 1: Before Implementation

**When**: After analysis, before code changes

**You Can**:
- ✅ **Approve**: Proceed with implementation
- 🔧 **Modify**: Adjust files, approach, or criteria
- ❌ **Reject**: Abort workflow

**Modification Options**:
```
What would you like to change?
- files - Adjust affected files list
- approach - Change implementation approach
- criteria - Update acceptance criteria
```

---

### Checkpoint 2: Before PR Creation

**When**: After verification, before PR

**You Can**:
- ✅ **Approve**: Create PR now
- 🔧 **Modify**: Edit PR title, description, reviewers
- ❌ **Reject**: Keep commits only (no PR)

**Modification Options**:
```
What would you like to change?
- title - Edit PR title
- description - Edit PR description
- reviewers - Add/change reviewers
- labels - Add/change labels
```

---

## Error Handling

### Build Failure

**Error**:
```
❌ Build failed with 3 errors
```

**Recovery Options**:
- `fix` - Fix manually and retry
- `rollback` - Undo changes
- `abort` - Stop workflow

---

### Test Failure

**Error**:
```
❌ Tests Failed (3/15 failed)
```

**Recovery Options**:
- `fix` - Investigate and fix
- `rollback` - Undo changes
- `abort` - Stop workflow

---

### JIRA API Error

**Error**:
```
❌ JIRA API timeout
```

**Recovery**:
- Automatic retry (3 attempts with exponential backoff)
- If fails: Manual ticket ID entry

---

## Rollback Levels

### Level 1: Soft Rollback
```bash
git reset --hard HEAD
```
- Reverts uncommitted changes
- Preserves branch and commits

### Level 2: Branch Rollback
```bash
git checkout master
git branch -D CCU2-17741-*
```
- Deletes feature branch
- Returns to base branch

### Level 3: Memory Rollback
- Clears workflow memories
- Preserves code changes

### Level 4: Complete Rollback
- Deletes everything (branch + memories)
- Full reset

---

## Advanced Features

### Cross-Session Persistence

**Automatic State Saving**:
- Every 30 minutes: `checkpoint_{timestamp}_{ticket_id}`
- After each phase: `phase_{N}_{mode}_{ticket_id}`
- After approvals: `checkpoint_{1|2}_{ticket_id}`

**Resume Workflow**:
```
Continue CCU2-17741
```

Agent will:
1. Load last checkpoint
2. Show progress so far
3. Ask to continue
4. Resume from last phase

---

### Memory Management

**View Progress**:
```
Show me the status of CCU2-17741
```

**Clear Memories** (after completion):
```
Cleanup CCU2-17741 workflow
```

---

### Custom Commit Messages

**Override Default**:
```
Use custom commit message for CCU2-17741:
"feat: add configurable startup delay with validation"
```

---

### Custom PR Details

**Override Default**:
```
Create PR for CCU2-17741 with custom title:
"[CCU2-17741] Implement configurable daemon startup delay"
```

---

## Best Practices

### 1. Clear JIRA Tickets

Ensure your JIRA ticket has:
- ✅ Clear summary
- ✅ Detailed description
- ✅ Acceptance criteria listed
- ✅ Affected components tagged

### 2. Clean Git State

Before starting:
```bash
git status  # No uncommitted changes
git branch  # On main/master
```

### 3. Review Approvals Carefully

At each checkpoint:
- Read the plan/details thoroughly
- Verify files and approach
- Modify if needed before approving

### 4. Monitor Verification

Check build/test output:
- Address failures immediately
- Don't skip quality checks
- Use rollback if needed

### 5. Keep Sessions Active

For long workflows:
- Stay engaged during execution
- Respond to prompts promptly
- Resume if interrupted

---

## Troubleshooting

### Skill Not Activating

**Symptoms**: Agent doesn't recognize JIRA workflow request

**Solutions**:
1. Use explicit trigger words:
   - "JIRA workflow"
   - "ticket automation"
   - "implement JIRA ticket"

2. Provide full JIRA URL:
   - `https://sonatus.atlassian.net/browse/CCU2-17741`

3. Check skill is enabled:
   ```bash
   ls ~/.claude-config/projects/container-manager/skills/
   ```

---

### JIRA Authentication Failing

**Symptoms**: "401 Unauthorized" or "403 Forbidden"

**Solutions**:
1. Check `~/.env`:
   ```bash
   cat ~/.env | grep JIRA
   ```

2. Regenerate API token:
   - Visit: https://id.atlassian.com/manage-profile/security/api-tokens
   - Create new token
   - Update `~/.env`

3. Verify email matches JIRA account

---

### Build System Not Detected

**Symptoms**: "No supported build system detected"

**Solutions**:
1. Ensure build files exist:
   - CMake: `CMakeLists.txt`
   - Yocto: `bitbake.conf` or `poky/`
   - npm: `package.json`
   - Cargo: `Cargo.toml`
   - Make: `Makefile`

2. Run from project root:
   ```bash
   cd /path/to/container-manager
   ```

---

### PR Creation Fails

**Symptoms**: "gh: command not found" or "not authenticated"

**Solutions**:
1. Install GitHub CLI:
   ```bash
   brew install gh  # macOS
   ```

2. Authenticate:
   ```bash
   gh auth login
   ```

3. Verify authentication:
   ```bash
   gh auth status
   ```

---

## Examples

### Example 1: Simple Feature Implementation

**Request**:
```
Implement CCU2-17741
```

**Workflow**:
1. Agent analyzes ticket
2. Shows plan with 3 files to modify
3. **[You approve]**
4. Agent implements code
5. Build passes, tests pass
6. Agent shows PR details
7. **[You approve]**
8. PR created: `https://github.com/org/repo/pull/123`

**Duration**: ~15-20 minutes

---

### Example 2: Complex Feature with Adjustments

**Request**:
```
Complete workflow for CCU2-18500
```

**Workflow**:
1. Agent analyzes complex ticket
2. Shows plan with 8 files across 3 components
3. **[You modify: remove 2 files, adjust approach]**
4. Agent updates plan
5. **[You approve modified plan]**
6. Agent implements code
7. Build passes, but 2 tests fail
8. Agent shows failures
9. **[You choose: fix manually]**
10. You fix tests
11. **[You run: "retry verification for CCU2-18500"]**
12. All tests pass
13. Agent shows PR details
14. **[You approve]**
15. PR created

**Duration**: ~1-2 hours

---

### Example 3: Analysis Only (Planning)

**Request**:
```
Analyze CCU2-19000 and create implementation plan
```

**Workflow**:
1. Agent fetches ticket
2. Analyzes requirements
3. Generates detailed plan:
   - Work type: Refactoring
   - Complexity: High
   - 12 files affected
   - 5 acceptance criteria
   - Estimated: 2-3 hours
4. Creates TodoWrite checklist
5. Saves to memory
6. Shows plan

**Result**: You have a complete plan to execute manually or later

---

## Testing Checklist

Use this checklist when testing the skill:

### Pre-Test Setup
- [ ] JIRA credentials configured in `~/.env`
- [ ] GitHub CLI authenticated (`gh auth status`)
- [ ] Git repository clean (`git status`)
- [ ] On main/master branch (`git branch`)

### Test 1: Simple Feature
- [ ] Provide JIRA ticket URL
- [ ] Agent analyzes ticket successfully
- [ ] Execution plan generated correctly
- [ ] Approve implementation
- [ ] Code changes applied correctly
- [ ] Build and tests pass
- [ ] Approve PR creation
- [ ] PR created successfully
- [ ] JIRA ticket linked in PR

### Test 2: Modification Flow
- [ ] Provide JIRA ticket
- [ ] Choose "modify" at checkpoint 1
- [ ] Successfully adjust plan
- [ ] Re-approve modified plan
- [ ] Implementation proceeds

### Test 3: Error Recovery
- [ ] Introduce deliberate build error
- [ ] Verify error is caught
- [ ] Recovery options presented
- [ ] Choose "rollback"
- [ ] State restored successfully

### Test 4: Session Resume
- [ ] Start workflow
- [ ] Interrupt after analysis phase
- [ ] Restart session
- [ ] Request resume
- [ ] Workflow continues from checkpoint

### Test 5: Memory Persistence
- [ ] Complete full workflow
- [ ] Check memory keys exist
- [ ] Request status/progress
- [ ] Verify correct state reported
- [ ] Cleanup memories

---

## FAQ

**Q: Can I use this for non-CCU2 tickets?**
A: Yes, it supports CCU2, SEB, and CRM projects.

**Q: What if my ticket doesn't have acceptance criteria?**
A: The agent will generate a plan based on description and summary.

**Q: Can I skip the approval checkpoints?**
A: Not recommended. Semi-auto mode requires 2 approvals for safety.

**Q: What happens if I reject at checkpoint 1?**
A: Workflow stops, branch is optionally deleted, no code changes made.

**Q: Can I modify the plan after approval?**
A: Yes, use "modify" option at approval checkpoint.

**Q: How do I resume an interrupted workflow?**
A: Just say "Continue working on CCU2-XXXXX"

**Q: Can I run only build/test without implementation?**
A: Yes, request "Verify CCU2-XXXXX" or use Mode 3 directly.

**Q: What if tests fail?**
A: You can fix manually and retry, or rollback changes.

**Q: Is the skill language-specific?**
A: No, it works with any project (C/C++, Python, JS, etc.)

**Q: Can I customize commit messages?**
A: Yes, either through modification at checkpoint or by providing custom message.

---

## Version History

- **v1.0.0** (2026-01-07)
  - Initial release
  - 5-mode workflow (ANALYZE, IMPLEMENT, VERIFY, SUBMIT, COMPLETE)
  - Semi-auto with 2 approval checkpoints
  - TodoWrite + Serena memory integration
  - Error recovery with 4 rollback levels
  - Cross-session resume capability
  - Integration with `/jira-commit` and `/jira-pr`

---

## Support

For issues or questions:
1. Check this README
2. Review reference documentation in `references/`
3. Check JIRA integration script: `~/.claude-config/projects/container-manager/scripts/jira-integration.sh`
4. Contact CCU2 team

---

## Reference Documentation

Detailed technical documentation:

- **`skill.md`** - Main skill definition and mode overview
- **`references/jira-analysis.md`** - JIRA API patterns and ticket parsing
- **`references/workflow-modes.md`** - Complete mode implementation logic
- **`references/approval-checkpoints.md`** - Approval UI/UX and handling
- **`references/memory-schema.md`** - Serena memory structure and TodoWrite integration
- **`references/error-recovery.md`** - Error handling and rollback mechanisms
- **`references/integration-commands.md`** - `/jira-commit` and `/jira-pr` integration
