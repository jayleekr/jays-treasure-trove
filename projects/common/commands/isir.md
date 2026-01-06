---
description: MISRA-C/CERT-CPP compliance analysis and violation suppression guidance
---

# ISIR Command - Interactive Code Compliance

Analyze MISRA-C 2023 and CERT-CPP violations with intelligent suppression workflow.

## Task

1. **Context Detection**
   - Identify module from argument or current directory
   - Detect checker type (MISRA, CERT-CPP, or both)
   - Check for local XML reports vs remote fetch

2. **Violation Analysis**
   - Download/cache violation reports from ops server
   - Parse XML reports and filter by module
   - Group violations by rule and file
   - Sort by frequency and severity

3. **Suppression Strategy**
   - Show rule statistics and worst offenders
   - Explain rule with documentation links
   - Suggest suppression approach (auto vs manual)
   - Generate suppression comments

4. **Workflow Guidance**
   - Explain branch strategy (base → output)
   - Guide through iterative suppression
   - Track progress with rule completion

## Usage

```bash
# Initial analysis - see violation overview
/isir container-manager MISRA

# Analyze specific rule violations
/isir container-manager MISRA 8.2.5

# Auto-suppress violations with predefined messages
/isir container-manager MISRA --auto-suppress

# Manual suppression with custom reason
/isir container-manager MISRA 8.2.5 "This cast is safe and required"

# Use local XML reports (when provided by user)
/isir container-manager MISRA --latest
```

## ISIR Tool Overview

**What**: Python tool for managing MISRA-C 2023 and CERT-CPP compliance violations

**Where**: `/home/jay.lee/ccu-2.0/isir.py`

**Data Source**: https://ops.us.sonatus.com/ccu2-misra/

**Supported Modules**: All CCU-2.0 components (container-manager, vam, libsntxx, etc.)

## Workflow Pattern

### Phase 1: Initial Analysis
```bash
./isir.py -m <module> -c MISRA -d
# Shows all violations sorted by quantity
# Identifies worst offenders
```

**Output**: Violation statistics by rule
```
Total violations: 1523
	MISRA violations: 1523
		misra_8.2.5.xml violations: 342
		misra_7.0.2.xml violations: 215
		...
```

### Phase 2: Branch Setup
```bash
# Checkout base branch (where report was generated)
git checkout <base-branch>

# Create output branch for suppressions
git checkout -b <output-branch>
```

### Phase 3: Auto-Suppression
```bash
./isir.py -m <module> -c MISRA -sa
# Auto-suppress all violations with predefined messages
# Uses dictionary at line 165 (suppression_message function)
```

**Generates**: Coverity suppression comments
```cpp
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] This is the correct, required cast
dangerous_cast = static_cast<Type*>(ptr);
```

### Phase 4: Manual Suppression (Iterative)
```bash
# 1. Identify next worst offender
./isir.py -m <module> -c MISRA -d

# 2. See violation details for specific rule
./isir.py -m <module> -c MISRA -sd 8.2.5

# 3. Suppress with custom message
./isir.py -m <module> -c MISRA -s 8.2.5 'This cast is safe and required'

# 4. Review and commit
git add .
git commit -m "[MISRA] Suppress rule 8.2.5 violations"

# 5. Mark rule as done (edit isir.py line 209)
# Add to is_done() function: '8.2.5',

# 6. Cherry-pick to output branch
git checkout <output-branch>
git cherry-pick <base-branch>

# 7. Reset base for next iteration
git checkout <base-branch>
git reset --hard HEAD~

# 8. Repeat for next rule
```

## Checker Types

### MISRA-C 2023
- **Mandatory Rules**: Must be followed (116 rules)
- **Advisory Rules**: Recommended (53 rules)
- **Documentation**: https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule*.html

### CERT-CPP
- **SEI CERT C++ Coding Standard**
- **Documentation**: https://uk.mathworks.com/help/bugfinder/ref/cert*cpp.html

## Key Flags

### Analysis Flags
- `-d, --dry-run` - Show statistics without modifying files
- `-sd, --dry-suppress <rule>` - Show details for specific rule violations
- `-l, --latest` - Use local XML files in `<module>.misra.xml/` folder

