#!/bin/bash
# JIRA API integration utilities for container-manager

# Validate ticket format
validate_ticket() {
  local ticket=$1
  if [[ ! $ticket =~ ^CCU2-[0-9]{5}$ ]]; then
    echo "Error: Invalid ticket format. Expected CCU2-XXXXX"
    return 1
  fi
  return 0
}

# Fetch ticket details from JIRA
fetch_ticket() {
  local ticket=$1
  local jira_url=${JIRA_URL}
  local jira_token=${JIRA_TOKEN}

  if [[ -z "$jira_url" ]] || [[ -z "$jira_token" ]]; then
    echo "Error: JIRA_URL or JIRA_TOKEN not set in ~/.env"
    return 1
  fi

  curl -s -H "Authorization: Bearer ${jira_token}" \
    "${jira_url}/rest/api/2/issue/${ticket}"
}

# Extract ticket summary
get_ticket_summary() {
  local ticket=$1
  local response=$(fetch_ticket "$ticket")
  echo "$response" | jq -r '.fields.summary'
}

# Check ticket exists
ticket_exists() {
  local ticket=$1
  local response=$(fetch_ticket "$ticket")
  if [[ $(echo "$response" | jq -r '.errorMessages') != "null" ]]; then
    return 1
  fi
  return 0
}

# Get ticket priority
get_ticket_priority() {
  local ticket=$1
  local response=$(fetch_ticket "$ticket")
  echo "$response" | jq -r '.fields.priority.name'
}

# Get ticket status
get_ticket_status() {
  local ticket=$1
  local response=$(fetch_ticket "$ticket")
  echo "$response" | jq -r '.fields.status.name'
}

export -f validate_ticket
export -f fetch_ticket
export -f get_ticket_summary
export -f ticket_exists
export -f get_ticket_priority
export -f get_ticket_status
