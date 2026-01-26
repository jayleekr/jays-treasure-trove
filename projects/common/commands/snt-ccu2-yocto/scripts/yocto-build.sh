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

# SDK Build Options
SDK_BUILD=false
SDK_TIER=""
SDK_SERVICE_IF=""

# Branch Override Options
BRANCH_NAME=""
KEEP_BRANCH=false
TIER="mobis"
RECIPE_BACKUP=""  # Track backup file for cleanup

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

SDK Build Options:
    --sdk                             Build SDK (cross-compilation toolchain)
    --tier <MOBIS|LGE>                Tier type for SDK build (required with --sdk)
    --service-if <version>            Service interface version (required with --sdk)

Branch Override Options:
    --branch <name>, -b               Build from specific git branch (requires --module)
    --keep-branch, -k                 Keep recipe changes after build (default: restore)
    --tier <MOBIS|LGE>, -t            Target tier for recipe location (default: mobis)

Examples:
    $0 --scope auto
    $0 --module linux-s32,systemd --clean
    $0 --scope full --release
    $0 --scope full --log-file /tmp/my-build.log
    $0 --sdk --tier MOBIS --service-if 0.24.2
    $0 --module container-manager --branch CCU2-16964-feature --tier mobis
    $0 --module vam -b feature-branch --keep-branch

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
        --module|-m) MODULES="$2"; shift 2 ;;
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
        --sdk) SDK_BUILD=true; shift ;;
        --tier|-t)
            # Handle both SDK tier and branch override tier
            if [ -z "$SDK_TIER" ]; then
                SDK_TIER="$2"
            fi
            TIER=$(echo "$2" | tr '[:upper:]' '[:lower:]')
            shift 2
            ;;
        --service-if) SDK_SERVICE_IF="$2"; shift 2 ;;
        --branch|-b) BRANCH_NAME="$2"; shift 2 ;;
        --keep-branch|-k) KEEP_BRANCH=true; shift ;;
        -h|--help) usage ;;
        *) print_error "Unknown option: $1"; usage ;;
    esac
done

# ============================================================================
# Branch Override Functions
# ============================================================================

# List of supported components with SNT_BRANCH
SUPPORTED_COMPONENTS=(
    "container-manager" "vam" "dpm" "diagnostic-manager" "ethnm"
    "libsntxx" "libsnt-vehicle" "libsnt-ehal" "libsnt-cantp" "libsnt-doip"
    "vcc" "vdc" "soa" "mqtt-middleware" "container-app"
    "trace-engine" "shared-storage" "build-common" "vehicle-schema"
    "ethernet-handler" "libsntlogging" "cdh" "json-schema-validator"
)

# Find recipe file for a component
# Usage: find_recipe_file <component> [tier]
find_recipe_file() {
    local component=$1
    local tier=${2:-mobis}

    # Base paths to search
    local base="$PROJECT_ROOT/${tier}/layers/meta-sonatus"
    local recipe=""

    # Primary location: sonatus-internal/recipes-core
    recipe="${base}/sonatus-internal/recipes-core/${component}/${component}.bb"
    if [ -f "$recipe" ]; then
        echo "$recipe"
        return 0
    fi

    # Secondary: sonatus-internal/recipes-extended
    recipe="${base}/sonatus-internal/recipes-extended/${component}/${component}.bb"
    if [ -f "$recipe" ]; then
        echo "$recipe"
        return 0
    fi

    # Tertiary: sonatus-internal/recipes-platform
    recipe="${base}/sonatus-internal/recipes-platform/${component}/${component}.bb"
    if [ -f "$recipe" ]; then
        echo "$recipe"
        return 0
    fi

    # Fallback: search all sonatus-internal subdirectories
    recipe=$(find "${base}/sonatus-internal" -name "${component}.bb" 2>/dev/null | head -1)
    if [ -n "$recipe" ] && [ -f "$recipe" ]; then
        echo "$recipe"
        return 0
    fi

    return 1
}

