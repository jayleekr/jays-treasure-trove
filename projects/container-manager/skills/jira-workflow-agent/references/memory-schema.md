# Memory Schema Reference

Serena MCP 메모리 구조 및 TodoWrite 통합 가이드.

## Overview

JIRA Workflow Agent는 두 가지 주요 상태 관리 시스템을 사용:
1. **Serena Memory**: 세션 간 지속되는 영구 상태 저장
2. **TodoWrite**: 세션 내 실시간 진행 상황 추적

## Serena Memory Structure

### Hierarchical Memory Model

```
jira-workflow-agent/
├── plan_{ticket_id}              # 실행 계획 (최상위)
├── phase_1_analyze_{ticket_id}   # 페이즈 1 상태
├── phase_2_implement_{ticket_id} # 페이즈 2 상태
├── phase_3_verify_{ticket_id}    # 페이즈 3 상태
├── phase_4_submit_{ticket_id}    # 페이즈 4 상태
├── impl_{ticket_id}              # 구현 결과
├── verify_{ticket_id}            # 검증 결과
├── submit_{ticket_id}            # 제출 결과
├── checkpoint_{timestamp}_{id}   # 주기적 체크포인트
├── checkpoint_1_{ticket_id}      # 승인 체크포인트 1
├── checkpoint_2_{ticket_id}      # 승인 체크포인트 2
├── approval_log_{ticket_id}      # 승인 로그
└── workflow_complete_{ticket_id} # 완료 기록
```

---

## Memory Schema Definitions

### 1. plan_{ticket_id}

**목적**: 전체 실행 계획 저장

**구조**:
```yaml
plan_CCU2-17741:
  ticket_id: "CCU2-17741"
  summary: "Add config parameter for daemon startup"
  work_type: "feature"  # feature|bugfix|refactor|doc-update
  complexity: "medium"  # low|medium|high
  priority: "High"      # JIRA priority
  estimated_duration: "15-20 minutes"

  phases:
    - "analyze"
    - "implement"
    - "verify"
    - "submit"

  acceptance_criteria:
    - "Parameter configurable via config file"
    - "Invalid values rejected"
    - "Applied on daemon startup"

  affected_files:
    - "src/daemon/main.cpp"
    - "include/config.h"

  tasks:
    - "Create feature branch"
    - "Add CONFIG_STARTUP_DELAY to config.h"
    - "Update main.cpp to read parameter"
    - "Add validation logic"
    - "Run build & tests"
    - "Create commit"
    - "Create pull request"

  created_at: "2026-01-07T11:00:00Z"
```

**사용**:
```python
# 생성
write_memory(f"plan_{ticket_id}", execution_plan)

# 조회
plan = read_memory(f"plan_{ticket_id}")

# 업데이트
plan['estimated_duration'] = "20-25 minutes"
write_memory(f"plan_{ticket_id}", plan)
```

---

### 2. phase_{N}_{mode}_{ticket_id}

**목적**: 각 워크플로우 페이즈의 실행 상태 및 결과 저장

#### Phase 1: Analyze

```yaml
phase_1_analyze_CCU2-17741:
  status: "completed"  # pending|in_progress|completed|failed
  started_at: "2026-01-07T11:00:00Z"
  completed_at: "2026-01-07T11:02:00Z"
  duration_seconds: 120

  inputs:
    ticket_url: "https://sonatus.atlassian.net/browse/CCU2-17741"

  outputs:
    work_type: "feature"
    complexity: "medium"
    acceptance_criteria: [...]
    affected_files: [...]
    execution_plan: {...}

  errors: null
```

#### Phase 2: Implement

```yaml
phase_2_implement_CCU2-17741:
  status: "completed"
  started_at: "2026-01-07T11:03:00Z"
  completed_at: "2026-01-07T11:20:00Z"
  duration_seconds: 1020

  inputs:
    execution_plan: "plan_CCU2-17741"
    approval_granted: true
    approval_timestamp: "2026-01-07T11:03:30Z"

  outputs:
    branch_name: "CCU2-17741-add-config-parameter"
    modified_files:
      - file: "src/daemon/main.cpp"
        additions: 30
        deletions: 5
      - file: "include/config.h"
        additions: 15
        deletions: 7
    changes_summary: "Added CONFIG_STARTUP_DELAY parameter..."

  errors: null
```

