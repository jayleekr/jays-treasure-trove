#!/bin/bash
#
# Jay's Treasure Trove Installer
# Centralized Claude Code configuration management
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install.sh | bash
#

set -euo pipefail

# Configuration
REPO_URL="git@github.com:jayleekr/jays-treasure-trove.git"
REPO_HTTPS="https://github.com/jayleekr/jays-treasure-trove.git"
INSTALL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-config}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "========================================"
echo "  Jay's Treasure Trove Installer"
echo "========================================"
echo

# Check prerequisites
command -v git >/dev/null 2>&1 || {
    log_error "git is required but not installed"
    exit 1
}

# Clone or update repo
if [[ -d "$INSTALL_DIR/.git" ]]; then
    log_info "Updating existing installation..."
    (cd "$INSTALL_DIR" && git pull --ff-only) || {
        log_warn "Fast-forward failed. Please resolve manually:"
        log_warn "  cd $INSTALL_DIR && git pull"
    }
else
    log_info "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR" 2>/dev/null || \
    git clone "$REPO_HTTPS" "$INSTALL_DIR" || {
        log_error "Failed to clone repository"
        exit 1
    }
fi

log_ok "Repository ready at $INSTALL_DIR"

# Check ~/.env
echo
if [[ ! -f "$HOME/.env" ]]; then
    log_warn "~/.env not found!"
    echo
    echo "Please create ~/.env from template:"
    echo "  cp $INSTALL_DIR/.env.template ~/.env"
    echo "  vi ~/.env  # Add your credentials"
    echo
    ENV_EXISTS=false
else
    log_ok "~/.env exists"
    ENV_EXISTS=true
fi

# Auto-detect project from current directory
detect_project() {
    local current_dir="$PWD"

    # Check path patterns for known projects
    if [[ "$current_dir" == *"CCU_GEN2.0_SONATUS"* ]]; then
        # Find the root of CCU_GEN2.0_SONATUS project
        local project_root="$current_dir"
        while [[ "$project_root" != "/" ]]; do
            if [[ "$(basename "$project_root")" == *"CCU_GEN2.0_SONATUS"* ]]; then
                echo "ccu2-yocto:$project_root"
                return 0
            fi
            project_root="$(dirname "$project_root")"
        done
    fi

    if [[ "$current_dir" == *"ccu-2.0"* ]] || [[ "$current_dir" == *"ccu2.0"* ]]; then
        local project_root="$current_dir"
        while [[ "$project_root" != "/" ]]; do
            if [[ "$(basename "$project_root")" == *"ccu-2.0"* ]] || [[ "$(basename "$project_root")" == *"ccu2.0"* ]]; then
                echo "ccu2-host:$project_root"
                return 0
            fi
            project_root="$(dirname "$project_root")"
        done
    fi

    return 1
}

# Try auto-detection
DETECTED=$(detect_project) || true

if [[ -n "$DETECTED" ]] && [[ "$ENV_EXISTS" == "true" ]]; then
    PROJECT_NAME="${DETECTED%%:*}"
    PROJECT_PATH="${DETECTED#*:}"

    echo
    log_info "Detected project: $PROJECT_NAME"
    log_info "Project path: $PROJECT_PATH"
    echo

    # Auto-configure the project
    "$INSTALL_DIR/setup-project.sh" "$PROJECT_NAME" "$PROJECT_PATH"
else
    # Show available projects (manual mode)
    echo
    echo "========================================"
    log_ok "Installation complete!"
    echo "========================================"
    echo
    echo "Location: $INSTALL_DIR"
    echo
    echo "Available projects:"
    if [[ -d "$INSTALL_DIR/projects" ]]; then
        ls -1 "$INSTALL_DIR/projects/" 2>/dev/null | sed 's/^/  - /'
    else
        echo "  (none found)"
    fi
    echo
    echo "To configure a project, run from project directory:"
    echo "  $INSTALL_DIR/setup-project.sh <project-name> ."
    echo
fi
