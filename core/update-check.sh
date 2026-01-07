#!/bin/bash
# Git Update Notification System for jays-treasure-trove
# Checks for updates once per day and displays warnings when commands/skills have changed

# Configuration
JAYS_TREASURE_DIR="${HOME}/.claude-config"
TIMESTAMP_FILE="${JAYS_TREASURE_DIR}/.update-check-timestamp"
CHECK_INTERVAL_SECONDS=$((24 * 60 * 60))  # 24 hours

# Function 1: Check if update check is needed (24-hour interval)
should_check_updates() {
    # If timestamp file doesn't exist, check is needed
    if [[ ! -f "$TIMESTAMP_FILE" ]]; then
        return 0  # Check needed
    fi

    local current_time=$(date +%s)
    local last_check=$(cat "$TIMESTAMP_FILE" 2>/dev/null || echo "0")
    local time_diff=$((current_time - last_check))

    if [[ $time_diff -ge $CHECK_INTERVAL_SECONDS ]]; then
        return 0  # Check needed (24+ hours passed)
    else
        return 1  # Skip check (< 24 hours)
    fi
}

# Function 2: Fetch remote changes with timeout
fetch_remote_changes() {
    # 5-second timeout to prevent hanging
    timeout 5 git fetch origin master 2>/dev/null
    return $?
}

# Function 3: Get current commit hash
get_current_commit() {
    git rev-parse --short HEAD 2>/dev/null
}

# Function 4: Get remote commit hash
get_remote_commit() {
    git rev-parse --short origin/master 2>/dev/null
}

# Function 5: Get list of changed commands/skills
get_changed_commands() {
    local current=$(get_current_commit)
    local remote=$(get_remote_commit)

    if [[ -z "$current" || -z "$remote" ]]; then
        return 1
    fi

    # Get changed .md files in commands/ and skills/ directories
    git diff --name-only "$current..$remote" 2>/dev/null | \
        grep -E '(commands|skills)/.*\.md$' | \
        sed 's|.*/\(.*\)\.md|\1|' | \
        sort -u
}

# Function 6: Detect breaking changes in commit messages
detect_breaking_changes() {
    local current=$(get_current_commit)
    local remote=$(get_remote_commit)

    if [[ -z "$current" || -z "$remote" ]]; then
        return 1
    fi

    # Search for "BREAKING:" prefix in commit messages
    if git log --oneline "$current..$remote" 2>/dev/null | grep -q "BREAKING:"; then
        return 0  # Breaking changes found
    else
        return 1  # No breaking changes
    fi
}

# Function 7: Display update warning
display_update_warning() {
    local current=$(get_current_commit)
    local remote=$(get_remote_commit)
    local changed_files=$(get_changed_commands)

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  jays-treasure-trove UPDATE AVAILABLE                        ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Current:  ${current}                                           ║"
    echo "║  Latest:   ${remote}                                           ║"
    echo "║                                                              ║"

    if [[ -n "$changed_files" ]]; then
        echo "║  Changed Commands/Skills:                                    ║"
        while IFS= read -r file; do
            printf "║    • %-55s║\n" "$file"
        done <<< "$changed_files"
        echo "║                                                              ║"
    fi

    if detect_breaking_changes; then
        echo "║  ⚠️  BREAKING CHANGES DETECTED                               ║"
        echo "║                                                              ║"
    fi

    echo "║  To update: cd ~/.claude-config && git pull                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function 8: Update timestamp file
update_timestamp() {
    local current_time=$(date +%s)
    echo "$current_time" > "$TIMESTAMP_FILE" 2>/dev/null || true
}

# Function 9: Main orchestrator - Check for updates
check_for_updates() {
    # Change to jays-treasure-trove directory
    cd "$JAYS_TREASURE_DIR" 2>/dev/null || return 0

    # 1. Check if in git repo (silent fail if not)
    if [[ ! -d ".git" ]]; then
        return 0  # Silent fail - not a git repo
    fi

    # 2. Check if update check is needed
    if ! should_check_updates; then
        return 0  # Skip check - within 24 hours
    fi

    # 3. Fetch remote changes (with timeout)
    if ! fetch_remote_changes; then
        # Update timestamp even on failure to avoid repeated failed attempts
        update_timestamp
        return 0  # Silent fail - network error or timeout
    fi

    # 4. Compare commits
    local current=$(get_current_commit)
    local remote=$(get_remote_commit)

    if [[ -z "$current" || -z "$remote" ]]; then
        update_timestamp
        return 0  # Silent fail - git error
    fi

    if [[ "$current" == "$remote" ]]; then
        update_timestamp
        return 0  # Up-to-date
    fi

    # 5-7. Display update warning
    display_update_warning

    # 8. Update timestamp
    update_timestamp
}

# Export main function for use in PROJECT_CLAUDE.md
export -f check_for_updates

# Auto-run check when sourced
check_for_updates