#### Phase 3: Verify

```yaml
phase_3_verify_CCU2-17741:
  status: "completed"
  started_at: "2026-01-07T11:21:00Z"
  completed_at: "2026-01-07T11:23:00Z"
  duration_seconds: 120

  inputs:
    modified_files: [...]

  outputs:
    build:
      success: true
      duration_seconds: 45
      errors: 0
      warnings: 0
      build_system: "cmake"

    tests:
      success: true
      tests_run: 15
      passed: 15
      failed: 0
      skipped: 0
      coverage_percent: 92

    static_analysis:
      passed: true
      violations: 0
      warnings: 2
      tool: "MISRA"

    overall_success: true
    quality_grade: "A"

  errors: null
```

#### Phase 4: Submit

```yaml
phase_4_submit_CCU2-17741:
  status: "completed"
  started_at: "2026-01-07T11:24:00Z"
  completed_at: "2026-01-07T11:25:00Z"
  duration_seconds: 60

  inputs:
    verification_passed: true
    approval_granted: true
    approval_timestamp: "2026-01-07T11:24:20Z"

  outputs:
    commit_hash: "abc123def456"
    commit_message: "[CCU2-17741] Add config parameter..."
    pr_url: "https://github.com/org/repo/pull/123"
    pr_number: 123

  errors: null
```

---

### 3. impl_{ticket_id}

**목적**: 구현 결과의 상세 정보 저장 (Phase 2와 중복되지만 접근 편의성을 위해 별도 저장)

```yaml
impl_CCU2-17741:
  status: "completed"
  timestamp: "2026-01-07T11:20:00Z"

  branch: "CCU2-17741-add-config-parameter"
  base_branch: "master"

  modified_files:
    - file: "src/daemon/main.cpp"
      path: "/Users/jaylee/CodeWorkspace/container-manager/src/daemon/main.cpp"
      additions: 30
      deletions: 5
      diff: |
        @@ -45,5 +45,30 @@
        +    int startup_delay = config.get_startup_delay();
        +    if (startup_delay > 0) {
        +        sleep(startup_delay);
        +    }

    - file: "include/config.h"
      path: "/Users/jaylee/CodeWorkspace/container-manager/include/config.h"
      additions: 15
      deletions: 7

  changes_summary: |
    Added CONFIG_STARTUP_DELAY parameter to config.h
    Updated main.cpp to read and apply the parameter on daemon startup
    Implemented validation logic to ensure value is between 0-60 seconds
    Added error handling for invalid configuration values

  total_additions: 45
  total_deletions: 12
```

---

### 4. verify_{ticket_id}

**목적**: 검증 결과의 상세 정보 저장

```yaml
verify_CCU2-17741:
  status: "completed"
  timestamp: "2026-01-07T11:23:00Z"
  overall_success: true

  build:
    success: true
    build_system: "cmake"
    build_command: "mkdir -p build && cd build && cmake .. && make"
    duration_seconds: 45
    errors: 0
    warnings: 0
    output_size_bytes: 2048576

  tests:
    success: true
    test_framework: "gtest"
    test_command: "cd build && ctest"
    tests_run: 15
    passed: 15
    failed: 0
    skipped: 0
    duration_seconds: 30
    coverage_percent: 92
    failed_tests: []

  static_analysis:
    passed: true
    tool: "MISRA"
    command: "misra-check src/ include/"
    violations: 0
    warnings: 2
    warning_details:
      - rule: "MISRA-C:2012 Rule 2.3"
        severity: "advisory"
        message: "Unused type declaration"
        file: "include/legacy.h"
        line: 45

  quality_grade: "A"  # A|B|C|D|F
```

---

### 5. submit_{ticket_id}

**목적**: 제출 결과 (커밋 및 PR) 정보 저장

