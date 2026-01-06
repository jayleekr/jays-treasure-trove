# ISIR Methodology - MISRA-C 2023 & CERT-CPP Compliance

## Overview

**ISIR** = Interactive Systematic Issue Resolution

**Purpose**: Manage MISRA-C 2023 and CERT-CPP coding standard compliance violations through automated suppression workflows

**Tool**: `/home/jay.lee/ccu-2.0/isir.py` (792 lines, Python 3)

**Data Source**: https://ops.us.sonatus.com/ccu2-misra/

**Supported Standards**:
- **MISRA-C 2023**: 169 rules (116 mandatory + 53 advisory)
- **CERT-CPP**: SEI CERT C++ Coding Standard

---

## Tool Architecture

### ⚠️ IMPORTANT: Remote-Only Operation

**ISIR only works in remote mode (`-d` flag)**:
- ✅ **Remote download mode** (`-d`): Downloads violations from ops.us.sonatus.com
- ❌ **Local analysis mode** (`-l`): NOT functional (requires local XML files)
- **Always use**: `isir.py -m <module> -c MISRA -d`

### Core Components

**1. Remote Data Fetcher** (line 343)
```python
class Remote:
    base_url = "https://ops.us.sonatus.com/ccu2-misra/"

    # Downloads XML violation reports from ops server
    # Caches locally for performance
    # Provides folder/file enumeration
```

**2. Violation Parser** (line 394)
```python
class Violation:
    checker: Checker      # MISRA or CERT-CPP
    rule: str            # Rule identifier
    filename: str        # Source file path
    function: str        # Function containing violation
    events: list[CallStackLine]  # Stack trace
```

**3. Rule Engines** (line 142, 259)
```python
class MisraRule:
    # MISRA-C 2023 specific logic
    # Documentation: mathworks.com MISRA reference

class CertCppRule:
    # CERT-CPP specific logic
    # Documentation: mathworks.com CERT reference
```

**4. Suppression Engine** (line 540)
```python
def suppress_all(violations, suppression, suppress_if):
    # Inserts coverity suppression comments
    # Handles line number tracking
    # Preserves code formatting
```

### Data Flow

```
Remote Server (ops.us.sonatus.com)
    ↓ download XML reports
Local Cache (<module>.<checker>.xml/cache/)
    ↓ parse XML
Violation Objects (grouped by rule)
    ↓ filter by module/blacklist
Sorted Violations (by file, line DESC)
    ↓ apply suppression strategy
Modified Source Files (with coverity comments)
```

---

## Coding Standards Reference

### MISRA-C 2023 Rules

**Mandatory Rules** (116 rules - MUST be followed):
```python
# Line 219-241
mandatory = (
    '0.0.1', '0.1.2', '0.2.2', '0.3.2',
    '4.1.1', '4.1.3', '4.6.1',
    '5.7.1', '5.7.3', '5.10.1', '5.13.1-7',
    '6.0.1', '6.0.4', '6.2.1-4', '6.4.1-3', '6.7.1-2', '6.8.1-3', '6.9.1',
    '7.0.1-6', '7.11.1-3',
    '8.1.1', '8.2.1-11', '8.7.1-2', '8.9.1', '8.18.1',
    '9.2.1', '9.3.1', '9.4.1-2', '9.5.2', '9.6.2-5',
    '10.1.2', '10.2.1', '10.2.3', '10.4.1',
    '11.6.2-3', '12.2.2-3', '12.3.1',
    '13.1.2', '13.3.1-4',
    '15.0.1', '15.1.1', '15.1.3', '15.1.5', '15.8.1',
    '16.5.1-2', '17.8.1',
    '18.3.2-3', '18.4.1', '18.8.1-2',
    '19.0.1-2', '19.1.1-3', '19.2.1-3', '19.3.2-5',
    '21.2.1-4', '21.6.2-5', '21.10.1-3',
    '22.3.1', '22.4.1',
    '24.5.1-2', '25.5.1-3',
    '28.3.1', '28.6.1-4',
    '30.0.1-2'
)
```

