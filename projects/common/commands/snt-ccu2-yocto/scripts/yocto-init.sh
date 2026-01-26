#!/bin/bash
# /snt-ccu2-yocto:init automation script
# This script validates environment and runs init.py with enhanced checks

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Default Configuration
# ============================================================================
TIER="MOBIS"
VERSION=""
FORCE=false
META_SONATUS_BRANCH=""
SONATUS_BRANCH=""
SONATUS_VERSION=""
BUILD_DATE=""
DRY_RUN=false
VERBOSE=false
CHECK_BL2=true

# ============================================================================
# Usage
# ============================================================================
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --tier <LGE|MOBIS>        Tier type (default: MOBIS)
    --version <name>          Vehicle/version type
    --force                   Force re-initialization
    --meta-sonatus-branch <b> Set meta-sonatus branch
    --sonatus-branch <b>      Set Sonatus repos branch
    --sonatus-version <v>     Set Sonatus release tag
    --date <YYMMDD>           Set build date
    --dry-run                 Show commands without executing
    --verbose                 Verbose output
    --no-bl2-check            Skip BL2 version check
    --no-log                  Disable log file saving
    --log-file <path>         Custom log file path
    -h, --help                Show this help

Available Versions:
    LGE:   jg1, bj1, lq2, ne1, ne1_new, nx5
    MOBIS: lw1, sx3, qy2

Examples:
    $0 --tier MOBIS --version qy2
    $0 --tier MOBIS --version qy2 --force
    $0 --tier MOBIS --version qy2 --meta-sonatus-branch CCU2-18227-podman
    $0 --tier LGE --version jg1

Log files are saved to: claudedocs/build-logs/
EOF
    exit 0
}

# ============================================================================
# Parse Arguments
# ============================================================================
CUSTOM_LOG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --tier) TIER="$2"; shift 2 ;;
        --version) VERSION="$2"; shift 2 ;;
        --force) FORCE=true; shift ;;
        --meta-sonatus-branch) META_SONATUS_BRANCH="$2"; shift 2 ;;
        --sonatus-branch) SONATUS_BRANCH="$2"; shift 2 ;;
        --sonatus-version) SONATUS_VERSION="$2"; shift 2 ;;
        --date) BUILD_DATE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --no-bl2-check) CHECK_BL2=false; shift ;;
        --no-log) SAVE_LOG=false; shift ;;
        --log-file) CUSTOM_LOG="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) print_error "Unknown option: $1"; usage ;;
    esac
done

# ============================================================================
# Validate Environment
# ============================================================================
validate_environment() {
    print_step "Validating environment..."

    # Check if in container
    if ! is_in_container; then
        print_error "Must run inside Docker container"
        print_info "Run: ./run-dev-container.sh"
        return 1
    fi
    print_success "Running inside Docker container"

    # Check required files
    if [ ! -f "$PROJECT_ROOT/init.py" ]; then
        print_error "init.py not found in project root"
        return 1
    fi
    print_success "init.py found"

    # Check repo_info.json
    if [ ! -f "$PROJECT_ROOT/info/repo_info.json" ]; then
        print_error "info/repo_info.json not found"
        return 1
    fi
    print_success "repo_info.json found"

    return 0
}

