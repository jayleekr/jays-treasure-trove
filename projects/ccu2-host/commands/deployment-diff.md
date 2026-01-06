---
description: Compare deployment configurations and security policies
---

# Deployment Diff Command

Compare container deployment configurations focusing on security policy differences.

## Task

1. **Deployment Discovery**
   - Find deployment JSON files in test_config/deploy/
   - Identify base deployment and diffs
   - List available configurations

2. **Configuration Parsing**
   - Parse deployment JSON structure
   - Extract seccomp profiles
   - Identify container settings
   - Parse policy files

3. **Security Policy Comparison**
   - **Seccomp Differences**:
     - bannedSyscalls changes
     - allowedSyscalls modifications
     - Default action changes

   - **Container Config**:
     - Command/entrypoint changes
     - Environment variables
     - Volume mounts
     - Capabilities

   - **Network/Resources**:
     - Port mappings
     - Resource limits
     - Network mode

4. **Impact Analysis**
   - Explain how differences affect tests
   - Identify security implications
   - Predict test behavior changes

5. **Visualization**
   - Side-by-side comparison
   - Highlight security-critical changes
   - Show policy inheritance chain

## Usage

```
/deployment-diff default_deploy.json setsid_restricted.json
/deployment-diff --all                           # Compare all deployments
/deployment-diff --focus seccomp                 # Show only seccomp changes
/deployment-diff base C11584_diff               # Apply diff to base
```

## Output Format

```markdown
## Deployment Comparison

### Base: default_deploy.json
### Modified: C11584_setsid_not_restricted_diff.json

## Seccomp Changes
| Aspect | Base | Modified | Impact |
|--------|------|----------|--------|
| bannedSyscalls | ["setsid"] | [] | setsid now allowed |
| defaultAction | SCMP_ACT_ERRNO | SCMP_ACT_ERRNO | No change |

## Expected Test Behavior
- **Step 2** (restricted): setsid blocked → EACCES → return 0 ✅
- **Step 4** (unrestricted): setsid allowed → success → return 1 ✅

## Security Implications
⚠️ Removing setsid from banned list allows containers to create new sessions
```

## Analysis Features

- JSON diff visualization
- Security impact assessment
- Test prediction
- Policy inheritance tracking
- SCML configuration analysis
