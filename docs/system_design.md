# System Design: Centralized Claude Configuration

## Overview

**Goal**: Centralize Claude Code configurations with unified config and auto-detection.

**Design Principles**:
- Single unified `common` config for all projects
- Auto-detection of project type from directory path
- Project-specific behavior handled by skills/commands internally
- `~/.claude/` global config remains untouched

---

## Architecture

```
[Per Machine - One-time Setup]
~/.env                              ← Manual (JIRA, API keys)
~/.claude-config/                   ← jays-treasure-trove clone
~/.claude/                          ← Untouched (global SuperClaude)

[Per Project - Automatic via install.sh]
~/CCU_GEN2.0_SONATUS.manifest/
├── .env → ~/.env
└── .claude/ → ~/.claude-config/projects/common/

~/ccu-2.0/
├── .env → ~/.env
└── .claude/ → ~/.claude-config/projects/common/
```

---

## Repository Structure

```
jays-treasure-trove/
├── README.md
├── install.sh              # Auto-detect installer
├── .gitignore
├── .env.template
├── docs/
│   └── system_design.md
│
└── projects/
    └── common/             # Unified config
        ├── settings.local.json
        ├── commands/
        │   ├── snt-ccu2-yocto/
        │   ├── snt-ccu2-host/
        │   └── *.md
        └── skills/
            ├── misra-compliance-agent/
            └── snt-ccu2-host/
```

---

## Auto-Detection

### Project Detection (install.sh)

```bash
detect_project_root() {
    # CCU_GEN2.0_SONATUS → matches *CCU_GEN2.0_SONATUS*
    # ccu-2.0 → matches *ccu-2.0* or *ccu2.0*
    # Returns: project root path
}
```

### Conditional Hooks (settings.local.json)

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "command": "if [ -f \"$CLAUDE_PROJECT_DIR/build.py\" ]; then cd ... && python build.py -fac; fi"
      }]
    }]
  }
}
```

Hook only runs if `build.py` exists (ccu-2.0), skipped for Yocto projects.

---

## Workflow

### New Machine Setup

```bash
# 1. Clone project
git clone <project-repo> ~/project
cd ~/project

# 2. Install (one-liner)
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install.sh | bash

# 3. Create credentials
cp ~/.claude-config/.env.template ~/.env
vi ~/.env
```

### Update Config

```bash
cd ~/.claude-config && git pull
```

---

## Security

- `~/.env` is **NEVER** committed
- Only `.env.template` in repository
- Each machine maintains own credentials

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-06 | 1.2.0 | Simplified to single install.sh |
| 2026-01-06 | 1.1.0 | Unified config with auto-detection |
| 2026-01-06 | 1.0.0 | Initial design |
