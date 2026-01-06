---
description: Create Draft PR with CCU-2.0 formatting, JIRA integration, and auto-comment to ticket
---

# JIRA PR Command

Create Pull Request with CCU-2.0 conventions, automatic content generation, and JIRA ticket linking.

## Task

Execute the following steps in order:

### 1. Environment Check

```bash
# Verify gh CLI is authenticated
gh auth status

# Check JIRA credentials (from .env or environment)
# Required: JIRA_EMAIL, JIRA_API_TOKEN, JIRA_BASE_URL
```

If `gh` is not authenticated, instruct user to run `gh auth login`.

### 2. Branch Validation

```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Ensure not on master/main
if [[ "$BRANCH" == "master" || "$BRANCH" == "main" ]]; then
  echo "ERROR: Cannot create PR from master/main branch"
  exit 1
fi

# Extract TICKET-ID from branch name
# Pattern: feature/<TICKET_ID>-description or <TICKET_ID>-description
TICKET_ID=$(echo "$BRANCH" | grep -oE '(CCU2|SEB|CRM|OTA)-[0-9]+')
```

If TICKET-ID is provided as argument, use that instead of extracting from branch.

### 3. Sync with Base Branch (Conflict Prevention)

**IMPORTANT**: Always sync with base branch before PR creation to prevent merge conflicts.

```bash
# Get base branch (default: master)
BASE_BRANCH="${BASE:-master}"

# Identify remote name (origin or ccu)
REMOTE=$(git remote | head -1)

# Fetch latest base branch
git fetch $REMOTE $BASE_BRANCH

# Check if rebase is needed
BEHIND=$(git rev-list --count HEAD..$REMOTE/$BASE_BRANCH)

if [[ "$BEHIND" -gt 0 ]]; then
  echo "⚠️ Branch is $BEHIND commits behind $BASE_BRANCH"
  echo "🔄 Rebasing onto latest $BASE_BRANCH..."

  # Attempt rebase
  if git rebase $REMOTE/$BASE_BRANCH; then
    echo "✅ Rebase successful"
  else
    echo "❌ Rebase conflict detected!"
    echo ""
    echo "Conflicting files:"
    git diff --name-only --diff-filter=U
    echo ""
    echo "Please resolve conflicts manually:"
    echo "  1. Edit conflicting files"
    echo "  2. git add <resolved_files>"
    echo "  3. git rebase --continue"
    echo "  4. Re-run /jira-pr"
    echo ""
    echo "To abort: git rebase --abort"
    exit 1
  fi
else
  echo "✅ Branch is up-to-date with $BASE_BRANCH"
fi
```

**Conflict Resolution Workflow**:

1. If rebase succeeds → Continue to next step
2. If conflict detected:
   - Show conflicting files
   - Pause and instruct user to resolve manually
   - User resolves → `git add` → `git rebase --continue`
   - Re-run `/jira-pr`

**Alternative (Merge instead of Rebase)**:
```bash
# If --merge flag is provided, use merge instead of rebase
if [[ "$USE_MERGE" == "true" ]]; then
  git merge $REMOTE/$BASE_BRANCH --no-edit
fi
```

### 4. Change Analysis

```bash
# Get commits since base (use remote base for accurate comparison)
git log --oneline $REMOTE/$BASE_BRANCH..HEAD

# Get changed files
git diff --name-only $REMOTE/$BASE_BRANCH..HEAD

# Detect CMakeLists.txt changes
CMAKE_CHANGED=$(git diff --name-only $REMOTE/$BASE_BRANCH..HEAD | grep -c "CMakeLists.txt" || echo "0")

# Detect cross-module changes (files in different top-level directories)
MODULES=$(git diff --name-only $REMOTE/$BASE_BRANCH..HEAD | cut -d'/' -f1 | sort -u | wc -l)
```

### 5. Pre-flight Checks

```bash
# Check for unpushed commits
UNPUSHED=$(git log origin/$BRANCH..$BRANCH --oneline 2>/dev/null | wc -l || echo "new")

# If unpushed or new branch, push with upstream
if [[ "$UNPUSHED" != "0" ]]; then
  git push -u origin $BRANCH
fi
```

### 6. PR Content Generation

Generate PR title:
```
[<TICKET_ID>] <Description from first commit or user input>
```

Generate PR body using this template:
```markdown
## Summary

<Generate bullet points from commit messages>

## Test Plan

- [ ] Build passes (`build.py --module <detected_module>`)
- [ ] Unit tests pass
- [ ] Integration tests pass

## Pull Request Checklist

- [x/] CMakeLists.txt modified: <YES if CMAKE_CHANGED > 0, with note about Yocto build log>
- [ ] Cross-module impact reviewed <auto-note if MODULES > 1>

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### 7. PR Creation

```bash
# Create Draft PR (default)
gh pr create --draft \
  --title "[TICKET_ID] Description" \
  --body "$PR_BODY" \
  --base "$BASE_BRANCH"

