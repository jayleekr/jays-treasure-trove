# Error Recovery Reference

에러 시나리오, 복구 전략, 롤백 메커니즘 가이드.

## Error Categories

에러는 크게 3가지 카테고리로 분류:

1. **Transient Errors** (일시적 오류): 재시도로 해결 가능
2. **User Errors** (사용자 오류): 안내 및 수정 필요
3. **State Errors** (상태 오류): 롤백 또는 복구 필요

---

## Error Category: Transient Errors

### Characteristics
- 네트워크 이슈, API timeout, 일시적 서비스 불가
- **해결 방법**: 재시도 (exponential backoff)
- **복구 시간**: 초~분 단위

### Examples

#### JIRA API Timeout

```python
def fetch_jira_ticket_with_retry(ticket_id, max_retries=3):
    """
    JIRA API 호출 (재시도 로직 포함)
    """
    retry_delays = [5, 10, 20]  # seconds

    for attempt in range(max_retries):
        try:
            response = requests.get(
                f"{JIRA_BASE_URL}/rest/api/3/issue/{ticket_id}",
                headers={"Authorization": f"Basic {AUTH}"},
                timeout=30
            )

            if response.status_code == 200:
                return response.json()

            elif response.status_code == 429:
                # Rate limited
                retry_after = int(response.headers.get('Retry-After', retry_delays[attempt]))
                print(f"⚠️ Rate limited. Retrying after {retry_after}s...")
                time.sleep(retry_after)

            else:
                raise JIRAAPIError(f"HTTP {response.status_code}: {response.text}")

        except requests.Timeout:
            if attempt < max_retries - 1:
                delay = retry_delays[attempt]
                print(f"⚠️ JIRA API timeout (attempt {attempt + 1}/{max_retries})")
                print(f"   Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                raise JIRAAPIError("JIRA API timeout after 3 retries")

        except requests.ConnectionError:
            if attempt < max_retries - 1:
                delay = retry_delays[attempt]
                print(f"⚠️ Network connection error (attempt {attempt + 1}/{max_retries})")
                print(f"   Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                raise JIRAAPIError("Network connection failed after 3 retries")

    raise JIRAAPIError("Failed to fetch ticket after all retries")
```

#### Network Errors

```python
def handle_network_error(error, operation):
    """네트워크 에러 처리"""

    error_message = f"""
⚠️ Network Error

**Operation**: {operation}
**Error**: {str(error)}

**Recovery**: Retrying automatically...
"""

    print(error_message)
    # 자동 재시도는 fetch_jira_ticket_with_retry에서 처리
```

---

## Error Category: User Errors

### Characteristics
- 잘못된 입력, 설정 누락, 권한 부족
- **해결 방법**: 사용자에게 안내 및 수정 요청
- **복구 시간**: 사용자 액션 필요

### Examples

#### Invalid Ticket ID Format

```python
def validate_and_guide_ticket_id(user_input):
    """
    티켓 ID 검증 및 안내
    """
    # 패턴: CCU2-12345 또는 https://sonatus.atlassian.net/browse/CCU2-12345
    patterns = [
        r'^(CCU2|SEB|CRM)-\d{5}$',  # CCU2-12345
        r'https://sonatus\.atlassian\.net/browse/(CCU2|SEB|CRM)-\d{5}$'  # URL
    ]

    for pattern in patterns:
        match = re.match(pattern, user_input)
        if match:
            # Extract ticket ID
            if user_input.startswith('http'):
                ticket_id = user_input.split('/')[-1]
            else:
                ticket_id = user_input
            return ticket_id

    # 검증 실패 - 사용자 안내
    error_guide = f"""
❌ Invalid Ticket Format

**Received**: {user_input}

**Expected Formats**:
- Ticket ID: `CCU2-17741`
- Full URL: `https://sonatus.atlassian.net/browse/CCU2-17741`

**Supported Projects**: CCU2, SEB, CRM

