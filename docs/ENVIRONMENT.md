# jays-treasure-trove - Development Environment and Infrastructure

## Overview

This document describes the complete development infrastructure for all projects managed by jays-treasure-trove, including physical environments, network topology, session type detection, and how Claude Code integrates across different machines.

## Network Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     jays-treasure-trove Infrastructure                      │
│                    (All Projects: CCU_GEN2.0, ccu-2.0, container-manager)   │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                            LOCAL DEVELOPMENT                                  │
└──────────────────────────────────────────────────────────────────────────────┘

         ┌─────────────────────────────────────────┐
         │         jaylee-mac (Local PC)           │
         │                                         │
         │  Session Type: normal (auto-detected)   │
         │  Detection: hostname = "jaylee-mac"     │
         │                                         │
         │  Claude Code Session:                   │
         │  ├─ ~/.claude-config/                   │
         │  │  ├─ core/detect-session.sh ✅       │
         │  │  ├─ core/block-hooks.sh ✅          │
         │  │  └─ core/session-info.sh ✅         │
         │  │                                      │
         │  └─ Projects (symbolic links):          │
         │     ├─ CCU_GEN2.0_SONATUS ⇄ config     │
         │     ├─ ccu-2.0 ⇄ config                │
         │     └─ container-manager ⇄ config      │
         │                                         │
         │  Capabilities:                          │
         │  ✅ Code editing & review               │
         │  ✅ JIRA integration                    │
         │  ✅ Git operations                      │
         │  ✅ Documentation                       │
         │  ❌ Build execution (BLOCKED)           │
         │  ❌ Test execution (BLOCKED)            │
         │                                         │
         │  Physical Connection:                   │
         │  └─ SSH → All builder & tester servers │
         └────────────┬────────────────────────────┘
                      │
                      │ SSH over network
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼

┌──────────────────────────────────────────────────────────────────────────────┐
│                          BUILD INFRASTRUCTURE                                 │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐         ┌─────────────────────────┐
│    builder-kr-4         │         │      builder10          │
│  (Korea Build Server)   │         │  (Alternative Builder)  │
│                         │         │                         │
│  Session: builder       │         │  Session: builder       │
│  Detection: hostname    │         │  Detection: hostname    │
│    matches "^builder"   │         │    matches "^builder"   │
│                         │         │                         │
│  Environment:           │         │  Environment:           │
│  ├─ YOCTO_SDK ✅        │         │  ├─ YOCTO_SDK ✅        │
│  ├─ OECORE_NATIVE ✅    │         │  ├─ OECORE_NATIVE ✅    │
│  ├─ bitbake ✅          │         │  ├─ bitbake ✅          │
│  ├─ gcc/g++/clang ✅    │         │  ├─ gcc/g++/clang ✅    │
│  └─ cmake/make ✅       │         │  └─ cmake/make ✅       │
│                         │         │                         │
│  Projects:              │         │  Projects:              │
│  ├─ CCU_GEN2.0_SONATUS  │         │  ├─ CCU_GEN2.0_SONATUS  │
│  ├─ ccu-2.0             │         │  ├─ ccu-2.0             │
│  └─ container-manager   │         │  └─ container-manager   │
│                         │         │                         │
│  Capabilities:          │         │  Capabilities:          │
│  ✅ Build execution     │         │  ✅ Build execution     │
│  ✅ Test execution      │         │  ✅ Test execution      │
│  ✅ MISRA analysis      │         │  ✅ MISRA analysis      │
│  ✅ All Yocto builds    │         │  ✅ All Yocto builds    │
└─────────────────────────┘         └─────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                          TEST INFRASTRUCTURE                                  │
└──────────────────────────────────────────────────────────────────────────────┘

┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│  ccu2-tester-4     │  │ ccu2-tester-kr-2   │  │  bcu-tester-1      │
│  (CCU2 Test Env)   │  │ (CCU2 Korea Test)  │  │  (BCU Test Env)    │
│                    │  │                    │  │                    │
│  Session: tester   │  │  Session: tester   │  │  Session: tester   │
│  Detection:        │  │  Detection:        │  │  Detection:        │
│    ".*-tester-.*"  │  │    ".*-tester-.*"  │  │    ".*-tester-.*"  │
│                    │  │                    │  │                    │
│  Target: CCU2 ECU  │  │  Target: CCU2 ECU  │  │  Target: BCU ECU   │
│                    │  │                    │  │                    │
│  Environment:      │  │  Environment:      │  │  Environment:      │
│  ├─ pytest ✅      │  │  ├─ pytest ✅      │  │  ├─ pytest ✅      │
│  ├─ gtest ✅       │  │  ├─ gtest ✅       │  │  ├─ gtest ✅       │
│  └─ NO Yocto SDK   │  │  └─ NO Yocto SDK   │  │  └─ NO Yocto SDK   │
│                    │  │                    │  │                    │
│  Capabilities:     │  │  Capabilities:     │  │  Capabilities:     │
│  ✅ Test execution │  │  ✅ Test execution │  │  ✅ Test execution │
│  ❌ Build (BLOCKED)│  │  ❌ Build (BLOCKED)│  │  ❌ Build (BLOCKED)│
└────────────────────┘  └────────────────────┘  └────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                          CI/CD INFRASTRUCTURE                                 │
└──────────────────────────────────────────────────────────────────────────────┘

                     ┌───────────────────────────┐
                     │      Jenkins CI/CD        │
                     │                           │
                     │  Automatic Triggers:      │
                     │  ├─ PR creation           │
                     │  ├─ Branch push           │
                     │  └─ Manual trigger        │
                     │                           │
                     │  Build Pipeline:          │
                     │  ├─ Source checkout       │
                     │  ├─ Multi-tier builds     │
                     │  ├─ MISRA compliance      │
                     │  ├─ Unit tests            │
                     │  ├─ Integration tests     │
                     │  └─ Artifact generation   │
                     │                           │
                     │  Projects:                │
                     │  ├─ CCU_GEN2.0_SONATUS    │
                     │  ├─ ccu-2.0               │
                     │  └─ container-manager     │
                     └───────────────────────────┘
```

## Physical Environment Details

### 1. Local Development Machine (jaylee-mac)

**Type**: Personal workstation / laptop
**Operating System**: macOS (Darwin 24.5.0)
**Hostname**: `jaylee-mac`
**Session Type**: `normal` (auto-detected by hostname)

**Physical Location**: Developer's local workspace

**Network Connectivity**:
- Local network access
- VPN connection to corporate network (if applicable)
- SSH access to all builder and tester servers
- Git repository access (GitHub, GitLab, etc.)
- JIRA API access
- Jenkins dashboard access

**Installed Software**:
- Git
- GitHub CLI (`gh`)
- Claude Code CLI
- jays-treasure-trove configuration system
- Text editors (vim, VS Code, etc.)
- SSH client
- Python (for scripts, not for builds)

**NOT Installed**:
- ❌ Yocto SDK
- ❌ Cross-compilation toolchains
- ❌ bitbake
- ❌ Target hardware test environments

**Session Detection**:
```bash
# Hostname check (PRIMARY detection method)
hostname  # Returns: jaylee-mac
# Matches: Everything else (not builder*, not *-tester-*)
# Result: normal session

# Core detection script path
~/.claude-config/core/detect-session.sh
```

**Claude Code Configuration**:
```bash
~/.claude-config/
├── core/                        # Universal session detection (ALL projects)
│   ├── detect-session.sh        # Hostname-based detection
│   ├── block-hooks.sh           # Build blocking system
│   └── session-info.sh          # Capability display
├── projects/
│   ├── CCU_GEN2.0_SONATUS/     # Project-specific configs
│   ├── ccu-2.0/
│   ├── container-manager/
│   └── common/                  # Fallback configs
└── install.sh                   # Setup script

# Project directories (symbolic links)
~/CodeWorkspace/CCU_GEN2.0_SONATUS/.claude/ → ~/.claude-config/projects/CCU_GEN2.0_SONATUS/
~/CodeWorkspace/ccu-2.0/.claude/ → ~/.claude-config/projects/ccu-2.0/
~/CodeWorkspace/container-manager/.claude/ → ~/.claude-config/projects/container-manager/
```

**Capabilities**:
- ✅ **Code Editing**: Full IDE-like editing across all projects
- ✅ **Git Operations**: Clone, commit, push, PR creation, branch management
- ✅ **JIRA Integration**: Ticket validation, commit messages, PR descriptions
- ✅ **Documentation**: README updates, technical writing, architecture docs
- ✅ **Code Review**: Static analysis, pattern detection, best practices
- ❌ **Build Execution**: BLOCKED (use Jenkins or builder servers)
- ❌ **Test Execution**: BLOCKED (use tester servers or Jenkins)

**Typical Workflow**:
```bash
# On jaylee-mac
cd ~/CodeWorkspace/container-manager
git checkout -b feature/new-feature
vi src/code.cpp                    # Edit code
git add src/
/jira-commit CCU2-12345            # JIRA-aware commit
git push origin feature/new-feature
/jira-pr CCU2-12345                # Create PR with JIRA link

