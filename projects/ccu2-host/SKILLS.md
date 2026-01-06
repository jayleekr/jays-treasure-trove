# CCU-2.0 Skills

Reusable, autonomous capabilities for CCU-2.0 automotive embedded development.

## What are Skills?

**Skills** are self-contained, autonomous agents that can:
- Execute complex multi-step workflows
- Make intelligent decisions
- Use tools and APIs autonomously
- Handle errors and edge cases
- Produce deliverable outputs

Unlike slash commands (which expand to prompts), skills are **active agents** that solve problems end-to-end.

---

## Available Skills

### 🔍 Analysis Skills

#### `analyze-component`
**Purpose**: Deep component architecture analysis with dependency mapping

**Capabilities**:
- Parse CMakeLists.txt for build dependencies
- Analyze C++ header includes for code dependencies
- Trace AUTOSAR service bindings (ARXML)
- Generate dependency graphs
- Identify circular dependencies
- Suggest refactoring opportunities

**Usage**:
```bash
skill analyze-component container-manager
skill analyze-component vam --depth=full --output=graph
```

**Output**:
- Dependency graph (text/graphviz)
- Architecture summary
- Dependency issues report
- Refactoring suggestions

---

#### `analyze-seccomp`
**Purpose**: Comprehensive seccomp profile analysis and validation

**Capabilities**:
- Parse deployment JSON seccomp profiles
- Identify syscall allow/deny lists
- Compare profiles across deployments
- Validate against kernel capabilities
- Suggest security hardening
- Generate test cases for edge syscalls

**Usage**:
```bash
skill analyze-seccomp container-manager/test_config/deploy/
skill analyze-seccomp --deployment=default_deploy.json --validate
```

**Output**:
- Seccomp profile summary
- Security risk assessment
- Syscall coverage report
- Test case suggestions

---

#### `misra-compliance-agent`
**Purpose**: Autonomous MISRA-C/CERT-CPP compliance workflow automation

**Capabilities**:
- Download and cache violation reports from ops server
- Analyze violations by module, rule, and severity
- Auto-suppress violations with predefined justifications
- Generate custom suppression comments with validation
- Manage git workflow (base/output branches)
- Track progress and completion status
- Create compliance reports and metrics
- Suggest next rules to address based on impact

**Usage**:
```bash
skill misra-compliance-agent container-manager --checker MISRA
skill misra-compliance-agent vam --checker CERT-CPP --auto-suppress
skill misra-compliance-agent libsntxx --checker all --target-rule 8.2.5
skill misra-compliance-agent --module dpm --workflow complete
```

**Workflow Modes**:
- **Analysis Mode**: Download reports, analyze violations, prioritize rules
- **Auto-Suppress Mode**: Apply all predefined suppressions automatically
- **Targeted Mode**: Suppress specific rule with custom justification
- **Complete Workflow**: Full compliance process from analysis to PR

**Output**:
- Violation statistics report (by rule, file, severity)
- Suppression strategy recommendations
- Git branch management (base/output branches)
- Source code with coverity suppression comments
- Progress tracking (rules completed vs remaining)
- Compliance metrics dashboard
- Pull request with all suppressions

**Autonomous Decisions**:
- Prioritize rules by violation count and severity
- Select appropriate suppression messages from dictionary
- Determine when to use auto-suppress vs manual justification
- Manage git branch workflow and cherry-picks
- Identify rules that need custom attention
- Generate compliant commit messages with rule references

**Error Handling**:
- Retry downloads on network failures
- Validate XML report format before processing
- Check for line number mismatches during suppression
- Detect merge conflicts in cherry-picks
- Verify source file exists before modification
- Rollback changes on suppression failures

---

### 🔨 Build & Test Skills

#### `smart-build`
**Purpose**: Intelligent build orchestration with dependency resolution

**Capabilities**:
- Detect changed files since last build
- Identify affected components
- Build only what's needed (incremental)
- Parallel build optimization
- Handle build errors with retry strategies
- Cache build artifacts

**Usage**:
```bash
skill smart-build
skill smart-build --component=vam --clean
skill smart-build --parallel=8 --cache
```

**Output**:
- Build plan (what will be built)
- Build execution log
- Timing analysis
- Artifact locations

---

#### `container-security-test`
**Purpose**: End-to-end container security test execution and analysis

**Capabilities**:
- Run container security tests
- Analyze test failures with deployment context
- Diagnose seccomp issues (PID 1, errno)
- Suggest fixes for failing tests
- Generate test reports with recommendations
- Validate container isolation