**Please provide a valid JIRA ticket ID or URL.**
"""

    print(error_guide)
    raise ValueError("Invalid ticket ID format")
```

#### Missing JIRA Credentials

```python
def check_jira_credentials():
    """
    JIRA 인증 정보 확인
    """
    required_vars = ['JIRA_BASE_URL', 'JIRA_EMAIL', 'JIRA_API_TOKEN']
    missing_vars = []

    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)

    if missing_vars:
        setup_guide = f"""
❌ Missing JIRA Credentials

**Missing Variables**: {', '.join(missing_vars)}

**Setup Guide**:

1. Open or create `~/.env`:
   ```bash
   nano ~/.env
   ```

2. Add the following lines:
   ```bash
   JIRA_BASE_URL=https://sonatus.atlassian.net/
   JIRA_EMAIL=your.email@sonatus.com
   JIRA_API_TOKEN=your_api_token_here
   ```

3. Generate API token:
   - Visit: https://id.atlassian.com/manage-profile/security/api-tokens
   - Click "Create API token"
   - Copy and paste into ~/.env

4. Restart Claude Code

**Need help?** Check the README or ask your team.
"""

        print(setup_guide)
        raise CredentialsError("JIRA credentials not configured")

    return True
```

#### Permission Denied

```python
def handle_permission_error(ticket_id, error):
    """
    권한 오류 처리
    """
    permission_guide = f"""
❌ Access Denied

**Ticket**: {ticket_id}
**Error**: {str(error)}

**Possible Causes**:
1. You don't have access to this JIRA project
2. The ticket is in a restricted project
3. Your API token has expired

**Solutions**:
1. **Check Ticket Access**:
   - Visit: https://sonatus.atlassian.net/browse/{ticket_id}
   - If you can't see it, request access from your manager

2. **Verify API Token**:
   - Generate a new token: https://id.atlassian.com/manage-profile/security/api-tokens
   - Update ~/.env with new token

3. **Contact Support**:
   - If issue persists, contact JIRA admin

**Your current email**: {os.getenv('JIRA_EMAIL')}
"""

    print(permission_guide)
    raise PermissionError(f"Cannot access ticket {ticket_id}")
```

---

## Error Category: State Errors

### Characteristics
- 빌드 실패, 테스트 실패, Git 충돌
- **해결 방법**: 롤백 또는 수동 수정
- **복구 시간**: 분~시간 단위

### Examples

#### Build Failure

```python
def handle_build_failure(ticket_id, build_result):
    """
    빌드 실패 처리
    """
    # 1. 에러 분석
    errors = parse_build_errors(build_result['output'])

    # 2. 사용자에게 에러 표시
    error_report = f"""
❌ Build Failed

**Ticket**: {ticket_id}
**Build System**: {build_result['build_system']}
**Errors**: {len(errors)}

### Error Details:
"""

    for i, error in enumerate(errors, 1):
        error_report += f"""
{i}. **{error['file']}:{error['line']}**
   ```
   {error['message']}
   ```
"""

    error_report += """
### Recovery Options:

**Option 1: Fix Manually**
- Review the errors above
- Fix the issues in your code
- Run verification again: `/verify {ticket_id}`

**Option 2: Rollback Changes**
- Level 1: Undo uncommitted changes
  ```bash
  git reset --hard HEAD
  ```

- Level 2: Delete feature branch
  ```bash
  git branch -D {branch_name}
  ```

**Option 3: Abort Workflow**
- Stop the workflow and preserve current state
- You can resume later

**What would you like to do?**
- `fix` - I'll fix the errors manually
- `rollback` - Rollback my changes
- `abort` - Abort workflow

**Your choice**: _
"""

    print(error_report)

    # 3. 사용자 선택 대기
    choice = get_user_input("Recovery option: ")

    if choice == "fix":
        return handle_manual_fix(ticket_id)
    elif choice == "rollback":
        return handle_rollback(ticket_id, level=1)
    elif choice == "abort":
        return handle_abort(ticket_id)
    else:
        return "Invalid choice. Aborting workflow."
```

#### Test Failure

```python
def handle_test_failure(ticket_id, test_result):
    """
    테스트 실패 처리
    """
    failed_tests = [t for t in test_result['tests'] if t['status'] == 'failed']

    test_report = f"""
❌ Tests Failed

