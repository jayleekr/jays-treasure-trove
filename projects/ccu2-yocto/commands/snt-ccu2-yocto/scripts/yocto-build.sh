#!/bin/bash
# /snt-ccu2-yocto:build automation script
# This script handles build execution inside Docker container

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Default Configuration
# ============================================================================
BUILD_SCOPE="auto"
MODULES=""
CLEAN=false
RELEASE=true   # Release build by default (-r)
MP=false
DRY_RUN=false
JOBS=16
PARALLEL=16
MAX_RETRIES=3  # Retry count for fetch failures (DNS issues)

# ============================================================================
# Usage
# ============================================================================
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --scope <auto|module|snt|full>   Build scope (default: auto)
    --module <name>                   Specific module(s) to build (comma-separated)
    --clean                           Run cleansstate before build
    --release                         Release build (-r) [default]
    --no-release                      Debug build (without -r)
    --mp                              MP Release build (--mp)
    --dry-run                         Print commands without executing
    --jobs <n>                        Number of bitbake jobs (default: 16)
    --parallel <n>                    Number of parallel tasks (default: 16)
    --retries <n>                     Max retries for fetch failures (default: 3)
    --no-log                          Disable log file saving
    --log-file <path>                 Custom log file path
    -h, --help                        Show this help

Examples:
    $0 --scope auto
    $0 --module linux-s32,systemd --clean
    $0 --scope full --release
    $0 --scope full --log-file /tmp/my-build.log

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
        --scope) BUILD_SCOPE="$2"; shift 2 ;;
        --module) MODULES="$2"; shift 2 ;;
        --clean) CLEAN=true; shift ;;
        --release) RELEASE=true; shift ;;
        --no-release) RELEASE=false; shift ;;
        --mp) MP=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --jobs) JOBS="$2"; shift 2 ;;
        --parallel) PARALLEL="$2"; shift 2 ;;
        --retries) MAX_RETRIES="$2"; shift 2 ;;
        --no-log) SAVE_LOG=false; shift ;;
        --log-file) CUSTOM_LOG="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) print_error "Unknown option: $1"; usage ;;
    esac
done

# ============================================================================
# Analyze Git Changes
# ============================================================================
analyze_changes() {
    print_info "Analyzing git changes..."

    cd "$PROJECT_ROOT"

    local changed_files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || git diff --name-only)

    if [ -z "$changed_files" ]; then
        print_info "No changes detected"
        echo "NO_BUILD"
        return
    fi

    local full_triggers=("build_info.json" "local.conf" "bblayers.conf")
    local kernel_changed=false
    local systemd_changed=false
    local image_changed=false
    local affected_modules=()

    while IFS= read -r file; do
        for trigger in "${full_triggers[@]}"; do
            if [[ "$file" == *"$trigger"* ]]; then
                echo "FULL"
                return
            fi
        done

        if [[ "$file" == *"linux-s32"* ]] || [[ "$file" == *"linux-ccu2"* ]]; then
            kernel_changed=true
            affected_modules+=("linux-s32")
        fi

        if [[ "$file" == *"systemd"* ]]; then
            systemd_changed=true
            affected_modules+=("systemd")
        fi

        if [[ "$file" == *"fsl-image"* ]]; then
            image_changed=true
        fi
    done <<< "$changed_files"

    if $image_changed; then
        echo "FULL"
    elif [ ${#affected_modules[@]} -gt 5 ]; then
        echo "FULL"
    elif [ ${#affected_modules[@]} -gt 0 ]; then
        local unique_modules=($(echo "${affected_modules[@]}" | tr ' ' '\n' | sort -u))
        echo "MODULE:${unique_modules[*]}"
    else
        echo "SNT"
    fi
}

# ============================================================================
# Generate Build Command
# ============================================================================
generate_build_command() {
    local scope=$1
    local cmd="./build.py"

    case $scope in
        FULL)
            cmd="$cmd -ncpb -j $JOBS -p $PARALLEL"
            $RELEASE && cmd="$cmd -r"
            $MP && cmd="$cmd --mp"
            ;;
        SNT)
            cmd="$cmd --snt"
            ;;
        MODULE:*)
            local modules="${scope#MODULE:}"
            cmd="$cmd -m ${modules// /,}"
            ;;
        NO_BUILD)
            echo ""
            return
            ;;
    esac

    echo "$cmd"
}

