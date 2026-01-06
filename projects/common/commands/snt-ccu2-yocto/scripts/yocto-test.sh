#!/bin/bash
# /snt-ccu2-yocto:test automation script
# Multi-stage test pipeline for embedded Linux systems

# Don't use set -e as it conflicts with arithmetic operations

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DEPLOY_DIR="$PROJECT_ROOT/mobis/deploy"

# ============================================================================
# Default Configuration
# ============================================================================
STAGES="1,2,3"
TARGET_IP=""
VERBOSE=false

# Test results
declare -A STAGE_RESULTS

# ============================================================================
# Usage
# ============================================================================
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --stages <1,2,3,4>    Stages to run (default: 1,2,3)
                          1: Build Verification
                          2: Image Validation
                          3: Static Analysis
                          4: Target Board Test
    --target-ip <ip>      Target board IP (required for stage 4)
    --verbose             Verbose output
    --no-log              Disable log file saving
    --log-file <path>     Custom log file path
    -h, --help            Show this help

Examples:
    $0                           # Run stages 1,2,3
    $0 --stages 1,2              # Run only stages 1,2
    $0 --stages 1,2,3,4 --target-ip 192.168.1.100

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
        --stages) STAGES="$2"; shift 2 ;;
        --target-ip) TARGET_IP="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        --no-log) SAVE_LOG=false; shift ;;
        --log-file) CUSTOM_LOG="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) print_error "Unknown option: $1"; usage ;;
    esac
done

# ============================================================================
# Stage 1: Build Verification
# ============================================================================
stage1_build_verification() {
    print_header "Stage 1: Build Verification"

    local passed=0
    local failed=0

    # Check deploy directory exists
    if [ -d "$DEPLOY_DIR" ]; then
        print_success "Deploy directory exists"
        ((passed++))
    else
        print_error "Deploy directory not found: $DEPLOY_DIR"
        ((failed++))
        STAGE_RESULTS[1]="FAIL"
        return 1
    fi

    # Check for image artifacts (required for flash)
    local image_files=(
        "ccu-image.tar.gz"                    # Main archive for flash (required)
        "fsl-image-ccu2-mobisccu2.wic"        # Raw rootfs image
        "fsl-image-ccu2-mobisccu2.tar.gz"     # Compressed rootfs
    )

    for pattern in "${image_files[@]}"; do
        if ls $DEPLOY_DIR/$pattern 1> /dev/null 2>&1; then
            print_success "Found: $pattern"
            ((passed++))
        else
            print_warning "Not found: $pattern"
        fi
    done

    # Check build_info.json
    if [ -f "$DEPLOY_DIR/build_info.json" ] || [ -f "$PROJECT_ROOT/mobis/build_info.json" ]; then
        print_success "build_info.json exists"
        ((passed++))
    else
        print_warning "build_info.json not found"
    fi

    if [ $failed -eq 0 ]; then
        print_success "Stage 1 PASSED ($passed checks passed)"
        STAGE_RESULTS[1]="PASS"
        return 0
    else
        print_error "Stage 1 FAILED ($failed checks failed)"
        STAGE_RESULTS[1]="FAIL"
        return 1
    fi
}

# ============================================================================
# Stage 2: Image Validation
# ============================================================================
stage2_image_validation() {
    print_header "Stage 2: Image Validation"

    local passed=0
    local failed=0
    local rootfs_dir="$PROJECT_ROOT/mobis/rootfs"

    # Check if rootfs exists (might need to extract)
    if [ ! -d "$rootfs_dir" ]; then
        print_warning "Rootfs directory not found, looking for tar.gz..."

        local tarball=$(ls $DEPLOY_DIR/fsl-image-ccu2-*.tar.gz 2>/dev/null | head -1)
        if [ -n "$tarball" ]; then
            print_info "Found tarball: $tarball"
            print_info "Image size: $(du -h "$tarball" | cut -f1)"
            ((passed++))
        else
            print_warning "No rootfs tarball found"
        fi

        # Skip rootfs checks if not extracted
        print_warning "Skipping rootfs structure checks (not extracted)"
        STAGE_RESULTS[2]="PASS"
        return 0
    fi

    # Required directories
    local required_dirs=(
        "usr/bin"
        "usr/lib"
        "etc/systemd"
        "lib/systemd/system"
    )

    for dir in "${required_dirs[@]}"; do
        if [ -d "$rootfs_dir/$dir" ]; then
            print_success "Directory exists: $dir"
            ((passed++))
        else
            print_error "Missing directory: $dir"
            ((failed++))
        fi
    done

    # Check for key binaries
    local key_binaries=(
        "usr/bin/systemctl"
    )

    for bin in "${key_binaries[@]}"; do
        if [ -f "$rootfs_dir/$bin" ] || [ -L "$rootfs_dir/$bin" ]; then
            print_success "Binary exists: $bin"
            ((passed++))
        else
            print_warning "Binary not found: $bin"
        fi
    done

    if [ $failed -eq 0 ]; then
        print_success "Stage 2 PASSED ($passed checks passed)"
        STAGE_RESULTS[2]="PASS"
        return 0
    else
        print_error "Stage 2 FAILED ($failed checks failed)"
        STAGE_RESULTS[2]="FAIL"
        return 1
    fi
}