**Ticket**: {ticket_id}
**Tests Run**: {test_result['tests_run']}
**Passed**: {test_result['passed']}
**Failed**: {test_result['failed']}

### Failed Tests:
"""

    for i, test in enumerate(failed_tests, 1):
        test_report += f"""
{i}. **{test['name']}**
   - **Expected**: {test['expected']}
   - **Actual**: {test['actual']}
   - **Message**: {test['message']}
"""

    test_report += """
### Recovery Options:

**Option 1: Investigate & Fix**
- Review failed test details
- Debug the root cause
- Fix code and re-run tests

**Option 2: Regression Test**
- Add regression tests for edge cases
- Ensure comprehensive coverage

**Option 3: Rollback**
- If tests passed before your changes, rollback

**What would you like to do?**
- `fix` - I'll investigate and fix
- `rollback` - Rollback changes
- `abort` - Abort workflow

**Your choice**: _
"""

    print(test_report)

    choice = get_user_input("Recovery option: ")

    if choice == "fix":
        return handle_manual_fix(ticket_id)
    elif choice == "rollback":
        return handle_rollback(ticket_id, level=1)
    elif choice == "abort":
        return handle_abort(ticket_id)
    else:
        return "Invalid choice. Aborting workflow."
```

#### Git Conflicts

```python
def handle_git_conflict(ticket_id, conflict_files):
    """
    Git 충돌 처리
    """
    conflict_report = f"""
❌ Git Merge Conflict

**Ticket**: {ticket_id}
**Conflicted Files**: {len(conflict_files)}

### Files with Conflicts:
"""

    for file in conflict_files:
        conflict_report += f"- {file}\n"

    conflict_report += """
### Resolution Steps:

**Option 1: Manual Resolution**
1. Open conflicted files
2. Resolve conflicts (keep/merge changes)
3. Stage resolved files:
   ```bash
   git add <resolved_files>
   ```
4. Continue workflow

**Option 2: Abort Merge**
```bash
git merge --abort
```

**Option 3: Rollback Branch**
- Delete branch and restart

**What would you like to do?**
- `resolve` - I'll resolve conflicts manually
- `abort_merge` - Abort the merge
- `rollback` - Delete branch and restart

**Your choice**: _
"""

    print(conflict_report)

    choice = get_user_input("Resolution option: ")

    if choice == "resolve":
        return "Please resolve conflicts and run workflow again"
    elif choice == "abort_merge":
        run_bash("git merge --abort")
        return "Merge aborted. You can continue from current state."
    elif choice == "rollback":
        return handle_rollback(ticket_id, level=2)
    else:
        return "Invalid choice. Aborting workflow."
```

---

## Rollback Mechanisms

### Rollback Levels

4단계 롤백 레벨:

```
Level 1 (Soft)    → Uncommitted changes only
Level 2 (Branch)  → Delete feature branch
Level 3 (Memory)  → Clear workflow memories
Level 4 (Complete)→ Full reset
```

### Level 1: Soft Rollback

**목적**: Uncommitted 변경사항만 되돌리기

```python
def rollback_level_1(ticket_id):
    """
    Level 1: Soft Rollback
    - Undo uncommitted changes
    - Preserve branch and commits
    """
    impl = read_memory(f"impl_{ticket_id}")

    if not impl:
        return "No implementation to rollback"

    # 1. 확인 메시지
    confirmation = f"""
🔄 Level 1 Rollback: Soft Reset

**Ticket**: {ticket_id}
**Branch**: {impl['branch']}

**This will**:
- ✅ Reset uncommitted changes
- ✅ Preserve branch
- ✅ Preserve commits (if any)
- ✅ Keep workflow memories