# Check if component supports SNT_BRANCH
# Usage: is_branch_supported <component>
is_branch_supported() {
    local component=$1
    local recipe=$(find_recipe_file "$component" "$TIER")

    if [ -z "$recipe" ]; then
        return 1
    fi

    grep -q "SNT_BRANCH" "$recipe" 2>/dev/null
    return $?
}

# Modify recipe to use specific branch
# Usage: modify_recipe_branch <recipe_file> <branch>
modify_recipe_branch() {
    local recipe=$1
    local branch=$2
    local backup="${recipe}.bak"

    # Warn if backup already exists
    if [ -f "$backup" ]; then
        print_warning "Backup already exists: $backup (will be overwritten)"
    fi

    # Create backup
    cp "$recipe" "$backup"
    RECIPE_BACKUP="$backup"
    print_info "Recipe backed up: $backup"

    # Modify SNT_BRANCH: change from weak assignment (?=) to strong assignment (=)
    # Original: SNT_BRANCH ?= "master"
    # Modified: SNT_BRANCH = "branch_name"
    sed -i "s/^SNT_BRANCH ?= \".*\"/SNT_BRANCH = \"${branch}\"/" "$recipe"

    print_success "Recipe modified: SNT_BRANCH = \"${branch}\""

    if $DRY_RUN; then
        print_info "Dry run: showing diff"
        diff "$backup" "$recipe" || true
    fi

    return 0
}

# Restore original recipe from backup
# Usage: restore_recipe_branch <recipe_file>
restore_recipe_branch() {
    local recipe=$1
    local backup="${recipe}.bak"

    if [ -f "$backup" ]; then
        mv "$backup" "$recipe"
        RECIPE_BACKUP=""
        print_success "Recipe restored: $recipe"
        return 0
    else
        print_warning "No backup found: $backup"
        return 1
    fi
}

# Cleanup handler for interrupts (SIGINT, SIGTERM)
cleanup_recipe_on_exit() {
    local exit_code=$?

    if [ -n "$RECIPE_BACKUP" ] && [ -f "$RECIPE_BACKUP" ]; then
        local recipe="${RECIPE_BACKUP%.bak}"
        print_warning "Interrupted! Restoring recipe..."
        mv "$RECIPE_BACKUP" "$recipe"
        print_success "Recipe restored after interrupt"
    fi

    exit $exit_code
}

# Validate branch override requirements
validate_branch_options() {
    if [ -n "$BRANCH_NAME" ]; then
        # Branch requires exactly one module
        if [ -z "$MODULES" ]; then
            print_error "--branch requires --module <component>"
            print_info "Example: $0 --module container-manager --branch feature-branch"
            exit 1
        fi

        # Check for multiple modules (not supported with branch)
        if [[ "$MODULES" == *","* ]]; then
            print_error "--branch only supports single component build"
            print_info "Provided: $MODULES"
            exit 1
        fi

        # Check if component is supported
        if ! is_branch_supported "$MODULES"; then
            print_error "Component '$MODULES' does not support SNT_BRANCH"
            print_info "Supported components: ${SUPPORTED_COMPONENTS[*]}"
            exit 1
        fi

        # Force module scope when branch is specified
        BUILD_SCOPE="module"

        # Force clean when branch is specified (to invalidate cache)
        CLEAN=true
        print_info "Auto-enabled clean (cleansstate) for branch build"
    fi
}