# Jenkins automatically runs builds/tests
# OR SSH to builder for manual verification
```

---

### 2. Builder Servers

#### builder-kr-4 (Primary Korea Builder)

**Type**: Dedicated build server
**Hostname**: `builder-kr-4`
**Session Type**: `builder` (auto-detected by hostname pattern `^builder`)
**Physical Location**: Korea data center

**Hardware Specifications** (typical):
- High-performance CPU (multi-core for parallel builds)
- 32-64GB RAM (Yocto builds are memory-intensive)
- Large SSD storage (500GB - 1TB for build artifacts)
- Network: Gigabit Ethernet

**Operating System**: Linux (likely Ubuntu or CentOS)

**Installed Software**:
- ✅ Yocto SDK (complete toolchain)
- ✅ OECORE_NATIVE_SYSROOT configured
- ✅ bitbake (Yocto build tool)
- ✅ Cross-compilation toolchains (ARM, x86, etc.)
- ✅ gcc, g++, clang (multiple versions)
- ✅ cmake, make, ninja
- ✅ Python 3.x (for build scripts)
- ✅ Git
- ✅ Static analysis tools (MISRA checkers, cppcheck, etc.)

**Environment Variables**:
```bash
YOCTO_SDK=/opt/yocto-sdk
OECORE_NATIVE_SYSROOT=/opt/yocto-sdk/sysroots/x86_64-linux
PATH includes bitbake, cross-compilers
```

**Session Detection**:
```bash
# Hostname check (PRIMARY)
hostname  # Returns: builder-kr-4
# Matches: ^builder
# Result: builder session

# Environment check (FALLBACK)
echo $YOCTO_SDK  # Returns: /opt/yocto-sdk
# Confirms: builder environment
```

**Projects**:
- CCU_GEN2.0_SONATUS (full build support)
- ccu-2.0 (full build support)
- container-manager (full build support)

**Capabilities**:
- ✅ **Build Execution**: All Yocto builds, all tiers, all ECUs
- ✅ **MISRA Analysis**: Static code analysis with fatal rules
- ✅ **Cross-Compilation**: ARM, x86, and other architectures
- ✅ **Test Execution**: Unit tests (limited hardware testing)
- ✅ **Artifact Generation**: Build outputs, images, packages
- ✅ **Code Review**: All development capabilities
- ✅ **Git Operations**: Full git access

**Typical Build Commands**:
```bash
# container-manager project
python3 build.py --tier LGE --ecu CCU2
python3 build.py --tier MOBIS --ecu CCU2_LITE
python3 build.py --misra-check

# CCU_GEN2.0_SONATUS project
./build.sh config1
make all

# ccu-2.0 project
bitbake ccu-image
```

**Access**:
```bash
# From jaylee-mac
ssh builder-kr-4

# Connection details
Host: builder-kr-4.company.com
Port: 22 (SSH)
Authentication: SSH key-based
User: jaylee (or your username)
```

#### builder10 (Alternative Builder)

**Type**: Dedicated build server
**Hostname**: `builder10`
**Session Type**: `builder` (auto-detected)
**Physical Location**: Alternative data center (possibly US/Europe)

**Purpose**:
- Load balancing for parallel builds
- Redundancy when builder-kr-4 is unavailable
- Geographic distribution for faster access

**Specifications**: Similar to builder-kr-4

**Capabilities**: Identical to builder-kr-4

---

### 3. Tester Servers

#### ccu2-tester-4 (CCU2 Primary Test Environment)

**Type**: Dedicated test server with hardware-in-the-loop (HIL) setup
**Hostname**: `ccu2-tester-4`
**Session Type**: `tester` (auto-detected by hostname pattern `.*-tester-.*`)
**Physical Location**: Test lab with CCU2 hardware

**Hardware Configuration**:
- Host PC: Standard Linux server
- Target Hardware: CCU2 ECU connected via debug/test interfaces
- Test Fixtures: May include CAN bus simulators, GPIO controllers, etc.

**Operating System**: Linux (Ubuntu/CentOS)

**Installed Software**:
- ✅ pytest (Python testing framework)
- ✅ gtest (Google Test for C++)
- ✅ Test runners and harnesses
- ✅ Debug tools (gdb, valgrind, etc.)
- ✅ Hardware interface tools (CAN tools, JTAG debuggers)
- ❌ NO Yocto SDK (builds not supported)
- ❌ NO cross-compilation toolchains

**Environment Variables**:
```bash
PYTEST_CURRENT_TEST=...  # May be set during test execution
GTEST_OUTPUT=xml:test_results.xml
TARGET_HARDWARE=CCU2
```

**Session Detection**:
```bash
# Hostname check (PRIMARY)
hostname  # Returns: ccu2-tester-4
# Matches: .*-tester-.*
# Result: tester session
```

**Target Hardware**: CCU2 ECU

**Capabilities**:
- ✅ **Test Execution**: Unit, integration, E2E, hardware-in-loop tests
- ✅ **Hardware Testing**: Real CCU2 ECU validation
- ✅ **Performance Testing**: Real-world performance measurement
- ✅ **Regression Testing**: Automated test suites
- ❌ **Build Execution**: BLOCKED (no compilation tools)
- ✅ **Code Review**: Development capabilities available
- ✅ **Git Operations**: Full git access

**Typical Test Commands**:
```bash
# container-manager project
pytest tests/integration/
./test_runner.sh --target ccu2