**Are you sure?** (yes/no): _
"""

    print(confirmation)
    choice = get_user_input("Confirm rollback: ")

    if choice != "yes":
        return "Rollback cancelled"

    # 2. Git reset 실행
    run_bash("git reset --hard HEAD")

    # 3. 메모리 업데이트
    write_memory(f"rollback_{ticket_id}", {
        "level": 1,
        "timestamp": now(),
        "reason": "User initiated soft rollback"
    })

    print("✅ Rollback Level 1 completed")
    return "success"
```

### Level 2: Branch Rollback

**목적**: Feature 브랜치 전체 삭제

```python
def rollback_level_2(ticket_id):
    """
    Level 2: Branch Rollback
    - Delete feature branch
    - Return to base branch (main/master)
    - Preserve workflow memories
    """
    impl = read_memory(f"impl_{ticket_id}")

    if not impl:
        return "No branch to rollback"

    branch_name = impl['branch']
    base_branch = impl.get('base_branch', 'master')

    # 1. 확인 메시지
    confirmation = f"""
🔄 Level 2 Rollback: Branch Deletion

**Ticket**: {ticket_id}
**Branch to Delete**: {branch_name}
**Return to**: {base_branch}

**This will**:
- ❌ Delete feature branch
- ❌ Delete all commits on branch
- ✅ Return to {base_branch}
- ✅ Keep workflow memories

**⚠️ Warning**: All code changes will be lost!

**Are you sure?** (yes/no): _
"""

    print(confirmation)
    choice = get_user_input("Confirm rollback: ")

    if choice != "yes":
        return "Rollback cancelled"

    # 2. Base 브랜치로 전환
    run_bash(f"git checkout {base_branch}")

    # 3. Feature 브랜치 삭제
    run_bash(f"git branch -D {branch_name}")

    # 4. 메모리 업데이트
    write_memory(f"rollback_{ticket_id}", {
        "level": 2,
        "timestamp": now(),
        "deleted_branch": branch_name,
        "reason": "User initiated branch rollback"
    })

    print(f"✅ Rollback Level 2 completed")
    print(f"   Branch '{branch_name}' deleted")
    print(f"   Current branch: {base_branch}")

    return "success"
```

### Level 3: Memory Rollback

**목적**: Workflow 메모리 정리 (코드는 유지)

```python
def rollback_level_3(ticket_id):
    """
    Level 3: Memory Rollback
    - Clear workflow memories
    - Preserve code changes
    - Preserve branch
    """
    # 1. 확인 메시지
    confirmation = f"""
🔄 Level 3 Rollback: Memory Cleanup

**Ticket**: {ticket_id}

**This will**:
- ❌ Delete workflow memories (plan, phases, checkpoints)
- ✅ Preserve code changes
- ✅ Preserve branch
- ✅ Preserve commits

**Use case**: Start fresh tracking without losing code

**Are you sure?** (yes/no): _
"""

    print(confirmation)
    choice = get_user_input("Confirm rollback: ")

    if choice != "yes":
        return "Rollback cancelled"

    # 2. 메모리 삭제
    memories_to_delete = [
        f"plan_{ticket_id}",
        f"phase_1_analyze_{ticket_id}",
        f"phase_2_implement_{ticket_id}",
        f"phase_3_verify_{ticket_id}",
        f"phase_4_submit_{ticket_id}",
        f"impl_{ticket_id}",
        f"verify_{ticket_id}",
        f"checkpoint_1_{ticket_id}",
        f"checkpoint_2_{ticket_id}",
        f"approval_log_{ticket_id}"
    ]

    # 모든 체크포인트 찾기
    all_memories = list_memories()
    checkpoints = [k for k in all_memories if k.startswith(f"checkpoint_") and ticket_id in k]
    memories_to_delete.extend(checkpoints)

    deleted_count = 0
    for memory_key in memories_to_delete:
        try:
            delete_memory(memory_key)
            deleted_count += 1
        except:
            pass

    # 3. 롤백 기록
    write_memory(f"rollback_{ticket_id}", {
        "level": 3,
        "timestamp": now(),
        "deleted_memories": deleted_count,
        "reason": "User initiated memory cleanup"
    })

    print(f"✅ Rollback Level 3 completed")
    print(f"   Deleted {deleted_count} memory entries")
    print(f"   Code and branch preserved")

    return "success"
```

### Level 4: Complete Rollback

**목적**: 모든 것 초기화 (코드 + 메모리)

```python
def rollback_level_4(ticket_id):
    """
    Level 4: Complete Rollback
    - Delete feature branch
    - Clear all memories
    - Full reset
    """
    # 1. 확인 메시지
    confirmation = f"""
