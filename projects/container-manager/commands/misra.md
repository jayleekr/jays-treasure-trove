# /misra - MISRA Compliance Information (Execution Blocked)

⚠️ **MISRA EXECUTION BLOCKED**: This session cannot run static analysis tools.

## What This Command Can Do
- ✅ Parse build.toml for MISRA rules configuration
- ✅ Show MISRA fatal rules from build.toml
- ✅ Review recent MISRA violations from commit messages
- ✅ Provide MISRA C++ 2023 compliance guidelines
- ✅ Link to Jenkins MISRA reports
- ✅ Analyze code for potential MISRA violations (code review)
- ❌ Execute static analysis (BLOCKED)

## MISRA Rules Configuration
Parse and display from build.toml:
```toml
[misra]
fatal_rules = [
  "rule_6_7_1",   # Functions with unused parameters
  "rule_8_4_1",   # Compatible declaration
  # ... etc
]

warning_rules = [
  # Non-fatal warnings
]
```

## How to Run MISRA Check

### Jenkins CI/CD (Recommended)
- MISRA analysis runs automatically on PR
- View reports in Jenkins artifacts
- Check for fatal violations blocking merge
- Review warning-level violations

### Manual Check (Requires Build Environment)
```bash
# SSH to builder server
ssh builder-kr-4

# Navigate to project
cd /path/to/container-manager

# Run static analysis
./build.sh --misra-check

# Or through build system
bitbake container-manager -c do_static_analysis
```

## MISRA Compliance Guidelines

### Fatal Rules (Must Pass)
These rules are configured as fatal in build.toml and must pass before merge:
- Rule 6.7.1: Unused function parameters
- Rule 8.4.1: Compatible declarations
- Rule 10.1.1: Implicit conversions
- [See build.toml for complete list]

### Code Review Assistance
This command can help with:
1. **Reviewing code changes** for potential MISRA violations
2. **Explaining MISRA rules** and their rationale
3. **Suggesting fixes** for common violations
4. **Documenting deviations** with proper justification

### Common MISRA Violations
- **Unused parameters**: Remove or use `(void)param`
- **Implicit conversions**: Add explicit casts
- **Magic numbers**: Use named constants
- **Missing const**: Add const for read-only data
- **Include guards**: Use proper header guards

## Recent Violations
Check recent commit messages for MISRA-related fixes:
```bash
git log --grep="MISRA" --oneline -10
```

## MISRA C++ 2023 Standards
- Follow AUTOSAR C++ coding guidelines
- Adhere to safety-critical development practices
- Document all deviations with justification
- Maintain clean static analysis reports

## Resources
- MISRA C++ 2023 Guidelines
- AUTOSAR C++ Coding Guidelines
- Project-specific coding standards in docs/
