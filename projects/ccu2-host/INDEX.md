# CCU-2.0 Claude Code - Complete Index

Quick navigation for all Claude Code configuration files.

## 📚 Documentation

| File | Purpose | For |
|------|---------|-----|
| **QUICKSTART.md** | ⚡ Fast start guide | New users |
| **README.md** | 📖 Complete overview | Everyone |
| **SETUP.md** | 🔧 Installation guide | First-time setup |
| **SKILLS.md** | 🤖 Autonomous agents | Advanced automation |
| **COMMANDS_VS_SKILLS.md** | 🤔 Decision guide | Choosing tools |
| **CLAUDE.md** | 🧠 Knowledge base | Deep reference |

---

## 🎯 Quick Links by Need

### I want to...

**Get started quickly**
→ [QUICKSTART.md](QUICKSTART.md)

**Understand commands vs skills**
→ [COMMANDS_VS_SKILLS.md](COMMANDS_VS_SKILLS.md)

**Set up configuration**
→ [SETUP.md](SETUP.md)

**Use autonomous workflows**
→ [SKILLS.md](SKILLS.md)

**Learn about the project**
→ [CLAUDE.md](CLAUDE.md)

**See all features**
→ [README.md](README.md)

---

## 🎯 Available Slash Commands

### Analysis & Navigation
- `/component` - Analyze component structure
- `/deployment-diff` - Compare deployment configs

### Build & Test
- `/build-component` - Smart component building
- `/container-test` - Container security testing
- `/syscall-test` - Syscall test diagnostics

### Compliance & Quality
- `/isir` - MISRA-C/CERT-CPP compliance workflow

### Git Integration
- `/jira-commit` - JIRA-formatted commits

**Location**: `.claude/commands/`
**Documentation**: Each command has detailed `.md` file

---

## 🤖 Available Skills

### 🔍 Analysis
- `analyze-component` - Deep architecture analysis
- `analyze-seccomp` - Seccomp profile validation
- `misra-compliance-agent` - Autonomous MISRA-C/CERT-CPP compliance

### 🔨 Build & Test
- `smart-build` - Intelligent incremental builds
- `container-security-test` - Automated security testing

### 🐛 Debug
- `syscall-debugger` - Syscall testing & fixes
- `dlt-log-analyzer` - DLT log analysis

### 📝 Documentation
- `auto-documenter` - Auto-generate docs

### 🔄 Git & CI
- `smart-commit` - Intelligent commits with JIRA
- `pr-assistant` - PR creation helper

### 🔐 Security
- `security-audit` - Security scanning

**Location**: Documented in `SKILLS.md`
**Status**: Specification (implementation upcoming)

---

## 📁 File Structure

```
.claude/
├── INDEX.md                   # 📍 This file - Navigation hub
├── QUICKSTART.md              # ⚡ Quick start (5 min)
├── README.md                  # 📖 Overview (15 min)
├── SETUP.md                   # 🔧 Setup guide (10 min)
├── SKILLS.md                  # 🤖 Skills reference
├── COMMANDS_VS_SKILLS.md      # 🤔 Decision guide
├── CLAUDE.md                  # 🧠 Knowledge base
├── .gitignore                 # 🔒 Ignore rules
├── settings.local.json        # ⚙️ Personal config
└── commands/                  # 📂 Slash commands
    ├── component.md
    ├── build-component.md
    ├── container-test.md
    ├── jira-commit.md
    ├── syscall-test.md
    └── deployment-diff.md
```

---

## 🚀 Getting Started Path

### New to CCU-2.0?
1. Read [QUICKSTART.md](QUICKSTART.md) (5 min)
2. Try `/component container-manager`
3. Read [CLAUDE.md](CLAUDE.md) for project knowledge

### New to Claude Code?
1. Read [COMMANDS_VS_SKILLS.md](COMMANDS_VS_SKILLS.md)
2. Try some slash commands
3. Read [SKILLS.md](SKILLS.md) for advanced features

### Setting up for team?
1. Read [SETUP.md](SETUP.md)
2. Review [README.md](README.md)
3. Commit to `jay-claude` branch

---

## 📊 Feature Matrix

| Feature | Commands | Skills | Docs |
|---------|----------|--------|------|
| **Component Analysis** | `/component` | `analyze-component` | ✅ |
| **Building** | `/build-component` | `smart-build` | ✅ |
| **Testing** | `/container-test` | `container-security-test` | ✅ |
| **MISRA Compliance** | `/isir` | `misra-compliance-agent` | ✅ |
| **Git Commits** | `/jira-commit` | `smart-commit` | ✅ |
| **Syscall Debug** | `/syscall-test` | `syscall-debugger` | ✅ |
| **Deployment Compare** | `/deployment-diff` | - | ✅ |
| **DLT Logs** | - | `dlt-log-analyzer` | ✅ |
| **Security Audit** | - | `security-audit` | ✅ |
| **Documentation** | - | `auto-documenter` | ✅ |
| **PR Creation** | - | `pr-assistant` | ✅ |

---

## 🎓 Learning Paths

### Path 1: Daily Developer
```
QUICKSTART.md → Try commands → Use daily
```

### Path 2: Automation Engineer
```
README.md → SKILLS.md → Implement skills → CI/CD
```

### Path 3: Team Lead
```
SETUP.md → CLAUDE.md → Customize → Share with team
```

### Path 4: New Team Member
```
QUICKSTART.md → CLAUDE.md → Practice commands → Productive!
```

---

## 🔗 External Resources

- **Claude Code Docs**: https://docs.claude.com/en/docs/claude-code
- **Anthropic Skills**: https://www.anthropic.com/news/skills
- **CCU-2.0 Wiki**: https://sonatus.atlassian.net/wiki/spaces/CCU2/
- **Build Guide**: https://sonatus.atlassian.net/wiki/spaces/CCU2/pages/1686732801/

---

## 📝 Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│ CCU-2.0 Claude Code Quick Reference             │
├─────────────────────────────────────────────────┤
│ LEARN:                                          │
│  /component [name]     - Analyze component      │
│  /syscall-test [file]  - Understand syscalls    │
│                                                 │
│ BUILD:                                          │
│  /build-component      - Build with defaults    │
│  skill smart-build     - Intelligent building   │
│                                                 │
│ TEST:                                           │
│  /container-test       - Run security tests     │
│  skill container-security-test - Automated      │
│                                                 │
│ COMMIT:                                         │
│  /jira-commit CCU2-123 - Manual commit          │
│  skill smart-commit    - Auto-generated         │
│                                                 │
│ HELP:                                           │
│  cat .claude/INDEX.md  - This reference         │
│  cat .claude/QUICKSTART.md - Quick start        │
└─────────────────────────────────────────────────┘
```

---

## 💡 Tips

1. **Start simple**: Use commands first, skills when ready
2. **Read examples**: Each doc has practical examples
3. **Customize**: Edit `.claude/settings.local.json`
4. **Share**: Commit to `jay-claude` branch
5. **Improve**: Add your own commands/skills!

---

**Last updated**: 2025-10-21
**Maintained on**: `jay-claude` branch
**Questions?**: Check [README.md](README.md) or [QUICKSTART.md](QUICKSTART.md)