**Advisory Rules** (53 rules - Recommended):
```python
# Line 242-248
advisory = (
    '0.0.2', '0.1.1', '0.2.1', '0.2.3-4', '0.3.1',
    '4.1.2', '5.0.1', '5.7.2',
    '6.0.2-3', '6.5.1-2', '6.8.4', '6.9.2',
    '8.0.1', '8.1.2', '8.2.7', '8.3.1-2', '8.14.1', '8.18.2', '8.19.1', '8.20.1',
    '9.5.1', '9.6.1',
    '10.0.1', '10.1.1', '10.2.2', '10.3.1',
    '11.3.1-2', '11.6.1',
    '12.2.1', '13.1.1', '14.1.1',
    '15.0.2', '15.1.2', '15.1.4',
    '16.6.1',
    '18.3.1', '18.5.1-2',
    '19.0.3-4', '19.3.1', '19.6.1',
    '21.6.1', '23.11.1', '26.3.1'
)
```

### Rule Categories

**Common Rule Themes**:
- **0.x**: General rules (language use, headers)
- **4.x**: Lexical conventions (comments, identifiers)
- **5.x-7.x**: Expressions and operators
- **8.x**: Declarations and definitions
- **9.x-13.x**: Statements and control flow
- **15.x-16.x**: Functions
- **18.x-19.x**: Templates and preprocessing
- **21.x**: Standard library
- **22.x-24.x**: Resources and exceptions
- **28.x-30.x**: Concurrency

---

## Suppression Comment Format

### MISRA-C 2023 Suppression

**Format**:
```cpp
// coverity[misra_cpp_2023_rule_X_Y_Z_violation:SUPPRESS] Justification message
violating_code();
```

**Generation** (line 160):
```python
def suppress(rule_name: str) -> Optional[str]:
    # Input: "MISRA 8.2.5"
    # Output: "// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS]"
    if r := MisraRule._parse(rule_name):
        return f'// coverity[misra_cpp_2023_rule_{r[0]}_{r[1]}_{r[2]}_violation:SUPPRESS]'
```

**Examples**:
```cpp
// Rule 8.2.5: Pointer cast requires justification
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] This is the correct, required cast
auto* ptr = static_cast<DerivedType*>(base_ptr);

// Rule 7.0.2: Const cast needs explanation
// coverity[misra_cpp_2023_rule_7_0_2_violation:SUPPRESS] False positive, or legitimate
const_cast<int&>(const_value) = 42;

// Rule 21.6.2: Dynamic memory justified
// coverity[misra_cpp_2023_rule_21_6_2_violation:SUPPRESS] Dynamic memory handling required
auto buffer = std::make_unique<uint8_t[]>(size);
```

### CERT-CPP Suppression

**Format**:
```cpp
// coverity[cert_RULE_cpp_violation:SUPPRESS] Justification message
violating_code();
```

**Generation** (line 276):
```python
def suppress(rule_name: str) -> Optional[str]:
    # Input: "CERT EXP50-CPP"
    # Output: "// coverity[cert_exp50_cpp_violation:SUPPRESS]"
    if r := CertCppRule._parse(rule_name):
        return f'// coverity[cert_{r.lower()}_cpp_violation:SUPPRESS]'
```

---

## Predefined Suppression Messages

**Auto-Suppression Dictionary** (line 165-204):