```yaml
submit_CCU2-17741:
  status: "completed"
  timestamp: "2026-01-07T11:25:00Z"

  commit:
    hash: "abc123def456789"
    short_hash: "abc123d"
    message: |
      [CCU2-17741] Add config parameter for daemon startup

      Added CONFIG_STARTUP_DELAY parameter to control startup delay.
      Validates value range (0-60 seconds) and applies on daemon startup.

      🤖 Generated with [Claude Code](https://claude.com/claude-code)

      Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
    author: "User Name <user@example.com>"
    timestamp: "2026-01-07T11:24:45Z"

  pull_request:
    url: "https://github.com/org/repo/pull/123"
    number: 123
    title: "[CCU2-17741] Add config parameter for daemon startup"
    description: |
      ## Summary
      Implements CONFIG_STARTUP_DELAY parameter for daemon startup control.

      ## Changes
      - Added parameter to config.h
      - Implemented validation (0-60s range)
      - Applied on daemon startup in main.cpp

      ## Testing
      - ✅ All tests passing (15/15)
      - ✅ MISRA compliance verified
      - ✅ Build successful

      🤖 Generated with [Claude Code](https://claude.com/claude-code)
    state: "open"
    created_at: "2026-01-07T11:25:00Z"

  jira_integration:
    ticket_id: "CCU2-17741"
    status_updated: true
    comment_added: true
```

---

### 6. checkpoint_{timestamp}_{ticket_id}

**목적**: 주기적(30분마다) 또는 중요 시점의 워크플로우 스냅샷 저장

```yaml
checkpoint_2026-01-07T11:15:00Z_CCU2-17741:
  timestamp: "2026-01-07T11:15:00Z"
  ticket_id: "CCU2-17741"

  current_phase: "implement"
  current_mode: 2
  current_task: "Add validation logic"

  completed_phases:
    - "analyze"

  in_progress_phases:
    - "implement"

  pending_phases:
    - "verify"
    - "submit"

  next_actions:
    - "Complete implementation"
    - "Run self-review"
    - "Proceed to verification"

  session_info:
    session_id: "session_123"
    duration_minutes: 15
    token_usage: 5000
```

---

### 7. checkpoint_{1|2}_{ticket_id}

**목적**: 승인 체크포인트의 결정 및 상태 저장

```yaml
checkpoint_1_CCU2-17741:
  checkpoint: "checkpoint_1"
  name: "Before Code Implementation"
  status: "approved"  # approved|modified|rejected|pending
  timestamp: "2026-01-07T11:03:30Z"

  user_decision: "approve"

  presented_plan:
    files: [...]
    approach: [...]
    criteria: [...]

  modifications: null  # null if not modified

checkpoint_2_CCU2-17741:
  checkpoint: "checkpoint_2"
  name: "Before PR Creation"
  status: "approved"
  timestamp: "2026-01-07T11:24:20Z"

  user_decision: "approve"

  presented_details:
    verification: {...}
    commit: {...}
    pr_template: {...}

  modifications: null
```

---

### 8. approval_log_{ticket_id}

**목적**: 모든 승인 결정의 감사 로그

```yaml
approval_log_CCU2-17741:
  - checkpoint: "checkpoint_1"
    decision: "approved"
    timestamp: "2026-01-07T11:03:30Z"
    details: null

  - checkpoint: "checkpoint_2"
    decision: "modified"
    timestamp: "2026-01-07T11:24:20Z"
    details:
      modification_type: "title"
      original_title: "[CCU2-17741] Add config parameter"
      modified_title: "[CCU2-17741] Add config parameter for daemon startup"
```

---

### 9. workflow_complete_{ticket_id}

**목적**: 완료된 워크플로우의 최종 요약

```yaml
workflow_complete_CCU2-17741:
  status: "completed"  # completed|commit_only|aborted
  completed_at: "2026-01-07T11:25:00Z"

  summary:
    ticket_id: "CCU2-17741"
    ticket_summary: "Add config parameter for daemon startup"
    work_type: "feature"
    complexity: "medium"
    priority: "High"

    started_at: "2026-01-07T11:00:00Z"
    total_duration_minutes: 25

    phases_completed:
      - "analyze"
      - "implement"
      - "verify"
      - "submit"

    results:
      branch: "CCU2-17741-add-config-parameter"
      commit_hash: "abc123def456"
      pr_url: "https://github.com/org/repo/pull/123"
      pr_number: 123

    quality_metrics:
      build_success: true
      tests_passed: 15
      test_coverage: 92
      misra_violations: 0
      quality_grade: "A"

  next_steps:
    - "PR review by team"
    - "Merge after approval"
```

---

