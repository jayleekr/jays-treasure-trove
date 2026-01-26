# Tester Flash Operations

Flash firmware to CCU2 boards via tester machines using `~/flash-boards/flash.py`.

## Usage
```
/tester:flash <tester> <mode> [options]
```

## Parameters

### Required
- `<tester>`: Target tester machine (e.g., `bcu-tester-3`, `ccu2-tester-1`)
- `<mode>`: Flash mode
  - `mcu` - Flash MCU/BL2 to QSPI
  - `uboot` - Flash FIP to eMMC
  - `ap` - Flash AP partitions via fastboot
  - `all` - Flash all components

### Options for Partial Flash (MCU mode)
- `--addr <hex>`: Start address (e.g., `0x280000` for BL2)
- `--size <hex>`: Size to flash (optional, uses file size if omitted)
- `--file <path>`: Specific file to flash (e.g., `/var/lib/tftpboot/a53_bl.bin`)

### Other Options
- `-i <path>`: Image source (tarball or jenkins job)
- `-r`: Reflash existing extracted image
- `-e`: Erase MCU memory before flashing

## Implementation

Uses `~/flash-boards/flash.py` on the tester:

```bash
# Full MCU flash
ssh <tester> "cd ~/flash-boards && python3 flash.py -m mcu -r"

# Partial flash (BL2 only)
ssh <tester> "cd ~/flash-boards && python3 flash.py -m mcu \
  --addr 0x280000 --file /var/lib/tftpboot/a53_bl.bin"
```

## Examples

### Flash BL2 only to 0x280000
```
/tester:flash bcu-tester-3 mcu --addr 0x280000 --file /var/lib/tftpboot/a53_bl.bin
```

### Full MCU flash with existing image
```
/tester:flash bcu-tester-3 mcu -r
```

### Flash specific a53_bl.bin (built fresh)
```
/tester:flash bcu-tester-3 mcu --addr 0x280000 \
  --file /var/lib/tftpboot/a53_bl.bin
```

## flash.bin Memory Layout

```
0x000000 ~ 0x27FFFF: MCU + HSE firmware
0x280000 ~ 0x2FFFFF: BL2/a53_bl.bin (512KB)
0x300000 ~ 0x1FFFFFF: Reserved
```

**Key offset**: BL2 starts at `0x280000`

## Environment

### Tester Paths
- **flash-boards repo**: `~/flash-boards/`
- **TFTP directory**: `/var/lib/tftpboot/`
- **Serial port**: `/dev/snt_ap`

## Notes

- Uses `~/flash-boards/flash.py` (modified with --addr, --size, --file options)
- Partial flash skips full memory erase (safe for MCU/HSE regions)
- BL2 region (0x280000-0x300000) is independent from MCU/HSE