# CCU_GEN2.0_SONATUS project
./run_tests.sh --suite integration

# Hardware-specific tests
./hardware_test.sh --ecu ccu2 --can-interface can0
```

**Access**:
```bash
# From jaylee-mac
ssh ccu2-tester-4
```

#### ccu2-tester-kr-2 (CCU2 Korea Test Environment)

**Type**: Dedicated test server (Korea location)
**Hostname**: `ccu2-tester-kr-2`
**Session Type**: `tester`
**Physical Location**: Korea test lab

**Purpose**:
- Geographic redundancy for testing
- Load balancing for parallel test execution
- Local testing for Korea development team

**Target Hardware**: CCU2 ECU

**Capabilities**: Identical to ccu2-tester-4

#### bcu-tester-1 (BCU Test Environment)

**Type**: Dedicated test server for BCU
**Hostname**: `bcu-tester-1`
**Session Type**: `tester`
**Physical Location**: Test lab with BCU hardware

**Target Hardware**: BCU ECU (different from CCU2)

**Capabilities**: Similar to CCU2 testers, specialized for BCU

---

### 4. Jenkins CI/CD Infrastructure

**Type**: Continuous Integration / Continuous Deployment platform
**Software**: Jenkins (open-source automation server)
**Physical Location**: Cloud-hosted or on-premise server

**Purpose**:
- Automated builds on PR creation
- Comprehensive test execution
- Quality gate enforcement
- Build artifact management
- Deployment automation

**Integration Points**:
- **GitHub/GitLab**: Webhook triggers on PR/push
- **JIRA**: Ticket status updates, build result linking
- **Builder Servers**: May delegate builds to builder-kr-4/builder10
- **Tester Servers**: May delegate tests to tester infrastructure

**Build Pipeline Stages**:
1. **Source Checkout**: Clone repository, checkout branch
2. **Build Phase**: Execute builds for all tier/ECU combinations
3. **Static Analysis**: MISRA compliance, code quality checks
4. **Unit Testing**: Run fast unit test suites
5. **Integration Testing**: Run integration test suites
6. **Hardware Testing**: (Optional) Deploy to HIL testers
7. **Artifact Archiving**: Store build outputs, test reports
8. **Notification**: Update GitHub PR status, JIRA tickets

**Projects Supported**:
- CCU_GEN2.0_SONATUS
- ccu-2.0
- container-manager
- (All projects in organization)

**Access**:
- Web dashboard: `https://jenkins.company.com`
- API access for automation
- Integration with Claude Code (view build status)

**Benefits**:
- ✅ Consistent, reproducible builds
- ✅ Automated quality gates
- ✅ Full tier/ECU matrix coverage
- ✅ Historical build data
- ✅ Parallel execution (faster than manual)
- ✅ Build artifact management

---

## Session Type Detection System

### Core Detection Algorithm

**Location**: `~/.claude-config/core/detect-session.sh`

**Priority Hierarchy**:
1. **CLAUDE_SESSION_TYPE environment variable** (manual override) - HIGHEST
2. **Hostname pattern matching** (PRIMARY automatic detection)
3. **Environment variable markers** (YOCTO_SDK, OECORE_NATIVE_SYSROOT)
4. **Tool availability** (bitbake command)
5. **Default to "normal"** (safest, blocks builds/tests) - LOWEST

### Detection Logic