**Usage**:
```bash
skill container-security-test
skill container-security-test --case=C11584 --debug
skill container-security-test --analyze-failures
```

**Output**:
- Test execution report
- Failure diagnosis with root cause
- Fix recommendations
- Deployment config analysis

---

### 🐛 Debug Skills

#### `syscall-debugger`
**Purpose**: Interactive syscall testing and debugging with kernel insight

**Capabilities**:
- Analyze syscall test code
- Identify PID 1 issues automatically
- Generate fork-based test fixes
- Explain kernel check ordering
- Validate errno interpretation
- Create test matrices for edge cases

**Usage**:
```bash
skill syscall-debugger container-app/src/demo/main.cxx
skill syscall-debugger --syscall=setsid --fix
skill syscall-debugger --generate-test-matrix
```

**Output**:
- Issue diagnosis report
- Fixed code (fork-based)
- Test behavior matrix
- Kernel check flow diagram

---

#### `dlt-log-analyzer`
**Purpose**: DLT (Diagnostic Log and Trace) log analysis and correlation

**Capabilities**:
- Parse DLT binary logs
- Filter by component/severity
- Correlate logs with test failures
- Identify SCML seccomp changes
- Timeline visualization
- Pattern detection (errors, warnings)

**Usage**:
```bash
skill dlt-log-analyzer /var/log/dlt.log
skill dlt-log-analyzer --component=CM --since="1 hour ago"
skill dlt-log-analyzer --pattern="SCML.*setsid"
```

**Output**:
- Filtered log entries
- Timeline visualization
- Pattern matches
- Correlation report

---

### 📝 Documentation Skills

#### `auto-documenter`
**Purpose**: Automatic code documentation generation with AUTOSAR awareness

**Capabilities**:
- Generate component README.md
- Document CMake build options
- Extract AUTOSAR service interfaces
- Create architecture diagrams
- Generate API documentation
- Update changelog from commits

**Usage**:
```bash
skill auto-documenter container-manager
skill auto-documenter --type=api --output=markdown
skill auto-documenter --changelog --since="v1.0.0"
```

**Output**:
- README.md (component overview)
- API.md (interface docs)
- ARCHITECTURE.md (design docs)
- CHANGELOG.md (version history)

---

### 🔄 Git & CI Skills

#### `smart-commit`
**Purpose**: Intelligent commit creation with JIRA integration and validation

**Capabilities**:
- Fetch JIRA ticket details via API
- Generate commit message from changes
- Validate ticket format (CCU2-*, SEB-*, CRM-*)
- Suggest component tags
- Pre-commit validation (lint, format)
- Create commits following conventions

**Usage**:
```bash
skill smart-commit CCU2-15604
skill smart-commit SEB-1294 --auto-message
skill smart-commit --validate-only
```

**Output**:
- Formatted commit message
- Validation results
- Commit created (if approved)
- Suggested next steps

---

#### `pr-assistant`
**Purpose**: Pull request creation and review assistance

**Capabilities**:
- Analyze branch changes
- Generate PR description
- Identify affected components
- Suggest reviewers based on CODEOWNERS
- Create checklist from template
- Validate CI requirements

**Usage**:
```bash
skill pr-assistant
skill pr-assistant --base=master --generate
skill pr-assistant --validate-ci
```

**Output**:
- PR title and description
- Reviewer suggestions
- Test/build status
- PR created (if approved)

---

### 🔐 Security Skills

#### `security-audit`
**Purpose**: Comprehensive security audit for container and code

**Capabilities**:
- Scan for hardcoded secrets
- Analyze seccomp profiles
- Check container capabilities
- Validate syscall filtering
- Identify privilege escalation risks
- Generate security report

**Usage**:
```bash
skill security-audit container-manager
skill security-audit --full-scan --report=pdf
```

**Output**:
- Security findings report
- Risk severity matrix
- Remediation recommendations
- Compliance checklist

---

## Skill vs Command Decision Guide

### Use **Slash Commands** (`/command`) when:
- ✅ Task is prompt-based (analysis, explanation)
- ✅ User needs to review before action
- ✅ Simple, single-step operation
- ✅ Output is informational

### Use **Skills** (`skill name`) when:
- ✅ Multi-step autonomous workflow
- ✅ Decision-making required
- ✅ Tool/API integration needed
- ✅ Deliverable output (files, commits, PRs)
- ✅ Error handling and retry logic

---

