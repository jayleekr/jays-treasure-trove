# Jay's Treasure Trove 🏴‍☠️

A collection of one-liner installation commands and utilities for rapid development setup.

## 🚀 Quick Install Commands

### 1. Install SuperClaude
Enhance your Claude Code experience with the complete SuperClaude framework:
```bash
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-superclaude.sh | bash
```

### 2. Install Claude Git Hooks
Add AI-powered code review to any git repository:
```bash
# Install pre-commit hook (default)
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-claude-hook.sh | bash

# Install specific hook type in current directory
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-claude-hook.sh | bash -s -- pre-push .

# Install in specific directory
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-claude-hook.sh | bash -s -- pre-commit /path/to/repo
```

Available hook types: `pre-commit`, `post-commit`, `pre-push`, `commit-msg`, `prepare-commit-msg`

### 3. Install Subagents

#### 🧠 Smart Installation (Recommended)
Analyzes your project and installs only the agents you need:
```bash
# Run in your project directory
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-smart-subagents.sh | bash

# Or specify a directory
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-smart-subagents.sh | bash -s -- /path/to/project
```

**Smart installer will:**
- 🔍 Analyze your technology stack (Node.js, Python, Go, etc.)
- 📊 Detect project type (frontend, backend, mobile, etc.)
- 📈 Check recent development activity
- 🎯 Recommend only relevant agents
- 📋 Create project-specific documentation

#### 📦 Basic Installation
Install a pre-defined set of essential agents:
```bash
curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-subagents.sh | bash
```

## 📦 What's Included

### SuperClaude Framework
- **Commands**: `/build`, `/analyze`, `/improve`, `/implement`, and more
- **Personas**: architect, frontend, backend, security, performance specialists
- **MCP Integration**: Context7, Sequential, Magic, Playwright servers
- **Intelligent Routing**: Automatic tool and persona selection

### Claude Git Hooks
- Automated code review on commits
- Smart suggestions for improvements
- Configurable for different git events
- Works with any git repository

### Recommended Subagents
**Engineering Agents:**
- `ai-engineer` - Integrate AI/ML features seamlessly
- `backend-architect` - Design scalable server systems
- `devops-automator` - Automate CI/CD pipelines
- `test-writer-fixer` - Write comprehensive test suites
- `rapid-prototyper` - Build MVPs in days

**Project Management:**
- `sprint-prioritizer` - Maximize sprint value delivery
- `project-shipper` - Launch without crashes

**Operations:**
- `infrastructure-maintainer` - Scale efficiently
- `analytics-reporter` - Data-driven insights

## 🎯 Usage Examples

### Using SuperClaude Commands
```bash
# Build a new feature
/build "user authentication system"

# Analyze code quality
/analyze --focus security @src/

# Improve performance
/improve --perf @api/
```

### Using Subagents
```bash
# Design a scalable architecture
/spawn @backend-architect "Design microservices for e-commerce platform"

# Add AI features
/spawn @ai-engineer "Integrate GPT-4 for customer support chat"

# Write comprehensive tests
/spawn @test-writer-fixer "Add test coverage to authentication module"
```

## 🛠️ Manual Installation

If you prefer to install components manually:

1. **SuperClaude**: Copy all `.md` files from `superclaude/` to `~/.claude/`
2. **Git Hooks**: Run `./install-claude-hook.sh [hook-type] [directory]`
3. **Subagents**: Clone from https://github.com/contains-studio/agents

## 🤝 Contributing

Feel free to add your own useful scripts and one-liners! Submit a PR to share with the community.

## 📄 License

MIT License - Use freely and customize to your needs!