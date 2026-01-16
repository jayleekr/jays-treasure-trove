#!/bin/bash
# Common logging and utility functions for snt-ccu2-yocto skills
# Source this file in other scripts: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# Color Definitions
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

# ============================================================================
# Project Paths
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
LOG_BASE_DIR="$PROJECT_ROOT/claudedocs/build-logs"
TEMP_DIR="$PROJECT_ROOT/.claude/tmp"

# ============================================================================
# Logging Configuration
# ============================================================================
SAVE_LOG=true
LOG_FILE=""
SKILL_NAME=""

# ============================================================================
# Initialize Logging
# Usage: init_logging "skill-name" ["custom-log-file"]
# ============================================================================
init_logging() {
    SKILL_NAME="${1:-unknown}"
    local custom_log="${2:-}"
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    if [ -n "$custom_log" ]; then
        LOG_FILE="$custom_log"
    else
        LOG_FILE="$LOG_BASE_DIR/${SKILL_NAME}_${timestamp}.log"
    fi

    if $SAVE_LOG; then
        mkdir -p "$LOG_BASE_DIR"
        {
            echo "═══════════════════════════════════════════════════════════════════"
            echo "  Skill: $SKILL_NAME"
            echo "  Started: $(date '+%Y-%m-%d %H:%M:%S %Z')"
            echo "  User: $(whoami)"
            echo "  Host: $(hostname)"
            echo "  PWD: $(pwd)"
            echo "═══════════════════════════════════════════════════════════════════"
            echo ""
        } > "$LOG_FILE"
    fi
}

# ============================================================================
# Logging Functions
# ============================================================================

# Internal: write to log file (strips color codes)
_write_log() {
    if $SAVE_LOG && [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
    fi
}

# Log to both stdout and file
log() {
    local msg="$1"
    echo -e "$msg"
    _write_log "$msg"
}

# Print functions with automatic logging
print_info() {
    local msg="${BLUE}[INFO]${NC} $1"
    echo -e "$msg"
    _write_log "[INFO] $1"
}

print_success() {
    local msg="${GREEN}[SUCCESS]${NC} $1"
    echo -e "$msg"
    _write_log "[SUCCESS] $1"
}

print_warning() {
    local msg="${YELLOW}[WARNING]${NC} $1"
    echo -e "$msg"
    _write_log "[WARNING] $1"
}

print_error() {
    local msg="${RED}[ERROR]${NC} $1"
    echo -e "$msg"
    _write_log "[ERROR] $1"
}

print_step() {
    local msg="${CYAN}[STEP]${NC} $1"
    echo -e "$msg"
    _write_log "[STEP] $1"
}

print_header() {
    local header="
═══════════════════════════════════════════════════════════════════
  $1
═══════════════════════════════════════════════════════════════════"
    echo -e "${CYAN}$header${NC}"
    _write_log "$header"
}

# ============================================================================
# Execute command with logging
# Usage: run_logged "command" ["description"]
# ============================================================================
run_logged() {
    local cmd="$1"
    local desc="${2:-Executing command}"
    mkdir -p "$TEMP_DIR"
    local temp_log="$TEMP_DIR/run_$(date +%s).log"
    local exit_code=0

    print_info "$desc"
    _write_log "Command: $cmd"
    _write_log "---"

    eval "$cmd" 2>&1 | tee "$temp_log"; exit_code=${PIPESTATUS[0]}

    if $SAVE_LOG && [ -f "$LOG_FILE" ]; then
        cat "$temp_log" >> "$LOG_FILE"
    fi
    _write_log "---"
    _write_log "Exit code: $exit_code"

    rm -f "$temp_log"
    return $exit_code
}

# ============================================================================
# Finalize Logging (call at end of script)
# Usage: finalize_logging "SUCCESS|FAILED" ["additional info"]
# ============================================================================
finalize_logging() {
    local status="${1:-UNKNOWN}"
    local info="${2:-}"

    if $SAVE_LOG && [ -n "$LOG_FILE" ]; then
        {
            echo ""
            echo "═══════════════════════════════════════════════════════════════════"
            echo "  SUMMARY"
            echo "═══════════════════════════════════════════════════════════════════"
            echo "  Skill: $SKILL_NAME"
            echo "  Status: $status"
            echo "  Ended: $(date '+%Y-%m-%d %H:%M:%S %Z')"
            [ -n "$info" ] && echo "  Info: $info"
            echo "  Log: $LOG_FILE"
            echo "═══════════════════════════════════════════════════════════════════"
        } >> "$LOG_FILE"

        print_info "Log saved to: $LOG_FILE"
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Check if running inside Docker container
is_in_container() {
    [ -f /.dockerenv ] && return 0
    return 1
}

# Get the yocto container name for this project
get_yocto_container() {
    local project_path="$PROJECT_ROOT"
    # Container naming: replace leading / and all / with _, append -yocto-ccu-2.0
    # Example: /home/jay.lee/CCU_GEN2.0_SONATUS.manifest -> home_jay.lee_CCU_GEN2.0_SONATUS.manifest-yocto-ccu-2.0
    local container_name=$(echo "$project_path" | sed 's|^/||' | tr '/' '_')
    container_name="${container_name}-yocto-ccu-2.0"

    # Check if container exists and is running
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$"; then
        echo "$container_name"
        return 0
    fi
    return 1
}

# Execute command in yocto container via docker exec
exec_in_container() {
    local cmd="$1"
    local container=$(get_yocto_container)

    if [ -n "$container" ]; then
        docker exec -u "$(id -u):$(id -g)" "$container" bash -c "$cmd"
        return $?
    else
        print_error "Yocto container not found. Please run: ./run-dev-container.sh"
        return 1
    fi
}

# Get elapsed time in human readable format
get_elapsed_time() {
    local start=$1
    local end=$(date +%s)
    local duration=$((end - start))
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))

    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m ${seconds}s"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

# List recent log files
list_recent_logs() {
    local count="${1:-10}"
    echo "Recent log files:"
    ls -lt "$LOG_BASE_DIR"/*.log 2>/dev/null | head -$count | awk '{print "  " $9 " (" $6 " " $7 " " $8 ")"}'
}
