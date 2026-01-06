# System Design: Centralized Claude Configuration Management

## Overview

**Goal**: Centralize all Claude Code configurations (project-specific) through the `jays-treasure-trove` repository for consistent development environments across multiple machines.

**Deployment Method**: Symlink-based
**Security**: `~/.env` is manually managed per machine; only templates are stored in the repository

---

## Architecture

```
[Per Machine - One-time Setup]
~/.env                              ← Manual creation (JIRA, API keys, etc.)
~/.claude-config/                   ← jays-treasure-trove clone location
~/.claude/                          ← Remains untouched (global SuperClaude framework)

[Per Project - Automatic via setup.sh]
~/CCU_GEN2.0_SONATUS.manifest/
├── .env → ~/.env                   ← Symlink (shared credentials)
└── .claude/ → ~/.claude-config/projects/ccu2-yocto/

~/ccu-2.0/
├── .env → ~/.env                   ← Symlink
└── .claude/ → ~/.claude-config/projects/ccu2-host/
```

**Key Principle**: Global `~/.claude/` is NOT modified. Only project-specific `.claude/` directories are symlinked.

---

## Repository Structure

```
jays-treasure-trove/
├── README.md                     # User documentation
├── install.sh                    # Initial installation (repo clone + env template)
├── setup-project.sh              # Per-project setup (.env + .claude symlinks)
├── .gitignore                    # Exclude sensitive/machine-local files
├── .env.template                 # Template for ~/.env creation
├── docs/
│   └── system_design.md          # This document
│
└── projects/
    ├── ccu2-yocto/               # → CCU_GEN2.0_SONATUS.manifest/.claude/
    │   ├── BUILD_LOGIC.md        # Yocto build system documentation
    │   ├── settings.local.json   # Permissions configuration
    │   └── commands/
    │       └── snt-ccu2-yocto/   # Custom Yocto commands
    │           ├── build.md
    │           ├── implement.md
    │           ├── jira.md
    │           ├── pipeline.md
    │           ├── spec.md
    │           ├── test.md
    │           └── scripts/
    │               ├── common.sh
    │               ├── yocto-build.sh
    │               └── yocto-test.sh
    │
    └── ccu2-host/                # → ccu-2.0/.claude/
        ├── CLAUDE.md             # Project knowledge base
        ├── README.md
        ├── SETUP.md
        ├── QUICKSTART.md
        ├── INDEX.md
        ├── SKILLS.md
        ├── COMMANDS_VS_SKILLS.md
        ├── ISIR_METHODOLOGY.md
        ├── settings.local.json   # Hooks configuration (auto-build)
        ├── commands/
        │   ├── build-component.md
        │   ├── component.md
        │   ├── container-test.md
        │   ├── deployment-diff.md
        │   ├── isir.md
        │   ├── jira-commit.md
        │   ├── jira-pr.md
        │   ├── snt-ccu2-host.md
        │   ├── syscall-test.md
        │   └── snt-ccu2-host/
        │       ├── build.md
        │       └── scripts/
        │           └── host-build.sh
        └── skills/
            ├── misra-compliance-agent/
            │   ├── SKILL.md
            │   └── references/
            └── snt-ccu2-host/
                ├── SKILL.md
                └── references/
```

---

## Symlink Architecture

### Project-Specific Symlinks Only

```
~/CCU_GEN2.0_SONATUS.manifest/
├── .env → ~/.env
└── .claude/ → ~/.claude-config/projects/ccu2-yocto/

~/ccu-2.0/
├── .env → ~/.env
└── .claude/ → ~/.claude-config/projects/ccu2-host/
```

### What Gets Symlinked

| Source | Target | Purpose |
|--------|--------|---------|
| `~/.env` | `<project>/.env` | Shared credentials across all projects |
| `~/.claude-config/projects/<name>/` | `<project>/.claude/` | Project-specific Claude configuration |

### What Remains Local (NOT symlinked)

| Location | Content | Reason |
|----------|---------|--------|
| `~/.claude/` | Global SuperClaude framework | Shared globally, managed separately |
| `~/.env` | Credentials (JIRA, API keys) | Security - never committed |
| `~/.claude/todos/` | Task tracking | Machine-specific state |
| `~/.claude/history.jsonl` | Conversation history | Machine-specific |
| `~/.claude/debug/` | Debug logs | Machine-specific |

---

## Security Design

### Credential Management

```
┌─────────────────────────────────────────────────────────────┐
│                    NEVER IN REPOSITORY                       │
├─────────────────────────────────────────────────────────────┤
│  ~/.env                                                      │
│  ├── JIRA_BASE_URL=https://sonatus.atlassian.net/           │
│  ├── JIRA_EMAIL=user@sonatus.com                            │
│  └── JIRA_API_TOKEN=<actual-token>                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ symlink
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ~/project/.env → ~/.env                                     │
│  (Projects access credentials via symlink)                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    IN REPOSITORY (safe)                      │
├─────────────────────────────────────────────────────────────┤
│  .env.template                                               │
│  ├── JIRA_BASE_URL=https://your-company.atlassian.net/      │
│  ├── JIRA_EMAIL=your-email@company.com                      │
│  └── JIRA_API_TOKEN=your-jira-api-token                     │
└─────────────────────────────────────────────────────────────┘
```

