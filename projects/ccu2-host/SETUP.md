# CCU-2.0 Claude Code Setup

## Directory Structure

```
ccu-2.0/.claude/
├── SETUP.md                 # This file - setup instructions
├── CLAUDE.md                # Project knowledge base
├── README.md                # Usage guide
├── commands/                # Slash commands (/command-name)
│   ├── component.md
│   ├── build-component.md
│   ├── container-test.md
│   ├── jira-commit.md
│   ├── syscall-test.md
│   └── deployment-diff.md
└── settings.local.json      # Local overrides (gitignored)
```

## Why In-Repo Configuration?

### ✅ Benefits
1. **Version Controlled**: Track changes to commands/knowledge
2. **Team Sharing**: Share via git branch (jay-claude)
3. **Project-Specific**: Configuration travels with codebase
4. **Easy Sync**: Pull/push to sync across machines

### 📋 Workflow
```bash
# On jay-claude branch
git checkout jay-claude
git add .claude/
git commit -m "[Claude] Update configuration"
git push origin jay-claude

# On other machine
git checkout jay-claude
git pull
# Commands now available!
```

## Installation

### Option 1: Use jay-claude Branch (Recommended)
```bash
# Switch to jay-claude branch
git checkout jay-claude

# Commands are automatically available when in this directory
cd /home/jay.lee/ccu-2.0
# Now you can use /component, /build-component, etc.
```

### Option 2: Cherry-Pick to Other Branches
```bash
# From your feature branch
git checkout my-feature
git checkout jay-claude -- .claude/
# Now .claude/ is available on your branch
```

### Option 3: Keep on Master (Add to .gitignore)
```bash
# Add to .gitignore if you don't want to commit
echo ".claude/settings.local.json" >> .gitignore
```

## Commands vs Skills

### Slash Commands (What We Created)
- **Purpose**: Project-specific workflow automation
- **Format**: Markdown files with prompts
- **Usage**: `/command-name [args]`
- **Location**: `.claude/commands/*.md`

**Example**:
```markdown
---
description: Analyze CCU-2.0 component
---

# Component Analysis

Analyze component structure and dependencies...
```

### Skills (Future Enhancement)
- **Purpose**: Cross-project reusable tools
- **Format**: Executable scripts or specialized agents
- **Usage**: Via Skill tool invocation
- **Location**: `.claude/skills/` or global `~/.claude/skills/`

**When to use**:
- Binary analysis tools
- Code generation utilities
- Cross-project automation

## Customization

### Personal Overrides
Create `.claude/settings.local.json`:
```json
{
  "preferred_build_type": "Debug",
  "jira_api_token": "your-token",
  "default_components": ["container-manager", "vam"]
}
```

**Note**: `settings.local.json` is gitignored by default

### Adding New Commands

1. Create `.claude/commands/my-command.md`:
```markdown
---
description: My custom command
---

# My Command

Task description...
```

2. Commit to jay-claude branch:
```bash
git add .claude/commands/my-command.md
git commit -m "[Claude] Add my-command"
```

3. Use it:
```bash
/my-command [args]
```

## Available Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `/component` | Analyze component structure | `/component vam` |
| `/build-component` | Smart component build | `/build-component --type Release` |
| `/container-test` | Run container tests | `/container-test C11584` |
| `/jira-commit` | JIRA-formatted commit | `/jira-commit CCU2-123 "Fix bug"` |
| `/syscall-test` | Syscall test analysis | `/syscall-test main.cxx --fix` |
| `/deployment-diff` | Compare deployments | `/deployment-diff base.json new.json` |

## Knowledge Base

**CLAUDE.md** contains:
- Repository structure
- Build system documentation
- Commit conventions
- Common workflows
- Technical stack
- Security patterns
- Troubleshooting guides

## Team Collaboration

### Sharing Your Commands
```bash
# Create PR from jay-claude to master
git checkout jay-claude
git push origin jay-claude

# Create PR: jay-claude → master
# Team reviews and merges .claude/ directory
```

### Using Team's Commands
```bash
# Pull latest
git checkout master
git pull

# Commands automatically available
cd /home/jay.lee/ccu-2.0
/component  # Works!
```

## Migration from ~/.claude

If you had files in `~/.claude/ccu-2.0/`:

```bash
# Already migrated to .claude/ in repo!
# Old location: ~/.claude/ccu-2.0/
# New location: /home/jay.lee/ccu-2.0/.claude/
```

**Benefits of migration**:
- ✅ Version controlled
- ✅ Shareable with team
- ✅ Syncs via git
- ✅ Project-specific

## Troubleshooting

### Commands not showing up?
1. Check you're in ccu-2.0 directory
2. Verify `.claude/commands/` exists
3. Check file permissions: `chmod +r .claude/commands/*.md`

### Want personal overrides?
Create `.claude/settings.local.json` (gitignored)

### Want global settings?
Use `~/.claude/CLAUDE.md` for cross-project configuration

## Advanced: Combining Global + Project Config

```
~/.claude/
├── CLAUDE.md              # Global settings (all projects)
└── ccu-2.0/ -> /home/jay.lee/ccu-2.0/.claude/  # Symlink

/home/jay.lee/ccu-2.0/
└── .claude/               # Project-specific (version controlled)
```

Claude Code loads **both**:
1. Global `~/.claude/CLAUDE.md`
2. Project `.claude/CLAUDE.md`

Project settings **override** global ones.
