# Commands vs Skills - When to Use What?

A practical guide to choosing between slash commands and skills in CCU-2.0.

## Quick Decision Tree

```
Need automation?
│
├─ Simple task, need review before action?
│  └─> Use COMMAND (/command-name)
│
└─ Complex workflow, autonomous execution?
   └─> Use SKILL (skill skill-name)
```

---

## Side-by-Side Comparison

| Aspect | Slash Commands | Skills |
|--------|----------------|--------|
| **Type** | Prompt templates | Autonomous agents |
| **Execution** | Expand to prompt | Execute workflow |
| **Interaction** | User reviews/approves | Autonomous decisions |
| **Complexity** | Single-step | Multi-step |
| **Output** | Information/analysis | Deliverables (files, commits) |
| **Tools** | Can suggest tools | Uses tools directly |
| **Error Handling** | User resolves | Automatic retry/recovery |

---

## Examples

### Analyze Component Architecture

**As Command** `/component`:
```bash
/component container-manager
```
**What happens**:
1. Shows component overview
2. Lists dependencies
3. Shows recent commits
4. **User decides** next action

**As Skill** `analyze-component`:
```bash
skill analyze-component container-manager --depth=full
```
**What happens**:
1. Parses CMakeLists.txt
2. Analyzes #includes
3. Traces AUTOSAR bindings
4. **Generates** dependency graph
5. **Creates** report file
6. **Identifies** issues
7. **Suggests** fixes

**When to use which**:
- **Command**: Quick overview, learning
- **Skill**: Deep analysis, deliverable needed

---

### Build Component

**As Command** `/build-component`:
```bash
/build-component vam --type Debug
```
**What happens**:
1. Shows build plan
2. Suggests build command
3. **User executes** command

**As Skill** `smart-build`:
```bash
skill smart-build --component=vam
```
**What happens**:
1. **Detects** changed files
2. **Identifies** dependencies
3. **Builds** incrementally
4. **Retries** on transient errors
5. **Reports** timing & artifacts
6. **Suggests** next steps

**When to use which**:
- **Command**: Simple build, learning workflow
- **Skill**: Automated CI, incremental builds

---

### Create Git Commit

**As Command** `/jira-commit`:
```bash
/jira-commit CCU2-15604 "Remove AA dependency"
```
**What happens**:
1. Shows formatted message
2. **User reviews** and confirms
3. Creates commit

**As Skill** `smart-commit`:
```bash
skill smart-commit CCU2-15604
```
**What happens**:
1. **Fetches** JIRA ticket title (API)
2. **Analyzes** git diff
3. **Generates** message
4. **Validates** format
5. **Runs** pre-commit hooks
6. **Creates** commit
7. **Suggests** push/PR

**When to use which**:
- **Command**: Manual commit, custom message
- **Skill**: Automated workflow, JIRA integration

---

### Container Security Test

**As Command** `/container-test`:
```bash
/container-test C11584
```
**What happens**:
1. Shows test configuration
2. Explains what will be tested
3. Shows deployment JSON
4. **User runs** test manually

**As Skill** `container-security-test`:
```bash
skill container-security-test --case=C11584
```
**What happens**:
1. **Runs** test
2. **Captures** output
3. **Analyzes** failures
4. **Parses** DLT logs
5. **Diagnoses** issues (PID 1, errno)
6. **Generates** report
7. **Suggests** fixes

**When to use which**:
- **Command**: Understanding tests, learning
- **Skill**: CI pipeline, automated testing

---

## Real-World Scenarios

### Scenario 1: Learning the Codebase (NEW DEVELOPER)

**Use Commands**:
```bash
/component container-manager        # Learn structure
/component vam                      # Understand another
/deployment-diff base.json new.json # Compare configs
```

**Why**: Need explanations, want to review before acting

---

### Scenario 2: Daily Development (EXPERIENCED DEVELOPER)

**Use Mix**:
```bash
# Morning: Check what to work on
/component my-feature              # Quick overview

# Work: Build and test
skill smart-build --watch          # Auto-rebuild on changes
skill container-security-test      # Run tests

# End of day: Commit
skill smart-commit CCU2-15604      # Auto-generate message
```