| Rule | Standard Message | Use Case |
|------|------------------|----------|
| 0.1.2 | Intentionally ignored | Deliberate violation |
| 4.6.1 | False positive | Tool misdetection |
| 5.13.3 | Canonical POSIX representation for permissions | Octal file modes |
| 6.2.1 | False positive | Incorrect tool analysis |
| 6.2.3 | Intentional | Deliberate design choice |
| 6.4.2 | Intentionally not virtual; no pointer to base | Non-polymorphic class |
| 6.8.1 | False positive | Tool error |
| 6.9.1 | False positive | Tool error |
| 7.0.1 | False positive | Tool error |
| 7.0.2 | False positive, or legitimate | Cast legitimacy |
| 7.0.4 | Bitwise operations don't care about type | Bitwise logic |
| 7.11.2 | Contains a null-terminated string | C-string handling |
| 8.1.1 | False positive | Tool error |
| 8.2.3 | False positive | Tool error |
| 8.2.5 | This is the correct, required cast | Necessary type conversion |
| 8.2.8 | This cast is safe | Verified safe cast |
| 8.2.10 | Recursion required by problem domain | Legitimate recursion |
| 8.7.1 | 3rd-party software, cannot change | External code |
| 8.7.2 | Intentional, required | Design requirement |
| 8.9.1 | Pointers point to same memory area | Aliasing analysis |
| 9.3.1 | False positive | Tool error |
| 9.5.2 | Intentional, harmless | Safe by design |
| 10.2.3 | 3rd party software, cannot change | External code |
| 12.3.1 | Intentional, required by design | Architecture decision |
| 13.3.3 | Intentional, mocking system function | Test mock |
| 15.0.1 | False positive | Tool error |
| 15.1.3 | Intentional | Design choice |
| 18.4.1 | Generated code | Auto-generated source |
| 19.0.2 | Required at compile time | Compile-time logic |
| 19.3.3 | This is a correct variadic macro | Variadic needed |
| 21.2.2 | Intentional; correct function to use | Proper API usage |
| 21.6.2 | Dynamic memory handling required | Heap allocation needed |
| 21.6.3 | Operation is safe and under control | Verified safe operation |
| 22.4.1 | Intentional, mocking system call | Test mock |
| 24.5.1 | toupper is the required function | Correct API |
| 24.5.2 | Intentional, function must be used | Necessary function |
| 28.6.3 | False positive | Tool error |

---

## File Blacklist

**Purpose**: Exclude files that should NOT be suppressed

**Categories** (line 91-122):

1. **Vendor/3rd Party Code**
   ```python
   '/_vendor/' in path    # External libraries
   '/_env/linux/' in path # Environment-specific
   ```

2. **Examples and Test Code**
   ```python
   '/example/' in path    # Example code
   ```

3. **Generated Code**
   ```python
   # Auto-generated bindings, not manually modified
   ```

4. **Module-Specific Exclusions**:

   **libsnt_vehicle**:
   - KVS (Key-Value Store) subsystem
   - Network protocol layers (ether, ip, ip6)
   - SQLite integration
   - Database proxy layers
   - argparse.hpp (external)

   **libsntxx**:
   - All vendor code in `_vendor/`

---

## Workflow Methodologies

### Phase 1: Initial Analysis

**Goal**: Understand violation landscape and prioritize suppression work

**Commands**:
```bash
# Download and analyze violations (dry-run)
./isir.py -m container-manager -c MISRA -d

# Force fresh download from ops server
./isir.py -m container-manager -c MISRA -d -f
```

**Output Analysis**:
```
Total violations: 1523
	MISRA violations: 1523
		misra_8.2.5.xml violations: 342 ← Worst offender
		misra_7.0.2.xml violations: 215
		misra_15.1.3.xml violations: 189
		misra_12.3.1.xml violations: 156
		...
```

**Prioritization Strategy**:
1. **Highest Count First**: Suppress rules with most violations
2. **Auto-Suppressible**: Target rules with predefined messages
3. **Mandatory vs Advisory**: Focus on mandatory rules first
4. **Module Boundaries**: Group by module/component

---

### Phase 2: Branch Strategy

**Goal**: Maintain stable line numbers across iterations while accumulating suppressions

**Branch Setup**:
```bash
# 1. Checkout base branch (matches ops server report)
git checkout master  # or relevant feature branch

# 2. Create base branch for iterative work
git checkout -b misra-suppression-base

# 3. Create output branch for final result
git checkout -b misra-suppression-output
git checkout misra-suppression-base
```

**Branch Roles**:

**Base Branch** (`misra-suppression-base`):
- Clean state matching violation report line numbers
- Work branch for individual rule suppressions
- Gets reset after each suppression commit

**Output Branch** (`misra-suppression-output`):
- Accumulates all suppressions via cherry-pick
- Never reset, only receives commits
- Final PR branch

**Why This Pattern?**:
- **Line Number Stability**: Base branch reset keeps line numbers matching report
- **Atomic Changes**: Each suppression is isolated commit
- **Reviewability**: Clear history of what was suppressed and why
- **Rollback Safety**: Can drop individual suppressions easily

---

### Phase 3: Auto-Suppression

**Goal**: Quickly suppress all violations with predefined justifications

**Command**:
```bash
# Auto-suppress all rules with predefined messages
./isir.py -m container-manager -c MISRA -sa

# Dry-run to preview changes
./isir.py -m container-manager -c MISRA -sa -d
```

