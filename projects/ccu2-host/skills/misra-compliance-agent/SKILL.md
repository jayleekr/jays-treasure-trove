---
name: misra-compliance-agent
description: This skill should be used when addressing MISRA-C 2023 or CERT-CPP compliance violations through automated suppression workflows. Use it for analyzing violation reports, applying systematic suppressions, and managing the git-based compliance workflow from initial analysis to pull request creation.
version: 1.1.0
author: CCU-2.0 Team
tags: [compliance, misra, cert-cpp, automation, quality]
---

# MISRA Compliance Agent

Automate MISRA-C 2023 and CERT-CPP compliance through systematic violation analysis, intelligent suppression, and git workflow management.

## When to Use This Skill

Activate this skill when the user requests:
- MISRA-C or CERT-CPP compliance analysis
- Violation report analysis and prioritization
- Automated or manual suppression of coding standard violations
- Complete compliance workflow from analysis to PR creation
- Guidance on the isir.py tool and compliance best practices

## Core Workflow

Execute the following workflow when helping with compliance tasks:

### 1. Understand User Intent

Determine the compliance task by asking clarifying questions if needed:
- Which module? (container-manager, vam, libsntxx, etc.)
- Which checker? (MISRA, CERT-CPP, or all)
- What mode? (analyze, auto-suppress, targeted, complete)
- Use remote reports or local XML files?

### 2. Execute Appropriate Mode

Choose one of four workflow modes based on user needs:

#### Analysis Mode (Default)
Use when user needs violation overview and strategy guidance.

Steps to execute:
1. Run violation analysis: `./isir.py -m <module> -c <checker> -d`
2. Parse output to identify:
   - Total violation counts by checker
   - Top offending rules sorted by frequency
   - Rules with predefined suppression messages vs manual needed
3. Calculate effort estimate based on violation counts
4. Present findings with recommendations for next steps
5. Suggest whether to use auto-suppress (if >70% auto-suppressible) or targeted approach

Reference `references/analysis-workflow.md` for detailed analysis patterns.

#### Auto-Suppress Mode
Use when user wants to quickly suppress all violations with predefined messages.

Steps to execute:
1. Verify git working directory is clean
2. Run auto-suppression: `./isir.py -m <module> -c <checker> -sa`
3. Monitor output for:
   - Files modified count
   - Rules completed count
   - Any errors or line number mismatches
4. Generate summary of changes for user review
5. Guide user through git commit with proper message format
6. Update tracking by adding completed rules to `is_done()` function
7. If using base/output branch workflow, guide cherry-pick process

Reference `references/auto-suppress-workflow.md` for detailed execution steps.

#### Targeted Mode
Use when user wants to suppress specific rule with custom justification.

Steps to execute:
1. Validate rule format (X.Y.Z for MISRA, RULE-CPP for CERT)
2. Show violation preview: `./isir.py -m <module> -c <checker> -sd <rule>`
3. Present violation details:
   - File locations and line numbers
   - Sample violation messages
   - Documentation link for rule
4. Confirm custom justification with user
5. Execute suppression: `./isir.py -m <module> -c <checker> -s <rule> "<reason>"`
6. Create git commit with rule reference in message
7. Update `is_done()` tracking
8. Guide cherry-pick to output branch if applicable

Reference `references/targeted-workflow.md` for detailed execution steps.

#### Complete Mode
Use when user wants full autonomous workflow from analysis to PR.

Steps to execute:
1. Run analysis mode to assess scope
2. Check for required Python dependencies (requests, beautifulsoup4, lxml, cpp_demangle)
3. Install missing dependencies if needed
4. Setup git branches (base + output) with user confirmation
5. Execute auto-suppress mode
6. For remaining rules, iterate through targeted mode
7. Generate compliance report in `.claude/compliance-reports/`
8. Create pull request with comprehensive description

Reference `references/complete-workflow.md` for detailed orchestration.

### 3. Handle Errors Gracefully

Apply error recovery strategies when issues occur:

**Network Failures**:
- Retry download with exponential backoff (3 attempts)
- Fall back to local XML files if available
- Guide user to manually provide XML reports if all retries fail

**Line Number Mismatches**:
- Search nearby lines (±5) for violation pattern
- Warn user if using nearby line
- Skip violation with detailed error if pattern not found
- Log to `.claude/compliance-errors.log` for manual review

**Git Conflicts**:
- Detect cherry-pick conflicts
- Attempt automatic resolution (prefer output branch changes)
- Pause and provide conflict resolution guidance if unresolvable
- Resume workflow after user resolves

**Missing Dependencies**:
- Auto-install with `pip3 install <package>`
- Provide manual installation instructions if auto-install fails
- Verify installation before proceeding with workflow

Reference `references/error-recovery.md` for comprehensive recovery strategies.

## Tool Integration

### Using isir.py

The primary tool for this skill is `isir.py` located at `/home/jay.lee/ccu-2.0/isir.py`.

Execute isir.py commands using the Bash tool:
```bash
./isir.py -m <module> -c <checker> [flags]
```

