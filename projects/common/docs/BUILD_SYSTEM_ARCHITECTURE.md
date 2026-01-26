# CCU-2.0 Build System Architecture

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CCU-2.0 Build Ecosystem                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────┐              ┌─────────────────────────────┐   │
│  │   Host Build        │              │   Yocto Build               │   │
│  │   (ccu-2.0)         │              │   (CCU_GEN2.0_SONATUS)      │   │
│  │                     │              │                             │   │
│  │  - C++/Python code  │◄────SDK──────│  - Embedded Linux images    │   │
│  │  - Unit tests       │              │  - SDK generation           │   │
│  │  - Cross-compile    │              │  - Bitbake recipes          │   │
│  └─────────────────────┘              └─────────────────────────────┘   │
│           │                                        │                     │
│           ▼                                        ▼                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     Shared Infrastructure                        │   │
│  │  /workspace/share/                                               │   │
│  │  ├── downloads/         # Yocto source cache                    │   │
│  │  ├── sstate-cache/      # Yocto build cache                     │   │
│  │  └── sdk-cache/         # Cross-compilation SDKs                │   │
│  │                                                                  │   │
│  │  /workspace/sdk/        # Installed SDKs                        │   │
│  │  ├── lge/0.25.1/                                                │   │
│  │  └── mobis/0.24.2/                                              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 2. Build Matrix

### 2.1 Build Dimensions

| Dimension | LGE Values | MOBIS Values | SDK Impact |
|-----------|------------|--------------|------------|
| **Tier** | LGE | MOBIS | Different toolchain |
| **ECU Type** | CCU2, CCU2_LITE | CCU2, BCU | Yocto machine target |
| **Service IF** | 0.25.1, 0.24.2, 0.23.1 | 0.24.2, 0.24.0 | Sysroot headers |
| **CAN DB** | 254Q, 253Q, 252Q, 251Q, 253Q.WM | 252Q | Symlink only |
| **Build Type** | Debug, Release, RelWithDebInfo | same | N/A |
| **Compiler** | clang, gcc-10, gcc-11 | same | Host only |

### 2.2 SDK Key Formula

```
SDK Key = {tier}-{service_if_version}

Examples:
- lge-0.25.1
- lge-0.24.2
- mobis-0.24.2
```

**Total SDKs Required:**
```
LGE   × [0.25.1, 0.24.2, 0.23.1] = 3 SDKs
MOBIS × [0.24.2, 0.24.0]         = 2 SDKs
─────────────────────────────────────────
Total: 5 base SDKs
```

### 2.3 CAN DB Handling

CAN DB versions do NOT require separate SDKs. They are handled via symlink updates:
- `update-symbolic-links.sh` updates `/usr/include/{TIER}` symlinks
- Same SDK can be used across different CAN DB versions

## 3. Directory Structure

### 3.1 Host Build Repository (ccu-2.0)

```
~/ccu-2.0/
├── build.py                    # Main build orchestrator
├── build_config.py             # Build configurations (TierType, EcuType, etc.)
├── sdk_manager.py              # SDK management module
├── update-symbolic-links.sh    # CAN DB symlink updater
│
├── container-manager/          # Component sources
├── vam/
├── diagnostic-manager/
├── dpm/
├── ethernet-handler/
├── ethnm/
├── libsnt_vehicle/
├── libsntxx/
├── libsntlogging/
├── soa/
├── vdc/
├── ...
│
├── mobilgene-x86_64/           # AUTOSAR platform (host)
├── ccu2-adaptive-arxml/        # Service interface definitions
│
└── dev-container/              # Docker container configuration
    ├── dockerfiles/
    │   ├── host/ccu-2.0/Dockerfile
    │   └── yocto/ccu-2.0/Dockerfile
    └── srcs/
        ├── impl_dev-container.sh
        ├── docker-common.sh
        └── create-container.sh
```

### 3.2 Yocto Build Repository (CCU_GEN2.0_SONATUS.manifest)

```
~/CCU_GEN2.0_SONATUS.manifest/
├── build.py                    # Yocto build orchestrator
├── init.py                     # Repository initialization (repo sync)
├── config.py                   # Build configurations
├── snt_common.py               # Common utilities
│
├── scripts/
│   └── sdk_manager.py          # SDK generation and publishing
│
├── info/
│   └── modules.yaml            # Module definitions
│
├── lge/                        # LGE tier workspace
│   ├── build_info.json         # Build configuration
│   ├── build_s32g274aevb/      # Bitbake build directory
│   │   ├── conf/
│   │   └── tmp/
│   │       └── deploy/
│   │           └── images/
│   │               └── s32g274aevb/
│   └── sources/                # Yocto layers
│       ├── meta-alb/
│       ├── meta-lge-ccu/
│       ├── meta-sonatus/
│       └── poky/
│
└── mobis/                      # MOBIS tier workspace
    ├── build-ccu2/
    └── sources/
```

### 3.3 Shared Storage (/workspace)