## TodoWrite Integration

### TodoWrite Structure

TodoWrite는 **세션 내** 실시간 진행 상황을 추적. Serena 메모리는 **세션 간** 지속.

```python
todos = [
    {
        "content": "Analyze JIRA ticket CCU2-17741",
        "status": "completed",  # pending|in_progress|completed|blocked
        "activeForm": "Analyzing JIRA ticket"
    },
    {
        "content": "Generate implementation plan",
        "status": "completed",
        "activeForm": "Generating plan"
    },
    {
        "content": "Create feature branch",
        "status": "in_progress",
        "activeForm": "Creating branch"
    },
    {
        "content": "Implement code changes",
        "status": "pending",
        "activeForm": "Implementing changes"
    },
    {
        "content": "Run build & tests",
        "status": "pending",
        "activeForm": "Running tests"
    },
    {
        "content": "Commit changes",
        "status": "pending",
        "activeForm": "Committing"
    },
    {
        "content": "Create pull request",
        "status": "pending",
        "activeForm": "Creating PR"
    }
]

TodoWrite(todos)
```

### Synchronization Pattern

**TodoWrite → Serena Memory**:

```python
def sync_todo_to_memory(ticket_id, todo_item):
    """TodoWrite 상태를 Serena 메모리에 동기화"""

    # 현재 메모리 상태 조회
    current_checkpoint = read_memory(f"checkpoint_latest_{ticket_id}")

    if not current_checkpoint:
        current_checkpoint = {
            "ticket_id": ticket_id,
            "todo_states": []
        }

    # TodoWrite 상태 추가
    current_checkpoint['todo_states'].append({
        "content": todo_item['content'],
        "status": todo_item['status'],
        "timestamp": now()
    })

    # 메모리 저장
    write_memory(f"checkpoint_latest_{ticket_id}", current_checkpoint)
```

**Serena Memory → TodoWrite** (Resume):

```python
def restore_todo_from_memory(ticket_id):
    """메모리에서 TodoWrite 상태 복원"""

    checkpoint = read_memory(f"checkpoint_latest_{ticket_id}")

    if not checkpoint:
        return None

    # TodoWrite 상태 복원
    todos = []
    for state in checkpoint['todo_states']:
        todos.append({
            "content": state['content'],
            "status": state['status'],
            "activeForm": generate_active_form(state['content'])
        })

    return todos
```

---

## Session Lifecycle Management

### Session Start

```python
def initialize_session(ticket_id):
    """세션 시작 시 초기화"""

    # 1. 기존 메모리 확인
    existing_memories = list_memories()
    resumable = check_resumable_work(ticket_id, existing_memories)

    if resumable:
        # 2. Resume 옵션 제공
        resume = ask_user_resume(resumable)

        if resume:
            # 3. 메모리에서 TodoWrite 복원
            todos = restore_todo_from_memory(ticket_id)
            TodoWrite(todos)

            # 4. 마지막 페이즈부터 재개
            last_phase = resumable['last_phase']
            return resume_from_phase(ticket_id, last_phase)

    # 새 세션 시작
    return start_new_workflow(ticket_id)
```

### Session Checkpoint (30분마다)

```python
def create_checkpoint(ticket_id, current_state):
    """주기적 체크포인트 생성"""

    checkpoint_key = f"checkpoint_{now()}_{ticket_id}"

    checkpoint_data = {
        "timestamp": now(),
        "ticket_id": ticket_id,
        "current_phase": current_state['phase'],
        "current_mode": current_state['mode'],
        "current_task": current_state['task'],
        "completed_phases": current_state['completed'],
        "next_actions": current_state['next']
    }

    write_memory(checkpoint_key, checkpoint_data)

    # 최신 체크포인트 참조 업데이트
    write_memory(f"checkpoint_latest_{ticket_id}", checkpoint_data)
```

### Session End