**Why**: Mix of learning (commands) and automation (skills)

---

### Scenario 3: CI/CD Pipeline (AUTOMATION)

**Use Skills**:
```bash
skill smart-build --parallel=16
skill container-security-test --all
skill security-audit --full-scan
skill auto-documenter --changelog
skill pr-assistant --auto-create
```

**Why**: Fully autonomous, no human review needed

---

### Scenario 4: Debugging Production Issue (URGENT)

**Use Mix**:
```bash
# Diagnose
skill dlt-log-analyzer --component=CM --pattern="error"
/syscall-test main.cxx --explain  # Understand issue

# Fix
skill syscall-debugger --fix      # Generate fix
skill smart-build --component=cm  # Build

# Test
skill container-security-test --validate
skill smart-commit CCU2-16807 --auto-message
```

**Why**: Skills for speed, commands for understanding

---

## Command → Skill Upgrade Path

Some commands can evolve into skills:

### Example: `/deployment-diff` → `skill deployment-validator`

**Command** (current):
- Shows differences
- User interprets impact

**Skill** (future):
- Shows differences
- **Validates** security implications
- **Suggests** policy improvements
- **Generates** test cases
- **Creates** report

---

## When to Create Each

### Create a **Command** when:
1. Task is educational/explanatory
2. User needs to review/approve
3. Output is primarily informational
4. Single-step or simple workflow
5. Rapid prototyping (commands are easier)

### Create a **Skill** when:
1. Task is repetitive and automated
2. Multi-step workflow with decisions
3. Integrates with external tools/APIs
4. Produces deliverable output
5. Error handling is critical

---

## Best Practices

### Command Best Practices
✅ **Do**:
- Provide clear explanations
- Show what will happen before doing it
- Offer multiple options
- Include examples
- Link to documentation

❌ **Don't**:
- Execute destructive actions
- Make complex decisions
- Hide information from user
- Require multiple rounds of interaction

### Skill Best Practices
✅ **Do**:
- Handle errors gracefully
- Provide progress updates
- Create audit logs
- Validate inputs
- Suggest next steps

❌ **Don't**:
- Require constant user input
- Make irreversible changes without validation
- Hide what's happening
- Fail silently

---

## Migration Guide

### Upgrading Command to Skill

1. **Identify** autonomous parts:
   ```
   Command: /build-component vam
   Manual: User runs build.py

   Skill: smart-build vam
   Autonomous: Runs build.py automatically
   ```

2. **Add** error handling:
   ```python
   # Skill has retry logic
   try:
       build()
   except BuildError:
       retry_with_clean_build()
   ```

3. **Generate** deliverables:
   ```
   Command: Shows build plan
   Skill: Creates build report file
   ```

4. **Integrate** tools:
   ```
   Command: Suggests git commands
   Skill: Executes git commands
   ```

---

## Future Vision

### Command Evolution
```
/component          →  /component-explain
/build-component    →  /build-explain
/container-test     →  /test-explain
```
(Focus on explanation/learning)

### Skill Evolution
```
skill analyze-component      → More intelligent
skill smart-build           → Faster, smarter caching
skill container-security-test → ML-based failure prediction
skill smart-commit          → Better message generation
```
(Focus on autonomy/intelligence)

---

## Summary Table

| Use Case | Recommended | Why |
|----------|-------------|-----|
| Learn codebase | Commands | Need explanations |
| Daily development | Mix | Balance automation & control |
| CI/CD pipeline | Skills | Fully autonomous |
| Debugging | Mix | Understanding + speed |
| Documentation | Commands | Informational |
| Code generation | Skills | Deliverable output |
| Analysis | Commands | Review before action |
| Testing | Skills | Automated execution |

---

## Quick Reference

**I want to...**
- **Understand** something → **Command**
- **Automate** something → **Skill**
- **Learn** workflow → **Command**
- **Execute** workflow → **Skill**
- **Explore** options → **Command**
- **Get** deliverable → **Skill**

---

**Remember**: Commands teach you to fish. Skills catch the fish for you. 🎣
