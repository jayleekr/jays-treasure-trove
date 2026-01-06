# CCU2 Project Build System Documentation

## Overview

The CCU2 build system is a Python-based automation framework for building embedded Linux images for automotive Central Communication Units (CCU) and Body Control Units (BCU). It supports two Tier-1 suppliers: **LGE** and **MOBIS**.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Build System Flow                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   init.py                              build.py                         │
│   ───────                              ────────                         │
│   ┌─────────────┐                      ┌─────────────┐                 │
│   │ Parse Args  │                      │ Parse Args  │                 │
│   └──────┬──────┘                      └──────┬──────┘                 │
│          │                                    │                         │
│          ▼                                    ▼                         │
│   ┌─────────────┐                      ┌─────────────┐                 │
│   │ Load Config │                      │ Load Config │                 │
│   │(repo_info.json)                    │(build_info.json)              │
│   └──────┬──────┘                      └──────┬──────┘                 │
│          │                                    │                         │
│          ▼                                    ▼                         │
│   ┌─────────────┐                      ┌─────────────┐                 │
│   │ Repo Sync   │─────────────────────▶│ Provision   │                 │
│   │ (repo init/ │                      │ (env setup) │                 │
│   │  repo sync) │                      └──────┬──────┘                 │
│   └──────┬──────┘                             │                         │
│          │                                    ▼                         │
│          ▼                                    ┌─────────────┐          │
│   ┌─────────────┐                      │ Apply Patches│                │
│   │ Download MCU│                      └──────┬──────┘                 │
│   │ Firmware    │                             │                         │
│   └──────┬──────┘                             ▼                         │
│          │                                    ┌─────────────┐          │
│          ▼                                    │ Bitbake     │          │
│   ┌─────────────┐                      │ Build       │                 │
│   │ Save Build  │                      └──────┬──────┘                 │
│   │ Info (JSON) │                             │                         │
│   └─────────────┘                             ▼                         │
│                                               ┌─────────────┐          │
│                                               │ Post-Build  │          │
│                                               │ Actions     │          │
│                                               └─────────────┘          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. init.py - Repository Initialization

**Purpose**: Initialize and synchronize repositories for the CCU2 project.

**Execution Requirements**:
- Must run inside Docker container (`/.dockerenv` check)
- Requires repo tool (`repo init`, `repo sync`)

#### Key Classes

| Class | Purpose |
|-------|---------|
| `RepoSyncBase` | Abstract base for repository synchronization |
| `LGERepoSync` | LGE-specific manifest manipulation and sync |
| `MobisRepoSync` | MOBIS-specific manifest manipulation and sync |
| `InitBase` | Base initialization workflow |
| `LGEInit` | LGE initialization with safe git setup |
| `MobisInit` | MOBIS initialization |
| `MCUDownloader` | Downloads and validates MCU firmware from Artifactory |
| `ArgumentParser` | Command-line argument handling |

#### Initialization Flow

```python
# 1. Parse arguments (--tier, --version, --force, etc.)
# 2. Load version configuration from info/repo_info.json
# 3. Update config from command-line args
# 4. Force cleanup if --force flag set
# 5. Sync repositories (tier-specific)
# 6. Create symbolic links
# 7. Save build_info.json
# 8. Download MCU firmware (LGE only)
```

#### Command-Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--tier` | `-t` | Tier type (LGE/MOBIS) |
| `--version` | `-v` | Release version |
| `--force` | `-f` | Force reinitialize |
| `--sonatus-branch` | `-sb` | Sonatus module branch |
| `--sonatus-version` | `-sv` | Sonatus release version |
| `--meta-sonatus-branch` | `-msb` | meta-sonatus branch |
| `--tier-branch` | `-tb` | Tier manifest branch |
| `--tier-manifest` | `-tm` | Tier manifest XML file |
| `--date` | | Build date (YYMMDD format) |
| `--dry-run` | `-d` | Print commands without executing |
| `--verbose` | | Enable verbose output |

---

### 2. build.py - Image Building

**Purpose**: Build the final image for the CCU2 project using Yocto/Bitbake.

**Execution Requirements**:
- Must run inside Docker container
- Must run from `lge/` or `mobis/` directory
- Requires `build_info.json` (created by init.py)

#### Key Classes

| Class | Purpose |
|-------|---------|
| `BaseBuildConfig` | Common build configuration settings |
| `LGEBuildConfig` | LGE-specific build configuration |
| `MOBISBuildConfig` | MOBIS-specific build configuration |
| `BaseBuildEnv` | Environment setup and provisioning |
| `LGEBuildEnv` | LGE environment setup |
| `MOBISBuildEnv` | MOBIS environment setup |
| `BaseBuildPatcher` | Base class for build workarounds |
| `LGEBuildPatcher` | LGE-specific patches (SMACK, etc.) |
| `MOBISBuildPatcher` | MOBIS-specific patches |
| `BuildProcess` | Main build execution logic |
| `PostBuildProcess` | Post-build actions (archiving, firmware copy) |
| `FileUtils` | File manipulation utilities |