Common flag combinations:
- Analysis: `-d` (dry-run statistics)
- Auto-suppress: `-sa` (suppress all with predefined messages)
- Targeted suppress: `-s <rule> "<reason>"`
- Show rule details: `-sd <rule>`
- Use local reports: `-l` or `--latest`
- Force fresh download: `-f` or `--fresh`

Reference `references/isir-tool-reference.md` for complete flag documentation.

### Reading Suppression Dictionary

Read the suppression message dictionary from isir.py to determine which rules have predefined messages:

Use Read tool on `/home/jay.lee/ccu-2.0/isir.py` lines 165-206 to extract the `suppression_message()` function.

The dictionary maps rule names to justification messages (40+ rules defined).

### Updating Tracking

After completing rule suppressions, update the `is_done()` function in isir.py:

Use Edit tool on `/home/jay.lee/ccu-2.0/isir.py` lines 209-213 to add completed rules to the return tuple.

Example:
```python
def is_done(rule_name: str) -> bool:
    if r := MisraRule.rule_number(rule_name):
        return r in (
            '8.2.5',  # Existing completed rules
            'X.Y.Z',  # Newly completed rule
        )
```

### Managing Git Workflow

Guide the user through the base/output branch strategy:

**Branch Strategy**:
1. Base branch: Clean state matching violation report
2. Output branch: Accumulates all suppressions
3. Work on base, commit, cherry-pick to output
4. Reset base after each rule to maintain line number stability

Execute git operations using Bash tool:
```bash
git checkout <base-branch>
git checkout -b <output-branch>
# Work on base, commit
git checkout <output-branch>
git cherry-pick <base-branch>
git checkout <base-branch>
git reset --hard HEAD~
```

Reference `references/git-workflow.md` for detailed branch management patterns.

## Communication Patterns

### Presenting Analysis Results

Format violation statistics clearly:
```
MISRA Compliance Analysis: <module>
=============================================

Total Violations: X,XXX
  - Mandatory (MISRA): X,XXX (116 rules)
  - Advisory (MISRA): XXX (53 rules)

Top Offenders:
  1. Rule X.Y.Z (XXX violations) [Predefined: ✅/❌]
  2. Rule X.Y.Z (XXX violations) [Predefined: ✅/❌]
  ...

Auto-suppressible: X,XXX violations (XX rules)
Manual needed: XXX violations (XX rules)

Recommendations:
  [Specific recommendations based on analysis]
```

### Guiding User Decisions

Ask clarifying questions when workflow requires user input:
- "Would you like to auto-suppress the X violations with predefined messages?"
- "What custom justification should be used for rule X.Y.Z?"
- "Should I setup the base/output branch workflow or work directly on current branch?"

### Progress Tracking

For multi-rule workflows, use TodoWrite to track progress:
- Create todo for each rule requiring suppression
- Mark completed as rules are processed
- Keep user informed of overall progress

## Success Criteria

Verify the following before considering a compliance task complete:
- ✅ All requested violations addressed (suppressed or user acknowledged)
- ✅ Every suppression has valid justification comment
- ✅ Git commits created with proper message format: `[MISRA] <description>`
- ✅ Tracking updated in `is_done()` function if applicable
- ✅ User guided to run build verification: `./build.py --module <module>`
- ✅ Compliance report generated for complete workflows

## Integration with Other Workflows

### Smart Build Integration
After applying suppressions, recommend build verification:
```bash
./build.py --module <module> --build-type Debug
```

Guide user to fix any compilation errors introduced by suppressions.

### PR Creation Integration
For complete workflows, create pull request with:
- Title: `[MISRA] Compliance suppressions for <module>`
- Description: Violation counts, rules addressed, testing checklist
- Reviewers: Based on CODEOWNERS for affected files

Reference `references/pr-template.md` for PR description format.

## Important Constraints

### What This Skill Can Do
- Analyze violation reports and provide statistics
- Execute isir.py commands and interpret results
- Guide users through systematic suppression workflows
- Manage git branches and commits for compliance work
- Generate compliance reports and documentation

### What This Skill Cannot Do
- Judge technical validity of suppression justifications (requires human review)
- Guarantee Coverity reports are accurate (may have false positives)
- Run tests automatically to verify suppressions (user responsibility)
- Modify isir.py logic without explicit user request

### Assumptions
- Violation reports from ops server are reasonably up-to-date
- User has necessary permissions for git operations
- Development environment has Python 3 and pip3 available
- User will review and validate all suppressions before merging

## Metrics and Reporting

When generating compliance reports, include:
- Total violations before/after
- Violations by severity (mandatory/advisory)
- Time saved estimate vs manual approach
- Rules completed vs remaining
- Files modified count
- Lines of suppression comments added

Reference `references/reporting-metrics.md` for detailed metric definitions.

## Version History

- 1.1.0 (2025-01-21): Rewritten for Agent Skills Spec compliance
- 1.0.0 (2025-01-21): Initial release with 4 workflow modes