```python
def finalize_session(ticket_id, status):
    """세션 종료 시 정리"""

    if status == "completed":
        # 1. 최종 요약 저장
        write_memory(f"workflow_complete_{ticket_id}", generate_summary())

        # 2. 임시 체크포인트 삭제 (선택적)
        delete_memory(f"checkpoint_latest_{ticket_id}")

        # 3. TodoWrite 상태 완료 마킹
        mark_all_todos_complete()

    elif status == "paused":
        # 1. 현재 상태 체크포인트 저장
        create_checkpoint(ticket_id, get_current_state())

        # 2. Resume 가이드 표시
        display_resume_guide(ticket_id)

    elif status == "aborted":
        # 1. 중단 사유 기록
        write_memory(f"workflow_aborted_{ticket_id}", {
            "reason": "User aborted",
            "timestamp": now()
        })

        # 2. 정리 옵션 제공
        offer_cleanup_options(ticket_id)
```

---

## Memory Cleanup Strategies

### 1. Automatic Cleanup

```python
def auto_cleanup_old_memories(days=30):
    """오래된 메모리 자동 정리"""

    all_memories = list_memories()
    cutoff_date = now() - timedelta(days=days)

    for memory_key in all_memories:
        memory_data = read_memory(memory_key)

        if 'timestamp' in memory_data:
            if memory_data['timestamp'] < cutoff_date:
                # 완료된 워크플로우의 오래된 체크포인트 삭제
                if memory_key.startswith("checkpoint_") and \
                   not memory_key.startswith("checkpoint_latest"):
                    delete_memory(memory_key)
```

### 2. Manual Cleanup

```python
def cleanup_workflow_memories(ticket_id, keep_summary=True):
    """특정 티켓의 메모리 정리"""

    memories_to_delete = [
        f"plan_{ticket_id}",
        f"phase_1_analyze_{ticket_id}",
        f"phase_2_implement_{ticket_id}",
        f"phase_3_verify_{ticket_id}",
        f"phase_4_submit_{ticket_id}",
        f"impl_{ticket_id}",
        f"verify_{ticket_id}",
        f"submit_{ticket_id}",
        f"checkpoint_1_{ticket_id}",
        f"checkpoint_2_{ticket_id}",
        f"approval_log_{ticket_id}"
    ]

    # 체크포인트 삭제
    checkpoints = [k for k in list_memories() if k.startswith(f"checkpoint_") and ticket_id in k]
    memories_to_delete.extend(checkpoints)

    # 삭제 실행
    for memory_key in memories_to_delete:
        delete_memory(memory_key)

    if not keep_summary:
        delete_memory(f"workflow_complete_{ticket_id}")
```

### 3. Selective Cleanup

```python
def cleanup_temporary_memories(ticket_id):
    """임시 메모리만 정리 (완료 기록은 유지)"""

    temporary_patterns = [
        f"checkpoint_*_{ticket_id}",
        f"phase_*_{ticket_id}"
    ]

    for pattern in temporary_patterns:
        matching_keys = find_memories_by_pattern(pattern)
        for key in matching_keys:
            delete_memory(key)

    # 핵심 메모리 유지:
    # - plan_{ticket_id}
    # - workflow_complete_{ticket_id}
```

---

## Best Practices

### 1. Memory Key Naming
- 일관된 네이밍 컨벤션 사용
- 티켓 ID 항상 포함
- 타임스탬프는 ISO 8601 형식

### 2. Data Validation
```python
def validate_memory_data(data, schema):
    """메모리 데이터 검증"""
    required_fields = schema['required']
    for field in required_fields:
        if field not in data:
            raise ValueError(f"Missing required field: {field}")
    return True
```

### 3. Error Handling
```python
def safe_write_memory(key, data):
    """안전한 메모리 쓰기 (에러 처리 포함)"""
    try:
        write_memory(key, data)
        return True
    except Exception as e:
        log_error(f"Failed to write memory {key}: {e}")
        return False
```

### 4. Memory Size Management
- 대용량 데이터 (예: full diff)는 별도 파일로 저장
- 메모리에는 참조(파일 경로)만 저장
- 정기적으로 오래된 메모리 정리

### 5. Cross-Session Continuity
```python
def ensure_continuity(ticket_id):
    """세션 간 연속성 보장"""

    # 1. 마지막 상태 확인
    latest = read_memory(f"checkpoint_latest_{ticket_id}")

    if not latest:
        return None

    # 2. 복원 가능 여부 판단
    can_resume = (
        latest['current_phase'] in ['analyze', 'implement', 'verify'] and
        latest['timestamp'] < now() - timedelta(hours=24)
    )

    return can_resume
```
