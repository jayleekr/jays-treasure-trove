---
name: snt-ccu2-yocto:init
description: "Initialize CCU2 Yocto project with repo sync and configuration. Supports LGE and MOBIS tiers with multiple vehicle types. Must run inside Docker container."
---

# /snt-ccu2-yocto:init - Project Initialization

Initialize CCU2 Yocto embedded Linux project repositories.

## Usage

```
/snt-ccu2-yocto:init [options]
```

## Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--tier` | `-t` | Tier type (LGE, MOBIS) | MOBIS |
| `--version` | `-v` | Vehicle/version type | tier default |
| `--force` | `-f` | Force re-init (removes .repo) | false |
| `--meta-sonatus-branch` | `-msb` | meta-sonatus branch | master |
| `--sonatus-branch` | `-sb` | Sonatus repos branch | master |
| `--sonatus-version` | `-sv` | Sonatus release tag | - |
| `--date` | | Build date (YYMMDD) | today |
| `--dry-run` | `-d` | Show commands without executing | false |

## Available Configurations

### LGE Tier
| Version | ECU | Type | Vehicle |
|---------|-----|------|---------|
| `jg1` | CCU2 | daily | JG1 |
| `bj1` | CCU2 | daily | BJ1 |
| `lq2` | CCU2 | daily | LQ2 |
| `ne1` | CCU2 | daily | NE1 |
| `ne1_new` | CCU2 | event | NE1 (new) |
| `nx5` | CCU2 | event | NX5 |

### MOBIS Tier
| Version | ECU | Type | Vehicle |
|---------|-----|------|---------|
| `lw1` | CCU2_LITE | - | LW1 |
| `sx3` | CCU2_LITE | - | SX3 |
| `qy2` | BCU | - | QY2 |

## Examples

```bash
# Initialize MOBIS BCU qy2 (default)
/snt-ccu2-yocto:init

# Force re-init with specific version
/snt-ccu2-yocto:init -f -t MOBIS -v qy2

# Initialize with custom meta-sonatus branch
/snt-ccu2-yocto:init -t MOBIS -v qy2 -msb CCU2-18227-podman

# LGE daily build
/snt-ccu2-yocto:init -t LGE -v jg1

# Dry run to see commands
/snt-ccu2-yocto:init -d -t MOBIS -v qy2 --verbose
```

## Behavioral Flow

1. **Pre-checks**
   - Verify running inside Docker container
   - Parse and validate arguments
   - Load version configuration from `info/repo_info.json`

2. **Configuration Display**
   - Show selected tier/version configuration
   - Display build options (service_if_version, can_db_version, etc.)

3. **Force Cleanup (if -f)**
   - Remove `.repo` directory
   - Clean tier directory (except sstate-cache and build-*)

4. **Repository Sync**
   - `repo init` with manifest from RepoCache
   - Modify manifest (add Sonatus remote, adjust paths)
   - `repo sync -c -j16 --force-sync`
   - `git submodule update --init`

5. **Post-Setup**
   - Create symbolic links (build.py, config.py)
   - Save `build_info.json` with configuration
   - Download MCU firmware (LGE only)

## Output Files

| File | Description |
|------|-------------|
| `{tier}/build_info.json` | Build configuration |
| `{tier}/build.py` | Symlink to root build.py |
| `{tier}/config.py` | Symlink to root config.py |

## Important Notes

### Docker Requirement
```bash
# Must run inside container first
./run-dev-container.sh

# Then run init
python3 init.py -t MOBIS -v qy2
```

### custom_mcu Flag
- **MOBIS**: `custom_mcu: true` - Uses prebuilt `customs/MOBIS/{version}/flash.bin`
- **LGE**: `custom_mcu: false` - Downloads MCU from artifactory

### BL2/FIP Version Mismatch Warning
When `custom_mcu: true`, ensure `customs/MOBIS/{version}/flash.bin` is up-to-date with BSP changes.

Check versions:
```bash
# Compare BL2 versions
strings customs/MOBIS/qy2/flash.bin | grep -E "^[0-9]{6}[A-Z]-v"
strings mobis/deploy/a53_bl.bin-* | grep -E "^[0-9]{6}[A-Z]-v"
```

## Related Commands

- `/snt-ccu2-yocto:build` - Build after init
- `/snt-ccu2-yocto:pipeline` - Full workflow (includes init)

## Troubleshooting

### "Please run within docker"
```bash
./run-dev-container.sh
```

### Repo sync fails
```bash
# Force re-init
python3 init.py -f -t MOBIS -v qy2
```

### BL2 version mismatch after build
```bash
# Check if customs flash.bin needs update
ls -la customs/MOBIS/*/flash.bin
# Compare with other updated versions (lw1, sx3)
```