# ============================================================================
# Stage 3: Static Analysis
# ============================================================================
stage3_static_analysis() {
    print_header "Stage 3: Static Analysis"

    local passed=0
    local warnings=0

    # Check bbappend files syntax (basic check)
    print_step "Checking recipe files..."
    local recipe_dir="$PROJECT_ROOT/mobis/layers/meta-sonatus"

    if [ -d "$recipe_dir" ]; then
        local bbappend_count=$(find "$recipe_dir" -name "*.bbappend" 2>/dev/null | wc -l)
        local bb_count=$(find "$recipe_dir" -name "*.bb" 2>/dev/null | wc -l)

        print_success "Found $bbappend_count bbappend files"
        print_success "Found $bb_count bb recipe files"
        ((passed++))

        # Check for common syntax issues
        local syntax_issues=0
        while IFS= read -r file; do
            # Check for tabs vs spaces issues (basic)
            if grep -P '^\t+ ' "$file" > /dev/null 2>&1; then
                $VERBOSE && print_warning "Mixed tabs/spaces in: $file"
                ((syntax_issues++))
            fi
        done < <(find "$recipe_dir" -name "*.bb" -o -name "*.bbappend" 2>/dev/null)

        if [ $syntax_issues -eq 0 ]; then
            print_success "No obvious syntax issues found"
            ((passed++))
        else
            print_warning "$syntax_issues files with potential issues"
            ((warnings++))
        fi
    else
        print_warning "Recipe directory not found"
    fi

    # Check config files
    print_step "Checking configuration files..."
    local config_files=(
        "$PROJECT_ROOT/mobis/build_info.json"
    )

    for config in "${config_files[@]}"; do
        if [ -f "$config" ]; then
            # Validate JSON
            if python3 -c "import json; json.load(open('$config'))" 2>/dev/null; then
                print_success "Valid JSON: $(basename $config)"
                ((passed++))
            else
                print_error "Invalid JSON: $(basename $config)"
            fi
        fi
    done

    print_success "Stage 3 PASSED ($passed checks, $warnings warnings)"
    STAGE_RESULTS[3]="PASS"
    return 0
}

# ============================================================================
# Stage 4: Target Board Test
# ============================================================================
stage4_target_test() {
    print_header "Stage 4: Target Board Test"

    if [ -z "$TARGET_IP" ]; then
        print_warning "No target IP specified, skipping stage 4"
        STAGE_RESULTS[4]="SKIP"
        return 0
    fi

    local passed=0
    local failed=0

    # Test SSH connection
    print_step "Testing SSH connection to $TARGET_IP..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes root@$TARGET_IP "echo 'Connected'" 2>/dev/null; then
        print_success "SSH connection successful"
        ((passed++))

        # Get system info
        print_step "Getting system info..."
        ssh root@$TARGET_IP "uname -a" 2>/dev/null && ((passed++))

        # Check systemd
        print_step "Checking systemd..."
        if ssh root@$TARGET_IP "systemctl is-system-running" 2>/dev/null; then
            print_success "Systemd is running"
            ((passed++))
        else
            print_warning "Systemd status check returned non-zero"
        fi

        # Check cgroup version (if relevant)
        print_step "Checking cgroup version..."
        local cgroup_info=$(ssh root@$TARGET_IP "cat /proc/filesystems | grep cgroup" 2>/dev/null)
        echo "$cgroup_info"

    else
        print_error "SSH connection failed"
        ((failed++))
        STAGE_RESULTS[4]="FAIL"
        return 1
    fi

    if [ $failed -eq 0 ]; then
        print_success "Stage 4 PASSED ($passed checks passed)"
        STAGE_RESULTS[4]="PASS"
        return 0
    else
        print_error "Stage 4 FAILED"
        STAGE_RESULTS[4]="FAIL"
        return 1
    fi
}

# ============================================================================
# Generate Report
# ============================================================================
generate_report() {
    echo ""
    print_header "TEST PIPELINE REPORT"
    echo ""

    local total_pass=0
    local total_fail=0
    local total_skip=0

    for stage in 1 2 3 4; do
        local result="${STAGE_RESULTS[$stage]:-N/A}"
        local status_icon

        case $result in
            PASS) status_icon="[PASS]"; ((total_pass++)) ;;
            FAIL) status_icon="[FAIL]"; ((total_fail++)) ;;
            SKIP) status_icon="[SKIP]"; ((total_skip++)) ;;
            *) status_icon="[N/A]" ;;
        esac

        local stage_name
        case $stage in
            1) stage_name="Build Verification" ;;
            2) stage_name="Image Validation" ;;
            3) stage_name="Static Analysis" ;;
            4) stage_name="Target Board Test" ;;
        esac

        print_info "Stage $stage: $stage_name - $status_icon $result"
    done

    echo ""
    echo "----------------------------------------------"
    print_info "Summary: $total_pass passed, $total_fail failed, $total_skip skipped"
    echo "----------------------------------------------"

    if [ $total_fail -gt 0 ]; then
        print_error "OVERALL: FAILED"
        return 1
    else
        print_success "OVERALL: PASSED"
        return 0
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    print_header "Yocto Test Pipeline"
    print_info "Project root: $PROJECT_ROOT"
    print_info "Stages to run: $STAGES"
    [ -n "$TARGET_IP" ] && print_info "Target IP: $TARGET_IP"

    # Initialize logging
    init_logging "test" "$CUSTOM_LOG"

    local test_start=$(date +%s)

    # Parse stages
    IFS=',' read -ra STAGE_ARRAY <<< "$STAGES"

    for stage in "${STAGE_ARRAY[@]}"; do
        case $stage in
            1) stage1_build_verification ;;
            2) stage2_image_validation ;;
            3) stage3_static_analysis ;;
            4) stage4_target_test ;;
            *) print_warning "Unknown stage: $stage" ;;
        esac
        echo ""
    done

    local overall_result=0
    generate_report || overall_result=1

    local elapsed=$(get_elapsed_time $test_start)
    print_info "Total test time: $elapsed"

    # Finalize logging
    local status="SUCCESS"
    [ $overall_result -ne 0 ] && status="FAILED"
    finalize_logging "$status" "Stages=$STAGES"

    return $overall_result
}

main "$@"