**What Gets Suppressed**:
- All rules in `suppression_message()` dictionary (40+ rules)
- Only violations NOT in blacklist
- Only mandatory/advisory rules (not experimental)

**Generated Suppressions**:
```cpp
// Before:
auto* ptr = static_cast<DerivedType*>(base_ptr);

// After:
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] This is the correct, required cast
auto* ptr = static_cast<DerivedType*>(base_ptr);
```

**Post-Suppression**:
```bash
# Review changes
git diff

# Commit
git add .
git commit -m "[MISRA] Auto-suppress violations with standard justifications"

# Cherry-pick to output branch
git checkout misra-suppression-output
git cherry-pick misra-suppression-base

# Reset base for next iteration
git checkout misra-suppression-base
git reset --hard HEAD~
```

---

### Phase 4: Manual Suppression (Iterative)

**Goal**: Suppress remaining rules one at a time with custom justifications

#### Step 1: Identify Next Target

```bash
# See remaining violations
./isir.py -m container-manager -c MISRA -d

# Output shows next worst offender
Total violations: 842
	MISRA violations: 842
		misra_13.3.1.xml violations: 156 ← Target this
		misra_10.4.1.xml violations: 89
		...
```

#### Step 2: Analyze Rule Violations

```bash
# Show detailed violations for specific rule
./isir.py -m container-manager -c MISRA -sd 13.3.1

# Output:
# File: ./container-manager/src/docker_client.cxx
#   Function: DockerClient::create_container
#     Line: 125, Column: 14
#     Message: Function `json()` has side effects
#   Function: DockerClient::start_container
#     Line: 156, Column: 22
#     Message: Function `to_string()` has side effects
# ...
#
# Documentation: https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule13.3.1.html
```

#### Step 3: Review Rule Documentation

**Read Rule**: Follow documentation link to understand:
- Rule rationale
- Compliant examples
- Non-compliant examples
- Exceptions and edge cases

**Determine Justification**:
- Is this a false positive?
- Is the violation intentional and safe?
- Is there a better coding approach?
- Does violation require architecture change?

#### Step 4: Suppress with Justification

```bash
# Suppress all violations of rule with custom message
./isir.py -m container-manager -c MISRA -s 13.3.1 "Safe side effects in controlled context"

# Conditional suppression (suppress if message matches)
./isir.py -m container-manager -c MISRA -sif 13.3.1 "False positive" "has side effects"

# Negate condition (suppress if message does NOT match)
./isir.py -m container-manager -c MISRA -sif 13.3.1 "Intentional" "has side effects" -n
```

**Suppression Placement**:
```cpp
// The suppression is placed on the line BEFORE the violation
void DockerClient::create_container(const std::string& name, const json& config) {
    // coverity[misra_cpp_2023_rule_13_3_1_violation:SUPPRESS] Safe side effects in controlled context
    auto request = config.json();  // ← Violation here

    // coverity[misra_cpp_2023_rule_13_3_1_violation:SUPPRESS] Safe side effects in controlled context
    send_request(request.to_string());  // ← Another violation
}
```

#### Step 5: Review and Commit

```bash
# Review generated suppressions
git diff

# Verify suppressions are correct
# Check placement, messages, rule numbers

# Commit on base branch
git add .
git commit -m "[MISRA] Suppress rule 13.3.1 - safe side effects"
```

#### Step 6: Mark Rule as Done (Optional)

**Edit isir.py** (line 209):
```python
@staticmethod
def is_done(rule_name: str) -> bool:
    if r := MisraRule.rule_number(rule_name):
        return r in (
            '13.3.1',  # ← Add completed rule
        )
    return False
```

**Purpose**: Filter out completed rules from future analysis

#### Step 7: Cherry-Pick to Output

```bash
# Switch to output branch
git checkout misra-suppression-output

# Cherry-pick the suppression commit
git cherry-pick misra-suppression-base

# Success! Output branch now has this suppression
```

#### Step 8: Reset Base Branch

```bash
# Switch back to base
git checkout misra-suppression-base

# Reset to before suppression commit
git reset --hard HEAD~

# Base branch is now clean again, matching original line numbers
```

#### Step 9: Repeat