### .gitignore Protection

```gitignore
# Credentials (NEVER commit)
.env
!.env.template
.credentials.json
**/credentials*.json
**/*secret*
**/*token*
```

---

## Script Design

### install.sh

**Purpose**: Initial installation on a new machine

**Flow**:
```
1. Check prerequisites (git)
2. Clone/update repo to ~/.claude-config
3. Check if ~/.env exists
   ├── Yes → Continue
   └── No  → Show template instructions
4. Print available projects
5. Show usage instructions
```

**One-liner**:
```bash
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install.sh | bash
```

### setup-project.sh

**Purpose**: Configure a specific project after cloning

**Flow**:
```
1. Parse arguments (project-name, target-path)
2. Ensure jays-treasure-trove is installed
   └── Auto-install if missing
3. Verify project exists in projects/
4. Verify target directory exists
5. Check ~/.env exists
   └── Exit with error if missing
6. Backup existing .claude/ if not symlink
7. Create symlinks:
   ├── .env → ~/.env
   └── .claude/ → ~/.claude-config/projects/<name>/
8. Print success message
```

**One-liner**:
```bash
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/setup-project.sh | bash -s -- ccu2-yocto ~/CCU_GEN2.0_SONATUS.manifest
```

---

## Project Configuration Details

### ccu2-yocto (CCU_GEN2.0_SONATUS.manifest)

**Purpose**: Yocto/Bitbake embedded Linux build system

**settings.local.json**:
```json
{
  "permissions": {
    "allow": ["Bash(rm:*)", "Bash(grep:*)"],
    "deny": []
  }
}
```

**Commands**:
| Command | Description |
|---------|-------------|
| `build` | Yocto build orchestration |
| `implement` | Implementation workflow |
| `jira` | JIRA integration |
| `pipeline` | Full development pipeline |
| `spec` | Specification generation |
| `test` | Test execution pipeline |

### ccu2-host (ccu-2.0)

**Purpose**: Host-based CCU2 development with JIRA and MISRA integration

**settings.local.json**:
```json
{
  "permissions": {
    "allow": ["Bash(find:*)"],
    "deny": []
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && python build.py -fac 2>/dev/null || true",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

**Commands**:
| Command | Description |
|---------|-------------|
| `build-component` | Component-specific build |
| `container-test` | Container test execution |
| `isir` | MISRA/CERT-CPP compliance |
| `jira-commit` | JIRA-based commits |
| `jira-pr` | JIRA PR integration |
| `snt-ccu2-host` | Full pipeline |

**Skills**:
| Skill | Description |
|-------|-------------|
| `misra-compliance-agent` | MISRA-C 2023 & CERT-CPP violation management |
| `snt-ccu2-host` | Full CCU-2.0 host pipeline |

---

## Workflow Summary

### New Machine Setup

```bash
# 1. Install jays-treasure-trove
curl -fsSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install.sh | bash

# 2. Create credentials (once per machine)
cp ~/.claude-config/.env.template ~/.env
vi ~/.env  # Add actual credentials

# 3. Clone and configure project
git clone <project-repo> ~/project
curl -fsSL .../setup-project.sh | bash -s -- <project-name> ~/project
```

### Updating Configurations

```bash
# All machines
cd ~/.claude-config && git pull

# Symlinks automatically reflect updates
```

### Adding a New Project

```bash
# 1. Create project directory
mkdir -p ~/.claude-config/projects/new-project/commands

# 2. Add configuration files
# - CLAUDE.md (project knowledge base)
# - settings.local.json (permissions, hooks)
# - commands/ (custom commands)

# 3. Commit and push
cd ~/.claude-config
git add projects/new-project
git commit -m "Add new-project configuration"
git push

# 4. Use on any machine
~/.claude-config/setup-project.sh new-project ~/path/to/project
```

---

## Benefits

1. **Single Source of Truth**: All project configurations in one repository
2. **No Project Repo Modifications**: Projects remain clean; configs are symlinked
3. **One-liner Setup**: Quick setup from anywhere via curl
4. **Automatic Updates**: `git pull` updates all symlinked configurations
5. **Secure Credentials**: Never committed; per-machine management
6. **Global Config Preservation**: `~/.claude/` remains untouched

---

## Limitations & Considerations

1. **Requires Git Access**: SSH or HTTPS access to GitHub required
2. **Manual Credential Setup**: `~/.env` must be created manually on each machine
3. **Symlink Dependency**: If repo is moved/deleted, symlinks break
4. **No Offline Initial Setup**: First installation requires network access

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-06 | 1.0.0 | Initial design and implementation |
