# Container Manager - Claude Code Setup

## Prerequisites
- jays-treasure-trove installed at ~/.claude-config
- JIRA access token (if using JIRA integration)
- Git and GitHub CLI (`gh`) configured

## Initial Setup

### 1. Install jays-treasure-trove
```bash
cd ~
git clone https://github.com/jayleekr/jays-treasure-trove.git .claude-config
```

### 2. Configure Environment
```bash
# Copy template
cp ~/.claude-config/.env.template ~/.env

# Edit with your credentials
vi ~/.env
```

Required environment variables:
```bash
# JIRA Integration
JIRA_URL=https://jira.your-company.com
JIRA_TOKEN=your_api_token_here

# Optional: Manual session type override
# CLAUDE_SESSION_TYPE=builder|tester|normal
```

### 3. Run Installation
```bash
cd /path/to/container-manager
bash ~/.claude-config/install.sh
```

This will:
- Detect your session type (Builder/Tester/Normal)
- Show session capabilities
- Create symbolic links:
  - `.env` → `~/.env`
  - `.claude/` → `~/.claude-config/projects/container-manager/`

## Session Type Detection

Session type is auto-detected by hostname:

| Hostname Pattern | Session Type | Build | Test | Code Review |
|-----------------|--------------|-------|------|-------------|
| `builder-kr-4`, `builder10` | Builder | ✅ | ✅ | ✅ |
| `ccu2-tester-*`, `bcu-tester-*` | Tester | ❌ | ✅ | ✅ |
| `jaylee-mac` (local) | Normal | ❌ | ❌ | ✅ |

### Current Session
Your current session: **jaylee-mac** (Normal)
- Build execution: **BLOCKED**
- Test execution: **BLOCKED**
- Code review: **ENABLED**
- JIRA integration: **ENABLED**

### Manual Override
If you need to override detection:
```bash
export CLAUDE_SESSION_TYPE=builder  # Enable build/test
export CLAUDE_SESSION_TYPE=normal   # Disable build/test
```

## Available Commands

### JIRA Integration
- `/jira-commit <CCU2-XXXXX>` - Create JIRA-aware commit ✅
- `/jira-pr <CCU2-XXXXX>` - Create JIRA-aware pull request ✅

### Build Information (Execution Blocked)
- `/yocto [tier] [ecu]` - Show build info ⚠️ (info only)
- `/misra [options]` - Show MISRA config ⚠️ (info only)

Note: Build and test execution are blocked in this session. Use Jenkins CI/CD or switch to Builder environment.

## Configuration Files

### Project Configuration
Location: `~/.claude-config/projects/container-manager/settings.local.json`

Key settings:
```json
{
  "session_detection": {
    "enabled": true,
    "use_core_detection": true
  },
  "integrations": {
    "jira": {
      "enabled": true,
      "project_key": "CCU2"
    }
  },
  "auto_hooks": {
    "auto_detect_and_block": true
  }
}
```

### Core Detection Scripts
Location: `~/.claude-config/core/`
- `detect-session.sh`: Universal session type detection
- `block-hooks.sh`: Hook blocking system
- `session-info.sh`: Capability display

## Verification

### Check Installation
```bash
# Verify symbolic links
ls -la /path/to/container-manager/.env
ls -la /path/to/container-manager/.claude

# Check session type
source ~/.claude-config/core/detect-session.sh
detect_session_type
```

### Test JIRA Integration
```bash
# Test ticket validation (requires ~/.env with JIRA credentials)
source ~/.claude-config/projects/container-manager/scripts/jira-integration.sh
validate_ticket CCU2-12345
```

## Troubleshooting

### Session Type Issues
**Problem**: Wrong session type detected
**Solution**:
```bash
# Check current detection
source ~/.claude-config/core/session-info.sh
show_session_info

# Manual override
export CLAUDE_SESSION_TYPE=builder
```

### JIRA Integration Issues
**Problem**: JIRA commands fail
**Solution**:
1. Verify `~/.env` exists and has `JIRA_URL` and `JIRA_TOKEN`
2. Test JIRA connectivity:
   ```bash
   curl -H "Authorization: Bearer $JIRA_TOKEN" \
     "${JIRA_URL}/rest/api/2/myself"
   ```

### Symbolic Link Issues
**Problem**: Symbolic links not created
**Solution**:
```bash
cd /path/to/container-manager
bash ~/.claude-config/install.sh
```

## Next Steps
- Review [WORKFLOW.md](./WORKFLOW.md) for development workflow
- Configure JIRA credentials in `~/.env`
- Test commands with your workflow
