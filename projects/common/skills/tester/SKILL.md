---
description: Hardware tester operations for CCU2 boards - SSH commands, file transfers, firmware flashing, and boot log capture
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
---

# Tester Skill

Autonomous hardware operations for CCU2 test boards via tester machines.

## Capabilities

| Operation | Description |
|-----------|-------------|
| `ssh` | Execute commands on tester (power, bootmode, serial) |
| `scp` | Copy files to/from tester |
| `flash` | Flash firmware (mcu, uboot, ap, all) |
| `boot-log` | Capture and analyze boot logs |

## Tester Machines

| Hostname | Description |
|----------|-------------|
| `bcu-tester-3.sonatus-internal` | BCU test machine |
| `bcu-tester-4.sonatus-internal` | BCU test machine |
| `bcu-tester-1.sonatus-internal` | BCU test machine |
| `ccu2-tester-1.sonatus-internal` | CCU2 test machine |

Short names also work: `bcu-tester-3`, `ccu2-tester-1`

## Usage

### SSH Operations
```bash
/tester:ssh <tester> <command>

# Power control
/tester:ssh bcu-tester-3 power cycle

# Boot mode
/tester:ssh bcu-tester-3 bootmode serial
```

### File Transfer
```bash
/tester:scp <direction> <tester> <source> [destination]

# Copy to tester
/tester:scp to bcu-tester-3 ./image.tar.gz /tmp/

# Copy from tester
/tester:scp from bcu-tester-3 /tmp/boot.log ./
```

### Firmware Flash
```bash
/tester:flash <tester> <mode> [options]

# Flash MCU
/tester:flash bcu-tester-3 mcu -r

# Flash BL2 only
/tester:flash bcu-tester-3 mcu --addr 0x280000 --file /var/lib/tftpboot/a53_bl.bin
```

### Boot Log Capture
```bash
/tester:boot-log <tester> [options]

# Basic capture
/tester:boot-log bcu-tester-3

# With analysis
/tester:boot-log bcu-tester-3 --timeout 60 --analyze
```

## Workflow Example

### Flash and Verify New Firmware

1. **Copy image to tester**
   ```bash
   /tester:scp to bcu-tester-3 mobis/deploy/ccu-image.tar.gz /tmp/
   ```

2. **Flash firmware**
   ```bash
   /tester:flash bcu-tester-3 all -i /tmp/ccu-image.tar.gz
   ```

3. **Capture boot log**
   ```bash
   /tester:boot-log bcu-tester-3 --analyze
   ```

## References

Detailed documentation in `references/`:
- `ssh-operations.md` - SSH command details
- `scp-operations.md` - File transfer details
- `flash-operations.md` - Firmware flash details
- `boot-log.md` - Boot log capture and analysis