# ============================================================================
# Check BL2 Version (for MOBIS with custom_mcu)
# ============================================================================
check_bl2_version() {
    local vehicle_type="$1"

    if [ "$TIER" != "MOBIS" ]; then
        return 0
    fi

    print_step "Checking BL2 (flash.bin) version..."

    local customs_flash="$PROJECT_ROOT/customs/MOBIS/$vehicle_type/flash.bin"

    if [ ! -f "$customs_flash" ]; then
        print_warning "customs flash.bin not found: $customs_flash"
        return 0
    fi

    local customs_version=$(strings "$customs_flash" | grep -E "^[0-9]{6}[A-Z]-v" | head -1)
    print_info "customs flash.bin version: $customs_version"

    # Check other vehicle types for comparison
    local other_versions=""
    for vtype in lw1 sx3 qy2; do
        if [ "$vtype" != "$vehicle_type" ]; then
            local other_flash="$PROJECT_ROOT/customs/MOBIS/$vtype/flash.bin"
            if [ -f "$other_flash" ]; then
                local ver=$(strings "$other_flash" | grep -E "^[0-9]{6}[A-Z]-v" | head -1)
                if [ -n "$ver" ]; then
                    other_versions="$other_versions\n  $vtype: $ver"
                fi
            fi
        fi
    done

    if [ -n "$other_versions" ]; then
        print_info "Other vehicle versions:$other_versions"
    fi

    # Check if current version is older
    local current_ver_num=$(echo "$customs_version" | grep -oE "^[0-9]{6}" | head -1)

    for vtype in lw1 sx3; do
        if [ "$vtype" != "$vehicle_type" ]; then
            local other_flash="$PROJECT_ROOT/customs/MOBIS/$vtype/flash.bin"
            if [ -f "$other_flash" ]; then
                local other_ver=$(strings "$other_flash" | grep -E "^[0-9]{6}[A-Z]-v" | head -1)
                local other_ver_num=$(echo "$other_ver" | grep -oE "^[0-9]{6}" | head -1)

                if [ "$current_ver_num" != "$other_ver_num" ]; then
                    print_warning "BL2 VERSION MISMATCH DETECTED!"
                    print_warning "  $vehicle_type: $customs_version"
                    print_warning "  $vtype: $other_ver"
                    print_warning "Consider updating customs/MOBIS/$vehicle_type/flash.bin"
                fi
            fi
        fi
    done

    return 0
}

# ============================================================================
# Build Init Command
# ============================================================================
build_init_command() {
    local cmd="python3 $PROJECT_ROOT/init.py"

    cmd="$cmd --tier $TIER"

    [ -n "$VERSION" ] && cmd="$cmd --version $VERSION"
    $FORCE && cmd="$cmd --force"
    [ -n "$META_SONATUS_BRANCH" ] && cmd="$cmd --meta-sonatus-branch $META_SONATUS_BRANCH"
    [ -n "$SONATUS_BRANCH" ] && cmd="$cmd --sonatus-branch $SONATUS_BRANCH"
    [ -n "$SONATUS_VERSION" ] && cmd="$cmd --sonatus-version $SONATUS_VERSION"
    [ -n "$BUILD_DATE" ] && cmd="$cmd --date $BUILD_DATE"
    $DRY_RUN && cmd="$cmd --dry-run"
    $VERBOSE && cmd="$cmd --verbose"

    echo "$cmd"
}

# ============================================================================
# Main
# ============================================================================
main() {
    print_header "Yocto Project Initialization"
    print_info "Project root: $PROJECT_ROOT"
    print_info "Tier: $TIER"
    print_info "Version: ${VERSION:-default}"

    # Initialize logging
    init_logging "init" "$CUSTOM_LOG"

    # Validate environment
    if ! validate_environment; then
        finalize_logging "FAILED" "Environment validation failed"
        return 1
    fi

    # Determine version for BL2 check
    local check_version="$VERSION"
    if [ -z "$check_version" ]; then
        # Get default version from repo_info.json based on tier
        if [ "$TIER" == "MOBIS" ]; then
            check_version="qy2"  # Default MOBIS version
        fi
    fi

    # Check BL2 version (MOBIS only)
    if $CHECK_BL2 && [ -n "$check_version" ]; then
        check_bl2_version "$check_version"
    fi

    # Build and execute command
    local init_cmd=$(build_init_command)
    print_info "Init command: $init_cmd"

    if $DRY_RUN; then
        print_warning "DRY RUN - Command not executed"
        finalize_logging "DRY_RUN" "Tier=$TIER, Version=$VERSION"
        return 0
    fi

    print_step "Running init.py..."
    local init_start=$(date +%s)

    if run_logged "$init_cmd" "Project initialization"; then
        local elapsed=$(get_elapsed_time $init_start)
        print_success "Initialization completed in $elapsed"
        finalize_logging "SUCCESS" "Tier=$TIER, Version=$VERSION"
        return 0
    else
        print_error "Initialization failed"
        finalize_logging "FAILED" "Tier=$TIER, Version=$VERSION"
        return 1
    fi
}

main "$@"
