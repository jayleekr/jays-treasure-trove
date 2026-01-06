# Jay's Treasure Trove

Centralized Claude Code configuration with auto-detection.

## Quick Start

```bash
# 1. Go to your project directory
cd ~/CCU_GEN2.0_SONATUS.manifest  # or ~/ccu-2.0

# 2. Install and configure (one-liner)
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install.sh | bash

# 3. Set up credentials (once per machine)
cp ~/.claude-config/.env.template ~/.env
vi ~/.env  # Add your credentials
```

That's it! The installer will:
- Clone this repo to `~/.claude-config`
- Auto-detect your project
- Create symlinks for `.claude/` and `.env`

## Supported Projects

| Project | Path Pattern |
|---------|--------------|
| CCU_GEN2.0_SONATUS.manifest | `*CCU_GEN2.0_SONATUS*` |
| ccu-2.0 | `*ccu-2.0*` or `*ccu2.0*` |

## Features

- **Yocto commands** (`snt-ccu2-yocto/`) - build, pipeline, spec, implement, jira, test
- **Host commands** (`snt-ccu2-host/`) - build, scripts
- **JIRA integration** - jira-commit, jira-pr
- **MISRA compliance** - isir command, misra-compliance-agent skill
- **Auto-build hooks** - Runs `build.py` on Edit/Write if available

## Directory Structure

```
~/.claude-config/           # This repo
├── .env.template           # Credentials template
├── install.sh              # Auto-detect installer
└── projects/common/        # Unified config
    ├── settings.local.json
    ├── commands/
    └── skills/

~/.env                      # Credentials (NOT in repo)
~/.claude/                  # Global config (untouched)

~/your-project/
├── .env → ~/.env
└── .claude/ → ~/.claude-config/projects/common/
```

## Updating

```bash
cd ~/.claude-config && git pull
```

## Troubleshooting

### ~/.env not found
```bash
cp ~/.claude-config/.env.template ~/.env
vi ~/.env
```

### Re-run setup
```bash
cd ~/your-project
bash ~/.claude-config/install.sh
```

## Security

- `~/.env` is **NEVER** committed
- Each machine maintains its own credentials