# ============================================================================
# Execute Build
# ============================================================================
execute_build() {
    local scope=$1
    local build_cmd=$(generate_build_command "$scope")

    if [ -z "$build_cmd" ]; then
        print_info "No build needed"
        return 0
    fi

    print_info "Build scope: $scope"
    print_info "Build command: $build_cmd"

    if $DRY_RUN; then
        print_warning "DRY RUN - Command not executed"
        return 0
    fi

    # Clean if requested
    if $CLEAN; then
        case $scope in
            MODULE:*)
                local modules="${scope#MODULE:}"
                for module in $modules; do
                    print_step "Cleaning $module..."
                    if is_in_container; then
                        cd "$PROJECT_ROOT/mobis"
                        run_logged "./build.py -m \"$module\" -c cleansstate" "Clean $module"
                    else
                        run_logged "$PROJECT_ROOT/run-dev-container.sh -x \"cd mobis && ./build.py -m $module -c cleansstate\"" "Clean $module"
                    fi
                done
                ;;
        esac
    fi

    # Execute build with retry for fetch failures
    print_step "Starting build..."
    local build_start=$(date +%s)

    local retry_count=0
    local build_success=false

    while [ $retry_count -lt $MAX_RETRIES ]; do
        local exit_code=0
        local build_output=""
        local temp_log=$(mktemp)

        if is_in_container; then
            cd "$PROJECT_ROOT/mobis"
            eval "$build_cmd" 2>&1 | tee "$temp_log" ; exit_code=${PIPESTATUS[0]}
        else
            "$PROJECT_ROOT/run-dev-container.sh" -x "cd mobis && $build_cmd" 2>&1 | tee "$temp_log" ; exit_code=${PIPESTATUS[0]}
        fi

        # Append to main log file
        if $SAVE_LOG && [ -f "$LOG_FILE" ]; then
            cat "$temp_log" >> "$LOG_FILE"
        fi
        build_output=$(cat "$temp_log")
        rm -f "$temp_log"

        if [ $exit_code -eq 0 ]; then
            build_success=true
            break
        fi

        # Check if it's a fetch failure (DNS/network issue)
        if echo "$build_output" | grep -qE "(do_fetch|Fetcher failure|Unable to fetch|Could not resolve host|Connection timed out|Network is unreachable)"; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                print_warning "Fetch failed (possibly DNS issue). Retrying... ($retry_count/$MAX_RETRIES)"
                sleep 5
            else
                print_error "Fetch failed after $MAX_RETRIES retries"
                return 1
            fi
        else
            print_error "Build failed (non-fetch error)"
            return 1
        fi
    done

    local elapsed=$(get_elapsed_time $build_start)

    if $build_success; then
        print_success "Build completed in $elapsed"
        return 0
    fi
    return 1
}

# ============================================================================
# Main
# ============================================================================
main() {
    print_header "Yocto Build Automation"
    print_info "Project root: $PROJECT_ROOT"

    # Initialize logging
    init_logging "build" "$CUSTOM_LOG"

    local scope

    if [ "$BUILD_SCOPE" == "auto" ]; then
        scope=$(analyze_changes)
    elif [ "$BUILD_SCOPE" == "module" ] && [ -n "$MODULES" ]; then
        scope="MODULE:$MODULES"
    elif [ "$BUILD_SCOPE" == "snt" ]; then
        scope="SNT"
    elif [ "$BUILD_SCOPE" == "full" ]; then
        scope="FULL"
    else
        print_error "Invalid build scope: $BUILD_SCOPE"
        exit 1
    fi

    local build_status="SUCCESS"
    execute_build "$scope" || build_status="FAILED"

    # Output summary
    echo ""
    print_header "BUILD SUMMARY"
    print_info "Scope: $scope"
    print_info "Status: $build_status"
    print_info "Artifacts: $PROJECT_ROOT/mobis/deploy"

    finalize_logging "$build_status" "Scope=$scope"

    [ "$build_status" == "SUCCESS" ] && return 0 || return 1
}

main "$@"
