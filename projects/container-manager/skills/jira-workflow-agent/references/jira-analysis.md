# JIRA Analysis Reference

JIRA REST API 통합 및 티켓 파싱 패턴 가이드.

## JIRA REST API Integration

### Authentication

**Basic Auth** 방식 사용:
```bash
# ~/.env에서 credentials 로드
JIRA_BASE_URL=https://sonatus.atlassian.net/
JIRA_EMAIL=your.email@sonatus.com
JIRA_API_TOKEN=your_api_token

# Base64 인코딩
AUTH=$(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)

# API 호출
curl -s -H "Authorization: Basic ${AUTH}" \
  "${JIRA_BASE_URL}/rest/api/3/issue/CCU2-12345"
```

### API Endpoints

| Endpoint | Method | Purpose | API Version |
|----------|--------|---------|-------------|
| `/rest/api/3/issue/{TICKET_ID}` | GET | Fetch single ticket details | v3 |
| `/rest/api/3/search/jql` | POST | Search tickets via JQL | v3 |
| `/rest/api/3/issue/{TICKET_ID}/comment` | POST | Add comment | v3 |

### Ticket ID Validation

```bash
validate_ticket() {
  local ticket=$1
  # Valid formats: CCU2-12345, SEB-1294, CRM-567
  if [[ ! $ticket =~ ^(CCU2|SEB|CRM)-[0-9]{5}$ ]]; then
    echo "Error: Invalid ticket format. Expected CCU2-XXXXX"
    return 1
  fi
  return 0
}
```

### Fetch Ticket Data

```bash
fetch_ticket() {
  local ticket_id=$1
  local response=$(curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
    "${JIRA_BASE_URL}/rest/api/3/issue/${ticket_id}")

  # Check for errors
  if [[ $(echo "$response" | jq -r '.errorMessages') != "null" ]]; then
    echo "Error: Ticket not found or access denied"
    return 1
  fi

  echo "$response"
}
```

## Data Extraction Patterns

### Core Fields

```bash
# Summary (티켓 제목)
get_summary() {
  local response=$1
  echo "$response" | jq -r '.fields.summary'
}

# Description (상세 내용)
get_description() {
  local response=$1
  echo "$response" | jq -r '.fields.description.content[].content[].text' | paste -sd ' ' -
}

# Status
get_status() {
  local response=$1
  echo "$response" | jq -r '.fields.status.name'
}

# Priority
get_priority() {
  local response=$1
  echo "$response" | jq -r '.fields.priority.name'
}

# Issue Type
get_issue_type() {
  local response=$1
  echo "$response" | jq -r '.fields.issuetype.name'
}

# Components
get_components() {
  local response=$1
  echo "$response" | jq -r '.fields.components[].name'
}

# Labels
get_labels() {
  local response=$1
  echo "$response" | jq -r '.fields.labels[]'
}
```

### CCU2 Custom Fields

```bash
# H/W Type (customfield_10478)
get_hw_type() {
  local response=$1
  echo "$response" | jq -r '.fields.customfield_10478.value'
}

# Category (customfield_10158)
get_category() {
  local response=$1
  echo "$response" | jq -r '.fields.customfield_10158.value'
}

# RN Components (customfield_10577)
get_rn_components() {
  local response=$1
  echo "$response" | jq -r '.fields.customfield_10577[].value'
}
```

### Response Structure Example

```json
{
  "key": "CCU2-17741",
  "fields": {
    "summary": "Add config parameter for daemon startup",
    "description": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [
            {"type": "text", "text": "Add CONFIG_STARTUP_DELAY parameter..."}
          ]
        }
      ]
    },
    "status": {"name": "To Do"},
    "priority": {"name": "High"},
    "issuetype": {"name": "Story"},
    "components": [{"name": "container-manager"}],
    "labels": ["feature", "config"],
    "issuelinks": [
      {
        "type": {"name": "Depends"},
        "outwardIssue": {"key": "CCU2-17500"}
      }
    ]
  }
}
```

## Work Type Classification

### Classification Algorithm

```python
def classify_work_type(issue_type, labels, summary):
    """
    Classify JIRA ticket into work type categories.

    Returns: "feature" | "bugfix" | "refactor" | "doc-update"
    """
    # Rule 1: Issue Type based
    if issue_type in ["Bug", "Defect"]:
        return "bugfix"

    if issue_type in ["Story", "Epic"]:
        # Check labels for further classification
        if "refactor" in labels or "tech-debt" in labels:
            return "refactor"
        return "feature"

    # Rule 2: Keyword based
    keywords = {
        "feature": ["implement", "add", "create", "new", "develop"],
        "bugfix": ["fix", "resolve", "correct", "crash", "error"],
        "refactor": ["improve", "optimize", "clean", "refactor", "reorganize"],
        "doc-update": ["document", "README", "guide", "manual", "docs"]
    }

    summary_lower = summary.lower()
    for work_type, words in keywords.items():
        if any(word in summary_lower for word in words):
            return work_type

    # Default
    return "feature"
```

