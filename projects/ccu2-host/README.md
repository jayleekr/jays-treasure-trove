# CCU-2.0 Claude Code Configuration

Project-specific Claude Code commands and knowledge base for CCU-2.0 automotive embedded system development.

## Files Created

### Knowledge Base
- **CLAUDE.md** - Comprehensive project knowledge:
  - Repository structure and components
  - Build system (build.py, CMake)
  - Commit conventions and JIRA integration
  - Common workflows and pain points
  - Technical stack and terminology
  - Security patterns (seccomp, container isolation)

### Custom Commands

#### 1. `/component` - Component Analysis
Analyze CCU-2.0 component structure, dependencies, and recent changes.
- Component overview and purpose
- Directory structure
- Dependencies (internal/external)
- Recent commits and branches
- Test information

#### 2. `/build-component` - Smart Component Build
Build specific components with intelligent defaults.
- Auto-detect component from directory
- Pre-build dependency checks
- Execute build.py with smart flags
- Post-build artifact reporting

#### 3. `/container-test` - Container Security Testing
Run and debug container security tests with deployment analysis.
- Test discovery and execution
- Deployment JSON parsing
- Seccomp profile analysis
- Debug support with DLT logs
- Common issue detection (PID 1, errno)

#### 4. `/jira-commit` - JIRA-Formatted Commits
Create properly formatted commits with JIRA ticket integration.
- Ticket validation (CCU2-*, SEB-*, CRM-*)
- Auto-generated descriptions from changes
- Proper formatting: `[TICKET-ID] Description (#PR)`
- Component tagging for multi-component changes

#### 5. `/syscall-test` - Syscall Test Analysis
Diagnose and fix syscall testing issues in containers.
- PID 1 session leader detection
- errno interpretation (EPERM vs EACCES)
- Fork-based testing recommendations
- Seccomp masking identification
- Fix templates and validation

#### 6. `/deployment-diff` - Deployment Comparison
Compare container deployment configurations and security policies.
- Seccomp profile differences
- Container config changes
- Security impact analysis
- Test behavior prediction
- Policy visualization

## Key Insights Captured

### Container Security Testing
- **PID 1 Issue**: Session leader always returns EPERM for setsid()
- **Solution**: Fork child process for clean testing context
- **errno Meanings**:
  - EACCES = Seccomp blocked syscall
  - EPERM = Process state issue (session leader)

### Kernel Syscall Check Order
1. Seccomp filter (returns EACCES if blocked)
2. Syscall-specific logic (returns EPERM for invalid state)
3. Execution (if checks pass)

### Build System
- Primary: `build.py` (Python orchestrator)
- CMake hierarchy for multi-component builds
- Docker containerization via `run-dev-container.sh`

### Commit Conventions
```
[CCU2-15604] Remove Adaptive AUTOSAR dependency (#621)
[SEB-1294] Add CRM project to PR title check (#620)
[CRM-9] Service Interface integration (#621)
```

## Usage

These commands and knowledge are automatically loaded when working in the CCU-2.0 repository.

### Quick Start
```bash
cd /home/jay.lee/ccu-2.0
# Commands are now available as /component, /build-component, etc.
```

### Example Workflows

**Analyze a component:**
```
/component container-manager
```

**Build and test:**
```
/build-component vam --type Debug --tests
/container-test C11584
```

**Fix syscall test:**
```
/syscall-test container-app/src/demo/main.cxx --fix
```

**Create commit:**
```
/jira-commit CCU2-17261 "Remove ECC version handling"
```

**Compare deployments:**
```
/deployment-diff default_deploy.json C11584_setsid_not_restricted_diff.json
```

## Project-Specific Terminology

| Term | Meaning |
|------|---------|
| CM | Container Manager |
| VAM | Vehicle Application Manager |
| SCML | Seccomp Management Layer |
| DLT | Diagnostic Log and Trace |
| ARXML | AUTOSAR XML definitions |
| SOME/IP | AUTOSAR middleware |

## Maintenance

This configuration is maintained on the `jay-claude` branch.

To update:
```bash
git checkout jay-claude
# Edit files in ~/.claude/ccu-2.0/
git add ~/.claude/ccu-2.0/
git commit -m "Update Claude Code configuration"
```

## Benefits

- **Domain Knowledge**: Automotive/AUTOSAR terminology and patterns
- **Workflow Automation**: Smart commands for common tasks
- **Issue Detection**: Automatic identification of container/seccomp issues
- **Code Quality**: JIRA integration and commit formatting
- **Debug Support**: Deep container and syscall testing insights
