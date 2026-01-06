---
description: Analyze and fix syscall testing issues (PID 1, errno, seccomp)
---

# Syscall Test Analysis Command

Diagnose and fix syscall testing issues in container environments.

## Task

1. **Test Code Analysis**
   - Identify syscall being tested (setsid, fork, etc.)
   - Check for PID 1 session leader issues
   - Verify errno checking logic
   - Detect fork-based testing patterns

2. **Common Issue Detection**
   - **PID 1 Problem**: Direct setsid() call in container init
   - **errno Confusion**: EPERM vs EACCES interpretation
   - **Missing Fork**: Testing from wrong execution context
   - **Seccomp Masking**: Process state errors hiding security policy

3. **Seccomp Configuration**
   - Parse deployment JSON seccomp profile
   - Show bannedSyscalls and allowedSyscalls
   - Validate against actual test behavior

4. **Fix Suggestions**
   - Provide fork-based testing template
   - Show proper errno checking
   - Explain kernel syscall check ordering:
     1. Seccomp filter (returns EACCES)
     2. Syscall-specific logic (returns EPERM for setsid)

5. **Test Validation**
   - Verify test covers both restricted and unrestricted cases
   - Check return code alignment
   - Validate error handling

## Usage

```
/syscall-test container-app/src/demo/main.cxx
/syscall-test --analyze                          # Analyze current context
/syscall-test --fix                              # Generate fork-based fix
/syscall-test --explain setsid                   # Explain specific syscall
```

## Key Insights

### PID 1 Session Leader Issue
```
Container: sh (PID 1) = Session Leader
         ↓
    Direct setsid() → Always EPERM
         ↓
    Masks seccomp errors ❌

Solution: Fork child (not session leader)
         ↓
    Child setsid() → Real seccomp errors ✅
```

### errno Meanings
| errno  | Source | Meaning |
|--------|--------|---------|
| EACCES | Seccomp | Syscall blocked by security policy |
| EPERM  | Kernel | Process state invalid (session leader) |

### Kernel Check Order
1. **Seccomp filter** (first) - Returns EACCES if blocked
2. **Syscall logic** (second) - Returns EPERM if invalid state
3. **Execution** - Performs syscall if checks pass

## Output

- Issue diagnosis
- Code analysis with line numbers
- Fix template (fork-based testing)
- Test behavior matrix
- Validation checklist
