#!/bin/bash
#
# Setup project-specific Claude configuration
#
# Usage:
#   ./setup-project.sh <project-name> <project-path>
#
# Examples:
#   ./setup-project.sh ccu2-yocto ~/CCU_GEN2.0_SONATUS.manifest
#   ./setup-project.sh ccu2-host ~/ccu-2.0
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/setup-project.sh | bash -s -- ccu2-yocto ~/CCU_GEN2.0_SONATUS.manifest
#

set -euo pipefail

# Configuration
INSTALL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-config}"
REPO_URL="git@github.com:jayleekr/jays-treasure-trove.git"
REPO_HTTPS="https://github.com/jayleekr/jays-treasure-trove.git"

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

# Parse arguments
PROJECT_NAME="${1:-}"
TARGET_DIR="${2:-}"

# Show usage if no arguments
if [[ -z "$PROJECT_NAME" ]] || [[ -z "$TARGET_DIR" ]]; then
    echo "Usage: $0 <project-name> <project-path>"
    echo
    echo "Available projects:"
    if [[ -d "$INSTALL_DIR/projects" ]]; then
        ls -1 "$INSTALL_DIR/projects/" 2>/dev/null | sed 's/^/  - /'
    else
        echo "  (install first: curl -fsSL .../install.sh | bash)"
    fi
    exit 1
fi

# Expand ~ in TARGET_DIR
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

echo "========================================"
echo "  Project Setup: $PROJECT_NAME"
echo "========================================"
echo

# Step 1: Ensure jays-treasure-trove is installed
if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    log_info "Installing jays-treasure-trove..."
    git clone "$REPO_URL" "$INSTALL_DIR" 2>/dev/null || \
    git clone "$REPO_HTTPS" "$INSTALL_DIR" || {
        log_error "Failed to clone repository"
        exit 1
    }
else
    log_info "Updating jays-treasure-trove..."
    (cd "$INSTALL_DIR" && git pull --ff-only 2>/dev/null) || true
fi

# Step 2: Check project exists
PROJECT_SRC="$INSTALL_DIR/projects/$PROJECT_NAME"
if [[ ! -d "$PROJECT_SRC" ]]; then
    log_error "Project '$PROJECT_NAME' not found in $PROJECT_SRC"
    echo
    echo "Available projects:"
    ls -1 "$INSTALL_DIR/projects/" 2>/dev/null | sed 's/^/  - /'
    exit 1
fi

# Step 3: Check target directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    log_error "Target directory not found: $TARGET_DIR"
    exit 1
fi

# Step 4: Check ~/.env exists
if [[ ! -f "$HOME/.env" ]]; then
    log_error "~/.env not found!"
    echo
    echo "Please create ~/.env from template:"
    echo "  cp $INSTALL_DIR/.env.template ~/.env"
    echo "  vi ~/.env  # Add your credentials"
    exit 1
fi

# Step 5: Backup existing .claude if not symlink
CLAUDE_TARGET="$TARGET_DIR/.claude"
if [[ -d "$CLAUDE_TARGET" ]] && [[ ! -L "$CLAUDE_TARGET" ]]; then
    BACKUP="$CLAUDE_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
    log_warn "Backing up existing .claude/ to $BACKUP"
    mv "$CLAUDE_TARGET" "$BACKUP"
fi

# Remove existing symlink if present
[[ -L "$CLAUDE_TARGET" ]] && rm "$CLAUDE_TARGET"

# Step 6: Create .env symlink
ENV_TARGET="$TARGET_DIR/.env"
if [[ -L "$ENV_TARGET" ]] || [[ -f "$ENV_TARGET" ]]; then
    rm -f "$ENV_TARGET"
fi
ln -sf "$HOME/.env" "$ENV_TARGET"
log_ok ".env -> ~/.env"

# Step 7: Create .claude symlink
ln -sf "$PROJECT_SRC" "$CLAUDE_TARGET"
log_ok ".claude/ -> $PROJECT_SRC"

echo
echo "========================================"
log_ok "Setup complete!"
echo "========================================"
echo
echo "Project: $TARGET_DIR"
echo "  .env    -> ~/.env"
echo "  .claude -> $PROJECT_SRC"
echo
