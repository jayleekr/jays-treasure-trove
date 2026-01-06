# Quick Start - CCU-2.0 Claude Commands

## 🚀 Instant Usage

Already in the repo? Commands are **ready to use**!

```bash
cd /home/jay.lee/ccu-2.0

# Try a command
/component container-manager
```

## 📋 Available Commands

### Development
```bash
/component [name]              # Analyze component structure
/build-component [name]        # Build with smart defaults
```

### Testing
```bash
/container-test [case]         # Run container security tests
/syscall-test [file]          # Analyze syscall testing issues
/deployment-diff [a] [b]       # Compare deployment configs
```

### Git Integration
```bash
/jira-commit [ticket] [msg]    # Create JIRA-formatted commit
```

## 💡 Quick Examples

### Analyze Current Component
```bash
cd /home/jay.lee/ccu-2.0/vam
/component  # Auto-detects 'vam'
```

### Build and Test
```bash
/build-component container-manager --type Debug
/container-test C11584
```

### Fix Syscall Test
```bash
/syscall-test container-app/src/demo/main.cxx --fix
```

### Create Commit
```bash
# Stage your changes first
git add .

# Create formatted commit
/jira-commit CCU2-15604 "Remove Adaptive AUTOSAR dependency"
```

### Compare Seccomp Policies
```bash
cd container-manager/test_config/deploy
/deployment-diff default_deploy.json C11584_setsid_not_restricted_diff.json
```

## 📚 Learn More

- `SETUP.md` - Installation and configuration
- `README.md` - Full documentation
- `CLAUDE.md` - Project knowledge base

## 🔧 Customization

Personal settings (not committed):
```bash
# Edit personal preferences
nano .claude/settings.local.json
```

## 🤝 Sharing

On `jay-claude` branch - ready to share with team:
```bash
git checkout jay-claude
git push origin jay-claude
```

## ❓ Help

Each command shows help:
```bash
/component --help
/build-component --help
```

Or check the full docs:
```bash
cat .claude/commands/component.md
```