```bash
detect_session_type() {
  # Priority 1: Explicit override (HIGHEST)
  if [[ -n "${CLAUDE_SESSION_TYPE:-}" ]]; then
    echo "$CLAUDE_SESSION_TYPE"
    return 0
  fi

  # Priority 2: Hostname pattern (PRIMARY, most reliable)
  local hostname=$(hostname -s 2>/dev/null || hostname)

  # Builder pattern: builder-kr-*, builder*, *-builder-*
  if [[ "$hostname" =~ ^builder ]] || [[ "$hostname" =~ -builder- ]]; then
    echo "builder"
    return 0
  fi

  # Tester pattern: *-tester-*, ccu2-tester-*, bcu-tester-*
  if [[ "$hostname" =~ -tester- ]]; then
    echo "tester"
    return 0
  fi

  # Priority 3: Build environment markers
  if [[ -n "${YOCTO_SDK:-}" ]] || [[ -n "${OECORE_NATIVE_SYSROOT:-}" ]]; then
    echo "builder"
    return 0
  fi

  # Priority 4: Build tools available
  if command -v bitbake &> /dev/null; then
    echo "builder"
    return 0
  fi

  # Priority 5: Default to normal (safest)
  echo "normal"
  return 0
}
```

### Hostname Pattern Mapping

| Hostname | Pattern Match | Session Type | Example Machines |
|----------|---------------|--------------|------------------|
| `builder-kr-4` | `^builder` | `builder` | builder-kr-4, builder10 |
| `builder10` | `^builder` | `builder` | builder-kr-4, builder10 |
| `ccu2-tester-4` | `.*-tester-.*` | `tester` | ccu2-tester-4, ccu2-tester-kr-2 |
| `ccu2-tester-kr-2` | `.*-tester-.*` | `tester` | ccu2-tester-4, ccu2-tester-kr-2 |
| `bcu-tester-1` | `.*-tester-.*` | `tester` | bcu-tester-1 |
| `jaylee-mac` | None (default) | `normal` | Local PCs, laptops |
| `localhost` | None (default) | `normal` | Local development |

### Manual Override

**Use Case**: Override automatic detection when needed

```bash
# Force builder mode (use cautiously)
export CLAUDE_SESSION_TYPE=builder

# Force tester mode
export CLAUDE_SESSION_TYPE=tester

# Force normal mode (disable all auto-detection)
export CLAUDE_SESSION_TYPE=normal

# Verify current detection
source ~/.claude-config/core/detect-session.sh
detect_session_type
```

**Warning**: Manual override bypasses safety checks. Only use when:
- You have the proper environment (e.g., Yocto SDK for builder mode)
- You understand the implications
- You're testing or debugging the detection system

---

## Build Blocking System

### Core Blocking Script

**Location**: `~/.claude-config/core/block-hooks.sh`

**Purpose**: Prevent build/test execution in non-appropriate sessions

### Blocked Command Patterns

```yaml
core_blocked_patterns:
  build_scripts:
    - build.sh
    - build.py
    - Makefile (when invoked with make)

  build_tools:
    - make
    - cmake
    - ninja
    - gcc (direct invocation)
    - g++ (direct invocation)
    - clang (direct invocation)

  yocto_specific:
    - bitbake
    - yocto-specific commands

  test_tools:
    - pytest
    - gtest
    - ctest
    - test (generic test scripts)

  compilation:
    - compile (generic compilation commands)
```

### Blocking Logic by Session Type

| Session Type | Build Commands | Test Commands | Rationale |
|--------------|----------------|---------------|-----------|
| **normal** | ❌ BLOCKED | ❌ BLOCKED | No build/test environment |
| **tester** | ❌ BLOCKED | ✅ ALLOWED | Test environment, no build tools |
| **builder** | ✅ ALLOWED | ✅ ALLOWED | Full build and test capability |

### Blocking Message

When a blocked command is attempted:

```
🚫 EXECUTION BLOCKED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Command: python3 build.py --tier LGE --ecu CCU2
Session Type: normal

This command is blocked in current session type.

Available options:
  1. Use CI/CD (Jenkins) for builds/tests (RECOMMENDED)
  2. SSH to Builder environment: ssh builder-kr-4
  3. Continue with code review/JIRA integration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Project Integration

### Supported Projects

All projects managed by jays-treasure-trove share the same environment infrastructure:

#### 1. CCU_GEN2.0_SONATUS
- **Type**: Embedded automotive project
- **Build System**: Custom build scripts, Yocto
- **Session Detection**: Uses core detection system
- **Builder Support**: ✅ (builder-kr-4, builder10)
- **Tester Support**: ✅ (project-specific testers)

#### 2. ccu-2.0
- **Type**: Embedded automotive project
- **Build System**: Yocto, bitbake
- **Session Detection**: Uses core detection system
- **Builder Support**: ✅ (builder-kr-4, builder10)
- **Tester Support**: ✅ (ccu2-tester-* servers)

#### 3. container-manager
- **Type**: AUTOSAR Adaptive platform project
- **Build System**: Python-based build.py with Yocto backend
- **Session Detection**: Uses core detection system
- **Builder Support**: ✅ (builder-kr-4, builder10)
- **Tester Support**: ✅ (ccu2-tester-*, bcu-tester-*)
- **JIRA Integration**: CCU2 project (CCU2-XXXXX format)
- **Tiers**: LGE, MOBIS
- **ECUs**: CCU2, CCU2_LITE, BCU

### Universal Features Across All Projects

Thanks to core session detection system at `~/.claude-config/core/`:

- ✅ **Automatic session type detection** (hostname-based)
- ✅ **Build blocking on local machines** (jaylee-mac)
- ✅ **Build allowance on builder servers** (builder-kr-4, builder10)
- ✅ **Test allowance on tester servers** (all *-tester-* machines)
- ✅ **Consistent behavior** across all projects
- ✅ **No project-specific configuration needed** for basic detection

---

## Network Connectivity and Access

### SSH Connections

```bash
# From jaylee-mac to builders
ssh builder-kr-4
ssh builder10