🔄 Level 4 Rollback: Complete Reset

**Ticket**: {ticket_id}

**This will**:
- ❌ Delete feature branch
- ❌ Delete all commits
- ❌ Delete all workflow memories
- ❌ Delete rollback history

**⚠️ WARNING**: This is irreversible!

**Are you sure?** Type 'DELETE' to confirm: _
"""

    print(confirmation)
    choice = get_user_input("Confirm complete rollback: ")

    if choice != "DELETE":
        return "Rollback cancelled"

    # 2. Branch 롤백 (Level 2)
    rollback_level_2(ticket_id)

    # 3. Memory 롤백 (Level 3)
    rollback_level_3(ticket_id)

    # 4. 완료 기록도 삭제
    try:
        delete_memory(f"workflow_complete_{ticket_id}")
        delete_memory(f"submit_{ticket_id}")
        delete_memory(f"rollback_{ticket_id}")
    except:
        pass

    print("✅ Rollback Level 4 completed")
    print("   All traces of workflow removed")

    return "success"
```

---

## Error Recovery Decision Tree

```
Error Detected
      │
      ▼
┌─────────────┐
│ Classify    │
│ Error Type  │
└──────┬──────┘
       │
    ┌──┴───┬────────┬─────────┐
    │      │        │         │
Transient User   State    Unknown
    │      │        │         │
    ▼      ▼        ▼         ▼
 Retry   Guide   Offer    Log &
 with    User    Recovery Alert
 Backoff         Options
    │      │        │         │
    └──────┴────────┴─────────┘
             │
             ▼
      ┌──────────────┐
      │ Resolved?    │
      └──┬────────┬──┘
         │        │
        YES       NO
         │        │
         ▼        ▼
     Continue  Escalate
     Workflow  to User
```

---

## Error Logging and Monitoring

### Error Log Structure

```python
def log_error(ticket_id, error_type, error, context):
    """에러 로깅"""

    error_log = {
        "ticket_id": ticket_id,
        "timestamp": now(),
        "error_type": error_type,  # transient|user|state|unknown
        "error_class": error.__class__.__name__,
        "error_message": str(error),
        "context": context,  # Which mode/step failed
        "stack_trace": traceback.format_exc()
    }

    # Serena 메모리에 로그
    existing_logs = read_memory(f"error_log_{ticket_id}") or []
    existing_logs.append(error_log)
    write_memory(f"error_log_{ticket_id}", existing_logs)

    # 로컬 파일 로그
    append_to_file("~/.claude-config/logs/workflow_errors.log", error_log)
```

### Error Metrics

```python
def generate_error_metrics():
    """에러 통계 생성"""

    all_errors = collect_all_error_logs()

    metrics = {
        "total_errors": len(all_errors),
        "by_type": {
            "transient": 0,
            "user": 0,
            "state": 0,
            "unknown": 0
        },
        "by_phase": {
            "analyze": 0,
            "implement": 0,
            "verify": 0,
            "submit": 0
        },
        "recovery_success_rate": 0.0
    }

    for error in all_errors:
        metrics['by_type'][error['error_type']] += 1
        metrics['by_phase'][error['context']] += 1

    return metrics
```

---

## Best Practices

### 1. Always Provide Context
에러 메시지에 항상 다음 포함:
- 무엇이 실패했는가
- 왜 실패했는가
- 어떻게 해결할 수 있는가

### 2. Offer Clear Recovery Paths
사용자에게 명확한 선택지 제공:
- `fix` - 수동 수정
- `rollback` - 변경사항 되돌리기
- `abort` - 워크플로우 중단

### 3. Safe Defaults
- Timeout 시 → abort
- 불명확한 상황 → ask user
- 위험한 작업 → require explicit confirmation

### 4. Preserve State
에러 발생 시에도 가능한 한 상태 보존:
- 메모리에 현재 상태 저장
- 사용자가 나중에 resume 가능하도록

### 5. Learn from Errors
- 에러 로그 분석
- 자주 발생하는 에러 패턴 식별
- 예방 조치 구현