#### Build Flow

```python
# 1. Parse arguments
# 2. Create tier-specific BuildConfig
# 3. Load build_info.json
# 4. Check build options
# 5. Update build_info.json with current settings
# 6. Provision environment:
#    - Remove old bitbake cache
#    - Run tier-specific provision script
#    - Update local.conf
#    - Apply workarounds/patches
# 7. Build module(s):
#    - Clean if needed
#    - Build dependencies (for image builds)
#    - Build main module
# 8. Post-build:
#    - Copy MCU firmware
#    - Create deployment symlinks
#    - Create tarball archive
```

#### Command-Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--module` | `-m` | Specific module to build |
| `--snt` | `-snt` | Build all Sonatus modules |
| `--release` | `-r` | Release build type |
| `--mp` | | MP (Mass Production) release |
| `--clean-cache` | `-cc` | Clean sstate cache |
| `--jobs` | `-j` | Parallel build jobs |
| `--parallel-make` | `-p` | Make parallelism |
| `--command` | `-c` | Extra bitbake arguments |
| `--no-build` | `-nb` | Skip actual build |
| `--no-restore` | `-nr` | Don't restore tier layer |
| `--no-cleanup-post-build` | `-ncpb` | Keep work directories |
| `--custom-ehal` | `-ce` | Use custom EHAL library |
| `--custom-mcu` | `-cm` | Use custom MCU binary |
| `--emmc-64gb` | | MOBIS 64GB eMMC image |
| `--asan` | | Enable AddressSanitizer |
| `--tsan` | | Enable ThreadSanitizer |
| `--lsan` | | Enable LeakSanitizer |
| `--ubsan` | | Enable UBSan |
| `--dry-run` | `-d` | Print commands only |
| `--verbose` | | Verbose output |

---

## Configuration Files

### info/repo_info.json

Contains version configurations for all supported tiers and ECU types:

```json
{
  "LGE": {
    "CCU2": {
      "bj1": { /* config */ },
      "lq2": { /* config */ },
      "ne1": { /* config */ }
    },
    "CCU2_LITE": {
      "nx5": { /* config */ }
    }
  },
  "MOBIS": {
    "BCU": { /* configs */ },
    "CCU2_LITE": { /* configs */ }
  }
}
```

### info/modules.yaml

Defines Sonatus modules with their build properties:

```yaml
base_modules:        # Common modules for all tiers
  - name: cdh
    has_version: true     # Creates version.txt entry
    is_installed: true    # Included in image
    is_deployed: true     # Deployed to Tier-1
    excluded: []          # ECU/CANDB exclusions

lge_modules:         # LGE-specific modules
mobis_modules:       # MOBIS-specific modules
```

### info/partnumber_info.json

Maps vehicle types to part numbers:

```json
{
  "partnumber": {
    "bj1": "91920GJ000",
    "ne1": "91920QI000"
  }
}
```

### build_info.json (generated)

Created by init.py, consumed by build.py:

```json
{
  "ecu": "CCU2",
  "tier": {
    "tier_type": "LGE",
    "version": "daily",
    "release_version": "251104",
    ...
  },
  "sonatus": {
    "branch": "master",
    "release_version": "..."
  },
  "build_option": {
    "service_if_version": "0.25.1",
    "can_db_version": "253Q",
    ...
  }
}
```

---

## Tier-Specific Details

### LGE Tier

**Repository Structure**:
- Source path: `lge/`
- Build directory: `build_s32g274aevb`
- Provision script: `sources/meta-alb/nxp-setup-alb.sh`

**Special Features**:
- SMACK security labeling
- EIDS CAP packages
- MCU firmware download from Artifactory
- PFE SCC firmware validation

**Manifest Modifications**:
- Replaces `hkmc/linux/meta-sonatus` → `CCU_GEN2.0_SONATUS.meta-ccu2-sonatus`
- Adds CCU remote for GitHub
- Sets clone-depth=1 and fetch=no-tags

### MOBIS Tier

**Repository Structure**:
- Source path: `mobis/`
- Build directory: `build-ccu2` or `build-bcu`
- Provision script: `env.sh`

**Special Features**:
- RepoCache-based repository fetching
- Custom MCU binaries required
- 32GB/64GB eMMC image variants

**Manifest Modifications**:
- Prefixes paths with `mobis/`
- Replaces bitbucket URLs with RepoCache file protocol

---

## Environment Variables

### Exported to Bitbake

