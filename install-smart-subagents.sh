#!/bin/bash
# Smart Subagent Installer - Analyzes your project and recommends relevant agents
# Usage: curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-smart-subagents.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Analyzing your project to recommend optimal subagents...${NC}"

# Get current directory or use provided directory
PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Initialize analysis results
DETECTED_STACK=""
RECOMMENDED_AGENTS=()
PROJECT_TYPE=""

# Function to add recommendation with reason
add_recommendation() {
    local agent=$1
    local reason=$2
    RECOMMENDED_AGENTS+=("$agent:$reason")
}

# Analyze project type and technology stack
echo -e "${YELLOW}📊 Detecting technology stack...${NC}"

# Check for package.json (Node.js/JavaScript)
if [ -f "package.json" ]; then
    DETECTED_STACK="$DETECTED_STACK Node.js"
    
    # Check for specific frameworks
    if grep -q "react\|next\|gatsby" package.json 2>/dev/null; then
        PROJECT_TYPE="frontend"
        add_recommendation "frontend-developer" "React/Next.js detected"
        add_recommendation "ui-designer" "Frontend project needs UI design"
        add_recommendation "whimsy-injector" "Add delightful interactions"
    fi
    
    if grep -q "express\|fastify\|koa\|nestjs" package.json 2>/dev/null; then
        PROJECT_TYPE="backend"
        add_recommendation "backend-architect" "Node.js backend framework detected"
        add_recommendation "test-writer-fixer" "Backend needs comprehensive testing"
    fi
    
    if grep -q "react-native\|expo" package.json 2>/dev/null; then
        PROJECT_TYPE="mobile"
        add_recommendation "mobile-app-builder" "React Native/Expo detected"
        add_recommendation "app-store-optimizer" "Mobile apps need store optimization"
    fi
    
    if grep -q "@tensorflow\|@huggingface\|openai\|@langchain" package.json 2>/dev/null; then
        add_recommendation "ai-engineer" "AI/ML libraries detected"
    fi
fi

# Check for Python projects
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
    DETECTED_STACK="$DETECTED_STACK Python"
    
    if [ -f "requirements.txt" ]; then
        if grep -q "django\|flask\|fastapi" requirements.txt 2>/dev/null; then
            PROJECT_TYPE="backend"
            add_recommendation "backend-architect" "Python web framework detected"
        fi
        
        if grep -q "tensorflow\|torch\|scikit-learn\|transformers" requirements.txt 2>/dev/null; then
            add_recommendation "ai-engineer" "ML/AI libraries detected"
        fi
    fi
fi

# Check for Go projects
if [ -f "go.mod" ]; then
    DETECTED_STACK="$DETECTED_STACK Go"
    PROJECT_TYPE="backend"
    add_recommendation "backend-architect" "Go project detected"
    add_recommendation "devops-automator" "Go projects often need deployment automation"
fi

# Check for mobile projects
if [ -d "ios" ] || [ -d "android" ] || [ -f "*.xcodeproj" ] || [ -f "build.gradle" ]; then
    PROJECT_TYPE="mobile"
    add_recommendation "mobile-app-builder" "Native mobile project detected"
    add_recommendation "app-store-optimizer" "Mobile apps need store optimization"
fi

# Check for infrastructure/DevOps
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f ".gitlab-ci.yml" ] || [ -f ".github/workflows/"*.yml ]; then
    add_recommendation "devops-automator" "Docker/CI configuration detected"
    add_recommendation "infrastructure-maintainer" "Infrastructure configuration present"
fi

# Check for testing needs
if [ -d "tests" ] || [ -d "test" ] || [ -d "__tests__" ] || [ -d "spec" ]; then
    add_recommendation "test-writer-fixer" "Test directory found"
fi

# Analyze recent git activity (if git repo)
if [ -d ".git" ]; then
    echo -e "${YELLOW}📈 Analyzing recent development activity...${NC}"
    
    # Check recent commit messages
    if git log --oneline -n 20 2>/dev/null | grep -qi "bug\|fix\|issue\|error"; then
        add_recommendation "test-writer-fixer" "Recent bug fixes detected"
    fi
    
    if git log --oneline -n 20 2>/dev/null | grep -qi "refactor\|optimize\|performance"; then
        add_recommendation "backend-architect" "Recent refactoring activity"
    fi
    
    if git log --oneline -n 20 2>/dev/null | grep -qi "ui\|ux\|design\|style\|css"; then
        add_recommendation "ui-designer" "Recent UI/UX work"
        add_recommendation "ux-researcher" "UI changes need user research"
    fi
fi