```bash
# Go back to Step 1
./isir.py -m container-manager -c MISRA -d
# Identify next target rule...
```

---

### Phase 5: Final Review

**Goal**: Validate all suppressions before creating PR

#### Build Verification

```bash
# Full clean build
python build.py --target container-manager --clean
python build.py --target container-manager --build-type Debug

# Ensure suppressions don't break compilation
# Check for syntax errors in suppression comments
```

#### Test Execution

```bash
# Run unit tests
python build.py --target container-manager --test

# Run integration tests (if applicable)
# Verify suppressions don't mask real issues
```

#### PR Checks

```bash
# Run PR validation
./build.py --target container-manager --pr-check

# Check MISRA status
# Should show reduced violation count
```

#### Code Review Preparation

```bash
# Switch to output branch
git checkout misra-suppression-output

# Review full diff
git diff master

# Count suppressions
git diff master | grep -c "coverity\[misra"

# Generate commit summary
git log --oneline master..HEAD
```

---

## Advanced Techniques

### Conditional Suppression

**Use Case**: Different justifications for same rule based on context

**Suppress if message matches**:
```bash
# Suppress only violations with "has side effects" in message
./isir.py -m container-manager -c MISRA -sif 13.3.1 "Intentional side effects" "has side effects"
```

**Suppress if message does NOT match**:
```bash
# Suppress all EXCEPT "has side effects"
./isir.py -m container-manager -c MISRA -sif 13.3.1 "False positive" "has side effects" -n
```

### Local XML Analysis

**Use Case**: User provides updated XML reports (fresher than ops server)

**Setup**:
```bash
# ⚠️ LOCAL MODE NOT FUNCTIONAL - USE REMOTE MODE ONLY
# Local analysis (-l flag) requires local XML files but doesn't work
# Always use remote download mode (-d flag)

# Download from remote server (RECOMMENDED)
./isir.py -m container-manager -c MISRA -d
```

**XML Naming Convention**:
- Ops server format: `misra.X.Y.Z.xml` (e.g., `misra.8.2.5.xml`)
- Tool normalizes: lowercase, replace `-` and `/` with `_`

### Cache Management

**Cache Location**: `./<module>.<checker>.xml/cache/`

**Clear Cache**:
```bash
# Force fresh download
./isir.py -m container-manager -c MISRA -f

# Manual cache clear
rm -rf ./container-manager.misra.xml/cache/
```

**Cache Benefits**:
- Fast re-analysis without re-downloading
- Offline work capability
- Bandwidth savings

---

## Command Reference

### Core Options

| Flag | Long Form | Arguments | Description |
|------|-----------|-----------|-------------|
| `-m` | `--module` | `<module>` | **Required**. Component name (e.g., container-manager) |
| `-c` | `--checker` | `<checker>` | **Required**. MISRA, Cert-CPP, or all |

### Analysis Modes

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-d` | `--dry-run` | Show statistics without modifying files |
| `-sd` | `--dry-suppress <rule>` | Show detailed violations for specific rule |
| `-l` | `--latest` | Use local XML files in `<module>.<checker>.xml/` |
| `-f` | `--fresh` | Clear cache and force download from ops server |

### Suppression Modes

| Flag | Long Form | Arguments | Description |
|------|-----------|-----------|-------------|
| `-sa` | `--auto-suppress` | - | Auto-suppress with predefined messages |
| `-s` | `--suppress` | `<rule> <reason>` | Manually suppress all violations of rule |
| `-sif` | `--suppress-if` | `<rule> <reason> <when>` | Conditional suppression (if message matches) |
| `-n` | `--not` | - | Negate condition for `--suppress-if` |

### Examples

```bash
# Initial analysis (dry-run)
./isir.py -m container-manager -c MISRA -d

# Show details for specific rule
./isir.py -m container-manager -c MISRA -sd 8.2.5

# Auto-suppress all with predefined messages
./isir.py -m container-manager -c MISRA -sa

# Manual suppression with custom reason
./isir.py -m container-manager -c MISRA -s 8.2.5 "This cast is safe and required"

# Conditional suppression (if message contains "pointer")
./isir.py -m container-manager -c MISRA -sif 8.2.5 "Safe pointer cast" "pointer" -d