# From jaylee-mac to testers
ssh ccu2-tester-4
ssh ccu2-tester-kr-2
ssh bcu-tester-1

# SSH config example (~/.ssh/config)
Host builder-kr-4
    HostName builder-kr-4.company.com
    User jaylee
    IdentityFile ~/.ssh/id_rsa
    ForwardAgent yes

Host builder10
    HostName builder10.company.com
    User jaylee
    IdentityFile ~/.ssh/id_rsa
    ForwardAgent yes

Host ccu2-tester-4
    HostName ccu2-tester-4.company.com
    User jaylee
    IdentityFile ~/.ssh/id_rsa

Host ccu2-tester-kr-2
    HostName ccu2-tester-kr-2.company.com
    User jaylee
    IdentityFile ~/.ssh/id_rsa

Host bcu-tester-1
    HostName bcu-tester-1.company.com
    User jaylee
    IdentityFile ~/.ssh/id_rsa
```

### Network Security

- **Authentication**: SSH key-based (no passwords)
- **VPN**: May be required for remote access (check with IT)
- **Firewall**: Restricts direct communication between some servers
- **Outbound Access**: Builder/tester servers may have restricted internet access
- **Internal Network**: Servers communicate over corporate internal network

### Git Repository Access

All environments have access to:
- GitHub (or GitLab)
- JIRA API
- Jenkins dashboard
- Artifact repositories

---

## Development Workflows

### Workflow 1: Local Development → Jenkins (Recommended)

**Environments Used**: jaylee-mac (normal) → Jenkins

```bash
# On jaylee-mac (normal session)
cd ~/CodeWorkspace/container-manager
git checkout -b feature/CCU2-12345-new-feature

# Edit code
vi src/container_lifecycle.cpp

# Review changes
git diff

# Commit with JIRA integration
git add src/
/jira-commit CCU2-12345

# Push to remote
git push -u origin feature/CCU2-12345-new-feature

# Create PR
/jira-pr CCU2-12345

# Jenkins automatically:
# - Builds all tier/ECU combinations
# - Runs MISRA compliance
# - Executes tests
# - Posts results to PR and JIRA

# Review Jenkins results and merge
```

**Advantages**:
- ✅ Consistent builds
- ✅ Automated quality gates
- ✅ No manual server access needed
- ✅ Full tier/ECU matrix coverage

### Workflow 2: Local → Builder (Manual Build)

**Environments Used**: jaylee-mac (normal) → builder-kr-4 (builder)

```bash
# On jaylee-mac
cd ~/CodeWorkspace/container-manager
git checkout -b feature/CCU2-12346-experiment
vi src/code.cpp
git commit -am "WIP: Experimental change"

# SSH to builder
ssh builder-kr-4

# On builder-kr-4 (builder session - builds allowed)
cd /path/to/container-manager
git fetch origin
git checkout feature/CCU2-12346-experiment

# Build (Claude Code detects builder session, allows build)
python3 build.py --tier LGE --ecu CCU2

# Test
./build.sh --test

# Exit back to local
exit

# On jaylee-mac - push if successful
git push origin feature/CCU2-12346-experiment
```

**Use Cases**:
- Quick build verification before PR
- Debugging build issues
- Testing experimental changes

### Workflow 3: Local → Tester (Manual Testing)

**Environments Used**: jaylee-mac (normal) → ccu2-tester-4 (tester)

```bash
# Assume binaries are already built (via Jenkins or builder)

# SSH to tester
ssh ccu2-tester-4

# On ccu2-tester-4 (tester session)
cd /path/to/container-manager

