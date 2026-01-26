# Tester SSH Operations

Execute commands on tester machines.

## Usage
```
/tester:ssh <tester> <command>
```

## Parameters

### Required
- `<tester>`: Target tester machine
  - `bcu-tester-3` - BCU test machine
  - `ccu2-tester-1` - CCU2 test machine
  - Other tester hostnames as needed
- `<command>`: Command or operation to execute

## Common Operations

### Power Control
```
/tester:ssh bcu-tester-3 power off     # Power off board
/tester:ssh bcu-tester-3 power on      # Power on board
/tester:ssh bcu-tester-3 power cycle   # Power cycle board
```

### Boot Mode
```
/tester:ssh bcu-tester-3 bootmode serial   # Set serial boot mode
/tester:ssh bcu-tester-3 bootmode normal   # Set normal boot mode
```

### Serial Console
```
/tester:ssh bcu-tester-3 serial capture 30   # Capture 30 seconds
/tester:ssh bcu-tester-3 serial boot-log     # Capture boot sequence
```

### File Operations
```
/tester:ssh bcu-tester-3 ls /var/lib/tftpboot/
/tester:ssh bcu-tester-3 extract /tmp/ccu-image.tar.gz
```

### Flash-boards Operations
```
/tester:ssh bcu-tester-3 flash-update      # Git pull flash-boards
/tester:ssh bcu-tester-3 flash-status      # Check flash-boards status
```

## Relay Commands (Low-level)

### Power
- `usbrelay SNPWR_1=0` - Power off
- `usbrelay SNPWR_1=1` - Power on

### Boot Mode
- `usbrelay CCUBT_1=0` - Normal boot
- `usbrelay CCUBT_1=1` - Serial boot

### PMIC Watchdog
- `usbrelay CCUBT_2=1` - Disable watchdog
- `usbrelay CCUBT_2=0` - Enable watchdog

## Examples

### Check tester status
```
/tester:ssh bcu-tester-3 status
```

### Run custom command
```
/tester:ssh bcu-tester-3 "ls -la /var/lib/tftpboot/*.bin"
```

### Capture boot log after power cycle
```
/tester:ssh bcu-tester-3 boot-capture
```

## Paths on Tester

| Path | Description |
|------|-------------|
| `~/flash-boards/` | Flash scripts (user clone) |
| `/qatools/flash-boards/` | NAS version (read-only, don't modify) |
| `/var/lib/tftpboot/` | TFTP directory for flash images |
| `/dev/snt_ap` | Serial console device |
| `/tmp/` | Temporary files |

## Notes

- Commands run as current user (jay.lee)
- Some operations require sudo (fuser, etc.)
- Serial port is `/dev/snt_ap` -> `/dev/ttyUSB0`