# Execute branch build
# Usage: execute_branch_build <component> <branch>
execute_branch_build() {
    local component=$1
    local branch=$2
    local recipe=$(find_recipe_file "$component" "$TIER")

    if [ -z "$recipe" ]; then
        print_error "Recipe not found for component: $component"
        return 1
    fi

    print_header "Branch Build: $component"
    print_info "Component: $component"
    print_info "Branch: $branch"
    print_info "Tier: $TIER"
    print_info "Recipe: $recipe"

    # Set up interrupt handler
    trap cleanup_recipe_on_exit SIGINT SIGTERM

    # Step 1: Backup and modify recipe
    print_step "Step 1: Modifying recipe for branch '$branch'"
    if ! modify_recipe_branch "$recipe" "$branch"; then
        print_error "Failed to modify recipe"
        return 1
    fi

    # Step 2: Clean (cleansstate) to invalidate cached version
    print_step "Step 2: Running cleansstate to invalidate cache"
    local clean_cmd="./build.py -m $component -c cleansstate"

    if $DRY_RUN; then
        print_info "Dry run: $clean_cmd"
    else
        if is_in_container; then
            cd "$PROJECT_ROOT/$TIER"
            eval "$clean_cmd" 2>&1
        else
            exec_in_container "cd $PROJECT_ROOT/$TIER && $clean_cmd" 2>&1
        fi

        if [ $? -ne 0 ]; then
            print_warning "cleansstate returned non-zero (may be OK if no previous build)"
        fi
    fi

    # Step 3: Build the component
    print_step "Step 3: Building $component from branch '$branch'"
    local build_cmd="./build.py -m $component"
    $RELEASE && build_cmd="$build_cmd -r"

    local build_success=false
    local retry_count=0

    while [ $retry_count -lt $MAX_RETRIES ]; do
        if $DRY_RUN; then
            print_info "Dry run: $build_cmd"
            build_success=true
            break
        fi

        local exit_code=0
        mkdir -p "$TEMP_DIR"
        local temp_log="$TEMP_DIR/build_$(date +%s).log"

        if is_in_container; then
            cd "$PROJECT_ROOT/$TIER"
            eval "$build_cmd" 2>&1 | tee "$temp_log"; exit_code=${PIPESTATUS[0]}
        else
            exec_in_container "cd $PROJECT_ROOT/$TIER && $build_cmd" 2>&1 | tee "$temp_log"; exit_code=${PIPESTATUS[0]}
        fi

        # Append to main log
        if $SAVE_LOG && [ -f "$LOG_FILE" ]; then
            cat "$temp_log" >> "$LOG_FILE"
        fi
        local build_output=$(cat "$temp_log")
        rm -f "$temp_log"

        if [ $exit_code -eq 0 ]; then
            build_success=true
            break
        fi

        # Check for fetch failure (DNS/network)
        if echo "$build_output" | grep -qE "(do_fetch|Fetcher failure|Unable to fetch|Could not resolve host|Connection timed out|Network is unreachable|Branch .* not found)"; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                print_warning "Fetch failed. Retrying... ($retry_count/$MAX_RETRIES)"
                sleep 5
            else
                print_error "Fetch failed after $MAX_RETRIES retries"
                print_error "Branch '$branch' may not exist on remote"
            fi
        else
            print_error "Build failed (non-fetch error)"
            break
        fi
    done

    # Step 4: Restore recipe (unless --keep-branch)
    if ! $KEEP_BRANCH; then
        print_step "Step 4: Restoring original recipe"
        restore_recipe_branch "$recipe"
    else
        print_info "Keeping modified recipe (--keep-branch specified)"
        print_warning "Don't forget to restore: git checkout $recipe"
        RECIPE_BACKUP=""  # Clear backup tracking
    fi

    # Remove trap
    trap - SIGINT SIGTERM

    if $build_success; then
        print_success "Branch build completed successfully"
        return 0
    else
        print_error "Branch build failed"
        return 1
    fi
}

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
                        # Use docker exec to run in existing container
                        run_logged "exec_in_container \"cd $PROJECT_ROOT/mobis && ./build.py -m $module -c cleansstate\"" "Clean $module"
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
        mkdir -p "$TEMP_DIR"
        local temp_log="$TEMP_DIR/build_$(date +%s).log"

        if is_in_container; then
            cd "$PROJECT_ROOT/mobis"
            eval "$build_cmd" 2>&1 | tee "$temp_log" ; exit_code=${PIPESTATUS[0]}
        else
            # Use docker exec to run in existing container
            exec_in_container "cd $PROJECT_ROOT/mobis && $build_cmd" 2>&1 | tee "$temp_log" ; exit_code=${PIPESTATUS[0]}
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
# Execute SDK Build
# ============================================================================
execute_sdk_build() {
    local tier=$1
    local service_if=$2

    print_header "SDK Build"
    print_info "Tier: $tier"
    print_info "Service Interface: $service_if"

    # Validate required parameters
    if [ -z "$tier" ] || [ -z "$service_if" ]; then
        print_error "SDK build requires --tier and --service-if options"
        return 1
    fi

    # Validate tier
    tier_upper=$(echo "$tier" | tr '[:lower:]' '[:upper:]')
    if [[ "$tier_upper" != "MOBIS" && "$tier_upper" != "LGE" ]]; then
        print_error "Invalid tier: $tier. Must be MOBIS or LGE"
        return 1
    fi

    local sdk_cmd="./build.py sdk --tier $tier_upper --service-if $service_if"

    print_info "SDK command: $sdk_cmd"

    if $DRY_RUN; then
        print_warning "DRY RUN - Command not executed"
        return 0
    fi

    # Execute SDK build with retry for fetch failures
    print_step "Starting SDK build..."
    local build_start=$(date +%s)

    local retry_count=0
    local build_success=false

    while [ $retry_count -lt $MAX_RETRIES ]; do
        local exit_code=0
        local build_output=""
        mkdir -p "$TEMP_DIR"
        local temp_log="$TEMP_DIR/build_$(date +%s).log"

        if is_in_container; then
            cd "$PROJECT_ROOT/mobis"
            eval "$sdk_cmd" 2>&1 | tee "$temp_log" ; exit_code=${PIPESTATUS[0]}
        else
            # Use docker exec to run in existing container
            exec_in_container "cd $PROJECT_ROOT/mobis && $sdk_cmd" 2>&1 | tee "$temp_log" ; exit_code=${PIPESTATUS[0]}
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
            print_error "SDK build failed (non-fetch error)"
            return 1
        fi
    done

    local elapsed=$(get_elapsed_time $build_start)

    if $build_success; then
        print_success "SDK build completed in $elapsed"
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

    # Validate branch options (must be called before any build)
    validate_branch_options

    # SDK Build mode
    if $SDK_BUILD; then
        local build_status="SUCCESS"
        execute_sdk_build "$SDK_TIER" "$SDK_SERVICE_IF" || build_status="FAILED"

        # Output summary
        echo ""
        print_header "SDK BUILD SUMMARY"
        print_info "Tier: $SDK_TIER"
        print_info "Service IF: $SDK_SERVICE_IF"
        print_info "Status: $build_status"
        print_info "SDK Cache: /workspace/share/sdk-cache/"

        finalize_logging "$build_status" "SDK=$SDK_TIER-$SDK_SERVICE_IF"

        [ "$build_status" == "SUCCESS" ] && return 0 || return 1
    fi

    # Branch Build mode (when --branch is specified)
    if [ -n "$BRANCH_NAME" ]; then
        local build_status="SUCCESS"
        execute_branch_build "$MODULES" "$BRANCH_NAME" || build_status="FAILED"

        # Output summary
        echo ""
        print_header "BRANCH BUILD SUMMARY"
        print_info "Component: $MODULES"
        print_info "Branch: $BRANCH_NAME"
        print_info "Tier: $TIER"
        print_info "Status: $build_status"
        print_info "Recipe Restored: $( $KEEP_BRANCH && echo "No (--keep-branch)" || echo "Yes" )"
        print_info "Artifacts: $PROJECT_ROOT/$TIER/tmp/deploy"

        finalize_logging "$build_status" "Branch=$BRANCH_NAME Component=$MODULES"

        [ "$build_status" == "SUCCESS" ] && return 0 || return 1
    fi

    # Regular build mode
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
