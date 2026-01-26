# Tester Boot Log Capture

Capture and analyze boot logs from CCU2 boards.

## Usage
```
/tester:boot-log <tester> [options]
```

## Parameters

### Required
- `<tester>`: Target tester machine (e.g., `bcu-tester-3`)

### Options
- `--timeout <seconds>`: Capture duration (default: 25)
- `--power-cycle`: Power cycle before capture (default: yes)
- `--analyze`: Analyze boot log for known issues
- `--save <path>`: Save log to local file

## Boot Stages Detected

| Stage | Pattern | Description |
|-------|---------|-------------|
| BL2 | `BL2: <version>` | ARM Trusted Firmware BL2 |
| BL31 | `BL31:` | Secure monitor |
| BL33_ENTRYPOINT | `Warning: Instruction at BL33_ENTRYPOINT` | Version mismatch |
| U-Boot | `U-Boot <version>` | Bootloader |
| Linux | `Linux version` | Kernel boot |

## Examples

### Basic capture
```
/tester:boot-log bcu-tester-3
```

### Extended capture with analysis
```
/tester:boot-log bcu-tester-3 --timeout 60 --analyze
```

### Save to file
```
/tester:boot-log bcu-tester-3 --save boot-$(date +%Y%m%d).log
```

### No power cycle (capture current state)
```
/tester:boot-log bcu-tester-3 --no-power-cycle --timeout 5
```

## Analysis Output

### Version Detection
```
BL2 version: 251001A
FIP version: 251201A
Version match: NO - MISMATCH!
```

### Boot Stage Progress
```
[OK] BL2 started
[OK] BL31 started
[WARN] BL33_ENTRYPOINT warning detected
[FAIL] U-Boot not reached
```

### Known Issues
- **BL33_ENTRYPOINT warning**: BL2/FIP version mismatch
- **Failure in post image load**: FIP signature mismatch
- **Cannot enter U-Boot prompt**: Board not booting

## Workflow

1. **Kill serial users**
   ```bash
   sudo fuser -k /dev/snt_ap
   ```

2. **Power cycle** (if enabled)
   ```bash
   usbrelay SNPWR_1=0
   sleep 2
   usbrelay SNPWR_1=1
   ```

3. **Open serial and capture**
   ```python
   ser = serial.Serial('/dev/snt_ap', 115200)
   # Read for timeout duration
   ```

4. **Analyze patterns**
   - Extract versions
   - Check boot stages
   - Identify issues

## Notes

- Serial baud rate: 115200
- Serial port: `/dev/snt_ap` (symlink to `/dev/ttyUSB0`)
- Power cycle delay: 2 seconds off, then on