# Negate condition (suppress all EXCEPT those with "pointer")
./isir.py -m container-manager -c MISRA -sif 8.2.5 "Non-pointer cast" "pointer" -n -d

# Force fresh download (clear cache) and analyze
./isir.py -m container-manager -c MISRA -f -d

# Analyze CERT-CPP violations
./isir.py -m container-manager -c Cert-CPP -d

# Analyze both MISRA and CERT-CPP
./isir.py -m container-manager -c all -d
```

---

## Documentation Resources

### MISRA-C 2023

**Official Documentation**: https://misra.org.uk/

**MathWorks Reference** (used by isir.py):
```
https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule{X}.{Y}.{Z}.html

Examples:
- Rule 8.2.5: https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule8.2.5.html
- Rule 13.3.1: https://uk.mathworks.com/help/bugfinder/ref/misracpp2023rule13.3.1.html
```

**Rule Categories**:
- **0.x**: General
- **4.x**: Lexical conventions
- **5.x-7.x**: Expressions
- **8.x**: Declarations
- **9.x-13.x**: Statements
- **15.x-16.x**: Functions
- **18.x-19.x**: Templates and preprocessing
- **21.x**: Standard library
- **22.x-28.x**: Resources and concurrency
- **30.x**: Exception safety

### CERT-CPP

**Official Documentation**: https://wiki.sei.cmu.edu/confluence/pages/viewpage.action?pageId=88046682

**MathWorks Reference**:
```
https://uk.mathworks.com/help/bugfinder/ref/cert{RULE}cpp.html

Examples:
- EXP50-CPP: https://uk.mathworks.com/help/bugfinder/ref/certexp50cpp.html
- DCL50-CPP: https://uk.mathworks.com/help/bugfinder/ref/certdcl50cpp.html
```

### Ops Server

**URL**: https://ops.us.sonatus.com/ccu2-misra/

**Structure**:
```
/ccu2-misra/
├── container-manager/
│   ├── MISRA/
│   │   ├── misra.0.1.2.xml
│   │   ├── misra.8.2.5.xml
│   │   └── ...
│   └── Cert-CPP/
│       ├── cert-cpp.exp50.xml
│       └── ...
├── vam/
├── libsntxx/
└── ...
```

**Update Frequency**: Weekly (typically Monday mornings)

**Access**: Internal network only

---

## Best Practices

### Suppression Quality

**1. Always Provide Meaningful Justification**
```cpp
// ❌ BAD: Generic, unhelpful
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] MISRA violation

// ✅ GOOD: Specific, technical reason
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] Cast required for Docker API compatibility
```

**2. Verify Suppressions Are Necessary**
- Can code be refactored to avoid violation?
- Is suppression masking a real issue?
- Are there cleaner alternatives?

**3. Group Related Suppressions**
```cpp
// If multiple violations in same function for same reason:
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] JSON library requires type erasure
auto json_ptr = static_cast<json_value*>(generic_ptr);
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] JSON library requires type erasure
auto string_ptr = static_cast<json_string*>(json_ptr);
```

### Workflow Efficiency

**1. Start with Auto-Suppression**
- Eliminates 40+ rules immediately
- Reduces manual work by ~60-80%
- Predefined messages are peer-reviewed

**2. Prioritize High-Volume Rules**
- Suppress worst offenders first
- Each suppression has biggest impact
- Builds momentum

**3. Batch Related Rules**
- Suppress all cast-related rules together (8.2.x)
- Group by component or file
- Maintain focus and context

**4. Use Dry-Run Extensively**
- Always preview with `-d` flag first
- Verify rule counts
- Check file modifications

**5. Commit Frequently**
- One rule per commit (or small related groups)
- Clear commit messages
- Easy to review and rollback

### Branch Management

**1. Keep Base Clean**
- Base branch matches ops report exactly
- Reset after every suppression
- Never push base branch

**2. Output is Truth**
- Output branch accumulates all work
- Only branch that gets pushed
- Use for PR creation

**3. Cherry-Pick, Don't Merge**
- Preserves commit atomicity
- Maintains clean history
- Easier to drop individual changes

### Code Review

**1. Review Suppressions Critically**
- Challenge generic justifications
- Verify technical accuracy
- Ensure no masking of real bugs

**2. Document Suppression Strategy**
- PR description explains approach
- Summarize rules suppressed
- Note any outstanding issues

**3. Incremental PRs**
- Don't suppress everything in one PR
- Break into reviewable chunks
- Allows focused review

---

## Troubleshooting

### Issue: Missing Dependencies

**Symptoms**:
```bash
./isir.py -m container-manager -c MISRA -d
Traceback (most recent call last):
  File "./isir.py", line 5, in <module>
    import requests