### Suppression Flags
- `-sa, --auto-suppress` - Auto-suppress with predefined messages
- `-s, --suppress <rule> <reason>` - Manually suppress all violations of rule
- `-sif, --suppress-if <rule> <reason> <when>` - Conditional suppression
- `-n, --not` - Negate condition for --suppress-if

### Data Management Flags
- `-f, --fresh` - Clear cache, force re-download from ops server
- `-m, --module` - Component name (required)
- `-c, --checker` - MISRA, Cert-CPP, or all (required)

## Rule Suppression Dictionary

Pre-defined auto-suppression messages (line 165):

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
| ... | (40+ rules defined) |

## Example Workflows

### Quick Auto-Suppression
```bash
# Download reports and auto-suppress everything possible
/isir container-manager MISRA --auto-suppress

# Review changes
git diff

# Commit
git commit -m "[MISRA] Auto-suppress violations with standard messages"
```

### Targeted Rule Suppression
```bash
# Analyze rule 8.2.5 violations
/isir container-manager MISRA 8.2.5

# Shows:
# - All file locations
# - Line numbers
# - Violation messages
# - Documentation link

# Suppress with custom justification
/isir container-manager MISRA 8.2.5 "Safe cast verified by review"
```

### Working with Local XML Reports
```bash
# User provides up-to-date XML reports
# Place in: ./container-manager.misra.xml/

# Analyze local reports
/isir container-manager MISRA --latest

# Auto-suppress
/isir container-manager MISRA --latest --auto-suppress
```

## Command Behavior

**This command will**:
- Explain the isir.py workflow and best practices
- Show violation statistics and rule documentation
- Generate suppression commands for copy-paste execution
- Guide through branch management strategy
- Suggest next steps based on violation analysis

**This command will NOT**:
- Execute isir.py directly (shows commands for user to run)
- Modify source code (user runs actual suppression)
- Change git branches (user manages workflow)

## Integration with Git Workflow

### Branch Strategy
```
base (clean, matches report)
  ↓ create
output (accumulates suppressions)
  ↓ iterative
base commits → cherry-pick to output
```

### Iteration Pattern
1. Work on `base` branch
2. Suppress one rule at a time
3. Commit on `base`
4. Cherry-pick to `output`
5. Reset `base` to keep line numbers stable
6. Repeat

**Why this pattern?**
- Line numbers stay consistent between iterations
- Output branch accumulates all suppressions
- Each rule suppression is atomic and reviewable

## Troubleshooting

### Missing Dependencies
```bash
# Install in dev container
pip3 install requests beautifulsoup4 lxml cpp-demangle
```

### Local XML Reports
```bash
# ⚠️ LOCAL MODE (-l) IS NOT FUNCTIONAL
# ISIR only works in remote download mode

# Always use remote download
./isir.py -m container-manager -c MISRA -d

# Force fresh download (clear cache)
./isir.py -m container-manager -c MISRA -f -d
```

### Rule Not Auto-Suppressing
- Check if rule has entry in `suppression_message()` (line 165)
- Add custom message to dictionary if needed
- Or use manual `-s` flag with explicit reason

## Documentation Links

**MISRA Rules**: https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule{X}.{Y}.{Z}.html

**CERT-CPP Rules**: https://uk.mathworks.com/help/bugfinder/ref/cert{RULE}cpp.html

**Report Server**: https://ops.us.sonatus.com/ccu2-misra/

## Next Steps After Suppression

1. **Run PR Checks**: `./build.py --module <module> --pr-check`
2. **Build Clean**: Verify suppressions don't break compilation
3. **Review Changes**: Ensure suppressions are justified
4. **Update Tracker**: Mark rules as done in `is_done()` function
5. **Create PR**: Submit suppressions for review

## Important Notes

⚠️ **Line Number Stability**: Always work from base branch for suppressions, cherry-pick to output
⚠️ **Rule Classification**: MISRA has mandatory (must fix) vs advisory (recommended)
⚠️ **Blacklist**: Some files auto-excluded (vendor code, examples, generated code)
⚠️ **Reports**: Server reports updated weekly, request fresh XML for accuracy
⚠️ **Justification**: Every suppression needs valid technical justification
