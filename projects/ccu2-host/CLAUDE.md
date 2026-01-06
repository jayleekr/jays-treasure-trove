# CCU-2.0 Project Knowledge Base

## Project Overview

**CCU-2.0** = Central Computing Unit 2.0 - Automotive Adaptive AUTOSAR platform
- **Purpose**: Meta-repo for automotive embedded system development
- **Architecture**: Multi-component C++/Python system with CMake build
- **Platform**: Adaptive AUTOSAR (mobilgene), Docker containerization
- **Testing**: Python-based test framework, container security validation

---

## Repository Structure

### Core Components
```
ccu-2.0/
├── container-manager/       # Docker container orchestration & security
├── container-app/           # Containerized applications (seccomp tests)
├── vam/                     # Vehicle Application Manager
├── libsnt_vehicle/          # Vehicle interface library
├── libsntxx/                # Sonatus C++ utilities
├── libsntlogging/           # Logging framework
├── diagnostic-manager/      # Vehicle diagnostics
├── dpm/                     # Data Path Manager
├── ethnm/                   # Ethernet Network Management
├── rta/                     # Runtime Aggregation
├── seccommon/               # Security common libraries
├── soa/                     # Service-Oriented Architecture
└── mobilgene-x86_64/        # Adaptive AUTOSAR platform
```

### Build System
- **Primary**: `build.py` - Main build orchestrator
- **Config**: `build_config.py` - Build parameters & targets
- **CMake**: Multi-level CMakeLists.txt hierarchy
- **Docker**: `run-dev-container.sh` - Containerized build environment

---

## Key Patterns & Conventions

### Commit Message Format
```
[TICKET-ID] Brief description (#PR)

Examples:
- [CCU2-15604] Remove Adaptive AUTOSAR dependency (#621)
- [SEB-1294] Add CRM project to PR title check (#620)
```

### Ticket Prefixes
- `CCU2-*` = Main CCU2 JIRA tickets
- `SEB-*` = Software Engineering Board tickets
- `CRM-*` = Container/Resource Management tickets

### Testing Patterns
- Python test framework: `snt_test_framework`
- Test files: `test.py`, `test_*.py` in component dirs
- Container tests: `/container-manager/test.py`
- Deployment configs: JSON-based in `test_config/deploy/`

---

## Common Workflows

### Build Patterns
```bash
# Host build
python build.py --target <component> --build-type Debug

# Container build
./run-dev-container.sh

# Clean build
python build.py --clean
```

### Git Submodule Pattern
- This is a meta-repo with multiple git submodules
- Each component (container-manager, vam, etc.) can be separate git repo
- Check `.gitmodules` or use `repo.sh` for manifest-based management

### Container Testing
```python
# Standard test pattern (see container-manager/test.py)
from snt_test_framework.core import executor
from snt_test_framework.core.api import cm_utils, test

@test.Case(11584)
class TestName(test.Test):
    def setup(self): ...
    def teardown(self): ...

    @test.Step(1)
    def test_step(self): ...
```

---

## Technical Stack

### Languages
- **C++17**: Core system components
- **Python 3**: Build system, tests, tooling
- **CMake**: Build configuration
- **Bash**: Helper scripts

### Frameworks & Libraries
- **Adaptive AUTOSAR**: mobilgene platform
- **Docker**: Containerization
- **Boost**: C++ utilities
- **vsomeip**: SOME/IP middleware
- **DLT**: Diagnostic Log and Trace

### Security
- **Seccomp**: Syscall filtering
- **Container isolation**: Docker security profiles
- **Syscall testing**: Fork-based validation to avoid PID 1 issues

---

## Pain Points & Solutions

### 1. Session Leader (PID 1) Syscall Testing
**Problem**: Container PID 1 is always session leader → `setsid()` returns EPERM, masking seccomp errors

**Solution**: Fork child process for syscall testing
```cpp
pid_t child = fork();
if (child == 0) {
    // Child is NOT session leader
    setsid();  // Can detect real seccomp errors
}
```

### 2. Errno Interpretation
**Problem**: EPERM vs EACCES confusion in seccomp testing

**Solution**:
- `EPERM` = Process state issue (session leader)
- `EACCES` = Seccomp blocked
- Always check errno immediately after syscall failure

### 3. Multi-Repo Navigation
**Problem**: Large monorepo with nested git repos

**Solution**: Use component-specific workflows (see custom commands below)

---

## Project-Specific Terminology

| Term | Meaning |
|------|---------|
| **CM** | Container Manager |
| **VAM** | Vehicle Application Manager |
| **DPM** | Data Path Manager |
| **SCML** | Seccomp Management Layer |
| **ARXML** | AUTOSAR XML (service definitions) |
| **SOME/IP** | Scalable service-Oriented MiddlewarE over IP |
| **DLT** | Diagnostic Log and Trace |
| **EthNM** | Ethernet Network Management |

---

## File Organization Standards

### Test Files
```
component/
├── tests/           # C++ unit tests
├── test.py          # Python integration tests
└── test_config/     # Test configurations
```

### Configuration
```
component/
├── config/          # Runtime configuration
└── test_config/     # Test-specific configs
```

### Generated Code
```
component/
└── gen/             # Auto-generated AUTOSAR bindings
    ├── includes/
    └── net-bindings/
```

---

## Development Environment

### Docker Container
- **Image naming**: `${USER}-ccu-2.0-${CONFIG_HASH}`
- **Container naming**: Based on `${MOUNT_DIR}`
- **Force rebuild**: `run-dev-container.sh -f`
- **Dependencies**: Modified via `dev-container-embedded` repo

### Build Artifacts
```
build-*/             # Build output directories
├── Debug/
├── Release/
└── autosar/         # AUTOSAR-specific builds
```

---

## Quality Standards

### Code Style
- Follow existing component conventions
- C++: Modern C++17 patterns
- Python: PEP 8 compliant
- CMake: Consistent indentation and structure

### Security
- All syscall tests must handle PID 1 session leader issue
- Always check errno for proper error interpretation
- Fork-based testing for seccomp validation

### Testing
- Integration tests in Python (snt_test_framework)
- Unit tests in C++ (component/tests/)
- Container security validation required

### Coding Standards Compliance

**MISRA-C 2023 & CERT-CPP**:
- **Tool**: `isir.py` - MISRA/CERT-CPP violation management
- **Server**: https://ops.us.sonatus.com/ccu2-misra/
- **Rules**: 116 mandatory + 53 advisory MISRA rules
- **Workflow**: `/isir` command or `misra-compliance-agent` skill

**Suppression Pattern**:
```cpp
// coverity[misra_cpp_2023_rule_X_Y_Z_violation:SUPPRESS] Justification message
violating_code();
```

**Common Workflow** (Remote-only mode):
1. Download violation reports: `./isir.py -m <module> -c MISRA -d`
2. Auto-suppress known rules: `./isir.py -m <module> -c MISRA -sa -d`
3. Manual suppress specific: `./isir.py -m <module> -c MISRA -s X.Y.Z "reason" -d`
4. **Note**: Local analysis mode (`-l`) is NOT functional - always use remote download (`-d`)