### Complexity Estimation

```python
def estimate_complexity(description, components, issuelinks):
    """
    Estimate implementation complexity.

    Returns: "low" | "medium" | "high"
    """
    score = 0

    # Factor 1: Description length
    if len(description) < 200:
        score += 1
    elif len(description) < 500:
        score += 2
    else:
        score += 3

    # Factor 2: Number of components
    component_count = len(components)
    if component_count <= 1:
        score += 1
    elif component_count <= 3:
        score += 2
    else:
        score += 3

    # Factor 3: Dependencies
    dependency_count = len(issuelinks)
    if dependency_count > 0:
        score += 2

    # Classification
    if score <= 3:
        return "low"
    elif score <= 6:
        return "medium"
    else:
        return "high"
```

## Requirements Parsing

### Acceptance Criteria Extraction

```python
def extract_acceptance_criteria(description_text):
    """
    Extract acceptance criteria from ticket description.

    Common patterns:
    - "Acceptance Criteria:"
    - "AC:"
    - Numbered/bulleted lists after keywords
    """
    import re

    # Pattern 1: Explicit "Acceptance Criteria" section
    ac_patterns = [
        r'Acceptance Criteria:?\s*\n((?:[-*\d.]\s+.+\n?)+)',
        r'AC:?\s*\n((?:[-*\d.]\s+.+\n?)+)',
        r'Requirements:?\s*\n((?:[-*\d.]\s+.+\n?)+)'
    ]

    for pattern in ac_patterns:
        match = re.search(pattern, description_text, re.MULTILINE | re.IGNORECASE)
        if match:
            criteria_text = match.group(1)
            # Parse individual criteria
            criteria = re.findall(r'[-*\d.]\s+(.+)', criteria_text)
            return criteria

    # Pattern 2: First bulleted list in description
    lists = re.findall(r'((?:[-*]\s+.+\n?)+)', description_text)
    if lists:
        criteria = re.findall(r'[-*]\s+(.+)', lists[0])
        return criteria

    return []
```

### File Path Identification

```python
def identify_affected_files(description, components):
    """
    Identify files likely to be affected by the change.

    Sources:
    1. Explicit mentions in description
    2. Component-to-directory mapping
    3. Common patterns
    """
    import re

    affected_files = []

    # Pattern 1: Explicit file mentions
    # Examples: "File: `src/main.cpp`", "Modified: include/config.h"
    file_patterns = [
        r'[Ff]ile:?\s*`?([a-zA-Z0-9_/.-]+\.[a-zA-Z]+)`?',
        r'[Mm]odified:?\s*`?([a-zA-Z0-9_/.-]+\.[a-zA-Z]+)`?',
        r'[Pp]ath:?\s*`?([a-zA-Z0-9_/.-]+\.[a-zA-Z]+)`?'
    ]

    for pattern in file_patterns:
        matches = re.findall(pattern, description)
        affected_files.extend(matches)

    # Pattern 2: Component mapping
    component_map = {
        "container-manager": ["src/container-manager/", "include/container-manager/"],
        "CM Daemon": ["src/cm-daemon/"],
        "deployment-manager": ["src/deployment-manager/"],
        "libsntxx": ["src/libsntxx/", "include/libsntxx/"],
        "diagnostic-manager": ["src/diagnostic-manager/"]
    }

    for component in components:
        if component in component_map:
            # Return directories for now
            affected_files.extend(component_map[component])

    return list(set(affected_files))  # Deduplicate
```

## Execution Plan Generation

### Plan Structure