# Capture PR URL
PR_URL=$(gh pr view --json url -q .url)
```

Use `--web` to open in browser if requested.

### 8. JIRA Integration

Post comment to JIRA ticket with PR URL:

```bash
# Load credentials
source .env 2>/dev/null || true

# JIRA API call
curl -s -X POST \
  -H "Authorization: Basic $(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)" \
  -H "Content-Type: application/json" \
  -d "{\"body\": \"Pull Request created: ${PR_URL}\"}" \
  "${JIRA_BASE_URL}/rest/api/2/issue/${TICKET_ID}/comment"
```

Skip if `--no-jira` flag is provided.

## Usage

```
/jira-pr CCU2-18882              # Create draft PR for ticket
/jira-pr                          # Auto-detect ticket from branch
/jira-pr --ready                  # Create as review-ready (not draft)
/jira-pr --base develop           # Target develop branch
/jira-pr --title "Custom title"   # Override title
/jira-pr --no-jira                # Skip JIRA comment
/jira-pr --web                    # Open PR in browser after creation
```

## Arguments

| Argument | Description |
|----------|-------------|
| `TICKET-ID` | JIRA ticket ID (CCU2-*, SEB-*, CRM-*). Auto-detected from branch if omitted |
| `--ready` | Create as review-ready PR instead of draft |
| `--draft` | Create as draft PR (default) |
| `--base <branch>` | Target branch for PR (default: master) |
| `--title "..."` | Override auto-generated title |
| `--no-jira` | Skip posting comment to JIRA ticket |
| `--no-push` | Don't auto-push unpushed commits |
| `--no-sync` | Skip syncing with base branch (not recommended) |
| `--merge` | Use merge instead of rebase for sync (preserves commit history) |
| `--web` | Open PR in browser after creation |

## Output

Upon successful execution:

```
🔄 Syncing with master...
   Fetching latest master from remote...
   ✅ Branch is up-to-date with master
   (or: ✅ Rebased 2 commits onto latest master)

✅ PR Created (Draft)
   URL: https://github.com/sonatus/container-manager/pull/XXX
   Title: [CCU2-18882] Description
   Base: master ← feature/CCU2-18882-description

✅ JIRA Comment Added
   Ticket: CCU2-18882
   Comment: "Pull Request created: <URL>"

📋 Summary:
   - 3 commits included
   - 5 files changed
   - CMakeLists.txt: No changes
   - Cross-module: No
   - Sync status: Up-to-date
```

## Error Handling

| Error | Resolution |
|-------|------------|
| `gh: command not found` | Install GitHub CLI: `brew install gh` or `sudo apt install gh` |
| `gh: not authenticated` | Run `gh auth login` to authenticate |
| `Not on feature branch` | Switch to feature branch: `git checkout feature/TICKET-ID-description` |
| `No commits to push` | Make commits before creating PR |
| `JIRA auth failed` | Check .env file for JIRA_EMAIL, JIRA_API_TOKEN, JIRA_BASE_URL |
| `Rebase conflict` | Resolve conflicts manually, then `git rebase --continue` and re-run `/jira-pr` |
| `Branch behind master` | Will auto-rebase; use `--no-sync` to skip (not recommended) |

## Examples

### Basic usage (auto-detect ticket from branch)
```
$ git checkout feature/CCU2-18882-add-health-check
$ /jira-pr

✅ PR Created (Draft)
   URL: https://github.com/sonatus/container-manager/pull/640
   Title: [CCU2-18882] Add health check endpoint
```

### With explicit ticket ID
```
$ /jira-pr CCU2-18882

✅ PR Created (Draft)
   URL: https://github.com/sonatus/container-manager/pull/640
```

### Review-ready PR (not draft)
```
$ /jira-pr --ready

✅ PR Created (Ready for Review)
   URL: https://github.com/sonatus/container-manager/pull/640
```

### Skip JIRA integration
```
$ /jira-pr --no-jira

✅ PR Created (Draft)
   URL: https://github.com/sonatus/container-manager/pull/640

⏭️ JIRA comment skipped (--no-jira)
```

## Integration with Workflow

This command is designed to be used after `/jira-commit`:

```
# Typical workflow
/jira-commit CCU2-18882 "Add new feature"   # Create commit
/jira-pr                                      # Create PR (auto-detects ticket)
```

Or as part of the full `/snt-ccu2-host` pipeline:
```
/snt-ccu2-host CCU2-18882
  → analyze → implement → build → test → /jira-commit → /jira-pr
```