```
/workspace/
├── share/
│   ├── downloads/              # Yocto source downloads
│   │   ├── LGE/
│   │   └── MOBIS/
│   │
│   ├── sstate-cache/           # Yocto build cache
│   │   ├── LGE/
│   │   │   └── {can_db}.{service_if}/
│   │   └── MOBIS/
│   │       └── {can_db}.{service_if}/
│   │
│   └── sdk-cache/              # SDK cache
│       ├── registry.json       # SDK metadata index
│       ├── lge/
│       │   ├── 0.25.1/
│       │   │   ├── sdk.tar.zst
│       │   │   └── manifest.json
│       │   ├── 0.24.2/
│       │   └── 0.23.1/
│       └── mobis/
│           ├── 0.24.2/
│           └── 0.24.0/
│
└── sdk/                        # Installed SDKs
    ├── lge/
    │   └── 0.25.1/
    │       ├── environment-setup-cortexa53-crypto-fsl-linux
    │       └── sysroots/
    │           └── cortexa53-crypto-fsl-linux/
    │               └── usr/
    │                   ├── include/
    │                   │   ├── mobilgene/
    │                   │   └── LGE/
    │                   └── lib/
    └── mobis/
        └── 0.24.2/
            ├── environment-setup-aarch64-fsl-linux
            └── sysroots/
```

## 4. Build Flows

### 4.1 Host Native Build

```
./build.py --tier LGE --service-if-version 0.25.1 container-manager
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Parse arguments                                          │
│  2. Load build configuration                                 │
│  3. Update symbolic links (CAN DB headers)                   │
│  4. CMake configure (host toolchain)                         │
│  5. Compile with host compiler (clang/gcc)                   │
│  6. Link                                                     │
│  7. Run tests (optional)                                     │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
Output: build-{tier}-{can_db}-{service_if}/{module}/
```

### 4.2 Host Cross-Compilation Build

```
./build.py --xc --tier LGE --service-if-version 0.25.1 container-manager
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Parse arguments                                          │
│  2. SDK Manager: ensure_sdk(LGE, 0.25.1)                     │
│     ├── Check /workspace/sdk/lge/0.25.1/                    │
│     │                                                        │
│     ├── If not installed:                                    │
│     │   ├── Check /workspace/share/sdk-cache/lge/0.25.1/    │
│     │   └── Extract and install SDK                          │
│     │                                                        │
│     └── Return: environment-setup script path                │
│                                                              │
│  3. Source environment-setup-cortexa53-crypto-fsl-linux      │
│  4. Update symbolic links (CAN DB headers in sysroot)        │
│  5. CMake configure (cross toolchain)                        │
│  6. Cross-compile for aarch64                                │
│  7. Link with target libraries                               │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
Output: ELF 64-bit LSB executable, ARM aarch64
```

### 4.3 Yocto Full Image Build

```
cd ~/CCU_GEN2.0_SONATUS.manifest/lge
../build.py build fsl-image-base
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Load build_info.json (tier, ECU, versions)               │
│  2. Provision (source env scripts)                           │
│  3. Setup local.conf                                         │
│  4. Run bitbake fsl-image-base                               │
│  5. Post-process (archive, rename)                           │
│  6. Generate build artifacts                                 │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
Output:
  - ccu-image.rootfs_ro.sdcard.gz
  - fip.bin
  - boot.sdcard
  - build_info.json
```

### 4.4 SDK Generation

```
cd ~/CCU_GEN2.0_SONATUS.manifest/lge
../build.py sdk --tier LGE --service-if 0.25.1
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Provision build environment                              │
│  2. Run bitbake fsl-image-base -c populate_sdk               │
│  3. Locate SDK installer script                              │
│  4. Package SDK with zstd compression                        │
│  5. Create manifest.json (metadata)                          │
│  6. Copy to /workspace/share/sdk-cache/lge/0.25.1/          │
│  7. Update registry.json                                     │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
Output:
  - /workspace/share/sdk-cache/lge/0.25.1/sdk.tar.zst
  - /workspace/share/sdk-cache/lge/0.25.1/manifest.json
  - Updated registry.json
```

## 5. Docker Containers

### 5.1 Host Container (ccu-2.0)

**Image**: `host-ccu-2.0:latest` (Ubuntu 22.04 based)

**Key Packages**:
- Build tools: cmake, gcc-10, gcc-11, clang-15, mold
- Libraries: boost, protobuf, CommonAPI, vsomeip, dlt-daemon
- Python: python3, pip packages for build scripts

**Volumes**:
```bash
-v ~/ccu-2.0:/workspace/ccu-2.0                              # Source code
-v /workspace/share/sdk-cache:/workspace/share/sdk-cache:ro  # SDK cache (read-only)
-v /workspace/sdk:/workspace/sdk                              # Installed SDKs
```

**Entry Script**: `run-dev-container.sh`

### 5.2 Yocto Container (CCU_GEN2.0_SONATUS)

