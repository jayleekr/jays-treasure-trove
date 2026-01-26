---
description: "[DEPRECATED] Use /snt-ccu2-yocto:build or /snt-ccu2-host:build instead"
---

# Build Component Command (DEPRECATED)

> **WARNING**: This command is deprecated and may have incorrect information.
>
> Use the environment-specific build commands instead:
> - **Yocto environment** (`CCU_GEN2.0_SONATUS`): `/snt-ccu2-yocto:build`
> - **Host environment** (`ccu-2.0`): `/snt-ccu2-host:build`

---

## Legacy Documentation (for reference only)

Build CCU-2.0 components using `./build.py` with intelligent defaults and automotive variant awareness.

## Task

1. **Module Detection**
   - Map component name to `--module` argument
   - Validate against supported modules list
   - Detect from current directory if not specified

2. **Variant Configuration**
   - Show current defaults (Tier, CAN DB, Service I/F, ECU)
   - Suggest common variant combinations
   - Validate variant compatibility

3. **Dependency Analysis**
   - Check reverse dependencies (rdeps)
   - Determine build order
   - Show what will be built

4. **Execute Build**
   - Run `./build.py --module <name> [options]`
   - Display build configuration summary
   - Show compiler and output directory

5. **Report Results**
   - Build duration and artifacts location
   - Test results (if `--tests`)
   - Suggested next actions

## Usage Examples

### Basic Module Build
```bash
/build-component container-manager
/build-component vam
/build-component                    # Detect from current directory
```

### With Build Type
```bash
/build-component vam --type Release
/build-component container-manager --type Debug
```

### With Vehicle Variants
```bash
/build-component vam --tier MOBIS --can-db 252Q
/build-component container-manager --service-if 0.24.2 --ecu CCU2_LITE
```

### Development Options
```bash
/build-component vam --clean --tests --coverage
/build-component container-manager --autosar --dlt --verbose
```

### Cross-Compilation
```bash
/build-component diagnostic-manager --cross-compile --ecu BCU
```

## Available Modules (--module)

**Core Infrastructure**:
- `container-manager` - Docker container orchestration
- `container-app` - Containerized applications
- `vam` - Vehicle Application Manager
- `dpm` - Data Path Manager

**Libraries**:
- `libsntxx` - C++ utilities
- `libsntlogging` - Logging framework
- `libsnt_vehicle` - Vehicle interface
- `libsnt_cantp`, `libsnt_doip` - Protocol libraries
- `libsnt_ehal` - EHAL library

**AUTOSAR & Interfaces**:
- `ccu2-adaptive-arxml` - AUTOSAR XML definitions
- `ccu2-fidl-interface` - FIDL interfaces
- `mobilgene-x86_64` - Mobilgene platform
- `soa` - Service-Oriented Architecture

**Managers & Services**:
- `diagnostic-manager` - Vehicle diagnostics
- `ethnm` - Ethernet Network Management
- `ethernet-handler` - Ethernet handling
- `mqtt-middleware` - MQTT middleware
- `trace-engine` - Trace engine

**Security & IDS**:
- `seccommon` - Security common libraries
- `uids` - User IDS

**Vehicle Controllers**:
- `vcc2`, `vdc` - Vehicle controllers
- `rta` - Runtime Aggregation

**Utilities**:
- `build-common` - Build utilities
- `shared-storage` - Shared storage
- `vehicle-schema` - Vehicle schema
- `mcu_mock` - MCU mock

## Build Options

### Build Types (--build-type)
- `Debug` **(default)** - Debug symbols, no optimization
- `Release` - Optimized, no debug symbols
- `RelWithDebInfo` - Optimized with debug symbols

### Compilers (--compiler)
- `CLANG` **(default)** - clang-15/clang++-15
- `GCC_10` - GCC 10.x
- `GCC_11` - GCC 11.x

### Vehicle Variants

**Tier** (--tier):
- `LGE` **(default)**
- `MOBIS`

**CAN DB Version** (--can-db-version):
- `253Q` **(default)** - Latest
- `252Q`, `251Q` - Older versions
- `253Q.WM` - Special variant

**Service Interface** (--service-if-version):
- `0.25.1` **(default)** - Latest
- `0.24.2`, `0.23.1` - Older versions

**ECU Type** (--ecu):
- `CCU2` **(default)**
- `CCU2_LITE`
- `BCU`

### Common Flags

**Development**:
- `--clean, -c` - Clean before build
- `--tests` - Build and run unit tests
- `--tests-build-only` - Build tests without running
- `--jobs N, -j N` - Parallel jobs (default: 24)
- `--verbose` - Detailed output

**Quality & Analysis**:
- `--coverage` - Generate code coverage report
- `--clang-format` - Check code formatting
- `--clang-format-apply` - Auto-fix formatting
- `--pr-check` - Run PR validation checks

**Sanitizers** (Debug mode):
- `--asan` - Address sanitizer
- `--tsan` - Thread sanitizer
- `--ubsan` - Undefined behavior sanitizer
- `--lsan` - Leak sanitizer

**AUTOSAR**:
- `--autosar` - Enable AUTOSAR flag
- `--cross-compile, --xc` - Cross-compilation mode
- `--dlt` - Enable DLT logging

**Variants**:
- `--all-variants, -av` - Build all variant combinations
- `--random-variants, -rv` - Random variant selection

**Debug & Control**:
- `--dry-run, -n` - Show command without executing
- `--trace-command` - Print executed commands
- `--no-build, -nb` - CMake only, skip build
- `--no-rdeps, -nr` - Skip reverse dependencies
- `--keep-going` - Continue on errors

## Execution Pattern

Command executes:
```bash
./build.py --module <component> [options]
```

Example output:
```
args.module:'container-manager'
rdeps:{'container-manager'}

Start building Module: container-manager.
========= Build Options =========
    Service I/F Version: 0.25.1
    CAN DB Version     : 253Q
    AUTOSAR            : False
    Build Type         : Debug
    MP Release        : False
    Compiler           : clang
    OUTPUT DIR         : build
Compiler:                clang-15 clang++-15

========= Module Operations =========
[Build proceeds...]
```

## Common Build Combinations

**Standard Development**:
```bash
./build.py --module vam
# Tier: LGE, CAN DB: 253Q, Service I/F: 0.25.1, Debug, clang
```

**MOBIS Variant**:
```bash
./build.py --module vam --tier MOBIS --can-db 252Q
```

**Release with AUTOSAR**:
```bash
./build.py --module container-manager --build-type Release --autosar --dlt
```

**Testing & Coverage**:
```bash
./build.py --module vam --tests --coverage --verbose
```

**Cross-Compile for Lite ECU**:
```bash
./build.py --module diagnostic-manager --cross-compile --ecu CCU2_LITE
```

**CI/CD All Variants**:
```bash
./build.py --module container-manager --all-variants --output-junit
```

## Important Notes

⚠️ **Only use build.py** - Never invoke `cmake` or `make` directly
⚠️ **Variant combinations** - Some variants affect dependencies
⚠️ **Reverse dependencies** - Check rdeps for build order
⚠️ **Output directory** - Default `build/`, override with `--output-dir`
⚠️ **Module names** - Must match exact names from supported list

## Troubleshooting

**Check what will be built**:
```bash
./build.py --module vam --dry-run --trace-command
```

**Clean rebuild**:
```bash
./build.py --module container-manager --clean
# Or full clean:
rm -rf build/
```

**Dependency issues**:
```bash
# Build dependencies first
./build.py --module libsntxx
./build.py --module libsntlogging
./build.py --module vam
```
