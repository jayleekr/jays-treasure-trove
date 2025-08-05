#!/bin/bash
# Basic Subagent Installer - Install pre-defined set of essential agents
# For smart project-based installation, use install-smart-subagents.sh
# Usage: curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-subagents.sh | bash

set -e

echo "🤖 Installing essential Contains Studio subagents..."
echo "💡 Tip: Use install-smart-subagents.sh for project-specific recommendations!"

# Essential subagents for general development
RECOMMENDED_AGENTS=(
    # Engineering essentials
    "ai-engineer"           # For AI/ML integration
    "backend-architect"     # For scalable API design
    "devops-automator"     # For CI/CD automation
    "test-writer-fixer"    # For comprehensive testing
    "rapid-prototyper"     # For quick MVPs
    
    # Project management
    "sprint-prioritizer"   # For efficient sprint planning
    "project-shipper"      # For smooth launches
    
    # Code quality
    "infrastructure-maintainer"  # For scaling and optimization
    "analytics-reporter"        # For data-driven insights
)

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
echo "🔗 Setting up recommended agents..."
for agent in "${RECOMMENDED_AGENTS[@]}"; do
    SOURCE="$AGENTS_DIR/contains-studio-agents/$agent"
    TARGET="$AGENTS_DIR/$agent"
    
    if [ -d "$SOURCE" ]; then
        ln -sfn "$SOURCE" "$TARGET"
        echo "✅ Linked: $agent"
    else
        echo "⚠️  Agent not found: $agent"
    fi
done

# Create a quick reference file
cat > "$AGENTS_DIR/README.md" << 'EOF'
# Installed Subagents

## Engineering Agents
- **ai-engineer**: Integrate AI/ML features into your projects
- **backend-architect**: Design scalable APIs and server systems
- **devops-automator**: Automate deployments and CI/CD pipelines
- **test-writer-fixer**: Write comprehensive tests that catch real bugs
- **rapid-prototyper**: Build MVPs quickly and efficiently

## Project Management Agents
- **sprint-prioritizer**: Maximize value delivery in each sprint
- **project-shipper**: Launch products smoothly without crashes

## Operations Agents
- **infrastructure-maintainer**: Scale systems without breaking the bank
- **analytics-reporter**: Turn data into actionable insights

## Usage
To use an agent, reference it in your Claude commands:
```
/spawn @ai-engineer "Integrate GPT-4 into our chat feature"
/spawn @backend-architect "Design a scalable microservices architecture"
/spawn @test-writer-fixer "Add comprehensive test coverage to the auth module"
```

## Add More Agents
Browse all available agents at: https://github.com/contains-studio/agents
EOF

echo "✅ Subagents installed successfully!"
echo "📍 Location: $AGENTS_DIR"
echo "📖 Reference: $AGENTS_DIR/README.md"
echo "🎯 Use '/spawn @agent-name' to activate any agent!"