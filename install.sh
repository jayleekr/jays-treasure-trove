#!/bin/bash
#
# Jay's Treasure Trove Installer
# Centralized Claude Code configuration management
#
# Usage:
#   cd ~/your-project
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

# Step 1: Clone or update repo
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

# Step 1.5: Initialize core session detection
echo
log_info "Initializing session detection..."
if [[ -f "$INSTALL_DIR/core/detect-session.sh" ]]; then
    source "$INSTALL_DIR/core/detect-session.sh"
    source "$INSTALL_DIR/core/session-info.sh"

    # Show session info
    show_session_info

    # Store session type for all projects
    SESSION_TYPE=$(detect_session_type)
    export CLAUDE_SESSION_TYPE=$SESSION_TYPE

    # Add to ~/.env if it exists
    if [[ -f "$HOME/.env" ]]; then
        if ! grep -q "CLAUDE_SESSION_TYPE" "$HOME/.env" 2>/dev/null; then
            echo "export CLAUDE_SESSION_TYPE=$SESSION_TYPE" >> "$HOME/.env"
            log_ok "Added CLAUDE_SESSION_TYPE=$SESSION_TYPE to ~/.env"
        fi
    fi
else
    log_warn "Core session detection scripts not found. Skipping session detection."
fi
echo

# Step 2: Check ~/.env
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

# Step 3: Auto-detect project from current directory
detect_project_root() {
    local current_dir="$PWD"

    # CCU_GEN2.0_SONATUS (Yocto build)
    if [[ "$current_dir" == *"CCU_GEN2.0_SONATUS"* ]]; then
        local dir="$current_dir"
        while [[ "$dir" != "/" ]]; do
            if [[ "$(basename "$dir")" == *"CCU_GEN2.0_SONATUS"* ]]; then
                echo "$dir"
                return 0
            fi
            dir="$(dirname "$dir")"
        done
    fi

    # ccu-2.0 (Host build)
    if [[ "$current_dir" == *"ccu-2.0"* ]] || [[ "$current_dir" == *"ccu2.0"* ]]; then
        local dir="$current_dir"
        while [[ "$dir" != "/" ]]; do
            if [[ "$(basename "$dir")" == *"ccu-2.0"* ]] || [[ "$(basename "$dir")" == *"ccu2.0"* ]]; then
                echo "$dir"
                return 0
            fi
            dir="$(dirname "$dir")"
        done
    fi

    # container-manager (AUTOSAR Adaptive)
    if [[ "$current_dir" == *"container-manager"* ]]; then
        local dir="$current_dir"
        while [[ "$dir" != "/" ]]; do
            # Check for container-manager project markers
            if [[ "$(basename "$dir")" == *"container-manager"* ]] || \
               [[ -f "$dir/build.toml" && -f "$dir/CMakeLists.txt" ]]; then
                # Verify it's container-manager by checking CMakeLists.txt
                if grep -q "project(container-manager" "$dir/CMakeLists.txt" 2>/dev/null || \
                   [[ "$(basename "$dir")" == *"container-manager"* ]]; then
                    echo "$dir"
                    return 0
                fi
            fi
            dir="$(dirname "$dir")"
        done
    fi

    return 1
}

PROJECT_ROOT=$(detect_project_root) || true

# Step 4: Determine project-specific config directory
determine_project_config() {
    local project_root="$1"
    local project_name=$(basename "$project_root")

    # Check for project-specific config
    if [[ -d "$INSTALL_DIR/projects/$project_name" ]]; then
        echo "$INSTALL_DIR/projects/$project_name"
        return 0
    fi

    # Check for partial match (e.g., CCU_GEN2.0_SONATUS.manifest → CCU_GEN2.0_SONATUS)
    for config_dir in "$INSTALL_DIR/projects"/*; do
        if [[ -d "$config_dir" ]]; then
            local config_name=$(basename "$config_dir")
            if [[ "$project_name" == *"$config_name"* ]] || [[ "$config_name" == *"$project_name"* ]]; then
                echo "$config_dir"
                return 0
            fi
        fi
    done

    # Fall back to common
    echo "$INSTALL_DIR/projects/common"
    return 0
}

# Step 5: Create symlinks if project detected and env exists
if [[ -n "$PROJECT_ROOT" ]] && [[ "$ENV_EXISTS" == "true" ]]; then
    echo
    log_info "Detected project: $PROJECT_ROOT"

    # Determine project config directory
    PROJECT_CONFIG=$(determine_project_config "$PROJECT_ROOT")
    log_info "Using config: $PROJECT_CONFIG"

    # Create .env symlink
    ENV_TARGET="$PROJECT_ROOT/.env"
    [[ -L "$ENV_TARGET" ]] && rm "$ENV_TARGET"
    [[ -f "$ENV_TARGET" ]] && rm "$ENV_TARGET"
    ln -sf "$HOME/.env" "$ENV_TARGET"
    log_ok ".env → ~/.env"

    # Create .claude symlink
    CLAUDE_TARGET="$PROJECT_ROOT/.claude"
    if [[ -d "$CLAUDE_TARGET" ]] && [[ ! -L "$CLAUDE_TARGET" ]]; then
        BACKUP="$CLAUDE_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backing up existing .claude/ to $BACKUP"
        mv "$CLAUDE_TARGET" "$BACKUP"
    fi
    [[ -L "$CLAUDE_TARGET" ]] && rm "$CLAUDE_TARGET"
    ln -sf "$PROJECT_CONFIG" "$CLAUDE_TARGET"
    log_ok ".claude/ → $PROJECT_CONFIG"

    # Create CLAUDE.md symlink
    CLAUDE_MD_TARGET="$PROJECT_ROOT/CLAUDE.md"
    [[ -L "$CLAUDE_MD_TARGET" ]] && rm "$CLAUDE_MD_TARGET"
    if [[ -f "$CLAUDE_MD_TARGET" ]]; then
        BACKUP="$CLAUDE_MD_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Backing up existing CLAUDE.md to $BACKUP"
        mv "$CLAUDE_MD_TARGET" "$BACKUP"
    fi
    ln -sf "$INSTALL_DIR/PROJECT_CLAUDE.md" "$CLAUDE_MD_TARGET"
    log_ok "CLAUDE.md → $INSTALL_DIR/PROJECT_CLAUDE.md"

    echo
    echo "========================================"
    log_ok "Setup complete!"
    echo "========================================"
    echo
    echo "Project: $PROJECT_ROOT"
    echo "  .env      → ~/.env"
    echo "  .claude/  → $PROJECT_CONFIG"
    echo "  CLAUDE.md → $INSTALL_DIR/PROJECT_CLAUDE.md"
    echo

elif [[ -z "$PROJECT_ROOT" ]]; then
    echo
    echo "========================================"
    log_warn "No project detected"
    echo "========================================"
    echo
    echo "Run this script from inside a supported project directory:"
    echo "  cd ~/CCU_GEN2.0_SONATUS.manifest && bash $INSTALL_DIR/install.sh"
    echo "  cd ~/ccu-2.0 && bash $INSTALL_DIR/install.sh"
    echo "  cd ~/container-manager && bash $INSTALL_DIR/install.sh"
    echo

else
    echo
    echo "========================================"
    log_warn "Setup incomplete - ~/.env required"
    echo "========================================"
    echo
    echo "Create ~/.env first, then re-run:"
    echo "  cp $INSTALL_DIR/.env.template ~/.env"
    echo "  vi ~/.env"
    echo "  bash $INSTALL_DIR/install.sh"
    echo
fi
