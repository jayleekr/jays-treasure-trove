# ISIR Tool Complete Reference

Comprehensive documentation for isir.py command-line interface.

## Tool Location

`/home/jay.lee/ccu-2.0/isir.py`

## Data Source

Violation reports: `https://ops.us.sonatus.com/ccu2-misra/`

## Basic Syntax

```bash
./isir.py -m <module> -c <checker> [flags]
```

## Required Arguments

### -m, --module <name>
Specifies the CCU-2.0 component to analyze.

Valid values:
- container-manager
- vam
- libsntxx
- libsnt_vehicle
- libsntlogging
- diagnostic-manager
- dpm
- ethnm
- rta
- seccommon
- soa

### -c, --checker <type>
Specifies which coding standard checker to use.

Valid values:
- `MISRA` - MISRA-C 2023 rules only
- `Cert-CPP` - CERT C++ Coding Standard only
- `all` - Both MISRA and CERT-CPP

## Analysis Flags

### -d, --dry-run
Show violation statistics without modifying files.

Output format:
```
Total violations: XXXX
	MISRA violations: XXXX
		misra_X_Y_Z.xml violations: XXX
		...
	Cert-CPP violations: XXX
		cert_RULE.xml violations: XX
		...
```

Use for initial analysis and prioritization.

### -sd, --dry-suppress <rule>
Show detailed information for specific rule violations.

Arguments:
- `<rule>`: Rule number (e.g., 8.2.5 for MISRA, CONST30 for CERT)

Output includes:
- All file locations with violations
- Line numbers
- Violation messages
- Documentation URL

Example:
```bash
./isir.py -m container-manager -c MISRA -sd 8.2.5
```

Output:
```
Rule: misra_cpp_2023_rule_8.2.5
Documentation: https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule8_2_5.html

Violations:
  ./container-manager/src/manager.cxx:145
    Message: Unsafe cast from void* to Type*

  ./container-manager/src/security.cxx:67
    Message: Cast removes const qualifier
  ...
```

## Suppression Flags

### -sa, --auto-suppress
Automatically suppress all violations using predefined messages.

Behavior:
- Reads suppression_message() function for predefined justifications
- Inserts coverity suppression comments in source files
- Only processes rules with predefined messages
- Skips rules without predefined messages (requires manual)

Example:
```bash
./isir.py -m container-manager -c MISRA -sa
```

### -s, --suppress <rule> <reason>
Manually suppress all violations of specific rule with custom justification.

Arguments:
- `<rule>`: Rule number (X.Y.Z for MISRA, RULE for CERT)
- `<reason>`: Custom justification message (quoted)

Example:
```bash
./isir.py -m container-manager -c MISRA -s 8.2.5 "Safe cast verified by security review"
```

Generated suppression:
```cpp
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] Safe cast verified by security review
dangerous_cast = static_cast<Type*>(ptr);
```

### -sif, --suppress-if <rule> <reason> <when>
Conditionally suppress violations based on pattern matching.

Arguments:
- `<rule>`: Rule number
- `<reason>`: Justification message
- `<when>`: Pattern to match in violation message or context

Example:
```bash
./isir.py -m container-manager -c MISRA -sif 8.2.5 "3rd party API requires cast" "boost::"
```

Only suppresses rule 8.2.5 violations where violation context contains "boost::".

### -n, --not
Negates the condition for --suppress-if.

Example:
```bash
./isir.py -m container-manager -c MISRA -sif 8.2.5 "Our code cast" "boost::" -n
```

Suppresses rule 8.2.5 violations where context does NOT contain "boost::".

## Data Management Flags

### -l, --latest
Use local XML reports instead of downloading from ops server.

Behavior:
- Looks for XML files in `./<module>.misra.xml/` directory
- Expected file format: `*_<rule>.errors.xml`
- Example: `misra_8_2_5.errors.xml`, `cert_CONST30.errors.xml`

Use when:
- User provides up-to-date XML reports
- Ops server is inaccessible
- Working with specific report snapshot

Setup:
```bash
# ⚠️ LOCAL MODE (-l) IS NOT FUNCTIONAL
# ISIR requires remote download mode

# Always use remote download
./isir.py -m container-manager -c MISRA -d
```

### -f, --fresh
Clear cache and force re-download from ops server.

Behavior:
- Deletes cached XML reports
- Downloads fresh reports from ops server
- Useful when reports have been updated

Example:
```bash
./isir.py -m container-manager -c MISRA -f -d
```

## Cache Location

Cached reports stored in: `./.cache/isir/<module>/<checker>/`

Example structure:
```
.cache/
└── isir/
    └── container-manager/
        └── MISRA/
            ├── misra_8_2_5.errors.xml
            ├── misra_7_0_2.errors.xml
            └── ...
```

## Suppression Message Dictionary

Located in isir.py lines 165-206.

Function signature:
```python
def suppression_message(rule_name: str) -> Optional[str]:
    mappings = {
        '8.2.5': 'This is the correct, required cast',
        '7.0.2': 'False positive, or legitimate',
        ...
    }
    return mappings.get(rule_name)
```

Returns:
- Predefined message string if rule has entry
- `None` if rule requires custom justification

