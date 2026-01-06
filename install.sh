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
else
    log_ok "~/.env exists"
fi

# Show available projects
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
echo "To configure a project:"
echo "  $INSTALL_DIR/setup-project.sh <project-name> <project-path>"
echo
echo "Or use one-liner:"
echo "  curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/setup-project.sh | bash -s -- <project-name> <project-path>"
echo
