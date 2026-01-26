# Tester SCP Operations

Copy files to/from tester machines.

## Usage
```
/tester:scp <direction> <tester> <source> [destination]
```

## Parameters

### Required
- `<direction>`: Transfer direction
  - `to` - Copy local file to tester
  - `from` - Copy file from tester to local
- `<tester>`: Target tester machine (e.g., `bcu-tester-3`)
- `<source>`: Source file path

### Optional
- `[destination]`: Destination path (defaults vary by direction)

## Common Destinations

### On Tester
- `/tmp/` - Temporary files
- `/var/lib/tftpboot/` - TFTP directory (flash images)
- `~/flash-boards/` - Flash scripts

### Local
- `mobis/deploy/` - Build outputs
- `mobis/build-bcu/tmp/deploy/images/mobisccu2/` - Raw build artifacts

## Examples

### Copy image tarball to tester
```
/tester:scp to bcu-tester-3 mobis/deploy/ccu-image.tar.gz /tmp/
```

### Copy specific binary
```
/tester:scp to bcu-tester-3 customs/MOBIS/qy2/flash.bin /var/lib/tftpboot/
```

### Copy boot log from tester
```
/tester:scp from bcu-tester-3 /tmp/boot.log ./
```

### Copy with default destination
```
/tester:scp to bcu-tester-3 mobis/deploy/ccu-image.tar.gz
# -> Copies to /tmp/ccu-image.tar.gz
```

## Workflow

1. **Validate paths**
   - Check source exists
   - Verify tester is reachable

2. **Execute transfer**
   ```bash
   # To tester
   scp <source> <tester>:<destination>

   # From tester
   scp <tester>:<source> <destination>
   ```

3. **Verify transfer**
   - Check file exists at destination
   - Compare sizes if needed

## Notes

- Uses SSH key authentication (no password)
- Large files may take time (ccu-image.tar.gz ~300MB)
- For tarball extraction, use `/tester:flash` with appropriate mode
