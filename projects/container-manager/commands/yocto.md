# /yocto - Yocto Build Information (Execution Blocked)

⚠️ **BUILD EXECUTION BLOCKED**: This Claude Code session is not configured as Builder/Tester.

## Build Information Only
This command provides build information and guides you to proper build execution methods.

## Session Type Detection
```
Current Session: NOT Builder/Tester
Build Execution: BLOCKED
Test Execution: BLOCKED
```

## How to Build container-manager

### Option 1: Jenkins CI/CD (Recommended)
- Create PR and Jenkins will automatically build
- View build logs in Jenkins pipeline
- Supports all tiers: LGE, MOBIS
- Supports all ECUs: CCU2, CCU2_LITE, BCU

### Option 2: Local Build Environment
Switch to a proper build environment:
```bash
# SSH to builder server
ssh builder-kr-4
# OR
ssh builder10

# Then navigate to project and build
cd /path/to/container-manager
python3 build.py --tier LGE --ecu CCU2
# OR
./build.sh
```

### Option 3: Manual Environment Override
If you have proper Yocto build environment on this machine:
```bash
export CLAUDE_SESSION_TYPE=builder
python3 build.py --tier LGE --ecu CCU2
```

## Build Command Reference
container-manager uses **build.py** (Python build system) and build.sh wrapper:

```bash
# Python build script (primary)
python3 build.py --tier LGE --ecu CCU2           # LGE tier, CCU2 ECU
python3 build.py --tier MOBIS --ecu CCU2_LITE    # MOBIS tier, CCU2_LITE ECU
python3 build.py --tier LGE --ecu BCU            # LGE tier, BCU ECU

# Shell wrapper (calls build.py internally)
./build.sh                    # Uses defaults from build.toml

# Clean build
python3 build.py --clean

# With specific options
python3 build.py --tier LGE --ecu CCU2 --verbose
```

## What This Command Can Do
- ✅ Show build configuration from build.toml
- ✅ Detect tier and ECU settings
- ✅ Generate build documentation
- ✅ Link to Jenkins build jobs
- ✅ Display build requirements and dependencies
- ❌ Execute builds (BLOCKED in this session)

## Build Configuration Detection
This command can analyze:
- `build.toml`: MISRA rules, compiler flags, build options
- `CMakeLists.txt`: Project structure, feature flags, dependencies
- Environment variables: YOCTO_SDK, build paths
- Current tier/ECU selection

## Jenkins Integration
- PR creation triggers automatic builds
- Check build status in Jenkins dashboard
- View build artifacts and logs
- Download built images (if successful)
