# /jira-commit - JIRA-Integrated Commit

Create git commits with JIRA ticket reference for container-manager.

## Usage
```bash
/jira-commit <ticket-id> [--smart-message]
```

## Arguments
- `<ticket-id>`: CCU2-XXXXX format JIRA ticket ID
- `--smart-message`: Auto-generate commit message from staged changes

## Examples
```bash
# Manual commit message
/jira-commit CCU2-12345

# Auto-generate from changes
/jira-commit CCU2-12345 --smart-message
```

## Commit Message Format
```
[CCU2-12345] <Summary from JIRA or user input>

<Detailed description of changes>

JIRA: https://jira.company.com/browse/CCU2-12345
```

## Implementation Steps

1. **Validate Ticket Format**
   - Check CCU2-XXXXX pattern
   - Error if invalid format

2. **Fetch Ticket Info** (Optional)
   - Get ticket summary from JIRA API
   - Fall back to user input if API unavailable

3. **Analyze Staged Changes**
   - List all staged files
   - Generate summary of changes
   - Identify affected components

4. **Generate or Prompt for Message**
   - If `--smart-message`: Auto-generate from analysis
   - Otherwise: Prompt user for commit message
   - Include ticket reference and JIRA link

5. **Create Commit**
   ```bash
   git commit -m "[CCU2-12345] <message>

   <details>

   JIRA: https://jira.company.com/browse/CCU2-12345"
   ```

## Prerequisites
- `~/.env` must contain:
  - `JIRA_URL`: JIRA instance URL
  - `JIRA_TOKEN`: API token for authentication
- Changes must be staged (`git add`)

## Error Handling
- Invalid ticket format → Error message with example
- No staged changes → Error: "No changes to commit"
- JIRA API failure → Continue with manual message
- Network issues → Fall back to user input