## Examples

### Workflow: Fix Failing Container Test

**Step 1**: Analyze failure
```bash
skill container-security-test --case=C11584 --analyze-failures
```

**Step 2**: Debug syscall issue
```bash
skill syscall-debugger container-app/src/demo/main.cxx --fix
```

**Step 3**: Validate fix
```bash
skill container-security-test --case=C11584
```

**Step 4**: Commit
```bash
skill smart-commit CCU2-15604 --auto-message
```

---

### Workflow: New Component Development

**Step 1**: Analyze architecture
```bash
skill analyze-component new-component --suggest-structure
```

**Step 2**: Build incrementally
```bash
skill smart-build --component=new-component --watch
```

**Step 3**: Generate docs
```bash
skill auto-documenter new-component
```

**Step 4**: Create PR
```bash
skill pr-assistant --template=feature
```

---

### Workflow: MISRA-C Compliance

**Step 1**: Initial analysis
```bash
skill misra-compliance-agent container-manager --checker MISRA
# Analyzes violations, downloads reports, prioritizes rules
```

**Step 2**: Auto-suppress known rules
```bash
skill misra-compliance-agent container-manager --auto-suppress
# Applies all predefined suppressions automatically
# Creates git commits for each rule group
```

**Step 3**: Target specific high-impact rules
```bash
skill misra-compliance-agent container-manager --target-rule 8.2.5 --reason "Safe cast verified by security review"
# Suppresses all 8.2.5 violations with custom justification
# Manages git branch workflow (base/output)
```

**Step 4**: Complete workflow
```bash
skill misra-compliance-agent container-manager --workflow complete
# Full autonomous workflow:
# 1. Download/analyze violations
# 2. Auto-suppress predefined rules
# 3. Identify remaining manual rules
# 4. Generate suppression strategy
# 5. Create git branches and commits
# 6. Generate compliance report
# 7. Create PR with all changes
```

**Output**: Complete compliance workflow with PR ready for review

---

## Skill Development

### Creating New Skills

1. **Identify autonomous workflow** (multi-step, decision-making)
2. **Define clear inputs/outputs**
3. **Implement error handling**
4. **Test edge cases**
5. **Document usage**

### Skill Template

```markdown
#### `skill-name`
**Purpose**: One-line description

**Capabilities**:
- Capability 1
- Capability 2
- Capability 3

**Usage**:
\`\`\`bash
skill skill-name [args]
\`\`\`

**Output**:
- Output 1
- Output 2
```

---

## Roadmap

### Planned Skills

- [ ] `autosar-validator` - ARXML validation and generation
- [ ] `test-generator` - Auto-generate tests from code
- [ ] `performance-profiler` - Profile and optimize builds
- [ ] `dependency-updater` - Smart dependency updates
- [ ] `migration-assistant` - Assist in code migrations
- [ ] `ci-optimizer` - Optimize Jenkins/CI pipelines

### Request a Skill

Have an idea? Add to roadmap or implement:
```bash
# Create skill request
echo "Skill: my-skill\nPurpose: ..." >> .claude/skill-requests.md
```

---

## Integration with Commands

Skills can be invoked from slash commands:

```markdown
---
description: Build and test component
---

# Build Test Command

1. Use smart-build skill to build
2. Use container-security-test skill to test
3. Report results
```

---

## Best Practices

### When to Use Skills

✅ **Do use skills for**:
- Complex multi-file operations
- Automated workflows
- Integration with external tools
- Error-prone manual processes

❌ **Don't use skills for**:
- Simple queries ("what is X?")
- One-off analysis
- Exploratory tasks
- User education

### Skill Composition

Skills can call other skills:

```bash
# smart-build calls analyze-component first
skill smart-build --component=vam
  └─> skill analyze-component vam --dependencies
      └─> Builds dependencies first
```

---

## Performance

Skills are optimized for:
- **Speed**: Parallel operations where possible
- **Efficiency**: Incremental processing, caching
- **Reliability**: Retry logic, error recovery
- **Observability**: Detailed logging, progress tracking

---

## Contributing

Add your own skills:
1. Create `skills/my-skill.md` (documentation)
2. Implement skill logic
3. Test thoroughly
4. Update this SKILLS.md
5. Commit to jay-claude branch

---

## Support

- **Documentation**: See individual skill docs in `skills/`
- **Examples**: Check workflow examples above
- **Issues**: Report via `.claude/skill-requests.md`
- **Questions**: Check QUICKSTART.md or README.md
