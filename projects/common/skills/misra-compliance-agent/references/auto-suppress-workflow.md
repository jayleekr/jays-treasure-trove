# Auto-Suppress Workflow - Detailed Execution

Complete guide for executing automated suppression with predefined messages.

## Prerequisites Check

Before executing auto-suppress mode, verify:

1. **Git status is clean**:
   ```bash
   git status
   ```
   Ensure "working tree clean" or guide user to commit/stash changes

2. **On correct branch**:
   ```bash
   git branch --show-current
   ```
   Confirm user is on intended branch (base or working branch)

3. **Python dependencies installed**:
   Required packages: requests, beautifulsoup4, lxml, cpp_demangle

   Check and install if missing:
   ```bash
   pip3 install requests beautifulsoup4 lxml cpp-demangle
   ```

## Command Execution

Execute auto-suppression:
```bash
./isir.py -m <module> -c <checker> -sa
```

Flags explained:
- `-sa` or `--auto-suppress`: Apply all predefined suppression messages
- Can combine with `-l` for local XML reports: `-sa -l`

## Monitoring Progress

Watch for output indicators:

**Success indicators**:
```
Processing rule 8.2.5...
  Suppressed 342 violations in 28 files
Processing rule 7.0.2...
  Suppressed 215 violations in 19 files
...
```

**Warning indicators**:
```
Warning: Line number mismatch in file.cxx:145
  Expected: <code pattern>
  Found: <different code>
  Skipping this violation
```

**Error indicators**:
```
Error: Cannot read file.cxx
Error: XML report malformed
ModuleNotFoundError: cpp_demangle
```

## Output Analysis

Parse final summary for:

1. **Files modified count**: How many source files were changed
2. **Total suppressions added**: Number of violations suppressed
3. **Rules completed**: Number of rules fully suppressed
4. **Skipped violations**: Count of violations that couldn't be suppressed (line mismatches)

Typical summary format:
```
Summary:
  Files modified: 87
  Suppressions added: 1,124
  Rules completed: 40
  Skipped: 15 (line number mismatches)
```

## Generated Suppressions

Auto-suppress generates coverity comments in source files:

**Standard format**:
```cpp
// coverity[misra_cpp_2023_rule_8_2_5_violation:SUPPRESS] This is the correct, required cast
dangerous_cast = static_cast<Type*>(ptr);
```

**Special case (rule 0.1.2)**:
```cpp
// coverity[misra_cpp_2023_rule_0_1_2_violation] Intentionally ignored
ignore(unused_variable);
```

Rule 0.1.2 uses `ignore()` wrapper instead of SUPPRESS.

## Review Changes

Guide user to review modifications:

```bash
# See all changed files
git status

# Review diff for specific file
git diff path/to/file.cxx

# Review all changes
git diff
```

Key review points:
- Verify suppression comments are on correct lines
- Check justification messages make sense for context
- Ensure no unintended code modifications

## Commit Creation

Guide user through proper commit message:

```bash
git add .
git commit -m "[MISRA] Auto-suppress violations with predefined messages

Suppressed XXXX violations across XX rules:
- Rule 8.2.5: Type casting (342 violations)
- Rule 7.0.2: Type conversions (215 violations)
- Rule 19.3.3: Variadic macros (156 violations)
... (list all rules)

Files modified: XX
Suppressions added: XXXX

Generated with Claude Code
https://claude.com/claude-code

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Tracking Update

After successful commit, update isir.py tracking:

Edit `/home/jay.lee/ccu-2.0/isir.py` lines 209-213:

Add all completed rules to `is_done()` function:
```python
def is_done(rule_name: str) -> bool:
    if r := MisraRule.rule_number(rule_name):
        return r in (
            # Existing rules...
            '8.2.5',  # Auto-suppressed
            '7.0.2',  # Auto-suppressed
            '19.3.3', # Auto-suppressed
            # ... all auto-suppressed rules
        )
```

## Cherry-Pick to Output Branch (Optional)

If using base/output branch workflow:

```bash
# Capture commit hash
COMMIT=$(git rev-parse HEAD)

# Switch to output branch
git checkout <output-branch>

# Cherry-pick the suppressions
git cherry-pick $COMMIT

# Handle conflicts if any (should be rare)
# Prefer output branch version if conflicts occur

# Return to base branch
git checkout <base-branch>
```

## Error Recovery

### Line Number Mismatches

If many violations are skipped due to line number mismatches:

1. **Check XML report freshness**:
   ```bash
   # Request fresh download
   ./isir.py -m <module> -c <checker> -f -d
   ```

2. **Review skipped violations**:
   - Check `.claude/compliance-errors.log` if exists
   - Manually suppress skipped violations with targeted mode

### Missing Predefined Messages

If user expects certain rules to be auto-suppressed but they're not:

1. Verify rule is in suppression_message dict (isir.py:165-206)
2. If missing, suggest adding to dict or use targeted mode
3. Document which rules need dictionary updates

### Git Conflicts During Cherry-Pick

If cherry-pick creates conflicts:

1. Examine conflict markers in files
2. Typically conflicts are in suppression comments (safe to take either)
3. Guide resolution:
   ```bash
   # Edit conflicted files, resolve markers
   git add <resolved-files>
   git cherry-pick --continue
   ```

## Verification Steps

After auto-suppress completion, recommend:

1. **Build verification**:
   ```bash
   ./build.py --module <module> --build-type Debug
   ```
   Ensure suppressions don't break compilation

2. **Diff review**:
   ```bash
   git show HEAD
   ```
   Final review of committed changes

3. **Violation recount**:
   ```bash
   ./isir.py -m <module> -c <checker> -d
   ```
   Verify remaining violations match expectations

## Next Steps Guidance

Based on remaining violations after auto-suppress:

**If 0 remaining**:
- ✅ Complete! Guide user to create PR

**If < 10 rules remaining**:
- Recommend targeted mode for each rule
- Estimate: ~10-15 minutes per rule

**If > 10 rules remaining**:
- Suggest prioritizing by violation count
- Consider updating suppression_message dict for common cases
- Break into multiple PR if needed

## Success Metrics

Report to user:
```
Auto-Suppress Complete
======================

Violations Suppressed: X,XXX / Y,YYY (XX%)
Rules Completed: XX / YY
Files Modified: XX
Time Saved: ~X hours vs manual suppression

Remaining Work:
  XX violations across YY rules need custom justification
  Estimated effort: ~X hours

Next Steps:
  1. Review changes: git show HEAD
  2. Run build: ./build.py --module <module>
  3. Address remaining violations with targeted mode
```