# Analyze project size and complexity
FILE_COUNT=$(find . -type f -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" 2>/dev/null | wc -l)
if [ "$FILE_COUNT" -gt 100 ]; then
    add_recommendation "project-shipper" "Large project needs shipping expertise"
    add_recommendation "sprint-prioritizer" "Complex project needs sprint planning"
fi

# Check for documentation needs
if [ ! -f "README.md" ] || [ $(wc -l < README.md 2>/dev/null || echo 0) -lt 20 ]; then
    add_recommendation "content-creator" "Documentation needs improvement"
fi

# Analyze for marketing/growth needs
if [ "$PROJECT_TYPE" = "frontend" ] || [ "$PROJECT_TYPE" = "mobile" ]; then
    add_recommendation "growth-hacker" "User-facing app needs growth strategy"
    add_recommendation "analytics-reporter" "Need analytics for user insights"
fi

# Default recommendations for all projects
add_recommendation "rapid-prototyper" "Useful for quick feature development"
add_recommendation "experiment-tracker" "Data-driven development"

# Display analysis results
echo -e "\n${GREEN}✅ Project Analysis Complete!${NC}"
echo -e "${BLUE}📋 Project Type:${NC} ${PROJECT_TYPE:-Mixed/Unknown}"
echo -e "${BLUE}🔧 Detected Stack:${NC}${DETECTED_STACK:-Not detected}"
echo -e "${BLUE}📁 Project Size:${NC} $FILE_COUNT source files"

# Show recommendations
echo -e "\n${YELLOW}🤖 Recommended Subagents:${NC}"
declare -A UNIQUE_AGENTS
for rec in "${RECOMMENDED_AGENTS[@]}"; do
    agent="${rec%%:*}"
    reason="${rec#*:}"
    if [ -z "${UNIQUE_AGENTS[$agent]}" ]; then
        UNIQUE_AGENTS[$agent]="$reason"
    else
        UNIQUE_AGENTS[$agent]="${UNIQUE_AGENTS[$agent]}, $reason"
    fi
done

# Sort and display unique recommendations
for agent in "${!UNIQUE_AGENTS[@]}"; do
    echo -e "  ${GREEN}►${NC} ${agent}"
    echo -e "    ${YELLOW}Why:${NC} ${UNIQUE_AGENTS[$agent]}"
done

# Ask for confirmation
echo -e "\n${BLUE}Would you like to install these recommended agents? (y/n)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Install selected agents
echo -e "\n${YELLOW}🚀 Installing recommended subagents...${NC}"

# Base directory for agents
AGENTS_DIR="$HOME/.claude/agents"
mkdir -p "$AGENTS_DIR"

# Clone or update the agents repository
if [ -d "$AGENTS_DIR/contains-studio-agents" ]; then
    echo "📥 Updating existing agents repository..."
    cd "$AGENTS_DIR/contains-studio-agents"
    git pull
else
    echo "📥 Cloning agents repository..."
    git clone https://github.com/contains-studio/agents.git "$AGENTS_DIR/contains-studio-agents"
fi

# Create symlinks for recommended agents
echo -e "\n${YELLOW}🔗 Setting up recommended agents...${NC}"
for agent in "${!UNIQUE_AGENTS[@]}"; do
    SOURCE="$AGENTS_DIR/contains-studio-agents/$agent"
    TARGET="$AGENTS_DIR/$agent"
    
    if [ -d "$SOURCE" ]; then
        ln -sfn "$SOURCE" "$TARGET"
        echo -e "${GREEN}✅ Installed:${NC} $agent"
    else
        echo -e "${RED}⚠️  Agent not found:${NC} $agent"
    fi
done

# Create project-specific recommendations file
cd "$PROJECT_DIR"
mkdir -p .claude
cat > .claude/recommended-agents.md << EOF
# Recommended Subagents for This Project

Based on the analysis of your project, these agents were recommended and installed:

$(for agent in "${!UNIQUE_AGENTS[@]}"; do
    echo "## $agent"
    echo "**Why:** ${UNIQUE_AGENTS[$agent]}"
    echo ""
done)

## Usage Examples

$(if [[ "${UNIQUE_AGENTS[frontend-developer]}" ]]; then
    echo '```bash'
    echo '/spawn @frontend-developer "Create responsive navigation component"'
    echo '```'
fi)

$(if [[ "${UNIQUE_AGENTS[backend-architect]}" ]]; then
    echo '```bash'
    echo '/spawn @backend-architect "Design scalable API architecture"'
    echo '```'
fi)

$(if [[ "${UNIQUE_AGENTS[ai-engineer]}" ]]; then
    echo '```bash'
    echo '/spawn @ai-engineer "Integrate LLM for smart features"'
    echo '```'
fi)

## Project Analysis Summary
- **Project Type:** ${PROJECT_TYPE:-Mixed/Unknown}
- **Technology Stack:**${DETECTED_STACK:-Not detected}
- **Project Size:** $FILE_COUNT source files
- **Analysis Date:** $(date +"%Y-%m-%d %H:%M:%S")

To re-analyze and update recommendations, run:
\`\`\`bash
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-smart-subagents.sh | bash
\`\`\`
EOF

echo -e "\n${GREEN}✅ Smart subagent installation complete!${NC}"
echo -e "${BLUE}📍 Agents installed to:${NC} $AGENTS_DIR"
echo -e "${BLUE}📋 Project recommendations:${NC} .claude/recommended-agents.md"
echo -e "${YELLOW}🎯 Start using agents with:${NC} /spawn @agent-name \"your task\""