# Run tests (Claude Code detects tester session, allows tests)
pytest tests/integration/
./test_runner.sh --target ccu2

# Build is BLOCKED (no build tools)
# python3 build.py --tier LGE  # ❌ EXECUTION BLOCKED

# Review results
cat test_results.log

# Exit
exit
```

**Use Cases**:
- Hardware validation
- Performance testing on real ECU
- Integration testing
- Regression testing

### Workflow 4: Multi-Environment (Complex)

**Environments Used**: jaylee-mac → builder-kr-4 → ccu2-tester-4 → Jenkins

```bash
# 1. Local development (jaylee-mac)
git checkout -b hotfix/critical-issue
vi src/critical_component.cpp

# 2. Quick build check (builder-kr-4)
ssh builder-kr-4
cd /path/to/project
git fetch && git checkout hotfix/critical-issue
python3 build.py --tier LGE --ecu CCU2  # Verify builds
exit

# 3. Hardware validation (ccu2-tester-4)
ssh ccu2-tester-4
cd /path/to/project
# Deploy binary from builder
./test_runner.sh  # Verify fix works
exit

# 4. Final validation via Jenkins (jaylee-mac)
git push origin hotfix/critical-issue
/jira-pr CCU2-99999

# Jenkins runs full validation pipeline
```

**Use Cases**:
- Critical bug fixes
- Complex feature development
- Pre-release validation

---

## Session Capabilities Matrix

| Capability | normal (jaylee-mac) | tester (test servers) | builder (build servers) | Jenkins CI/CD |
|------------|---------------------|----------------------|------------------------|---------------|
| Code Editing | ✅ | ✅ | ✅ | N/A |
| Git Operations | ✅ | ✅ | ✅ | ✅ (automated) |
| JIRA Integration | ✅ | ✅ | ✅ | ✅ (automated) |
| Documentation | ✅ | ✅ | ✅ | N/A |
| Build Execution | ❌ BLOCKED | ❌ BLOCKED | ✅ ALLOWED | ✅ (automated) |
| Test Execution | ❌ BLOCKED | ✅ ALLOWED | ✅ ALLOWED | ✅ (automated) |
| MISRA Analysis | ❌ BLOCKED | ❌ BLOCKED | ✅ ALLOWED | ✅ (automated) |
| Hardware Testing | ❌ | ✅ (HIL) | ⚠️ (limited) | ✅ (via HIL) |
| Cross-Compilation | ❌ | ❌ | ✅ | ✅ |
| Artifact Generation | ❌ | ❌ | ✅ | ✅ |

---

## Troubleshooting

### Issue 1: Session Type Incorrectly Detected

**Symptom**: Wrong session type shown

**Diagnosis**:
```bash
# Check hostname
hostname

# Check detection script
source ~/.claude-config/core/detect-session.sh
detect_session_type

# Show full session info
show_session_info

# Check environment variables
echo $CLAUDE_SESSION_TYPE
echo $YOCTO_SDK
echo $OECORE_NATIVE_SYSROOT
```

**Solutions**:
1. Verify hostname matches expected pattern
2. Check if environment variables are set correctly
3. Manual override: `export CLAUDE_SESSION_TYPE=builder`
4. Reinstall jays-treasure-trove: `cd ~/.claude-config && ./install.sh`

### Issue 2: Cannot Access Builder/Tester Servers

**Symptom**: SSH connection fails

**Diagnosis**:
```bash
# Test SSH connectivity
ssh builder-kr-4 "echo Connection successful"

# Check SSH config
cat ~/.ssh/config | grep -A 5 "builder-kr-4"

# Verify SSH key
ssh-add -l
```

**Solutions**:
1. Ensure VPN is connected (if required)
2. Verify SSH key is added: `ssh-add ~/.ssh/id_rsa`
3. Check firewall rules (contact IT if needed)
4. Verify server is online: `ping builder-kr-4.company.com`

### Issue 3: Build Blocked on Builder Server

**Symptom**: Build commands blocked even on builder-kr-4

**Diagnosis**:
```bash
# On builder-kr-4
hostname  # Should show: builder-kr-4
source ~/.claude-config/core/detect-session.sh
detect_session_type  # Should show: builder