**Image**: `yocto-ccu-2.0:latest` (Ubuntu 20.04 based)

**Key Packages**:
- Yocto requirements: chrpath, diffstat, gawk, texinfo
- Cross-compilers: gcc-aarch64-linux-gnu
- Python: python3.8, yocto build dependencies

**Volumes**:
```bash
-v ~/CCU_GEN2.0_SONATUS.manifest:/workspace/yocto    # Source code
-v /workspace/share:/workspace/share                  # Shared cache (read-write)
-v /RepoCache:/RepoCache:ro                           # Git reference cache
```

**Entry Script**: `run-dev-container.sh`

## 6. SDK Management

### 6.1 SDK Cache Structure

```
/workspace/share/sdk-cache/
├── registry.json
├── lge/
│   └── 0.25.1/
│       ├── sdk.tar.zst      # ~400-500MB compressed
│       └── manifest.json
└── mobis/
    └── 0.24.2/
        ├── sdk.tar.zst
        └── manifest.json
```

### 6.2 Registry Schema (registry.json)

```json
{
  "version": "1.0",
  "updated": "2026-01-08T12:00:00Z",
  "sdks": {
    "lge-0.25.1": {
      "path": "lge/0.25.1/sdk.tar.zst",
      "checksum": "sha256:abc123...",
      "size_mb": 450,
      "created": "2026-01-08T12:00:00Z",
      "yocto_commit": "fc55b25",
      "arch": "cortexa53-crypto-fsl-linux"
    },
    "mobis-0.24.2": {
      "path": "mobis/0.24.2/sdk.tar.zst",
      "checksum": "sha256:def456...",
      "size_mb": 420,
      "created": "2026-01-07T10:00:00Z",
      "yocto_commit": "da01855",
      "arch": "aarch64-fsl-linux"
    }
  }
}
```

### 6.3 SDK Manifest Schema (manifest.json)

```json
{
  "sdk_key": "lge-0.25.1",
  "tier": "LGE",
  "service_if_version": "0.25.1",
  "arch": "cortexa53-crypto-fsl-linux",
  "created": "2026-01-08T12:00:00Z",
  "yocto_commit": "fc55b25",
  "meta_sonatus_commit": "abc123",
  "compatible_can_db": ["254Q", "253Q", "252Q", "251Q"],
  "environment_script": "environment-setup-cortexa53-crypto-fsl-linux",
  "sysroot_path": "sysroots/cortexa53-crypto-fsl-linux"
}
```

### 6.4 SDK Installation Path

```
/workspace/sdk/{tier}/{service_if}/
├── environment-setup-{arch}
├── site-config-{arch}
├── version-{arch}
└── sysroots/
    ├── {arch}/                    # Target sysroot
    │   └── usr/
    │       ├── include/
    │       │   ├── mobilgene/     # AUTOSAR headers
    │       │   └── {TIER}/        # Service interface headers
    │       └── lib/
    └── x86_64-pokysdk-linux/      # Host tools
        └── usr/
            ├── bin/
            │   ├── aarch64-fsl-linux-gcc
            │   └── aarch64-fsl-linux-g++
            └── lib/
```

## 7. CI/CD Integration

### 7.1 Jenkins Pipeline Stages

```groovy
pipeline {
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Setup') {
            steps {
                sh './run-dev-container.sh -ni'
            }
        }

        stage('Build') {
            parallel {
                stage('Host Build') {
                    steps {
                        sh './build.py --tier LGE container-manager'
                    }
                }
                stage('Cross Build') {
                    steps {
                        sh './build.py --xc --tier LGE container-manager'
                    }
                }
            }
        }

        stage('Test') {
            steps {
                sh './build.py test'
            }
        }

        stage('SDK Generation') {
            when {
                branch 'release/*'
            }
            steps {
                sh '../build.py sdk --tier LGE --service-if 0.25.1'
            }
        }
    }
}
```

### 7.2 SDK Auto-Generation Triggers

| Trigger | Action |
|---------|--------|
| Release branch build | Generate and publish SDK to cache |
| Service IF version change | Generate new SDK |
| Manual trigger | On-demand SDK generation |

## 8. Troubleshooting

### 8.1 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| SDK not found | Not in cache | Generate SDK from Yocto build |
| Permission denied | /opt access | Use /workspace/sdk instead |
| Wrong headers | CAN DB mismatch | Run `update-symbolic-links.sh` |
| Linker errors | Library mismatch | Verify SDK and sysroot match |

### 8.2 Debugging Commands

```bash
# Check SDK installation
ls -la /workspace/sdk/lge/0.25.1/

# Verify environment setup
source /workspace/sdk/lge/0.25.1/environment-setup-*
echo $CC $CXX $SYSROOT

# Check sysroot headers
ls /workspace/sdk/lge/0.25.1/sysroots/*/usr/include/

# Verify cross-compiler
$CC --version
```

## 9. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-08 | Initial documentation |
