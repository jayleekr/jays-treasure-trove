---
description: Create properly formatted commit with JIRA ticket integration
---

# JIRA Commit Command

Create commit with proper CCU-2.0 formatting and JIRA ticket integration.

## Task

1. **Ticket Validation**
   - Validate JIRA ticket format (CCU2-*, SEB-*, CRM-*)
   - Optionally fetch ticket title from JIRA API
   - Suggest ticket prefix if missing

2. **Change Analysis**
   - Show git diff summary
   - Identify affected components
   - Suggest commit scope

3. **Commit Message Generation**
   - Format: `[TICKET-ID] Description (#PR)`
   - Generate description from changes
   - Add component tags if multiple components affected

4. **Validation**
   - Check commit message length
   - Verify ticket format
   - Ensure description is meaningful

5. **Execution**
   - Stage changes (if not staged)
   - Create commit with formatted message
   - Show commit hash and summary

## Usage

```
/jira-commit CCU2-15604 "Remove Adaptive AUTOSAR dependency"
/jira-commit SEB-1294                # Auto-generate description
/jira-commit --amend CCU2-15604      # Amend last commit
```

## Ticket Prefixes

- `CCU2-*` - Main CCU2 features/bugs
- `SEB-*` - Software Engineering Board
- `CRM-*` - Container/Resource Management

## Output

- Formatted commit message
- Files committed
- Commit hash
- Suggested next steps (push, PR creation)