# Check if CLAUDE_SESSION_TYPE is set incorrectly
echo $CLAUDE_SESSION_TYPE
```

**Solutions**:
1. Unset manual override: `unset CLAUDE_SESSION_TYPE`
2. Verify hostname: Should match `^builder` pattern
3. Check core detection scripts are installed on builder server
4. Reinstall jays-treasure-trove on builder server

### Issue 4: Test Blocked on Tester Server

**Symptom**: Test commands blocked on ccu2-tester-4

**Diagnosis**:
```bash
# On ccu2-tester-4
hostname  # Should show: ccu2-tester-4
detect_session_type  # Should show: tester
```

**Solutions**:
1. Verify hostname contains `-tester-`
2. Unset manual override: `unset CLAUDE_SESSION_TYPE`
3. Check core detection scripts are installed

### Issue 5: Jenkins Build Failures

**Symptom**: Jenkins builds failing

**Access Jenkins**:
1. Open Jenkins dashboard
2. Find failing build
3. Review console output
4. Check build logs

**Common Causes**:
- Build tool version mismatch
- Missing dependencies
- Test failures
- MISRA violations
- Environment issues

**Solutions**:
1. Review Jenkins console output for specific errors
2. Reproduce build locally on builder server
3. Check recent code changes for issues
4. Consult Jenkins administrator if infrastructure issue

---

## Best Practices

### 1. Environment Selection

**Local Development (jaylee-mac)**:
- ✅ **DO**: Code editing, git operations, JIRA integration, documentation
- ❌ **DON'T**: Try to build locally (use Jenkins or builder servers)
- ❌ **DON'T**: Try to run tests locally (use tester servers or Jenkins)

**Builder Servers**:
- ✅ **DO**: Manual builds for debugging, MISRA checks, build verification
- ⚠️ **CAUTION**: Limited testing (prefer tester servers for comprehensive tests)
- ℹ️ **USE FOR**: Build-time issues, compilation debugging

**Tester Servers**:
- ✅ **DO**: Hardware testing, integration testing, performance validation
- ❌ **DON'T**: Try to build (use builder servers or Jenkins)
- ℹ️ **USE FOR**: Runtime validation, hardware-in-loop testing

**Jenkins CI/CD**:
- ✅ **DO**: Use for all production builds, automated quality gates
- ✅ **DO**: Trust Jenkins for tier/ECU matrix validation
- ℹ️ **PREFER**: Jenkins over manual builds for all PR code

### 2. Security

**SSH Keys**:
- Use separate keys for different environments
- Rotate keys regularly
- Never commit private keys to repositories
- Use `ssh-agent` for key management

**Environment Variables**:
- Keep `~/.env` secure (contains JIRA tokens)
- Never commit `.env` to version control
- Use environment-specific credentials

**Session Type Awareness**:
- Verify session type before sensitive operations
- Use manual override cautiously
- Understand implications of overriding detection

### 3. Performance

**Network**:
- Use SSH connection multiplexing
- Consider `tmux` or `screen` for long-running remote processes
- Keep builds on servers, not local machine

**Builds**:
- Prefer Jenkins for parallel builds
- Cache Yocto builds on builder servers
- Use incremental builds when possible

**Tests**:
- Run targeted tests during development
- Save comprehensive test suites for Jenkins
- Use tester servers for hardware-dependent tests only

---

## Quick Reference

### Session Type Determination

```bash
# Check current session
hostname
source ~/.claude-config/core/detect-session.sh
detect_session_type
show_session_info
```

### SSH Quick Access

```bash
# Builders
ssh builder-kr-4
ssh builder10

# Testers
ssh ccu2-tester-4
ssh ccu2-tester-kr-2
ssh bcu-tester-1
```

### Manual Session Override

```bash
# Force builder mode
export CLAUDE_SESSION_TYPE=builder

# Force tester mode
export CLAUDE_SESSION_TYPE=tester

# Force normal mode
export CLAUDE_SESSION_TYPE=normal

# Unset override
unset CLAUDE_SESSION_TYPE
```

### Verify Installation

```bash
# Check jays-treasure-trove installation
ls -la ~/.claude-config/core/

# Verify core detection scripts
source ~/.claude-config/core/detect-session.sh
source ~/.claude-config/core/session-info.sh

# Show current session info
show_session_info
```

---

## Summary

The jays-treasure-trove infrastructure provides:

1. **Universal Session Detection**: Hostname-based detection works across all projects
2. **Safety First**: Blocks builds/tests on inappropriate machines (jaylee-mac)
3. **Flexibility**: Manual override when needed, SSH access to all environments
4. **Consistency**: Same detection system for CCU_GEN2.0_SONATUS, ccu-2.0, container-manager
5. **Automation**: Jenkins CI/CD for production-grade builds and tests
6. **Security**: SSH key-based authentication, environment-specific credentials
7. **Efficiency**: Right tool for right task (local dev, builder, tester, Jenkins)

All projects benefit from this shared infrastructure without project-specific configuration!