ModuleNotFoundError: No module named 'requests'
```

**Solution**:
```bash
# Install in dev container
pip3 install requests beautifulsoup4 lxml cpp-demangle

# Or use system package manager
apt-get install python3-requests python3-bs4 python3-lxml
```

### Issue: Cache Corruption

**Symptoms**:
- Incorrect violation counts
- XML parse errors
- Stale data

**Solution**:
```bash
# Clear cache and re-download
./isir.py -m container-manager -c MISRA -f -d

# Manual cache clear
rm -rf ./container-manager.misra.xml/cache/
```

### Issue: Line Number Mismatches

**Symptoms**:
- Suppressions placed on wrong lines
- Can't find violation location

**Root Cause**:
- Code changed after report generation
- Base branch doesn't match report

**Solution**:
```bash
# Reset to commit that matches report
git log --oneline  # Find report generation commit
git checkout <commit-sha>

# Create fresh base branch
git checkout -b misra-suppression-base-v2

# Re-run suppression
./isir.py -m container-manager -c MISRA -sa
```

### Issue: Suppression Not Applied

**Symptoms**:
- Violation still shows in report
- Suppression comment present but ignored

**Possible Causes**:

**1. Wrong Rule Format**
```cpp
// ❌ WRONG: Incorrect rule number format
// coverity[misra_cpp_rule_8_2_5_violation:SUPPRESS] Message

// ✅ CORRECT: Must be "misra_cpp_2023_rule_..."
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] Message
```

**2. Suppression on Wrong Line**
```cpp
// ❌ WRONG: Suppression after violation
auto* ptr = static_cast<Type*>(base);
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] Message

// ✅ CORRECT: Suppression before violation
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] Message
auto* ptr = static_cast<Type*>(base);
```

**3. Missing Justification**
```cpp
// ❌ WRONG: No message after SUPPRESS
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS]
auto* ptr = static_cast<Type*>(base);

// ✅ CORRECT: Message required
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] This cast is safe
auto* ptr = static_cast<Type*>(base);
```

### Issue: Rule Not Auto-Suppressing

**Symptoms**:
- Rule has violations but not suppressed by `-sa`

**Cause**: Rule not in suppression dictionary

**Solution**:

**1. Check if rule is in dictionary** (line 165):
```python
@staticmethod
def suppression_message(rule_name: str) -> Optional[str]:
    mappings = {
        '8.2.5': 'This is the correct, required cast',
        # ... rule not present ...
    }
    if r := MisraRule.rule_number(rule_name):
        return mappings.get(r)  # Returns None if not found
```

**2. Add to dictionary**:
```python
# Edit isir.py
mappings = {
    # ... existing rules ...
    '13.3.1': 'Safe side effects in controlled context',  # ← Add new rule
}
```

**3. Or use manual suppression**:
```bash
./isir.py -m container-manager -c MISRA -s 13.3.1 "Custom message"
```

### Issue: Blacklisted Files Still Show

**Symptoms**:
- Vendor code shows violations
- Example files appear in report

**Cause**: Blacklist needs updating

**Solution**:

**Edit isir.py** (line 91-122):
```python
@staticmethod
def includes(module: str, path: str) -> bool:
    if module == 'container-manager':
        return '/vendor/' in path \
            or '/examples/' in path \
            or path.endswith('/external.hpp') \
            or False  # ← Add more patterns
    # ...
```

### Issue: Network Connection Failed

**Symptoms**:
```
requests.exceptions.ConnectionError: Failed to establish connection
```

**Solutions**:

**1. Check VPN**:
```bash
# Ops server requires internal network access
# Verify VPN connection
```

**2. Force Fresh Download**:
```bash
# Clear cache and force fresh download
./isir.py -m container-manager -c MISRA -f -d
```

**3. Verify Server Status**:
```bash
curl https://ops.us.sonatus.com/ccu2-misra/
```

---

## Integration with CCU-2.0 Workflow

### Build Integration

**PR Checks**:
```bash
# Build system checks MISRA compliance
./build.py --target container-manager --pr-check

