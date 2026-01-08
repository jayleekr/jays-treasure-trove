<!-- Update Check Hook - DO NOT REMOVE -->
```bash
# Auto-check for jays-treasure-trove updates (once per day)
source ~/.claude-config/core/update-check.sh 2>/dev/null || true
```
<!-- End Update Check Hook -->

# Project Instructions

## Language Policy

**All documentation must be written in English.**

This includes:
- Code comments
- Commit messages
- Pull request descriptions
- Technical documentation
- README files

## Available Commands

This project uses centralized Claude configuration from `jays-treasure-trove`.

### Yocto Commands (CCU_GEN2.0_SONATUS)
| Command | Description |
|---------|-------------|
| `/snt-ccu2-yocto:pipeline` | Full pipeline (JIRA → spec → implement → build → test) |
| `/snt-ccu2-yocto:build` | Docker bitbake build |
| `/snt-ccu2-yocto:spec` | Generate specification |
| `/snt-ccu2-yocto:implement` | Implement recipes/configs |
| `/snt-ccu2-yocto:test` | Run test pipeline |
| `/snt-ccu2-yocto:jira` | JIRA integration |

### Host Commands (ccu-2.0)
| Command | Description |
|---------|-------------|
| `/snt-ccu2-host` | Full pipeline (analysis → implement → build → test) |
| `/snt-ccu2-host:build` | Component build |
| `/jira-commit` | JIRA-based commit |
| `/jira-pr` | Create PR with JIRA |
| `/isir` | MISRA/CERT-CPP compliance |
| `/container-test` | Container security test |

### Common Commands
| Command | Description |
|---------|-------------|
| `/build-component` | Build specific component |
| `/deployment-diff` | Compare deployments |

## Skills

| Skill | Description |
|-------|-------------|
| `snt-ccu2-yocto` | Yocto embedded Linux development |
| `snt-ccu2-host` | Host-based CCU2 development |
| `misra-compliance-agent` | MISRA-C 2023 & CERT-CPP compliance |
| `jira-workflow-agent` | JIRA ticket-based development pipeline automation (analyze → implement → build → PR) |

## Configuration

- `.claude/` → Symlink to `~/.claude-config/projects/common/`
- `.env` → Symlink to `~/.env` (credentials)

## Update Configuration

```bash
cd ~/.claude-config && git pull
```
