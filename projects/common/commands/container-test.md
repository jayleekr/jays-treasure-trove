---
description: Run and debug container security tests with deployment analysis
---

# Container Test Command

Execute and analyze container security tests with deployment configuration insights.

## Task

1. **Test Discovery**
   - Find test.py in container-manager
   - Identify deployment configs in test_config/deploy/
   - List available test cases

2. **Deployment Analysis**
   - Parse deployment JSON
   - Show seccomp profile (bannedSyscalls, allowedSyscalls)
   - Display container configuration
   - Identify security policies

3. **Test Execution**
   - Run specified test case or all tests
   - Capture output with proper logging
   - Monitor container lifecycle

4. **Results Analysis**
   - Show test results with context
   - Explain failures with deployment context
   - Suggest fixes for common issues

5. **Debug Support**
   - Show DLT logs related to test
   - Container state inspection
   - Seccomp profile validation

## Usage

```
/container-test                    # Run all container tests
/container-test C11584             # Run specific test case
/container-test --analyze-only     # Just analyze deployments
/container-test --deployment default_deploy.json  # Test specific deployment
```

## Common Issues Detected

- PID 1 session leader problems
- Seccomp errno interpretation (EPERM vs EACCES)
- Fork-based testing validation
- Deployment configuration errors

## Output

- Test execution summary
- Deployment configuration used
- Seccomp profile details
- Container state at failure
- Debug commands for investigation