```python
def generate_execution_plan(ticket_data):
    """
    Generate structured execution plan from JIRA ticket.

    Returns: dict with phases, tasks, estimates
    """
    work_type = classify_work_type(
        ticket_data["issuetype"],
        ticket_data["labels"],
        ticket_data["summary"]
    )

    complexity = estimate_complexity(
        ticket_data["description"],
        ticket_data["components"],
        ticket_data["issuelinks"]
    )

    acceptance_criteria = extract_acceptance_criteria(
        ticket_data["description"]
    )

    affected_files = identify_affected_files(
        ticket_data["description"],
        ticket_data["components"]
    )

    # Time estimates based on complexity
    time_estimates = {
        "low": "15-30 minutes",
        "medium": "30-60 minutes",
        "high": "1-3 hours"
    }

    plan = {
        "ticket_id": ticket_data["key"],
        "summary": ticket_data["summary"],
        "work_type": work_type,
        "complexity": complexity,
        "priority": ticket_data["priority"],
        "estimated_duration": time_estimates[complexity],
        "phases": ["analyze", "implement", "verify", "submit"],
        "acceptance_criteria": acceptance_criteria,
        "affected_files": affected_files,
        "tasks": generate_task_list(work_type, acceptance_criteria)
    }

    return plan

def generate_task_list(work_type, acceptance_criteria):
    """Generate specific tasks based on work type."""
    base_tasks = [
        "Create feature branch",
        "Implement code changes",
        "Run build and tests",
        "Create commit",
        "Create pull request"
    ]

    # Add work-type specific tasks
    if work_type == "feature":
        base_tasks.insert(1, "Add new functionality")
        base_tasks.insert(3, "Add unit tests")
    elif work_type == "bugfix":
        base_tasks.insert(1, "Identify root cause")
        base_tasks.insert(2, "Fix the issue")
        base_tasks.insert(4, "Add regression test")
    elif work_type == "refactor":
        base_tasks.insert(1, "Refactor code structure")
        base_tasks.insert(3, "Verify no behavior change")

    # Add acceptance criteria as tasks
    for i, criterion in enumerate(acceptance_criteria, 1):
        base_tasks.insert(2, f"AC{i}: {criterion}")

    return base_tasks
```

## Error Handling

### JIRA API Errors

| Status | Error | Resolution |
|--------|-------|-----------|
| 401 | Unauthorized | Check JIRA_API_TOKEN in ~/.env |
| 403 | Forbidden | Verify ticket access permissions |
| 404 | Not Found | Check ticket ID format |
| 429 | Rate Limited | Wait and retry after Retry-After header |

### Detection and Recovery

```bash
check_jira_response() {
  local response=$1

  # Check for error messages
  local error=$(echo "$response" | jq -r '.errorMessages[]' 2>/dev/null)
  if [[ -n "$error" && "$error" != "null" ]]; then
    echo "JIRA API Error: $error"
    return 1
  fi

  # Check for HTML (auth failure)
  if echo "$response" | grep -q "<html"; then
    echo "Authentication failed. Check JIRA credentials in ~/.env"
    return 1
  fi

  return 0
}
```

## Usage Examples

### Example 1: Fetch and Analyze Ticket

```bash
#!/bin/bash

# Source utilities
source ~/.claude-config/projects/container-manager/scripts/jira-integration.sh

# Fetch ticket
TICKET_ID="CCU2-17741"
response=$(fetch_ticket "$TICKET_ID")

# Extract data
summary=$(get_summary "$response")
description=$(get_description "$response")
priority=$(get_priority "$response")
components=$(get_components "$response")

echo "Summary: $summary"
echo "Priority: $priority"
echo "Components: $components"
```

### Example 2: Generate Execution Plan

```python
# Python implementation
import requests
import json
from base64 import b64encode

# Load credentials
jira_url = os.getenv("JIRA_BASE_URL")
jira_email = os.getenv("JIRA_EMAIL")
jira_token = os.getenv("JIRA_API_TOKEN")

# Fetch ticket
ticket_id = "CCU2-17741"
auth = b64encode(f"{jira_email}:{jira_token}".encode()).decode()
headers = {"Authorization": f"Basic {auth}"}

response = requests.get(
    f"{jira_url}/rest/api/3/issue/{ticket_id}",
    headers=headers
)

ticket_data = response.json()

# Generate plan
plan = generate_execution_plan(ticket_data)

# Save to memory
write_memory(f"plan_{ticket_id}", json.dumps(plan))

# Display
print(json.dumps(plan, indent=2))
```

## Best Practices

1. **Always validate ticket ID** before API calls
2. **Cache ticket data** to avoid repeated API calls
3. **Check for dependencies** in issuelinks field
4. **Parse description carefully** - may contain AsciiDoc or Markdown
5. **Map components to code paths** for accurate file identification
6. **Use custom fields** for CCU2-specific metadata
7. **Handle rate limits** with exponential backoff
8. **Verify credentials** before starting workflow

## Troubleshooting

**Issue**: "Authentication failed"
- **Check**: JIRA_EMAIL and JIRA_API_TOKEN in ~/.env
- **Solution**: Regenerate API token from JIRA settings

**Issue**: "Ticket not found"
- **Check**: Ticket ID format (CCU2-XXXXX)
- **Solution**: Verify ticket exists and you have access

**Issue**: "Empty description"
- **Check**: Ticket has description field populated
- **Solution**: Ask user to clarify requirements manually

**Issue**: "Cannot determine work type"
- **Check**: Issue type and labels
- **Solution**: Use default "feature" and ask user to clarify