**40+ rules have predefined messages** (as of v1.1.0)

Sample entries:
| Rule | Message |
|------|---------|
| 0.1.2 | Intentionally ignored |
| 4.6.1 | False positive |
| 5.13.3 | Canonical POSIX representation for permissions |
| 6.4.2 | Intentionally not virtual; no pointer to base |
| 7.0.4 | Bitwise operations don't care about type |
| 8.2.5 | This is the correct, required cast |
| 8.2.10 | Recursion required by problem domain |
| 19.3.3 | This is a correct variadic macro |
| 21.6.2 | Dynamic memory handling required |

## Completion Tracking

Located in isir.py lines 209-213.

Function signature:
```python
def is_done(rule_name: str) -> bool:
    if r := MisraRule.rule_number(rule_name):
        return r in (
            # Tuple of completed rule numbers
            '8.2.5',
            '7.0.2',
            ...
        )
    return False
```

Purpose:
- Track which rules have been fully suppressed
- Prevent re-processing completed rules
- Enable incremental workflow

Update after completing rule suppression:
```python
def is_done(rule_name: str) -> bool:
    if r := MisraRule.rule_number(rule_name):
        return r in (
            '8.2.5',  # Previously completed
            'X.Y.Z',  # Newly completed - add here
        )
    return False
```

## Rule Naming Conventions

### MISRA Rules
Format: `X.Y.Z` (three numeric components)

Examples:
- 8.2.5 - Type casting
- 7.0.2 - Type conversions
- 19.3.3 - Variadic macros

XML file format: `misra_X_Y_Z.errors.xml` (underscores instead of dots)

Coverity format: `misra_cpp_2023_rule_X_Y_Z_violation`

### CERT-CPP Rules
Format: `RULE-CPP` or `RULE` (alphanumeric identifier)

Examples:
- CONST30-CPP
- DCL50-CPP
- EXP55-CPP

XML file format: `cert_RULE.errors.xml`

Coverity format: `cert_RULEcpp_violation`

## Documentation URLs

### MISRA Rules
Template: `https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule<X>_<Y>_<Z>.html`

Example for rule 8.2.5:
`https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule8_2_5.html`

### CERT-CPP Rules
Template: `https://uk.mathworks.com/help/bugfinder/ref/cert<RULE>cpp.html`

Example for CONST30-CPP:
`https://uk.mathworks.com/help/bugfinder/ref/certconst30cpp.html`

## Blacklist / File Exclusions

Some files are automatically excluded from suppression:

Categories:
- Vendor code (third-party libraries)
- Generated code (auto-generated AUTOSAR bindings)
- Examples and tests (sample code)

Check isir.py source for current blacklist logic.

## Dependencies

Required Python packages:
- requests - HTTP client for downloading reports
- beautifulsoup4 - HTML/XML parsing
- lxml - XML parser backend
- cpp-demangle - C++ symbol demangling

Install all:
```bash
pip3 install requests beautifulsoup4 lxml cpp-demangle
```

Check installation:
```bash
python3 -c "import requests, bs4, lxml, cpp_demangle; print('All dependencies installed')"
```

## Error Messages

Common error messages and solutions:

**"ModuleNotFoundError: No module named 'requests'"**
- Solution: `pip3 install requests beautifulsoup4 lxml cpp-demangle`

**"Error downloading report from server"**
- Solution: Check network connection, try `--latest` with local XML

**"No violations found for module X"**
- Solution: Verify module name is correct, check ops server has reports

**"Line number mismatch in file.cxx:145"**
- Solution: Code has changed since report generated, use fresh reports

**"Invalid rule format: ABC"**
- Solution: Use X.Y.Z format for MISRA, RULE format for CERT-CPP

## Best Practices

1. **Always start with dry-run**: `./isir.py -m <module> -c <checker> -d`
2. **Use fresh reports**: Run with `-f` periodically to get latest violations
3. **Review changes**: Always `git diff` before committing suppressions
4. **Update tracking**: Add completed rules to `is_done()` function
5. **Commit frequently**: One commit per rule or per auto-suppress run
6. **Test after suppression**: Build module to verify no compilation errors

## Common Workflows

### Quick Auto-Suppression
```bash
# 1. Analysis
./isir.py -m container-manager -c MISRA -d

# 2. Auto-suppress
./isir.py -m container-manager -c MISRA -sa

# 3. Review
git diff

# 4. Commit
git add .
git commit -m "[MISRA] Auto-suppress violations"
```

### Targeted Rule Suppression
```bash
# 1. Find worst offender
./isir.py -m container-manager -c MISRA -d

# 2. See rule details
./isir.py -m container-manager -c MISRA -sd 8.2.5

# 3. Suppress with custom reason
./isir.py -m container-manager -c MISRA -s 8.2.5 "Reviewed and verified safe"

# 4. Commit
git add .
git commit -m "[MISRA] Suppress rule 8.2.5: Reviewed and verified safe"
```

### Using Local Reports
```bash
# 1. Setup directory
mkdir -p ./container-manager.misra.xml/

# 2. Download from remote server
./isir.py -m container-manager -c MISRA -d

# 3. Auto-suppress violations
./isir.py -m container-manager -c MISRA -sa -d
```
