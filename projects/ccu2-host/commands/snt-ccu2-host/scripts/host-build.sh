#!/bin/bash
# host-build.sh - CCU-2.0 Host Build Orchestrator
# Smart build script with automatic scope detection and error recovery

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
MODULE=""
BUILD_TYPE="Debug"
CLEAN=false
TESTS=false
COVERAGE=false
CROSS_COMPILE=false
ECU="CCU2"
DRY_RUN=false
VERBOSE=false
SCOPE="auto"

# Project root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"

# Module path mapping
declare -A MODULE_PATHS=(
    ["container-manager"]="container-manager"
    ["container-app"]="container-app"
    ["vam"]="vam"
    ["dpm"]="dpm"
    ["diagnostic-manager"]="diagnostic-manager"
    ["libsntxx"]="libsntxx"
    ["libsntlogging"]="libsntlogging"
    ["libsnt_vehicle"]="libsnt_vehicle"
    ["ethnm"]="ethnm"
    ["soa"]="soa"
    ["seccommon"]="seccommon"
    ["rta"]="rta"
)

usage() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
    --module, -m <name>    Specific module to build
    --scope <auto|module>  Build scope detection mode (default: auto)
    --clean, -c            Clean build
    --tests, -t            Build and run tests
    --coverage             Generate code coverage
    --release, -r          Release build
    --cross-compile, -x    Cross-compilation mode
    --ecu <type>           ECU target (CCU2, CCU2_LITE, BCU)
    --dry-run, -n          Show commands without executing
    --verbose, -v          Verbose output
    --help, -h             Show this help message

Examples:
    $(basename "$0") --scope auto
    $(basename "$0") --module container-manager --tests
    $(basename "$0") --module vam --clean --release
    $(basename "$0") --module container-manager --cross-compile --ecu CCU2_LITE
EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --module|-m)
                MODULE="$2"
                shift 2
                ;;
            --scope)
                SCOPE="$2"
                shift 2
                ;;
            --clean|-c)
                CLEAN=true
                shift
                ;;
            --tests|-t)
                TESTS=true
                shift
                ;;
            --coverage)
                COVERAGE=true
                shift
                ;;
            --release|-r)
                BUILD_TYPE="Release"
                shift
                ;;
            --cross-compile|-x)
                CROSS_COMPILE=true
                shift
                ;;
            --ecu)
                ECU="$2"
                shift 2
                ;;
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Detect module from git changes
detect_module_from_changes() {
    cd "${PROJECT_ROOT}"

    local changed_files
    changed_files=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "")

    if [[ -z "$changed_files" ]]; then
        # No uncommitted changes, check staged files
        changed_files=$(git diff --cached --name-only 2>/dev/null || echo "")
    fi

    if [[ -z "$changed_files" ]]; then
        log_warn "No changed files detected"
        return 1
    fi

    # Find affected modules
    local affected_modules=()
    for module in "${!MODULE_PATHS[@]}"; do
        local path="${MODULE_PATHS[$module]}"
        if echo "$changed_files" | grep -q "^${path}/"; then
            affected_modules+=("$module")
        fi
    done

    if [[ ${#affected_modules[@]} -eq 0 ]]; then
        log_warn "No module changes detected"
        return 1
    elif [[ ${#affected_modules[@]} -eq 1 ]]; then
        echo "${affected_modules[0]}"
    else
        # Multiple modules changed, return the first one
        log_info "Multiple modules changed: ${affected_modules[*]}"
        echo "${affected_modules[0]}"
    fi
}

# Detect module from current directory
detect_module_from_cwd() {
    local current_dir
    current_dir=$(pwd)

    for module in "${!MODULE_PATHS[@]}"; do
        local path="${MODULE_PATHS[$module]}"
        if [[ "$current_dir" == *"${path}"* ]]; then
            echo "$module"
            return 0
        fi
    done

    return 1
}

# Auto-detect module
auto_detect_module() {
    local module

    # Try detecting from git changes first
    module=$(detect_module_from_changes 2>/dev/null)
    if [[ -n "$module" ]]; then
        log_info "Detected module from changes: $module"
        echo "$module"
        return 0
    fi

    # Try detecting from current directory
    module=$(detect_module_from_cwd)
    if [[ -n "$module" ]]; then
        log_info "Detected module from directory: $module"
        echo "$module"
        return 0
    fi

    return 1
}

# Build the command
build_command() {
    local cmd="./build.py --module ${MODULE}"

    if [[ "$BUILD_TYPE" != "Debug" ]]; then
        cmd+=" --build-type ${BUILD_TYPE}"
    fi

    if [[ "$CLEAN" == true ]]; then
        cmd+=" --clean"
    fi

    if [[ "$TESTS" == true ]]; then
        cmd+=" --tests"
    fi

    if [[ "$COVERAGE" == true ]]; then
        cmd+=" --coverage"
    fi

    if [[ "$CROSS_COMPILE" == true ]]; then
        cmd+=" --cross-compile --ecu ${ECU}"
    fi

    if [[ "$VERBOSE" == true ]]; then
        cmd+=" --verbose"
    fi

    echo "$cmd"
}

# Execute build
execute_build() {
    cd "${PROJECT_ROOT}"

    local cmd
    cmd=$(build_command)

    echo ""
    echo "=========================================="
    echo " CCU-2.0 Host Build"
    echo "=========================================="
    echo " Module    : ${MODULE}"
    echo " Build Type: ${BUILD_TYPE}"
    echo " Clean     : ${CLEAN}"
    echo " Tests     : ${TESTS}"
    echo " Coverage  : ${COVERAGE}"
    echo " Cross     : ${CROSS_COMPILE}"
    if [[ "$CROSS_COMPILE" == true ]]; then
        echo " ECU       : ${ECU}"
    fi
    echo "=========================================="
    echo " Command: ${cmd}"
    echo "=========================================="
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Dry run mode - command not executed"
        return 0
    fi

    local start_time
    start_time=$(date +%s)

    if eval "$cmd"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo "=========================================="
        log_success "Build completed successfully!"
        echo " Duration: ${duration}s"
        echo "=========================================="

        # Show artifacts location
        if [[ -d "build/${BUILD_TYPE}/${MODULE}" ]]; then
            echo ""
            echo "Artifacts:"
            find "build/${BUILD_TYPE}/${MODULE}" -name "*.a" -o -name "*.so" 2>/dev/null | head -5
        fi

        return 0
    else
        local exit_code=$?
        log_error "Build failed with exit code: $exit_code"

        # Suggest recovery
        echo ""
        echo "Recovery suggestions:"
        echo "  1. Clean build: ./build.py --module ${MODULE} --clean"
        echo "  2. Check dependencies: ./build.py --module libsntxx && ./build.py --module ${MODULE}"
        echo "  3. Full clean: rm -rf build/ && ./build.py --module ${MODULE}"

        return $exit_code
    fi
}

# Main
main() {
    parse_args "$@"

    # Auto-detect module if not specified
    if [[ -z "$MODULE" ]]; then
        if [[ "$SCOPE" == "auto" ]]; then
            MODULE=$(auto_detect_module)
            if [[ -z "$MODULE" ]]; then
                log_error "Could not auto-detect module. Please specify with --module"
                exit 1
            fi
        else
            log_error "Module not specified. Use --module <name>"
            exit 1
        fi
    fi

    # Validate module
    if [[ -z "${MODULE_PATHS[$MODULE]:-}" ]]; then
        log_error "Unknown module: $MODULE"
        echo "Available modules: ${!MODULE_PATHS[*]}"
        exit 1
    fi

    # Execute build
    execute_build
}

main "$@"
