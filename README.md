# Jay's Treasure Trove

Centralized project-specific Claude Code configuration management across multiple machines.

## Quick Start

### 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install.sh | bash
```

This will:
- Clone this repo to `~/.claude-config`
- Show available project configurations

### 2. Set Up Credentials (once per machine)

```bash
cp ~/.claude-config/.env.template ~/.env
vi ~/.env  # Add your credentials
```

**Required:**
- `JIRA_BASE_URL` - Your JIRA instance URL
- `JIRA_EMAIL` - Your JIRA email
- `JIRA_API_TOKEN` - Your JIRA API token

### 3. Configure a Project

After cloning a project repository:

```bash
# For CCU_GEN2.0_SONATUS.manifest (Yocto build)
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/setup-project.sh | bash -s -- ccu2-yocto ~/CCU_GEN2.0_SONATUS.manifest

# For ccu-2.0 (Host build)
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/setup-project.sh | bash -s -- ccu2-host ~/ccu-2.0
```

Or if already installed:
```bash
~/.claude-config/setup-project.sh ccu2-yocto ~/CCU_GEN2.0_SONATUS.manifest
```

## Available Projects

| Project | Config Name | Features |
|---------|-------------|----------|
| CCU_GEN2.0_SONATUS.manifest | ccu2-yocto | Yocto build commands, scripts |
| ccu-2.0 | ccu2-host | JIRA integration, MISRA compliance, auto-build hooks |

## Directory Structure

```
~/.claude-config/           # This repo (cloned)
├── .env.template           # Credentials template
├── install.sh              # Installation script
├── setup-project.sh        # Project setup script
└── projects/
    ├── ccu2-yocto/        # → project/.claude/ (symlinked)
    │   ├── BUILD_LOGIC.md
    │   ├── settings.local.json
    │   └── commands/snt-ccu2-yocto/
    └── ccu2-host/
        ├── CLAUDE.md
        ├── settings.local.json
        ├── commands/
        └── skills/

~/.env                      # Credentials (machine-local, NOT in repo)
~/.claude/                  # Global config (untouched)

~/your-project/
├── .env → ~/.env          # Symlink to shared credentials
└── .claude/ → ~/.claude-config/projects/xxx/
```

**Note:** Global `~/.claude/` is NOT modified by this tool.

## Updating

```bash
cd ~/.claude-config && git pull
```

All symlinked configurations update automatically.

## Adding a New Project

1. Create directory:
   ```bash
   mkdir -p ~/.claude-config/projects/my-project/commands
   ```

2. Add files:
   - `CLAUDE.md` - Project knowledge base
   - `settings.local.json` - Permissions and hooks
   - `commands/` - Custom commands

3. Commit and push:
   ```bash
   cd ~/.claude-config
   git add projects/my-project
   git commit -m "Add my-project configuration"
   git push
   ```

4. Use:
   ```bash
   ~/.claude-config/setup-project.sh my-project ~/path/to/project
   ```

## Troubleshooting

### ~/.env not found
```bash
cp ~/.claude-config/.env.template ~/.env
vi ~/.env
```

### Project config not loading
```bash
ls -la ~/your-project/.claude
~/.claude-config/setup-project.sh <project-name> ~/your-project
```

### Update failed
```bash
cd ~/.claude-config
git status
git stash  # if needed
git pull
git stash pop  # if needed
```

## Security

- `~/.env` is **NEVER** committed (contains credentials)
- Only `.env.template` is in the repository
- Each machine maintains its own credentials