# Should show reduced violation count after suppression
```

**CI/CD Pipeline**:
- Jenkins builds check MISRA status
- Violations reported but don't block (currently)
- Trend tracking over time

### Git Workflow

**Branch Naming**:
```bash
# Standard format
<component>-misra-suppression

# Examples
container-manager-misra-suppression
vam-cert-cpp-suppression
libsntxx-misra-cert-suppression
```

**Commit Message Format**:
```
[MISRA|CERT-CPP] Brief description

Detailed explanation:
- Rules suppressed: X.Y.Z, A.B.C
- Justification summary
- Violation count: Before 1523 → After 342

Ticket: CCU2-XXXXX (if applicable)
```

**PR Template**:
```markdown
## MISRA/CERT-CPP Suppression

### Component
container-manager

### Rules Suppressed
- 8.2.5: Type casts (342 violations) - Required for API compatibility
- 7.0.2: Const casts (215 violations) - Legacy interface requirements
- 13.3.1: Side effects (156 violations) - Safe in controlled contexts

### Suppression Strategy
- Auto-suppression: 40 rules with predefined messages
- Manual suppression: 3 rules with custom justifications
- Total violations: 1523 → 342 (77% reduction)

### Validation
- ✅ Clean build (Debug and Release)
- ✅ All unit tests pass
- ✅ PR checks pass
- ✅ No new violations introduced

### Remaining Work
- Rules 10.4.1, 15.1.3 require code refactoring
- To be addressed in follow-up PR
```

### Documentation Updates

**After Major Suppression**:
1. Update `is_done()` function with completed rules
2. Document any new patterns in suppression dictionary
3. Update module-specific blacklist if needed
4. Note any architectural issues found

---

## Future Enhancements

### Planned Features

**1. Automated PR Creation**
```python
# Generate PR with suppression summary
./isir.py -m container-manager -c MISRA --create-pr
```

**2. Violation Trending**
```python
# Track violation counts over time
./isir.py -m container-manager -c MISRA --trend
```

**3. Module Comparison**
```python
# Compare violation rates across modules
./isir.py --compare-modules
```

**4. Rule Impact Analysis**
```python
# Show files most affected by rule
./isir.py -m container-manager -c MISRA --impact 8.2.5
```

### Tool Improvements

**1. Interactive Mode**
- CLI wizard for guided suppression
- Rule-by-rule review with prompts
- Automatic branch management

**2. JSON Export**
- Export violations to JSON
- Integration with other tools
- Automated reporting

**3. Refactoring Suggestions**
- Detect suppressible patterns
- Suggest code changes to eliminate violations
- Auto-refactor where possible

---

## Summary

### Key Takeaways

**1. ISIR is Systematic**
- Analyzes violations from ops server
- Groups and prioritizes by rule
- Applies suppressions consistently

**2. Branch Strategy is Critical**
- Base branch: iterative work, reset after each commit
- Output branch: accumulates all suppressions
- Cherry-pick maintains clean history

**3. Start with Auto-Suppression**
- 40+ rules with predefined messages
- Reduces manual work by 60-80%
- Quick wins build momentum

**4. Iterative Manual Suppression**
- One rule at a time
- Custom justifications
- Atomic commits

**5. Quality Over Speed**
- Meaningful justifications
- Technical accuracy
- Review suppressions critically

### Quick Reference

**Initial Analysis**:
```bash
./isir.py -m <module> -c MISRA -d
```

**Auto-Suppress**:
```bash
./isir.py -m <module> -c MISRA -sa
```

**Manual Suppress**:
```bash
./isir.py -m <module> -c MISRA -s <rule> "<reason>"
```

**Branch Workflow**:
```bash
git checkout -b misra-base
git checkout -b misra-output
git checkout misra-base
# ... suppress ...
git commit -m "[MISRA] Suppress rule X.Y.Z"
git checkout misra-output
git cherry-pick misra-base
git checkout misra-base
git reset --hard HEAD~
```

---

*Last Updated: 2025-11-04*
*Tool Version: isir.py (792 lines)*
*Standards: MISRA-C 2023, CERT-CPP*