| Variable | Description |
|----------|-------------|
| `BB_NUMBER_THREADS` | Parallel bitbake tasks |
| `PARALLEL_MAKE` | Make parallelism |
| `SNT_BUILD_TYPE` | debug/Release/RelWithDebInfo |
| `SNT_TIER_TYPE` | LGE/MOBIS |
| `SERVICE_IF_VERSION` | Service interface version |
| `CAN_DB_VERSION` | CAN database version |
| `DL_DIR` | Download directory path |
| `SSTATE_DIR` | Shared state cache path |
| `ECU_NAME` | CCU2/CCU2_LITE/BCU |
| `VERSIONED_MODULES` | Modules with version tracking |
| `NON_INSTALLABLE_MODULES` | Modules not installed to image |

### LGE-Specific

| Variable | Description |
|----------|-------------|
| `EIDS_CAP_VERSION` | EIDS CAP package version |

---

## Module System

### Module Properties

| Property | Description |
|----------|-------------|
| `name` | Bitbake recipe name |
| `has_version` | Creates entry in version.txt |
| `is_installed` | Included in final image |
| `is_deployed` | Released to Tier-1 |
| `excluded` | ECU/CANDB types to exclude |

### Base Modules (All Tiers)

- `build-common` - Common build infrastructure
- `cdh` - Container/Data Handler
- `container-manager` - Container orchestration
- `diagnostic-manager` - Vehicle diagnostics
- `dpm` - Data Protection Manager
- `ethernet-handler` - Ethernet stack
- `ethnm` - Ethernet Network Management
- `libsntxx` - Sonatus C++ library
- `mqtt-middleware` - MQTT broker/client
- `soa` - Service-Oriented Architecture
- `vcc` - Vehicle Communication Controller
- `vdc` - Vehicle Data Controller
- `vam` - Vehicle Access Manager
- `vehicle-schema` - Vehicle data schemas
- `trace-engine` - Logging/tracing

### LGE-Specific Modules

- `seccommon` - Security common library
- `eids` - EIDS security module
- `eids-factory-cap` - Factory CAP packages
- `eids-ota-caps` - OTA CAP packages
- `rta` - Runtime Analysis

### MOBIS-Specific Modules

- `libsnt-ehal` - EHAL library

---

## Build Types

| Type | Description |
|------|-------------|
| `debug` | Debug build with symbols |
| `perf` | Performance/MP build |
| `Release` | Full release build |
| `RelWithDebInfo` | Release with debug info (default) |

---

## Typical Workflows

### Fresh Initialization

```bash
# Initialize LGE tier with default version
./init.py --tier LGE

# Initialize MOBIS tier with specific version
./init.py --tier MOBIS --version ccu2_lite2

# Force reinitialize
./init.py --tier LGE --force
```

### Building

```bash
cd lge  # or mobis

# Build default image
./build.py

# Build specific module
./build.py --module vcc

# Build all Sonatus modules
./build.py --snt

# Release build
./build.py --release

# MP release build
./build.py --mp

# With sanitizers
./build.py --asan --snt
```

### Clean Build

```bash
./build.py --clean-cache
./build.py --clean-cache --snt  # Clean all Sonatus modules
```

---

## Directory Structure

```
CCU_GEN2.0_SONATUS.manifest/
├── init.py              # Repository initialization
├── build.py             # Build orchestration
├── config.py            # Configuration enums and classes
├── snt_common.py        # Common utilities
├── board_utils.py       # Board communication utilities
├── info/
│   ├── repo_info.json   # Version configurations
│   ├── modules.yaml     # Module definitions
│   └── partnumber_info.json
├── customs/             # Custom MCU binaries, SMACK rules
├── lge/                 # LGE workspace (created by init.py)
│   ├── sources/         # Yocto layers
│   ├── build_s32g274aevb/
│   ├── deploy -> tmp/deploy/images/...
│   └── build_info.json
├── mobis/               # MOBIS workspace
│   ├── layers/          # Yocto layers
│   ├── build-ccu2/
│   └── build_info.json
└── ethernet-switch-generator/  # ESW configuration
```

---

## Error Handling

The build system uses `snt.set_last_exit_code()` for error tracking:
- Non-zero codes trigger `sys.exit()` unless `KEEP_GOING=True`
- Final status reported at script completion
- Timing information included in success/failure messages

---

## Dependencies

### Python Packages

- `argparse` - CLI parsing
- `requests` - HTTP for Artifactory
- `bs4` (BeautifulSoup) - HTML parsing
- `ruamel.yaml` - YAML parsing
- `prettytable` - Console output formatting
- `structlog` - Structured logging

### External Tools

- `repo` - Google repo tool
- `bitbake` - Yocto build system
- `git` - Version control
- Docker - Container environment
