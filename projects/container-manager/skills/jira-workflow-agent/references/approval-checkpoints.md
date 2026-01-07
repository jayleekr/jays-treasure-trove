# Approval Checkpoints Reference

승인 체크포인트 처리 로직 및 UI/UX 패턴 가이드.

## Overview

Semi-auto 모드에서는 2개의 전략적 승인 체크포인트가 존재:
1. **Checkpoint 1**: 코드 구현 전 (Mode 2: IMPLEMENT)
2. **Checkpoint 2**: PR 생성 전 (Mode 4: SUBMIT)

## Checkpoint 1: Before Code Implementation

### Location
Mode 2 (IMPLEMENT), Step 4 - 브랜치 생성 후, 코드 작성 전

### Purpose
- 사용자가 구현 계획을 검토하고 승인할 기회 제공
- 잘못된 방향으로 코드 작성하는 것 방지
- 계획 조정 또는 중단 옵션 제공

### Implementation

```python
def request_implementation_approval(ticket_id, branch, affected_files, implementation_approach):
    """
    Checkpoint 1: 구현 전 승인 요청
    """
    # 1. 계획 정보 수집
    plan = read_memory(f"plan_{ticket_id}")

    # 2. 승인 UI 표시
    display_approval_checkpoint_1(
        ticket_id=ticket_id,
        branch=branch,
        work_type=plan['work_type'],
        complexity=plan['complexity'],
        affected_files=affected_files,
        approach=implementation_approach,
        acceptance_criteria=plan['acceptance_criteria'],
        estimated_effort=plan['estimated_duration']
    )

    # 3. 사용자 입력 대기
    user_response = get_user_input(
        prompt="**Proceed with code implementation?**",
        options=["approve", "modify", "reject"]
    )

    # 4. 응답 처리
    if user_response == "approve":
        log_approval(ticket_id, "checkpoint_1", "approved")
        return "approve"

    elif user_response == "modify":
        # 수정 사항 수집
        modifications = collect_user_modifications()
        log_approval(ticket_id, "checkpoint_1", "modified", modifications)
        return "modify"

    elif user_response == "reject":
        log_approval(ticket_id, "checkpoint_1", "rejected")
        return "reject"

    else:
        # 기본값: reject (안전 모드)
        return "reject"
```

### UI Template

```markdown
## 🔍 Implementation Plan Review

**JIRA**: {ticket_id} - {summary}
**Work Type**: {work_type} | **Complexity**: {complexity}
**Branch**: {branch_name}

### Planned Changes:
- **Files to Modify**:
{affected_files_list}

- **Implementation Approach**:
{step_by_step_approach}

- **Estimated Effort**: {duration}
- **Risk**: {risk_level} ({risk_justification})

### Acceptance Criteria:
{acceptance_criteria_checkboxes}

---

**Proceed with code implementation?**

- `approve` - Continue with implementation as planned
- `modify` - Adjust the plan before proceeding
- `reject` - Abort workflow and cleanup

**Your choice**: _
```

### Example Output

```markdown
## 🔍 Implementation Plan Review

**JIRA**: CCU2-17741 - Add config parameter for daemon startup
**Work Type**: Feature | **Complexity**: Medium
**Branch**: CCU2-17741-add-config-parameter

### Planned Changes:
- **Files to Modify**:
  - src/daemon/main.cpp
  - include/config.h

- **Implementation Approach**:
  1. Add CONFIG_STARTUP_DELAY parameter to config.h
  2. Update main.cpp to read the parameter on startup
  3. Add validation logic (0-60 second range)
  4. Handle invalid values with default fallback

- **Estimated Effort**: 15-20 minutes
- **Risk**: Low (isolated change, no external dependencies)

### Acceptance Criteria:
- [ ] Parameter configurable via config file
- [ ] Invalid values rejected with error message
- [ ] Applied on daemon startup

---

**Proceed with code implementation?**

- `approve` - Continue with implementation as planned
- `modify` - Adjust the plan before proceeding
- `reject` - Abort workflow and cleanup

**Your choice**: _
```

### Response Handling

#### approve
```python
def handle_checkpoint1_approve(ticket_id):
    """승인 시 처리"""
    write_memory(f"checkpoint_1_{ticket_id}", {
        "status": "approved",
        "timestamp": now(),
        "user_decision": "approve"
    })

    # 구현 진행
    return execute_code_implementation(ticket_id)
```

#### modify
```python
def handle_checkpoint1_modify(ticket_id):
    """수정 요청 시 처리"""
    # 1. 수정 사항 수집
    print("\n### 🔧 Plan Modification\n")
    print("What would you like to change?")
    print("- `files` - Adjust affected files list")
    print("- `approach` - Change implementation approach")
    print("- `criteria` - Update acceptance criteria")
    print("- `cancel` - Cancel modification")

    modification_type = get_user_input("Modification type: ")

    if modification_type == "files":
        new_files = collect_file_modifications()
        update_affected_files(ticket_id, new_files)

    elif modification_type == "approach":
        new_approach = collect_approach_modifications()
        update_implementation_approach(ticket_id, new_approach)

    elif modification_type == "criteria":
        new_criteria = collect_criteria_modifications()
        update_acceptance_criteria(ticket_id, new_criteria)

    elif modification_type == "cancel":
        return "approve"  # 수정 취소, 원래 계획으로 진행

    # 2. 수정된 계획 저장
    updated_plan = read_memory(f"plan_{ticket_id}")
    write_memory(f"plan_{ticket_id}_modified", updated_plan)

    # 3. 수정된 계획 재표시
    print("\n### Updated Plan:")
    display_approval_checkpoint_1(ticket_id, ...)

    # 4. 재승인 요청
    re_approval = get_user_input("Proceed with modified plan? (yes/no): ")

    if re_approval == "yes":
        return "approve"
    else:
        return "reject"
```

#### reject
```python
def handle_checkpoint1_reject(ticket_id):
    """거부 시 처리"""
    write_memory(f"checkpoint_1_{ticket_id}", {
        "status": "rejected",
        "timestamp": now(),
        "user_decision": "reject"
    })

    # 브랜치 삭제 옵션 제공
    cleanup = get_user_input("Delete feature branch? (yes/no): ")

    if cleanup == "yes":
        rollback_branch(ticket_id)

    return "Workflow aborted by user"
```

---

## Checkpoint 2: Before PR Creation

### Location
Mode 4 (SUBMIT), Step 4 - 커밋 생성 후, PR 생성 전

### Purpose
- 사용자가 PR 상세 정보를 검토하고 승인할 기회 제공
- 검증 결과 확인 후 PR 생성 여부 결정
- PR 제목/설명 수정 또는 커밋만 유지 옵션 제공

### Implementation

```python
def request_pr_approval(ticket_id, branch, commit_hash, verification, files_changed):
    """
    Checkpoint 2: PR 생성 전 승인 요청
    """
    # 1. 검증 및 커밋 정보 수집
    plan = read_memory(f"plan_{ticket_id}")
    impl = read_memory(f"impl_{ticket_id}")

    # 2. PR 상세 정보 준비
    pr_details = generate_pr_details(
        ticket_id=ticket_id,
        summary=plan['summary'],
        branch=branch,
        commit_hash=commit_hash,
        work_type=plan['work_type'],
        files_changed=files_changed,
        verification_results=verification
    )

    # 3. 승인 UI 표시
    display_approval_checkpoint_2(
        ticket_id=ticket_id,
        branch=branch,
        commit_hash=commit_hash,
        verification=verification,
        pr_details=pr_details
    )

    # 4. 사용자 입력 대기
    user_response = get_user_input(
        prompt="**Create pull request?**",
        options=["approve", "modify", "reject"]
    )

    # 5. 응답 처리
    if user_response == "approve":
        log_approval(ticket_id, "checkpoint_2", "approved")
        return "approve"

    elif user_response == "modify":
        # PR 상세 수정
        modified_details = collect_pr_modifications()
        log_approval(ticket_id, "checkpoint_2", "modified", modified_details)
        return "modify"

    elif user_response == "reject":
        log_approval(ticket_id, "checkpoint_2", "rejected")
        return "reject"

    else:
        # 기본값: reject (안전 모드)
        return "reject"
```

### UI Template

```markdown
## 📤 Pull Request Review

**JIRA**: {ticket_id} - {summary}
**Branch**: {branch_name}
**Commit**: {commit_hash}

### Verification Results:
- {build_status} Build: {build_result}
- {test_status} Tests: {test_result}
- {analysis_status} Static Analysis: {analysis_result}
- {overall_status} Quality: {quality_grade}

### PR Details:
- **Title**: {pr_title}
- **Files**: {file_count} modified ({additions_count} additions, {deletions_count} deletions)
{file_changes_list}

### Changes Summary:
{implementation_summary}

---

**Create pull request?**

- `approve` - Create PR now with these details
- `modify` - Edit PR title, description, or other details
- `reject` - Keep commits on branch only (no PR)

**Your choice**: _
```

### Example Output

```markdown
## 📤 Pull Request Review

**JIRA**: CCU2-17741 - Add config parameter for daemon startup
**Branch**: CCU2-17741-add-config-parameter
**Commit**: abc123def456

### Verification Results:
- ✅ Build: PASSED (0 errors, 0 warnings)
- ✅ Tests: PASSED (15/15 tests)
- ✅ Static Analysis: PASSED (0 violations)
- ✅ Quality: Grade A

### PR Details:
- **Title**: [CCU2-17741] Add config parameter for daemon startup
- **Files**: 2 modified (+45/-12 lines)
  - src/daemon/main.cpp (+30/-5)
  - include/config.h (+15/-7)

### Changes Summary:
- Added CONFIG_STARTUP_DELAY parameter to config.h
- Implemented validation logic (0-60 second range)
- Applied parameter on daemon startup
- Added error handling for invalid values

---

**Create pull request?**

- `approve` - Create PR now with these details
- `modify` - Edit PR title, description, or other details
- `reject` - Keep commits on branch only (no PR)

**Your choice**: _
```

### Response Handling

#### approve
```python
def handle_checkpoint2_approve(ticket_id):
    """승인 시 처리"""
    write_memory(f"checkpoint_2_{ticket_id}", {
        "status": "approved",
        "timestamp": now(),
        "user_decision": "approve"
    })

    # PR 생성
    return execute_jira_pr(ticket_id)
```

#### modify
```python
def handle_checkpoint2_modify(ticket_id):
    """수정 요청 시 처리"""
    # 1. 수정 가능 항목 표시
    print("\n### 🔧 PR Details Modification\n")
    print("What would you like to change?")
    print("- `title` - Edit PR title")
    print("- `description` - Edit PR description")
    print("- `reviewers` - Add/change reviewers")
    print("- `labels` - Add/change labels")
    print("- `cancel` - Cancel modification")

    modification_type = get_user_input("Modification type: ")

    pr_details = {}

    if modification_type == "title":
        new_title = get_user_input("New PR title: ")
        pr_details['title'] = new_title

    elif modification_type == "description":
        new_description = get_multiline_input("New PR description: ")
        pr_details['description'] = new_description

    elif modification_type == "reviewers":
        reviewers = get_user_input("Reviewers (comma-separated): ")
        pr_details['reviewers'] = reviewers.split(',')

    elif modification_type == "labels":
        labels = get_user_input("Labels (comma-separated): ")
        pr_details['labels'] = labels.split(',')

    elif modification_type == "cancel":
        return "approve"  # 수정 취소, 원래 PR로 진행

    # 2. 수정된 PR 상세 저장
    write_memory(f"pr_details_{ticket_id}_modified", pr_details)

    # 3. 재승인 요청
    re_approval = get_user_input("Create PR with modified details? (yes/no): ")

    if re_approval == "yes":
        return {"action": "approve", "details": pr_details}
    else:
        return "reject"
```

#### reject
```python
def handle_checkpoint2_reject(ticket_id):
    """거부 시 처리"""
    write_memory(f"checkpoint_2_{ticket_id}", {
        "status": "rejected",
        "timestamp": now(),
        "user_decision": "reject",
        "note": "Commit preserved, no PR created"
    })

    print("\n### ℹ️ PR Creation Cancelled")
    print(f"Your commits are preserved on branch: {branch_name}")
    print("You can create a PR manually later using:")
    print(f"  /jira-pr {ticket_id}")

    return "commit_only"
```

---

## Approval Flow Diagrams

### Checkpoint 1 Flow

```
┌──────────────────────┐
│  Display Plan Review │
│  - Files             │
│  - Approach          │
│  - Criteria          │
│  - Risk              │
└──────────┬───────────┘
           │
    Request Input
           │
     ┌─────┴─────┐
     │  approve  │
     │  modify   │
     │  reject   │
     └─────┬─────┘
           │
     ┌─────┴──────┬───────────┬──────────┐
     │            │           │          │
  approve      modify      reject    timeout
     │            │           │          │
     ↓            ↓           ↓          ↓
Implement   ┌─────────┐  Rollback   Default:
  Code      │ Collect │  Branch     Reject
            │  Mods   │
            └────┬────┘
                 │
          Update Plan
                 │
            Re-display
                 │
          Request Input
                 │
           ┌─────┴─────┐
          yes         no
           │           │
           ↓           ↓
      Implement    Reject
```

### Checkpoint 2 Flow

```
┌──────────────────────┐
│ Display PR Review    │
│ - Verification       │
│ - Commit Info        │
│ - PR Details         │
└──────────┬───────────┘
           │
    Request Input
           │
     ┌─────┴─────┐
     │  approve  │
     │  modify   │
     │  reject   │
     └─────┬─────┘
           │
     ┌─────┴──────┬───────────┬──────────┐
     │            │           │          │
  approve      modify      reject    timeout
     │            │           │          │
     ↓            ↓           ↓          ↓
Create PR   ┌─────────┐  Commit    Default:
            │ Collect │   Only     Reject
            │PR Mods  │
            └────┬────┘
                 │
          Update Details
                 │
          Request Input
                 │
           ┌─────┴─────┐
          yes         no
           │           │
           ↓           ↓
      Create PR   Commit Only
```

---

## User Experience Patterns

### Clear Decision Options

**Good Example** (명확한 선택지):
```
**Proceed with code implementation?**

- `approve` - Continue with implementation as planned
- `modify` - Adjust the plan before proceeding
- `reject` - Abort workflow and cleanup

**Your choice**: _
```

**Bad Example** (모호한 선택지):
```
What do you want to do? (y/n/m)
```

### Context-Rich Information

**Good Example** (충분한 컨텍스트):
```
### Planned Changes:
- **Files to Modify**:
  - src/daemon/main.cpp
  - include/config.h

- **Implementation Approach**:
  1. Add CONFIG_STARTUP_DELAY to config.h
  2. Update main.cpp to read parameter
  3. Add validation (0-60s range)

- **Risk**: Low (isolated change)
```

**Bad Example** (불충분한 정보):
```
Files: 2
Approach: Add parameter
```

### Visual Indicators

사용 권장 기호:
- ✅ : 성공, 통과
- ❌ : 실패, 오류
- ⚠️ : 경고
- ℹ️ : 정보
- 🔍 : 검토, 분석
- 📤 : 제출, PR
- 🔧 : 수정, 조정

---

## Timeout and Default Behavior

### Timeout Policy
- 기본 대기 시간: **5분**
- Timeout 발생 시 기본 동작: **reject** (안전 모드)

```python
def get_user_input_with_timeout(prompt, options, timeout=300):
    """사용자 입력 대기 (timeout 적용)"""
    import select
    import sys

    print(prompt)
    print(f"(Timeout: {timeout}s)")

    ready, _, _ = select.select([sys.stdin], [], [], timeout)

    if ready:
        response = sys.stdin.readline().strip()
        if response in options:
            return response
        else:
            print(f"Invalid option. Expected: {options}")
            return None
    else:
        print("\n⏱️ Timeout reached. Defaulting to 'reject' for safety.")
        return "reject"
```

---

## Logging and Audit Trail

### Approval Logging

```python
def log_approval(ticket_id, checkpoint, decision, details=None):
    """승인 결정 로깅"""
    log_entry = {
        "ticket_id": ticket_id,
        "checkpoint": checkpoint,  # "checkpoint_1" or "checkpoint_2"
        "decision": decision,       # "approved", "modified", "rejected"
        "timestamp": now(),
        "details": details
    }

    # Serena 메모리에 로그 저장
    existing_logs = read_memory(f"approval_log_{ticket_id}") or []
    existing_logs.append(log_entry)
    write_memory(f"approval_log_{ticket_id}", existing_logs)

    # 로컬 파일 로그 (옵션)
    append_to_file("~/.claude-config/logs/approvals.log", log_entry)
```

### Audit Report Generation

```python
def generate_approval_audit_report(ticket_id):
    """승인 감사 리포트 생성"""
    logs = read_memory(f"approval_log_{ticket_id}")

    if not logs:
        return "No approval logs found"

    report = f"## Approval Audit Report\n\n"
    report += f"**JIRA**: {ticket_id}\n\n"

    for log in logs:
        report += f"### {log['checkpoint']}\n"
        report += f"- **Decision**: {log['decision']}\n"
        report += f"- **Timestamp**: {log['timestamp']}\n"

        if log['details']:
            report += f"- **Details**: {log['details']}\n"

        report += "\n"

    return report
```

---

## Best Practices

### 1. Always Provide Context
승인 요청 시 사용자가 의사결정에 필요한 모든 정보 제공:
- 무엇을 할 것인가 (What)
- 왜 하는가 (Why)
- 어떤 영향이 있는가 (Impact)
- 얼마나 걸리는가 (Effort)
- 위험은 무엇인가 (Risk)

### 2. Clear Action Items
선택지는 명확하고 구체적으로:
- ✅ `approve` - Create PR now
- ❌ `ok` - Do something (모호함)

### 3. Safe Defaults
- Timeout 시 항상 **reject** (안전 모드)
- 불명확한 입력 시 재요청 또는 reject
- 중요한 작업 전 항상 확인

### 4. Modification Support
사용자가 계획이나 PR 상세를 조정할 수 있도록 지원:
- 파일 목록 수정
- 구현 방법 조정
- PR 제목/설명 변경

### 5. Logging and Traceability
모든 승인 결정을 로그로 남겨 추적 가능성 확보

---

## Integration with Serena Memory

### Memory Keys for Approvals

```yaml
checkpoint_1_{ticket_id}:
  status: "approved" | "modified" | "rejected"
  timestamp: "2026-01-07T12:00:00Z"
  user_decision: "approve"
  modifications: {...}  # if modified

checkpoint_2_{ticket_id}:
  status: "approved" | "modified" | "rejected"
  timestamp: "2026-01-07T12:30:00Z"
  user_decision: "approve"
  pr_modifications: {...}  # if modified

approval_log_{ticket_id}:
  - checkpoint: "checkpoint_1"
    decision: "approved"
    timestamp: "2026-01-07T12:00:00Z"
  - checkpoint: "checkpoint_2"
    decision: "modified"
    timestamp: "2026-01-07T12:30:00Z"
    details: {"title": "New PR title"}
```

### Cross-Session Resume

승인 상태는 세션 간 유지되므로 중단 후 재개 가능:

```python
def resume_after_checkpoint(ticket_id, checkpoint):
    """체크포인트 이후 재개"""
    approval_state = read_memory(f"checkpoint_{checkpoint}_{ticket_id}")

    if not approval_state:
        # 체크포인트 이력 없음, 처음부터 시작
        return None

    if approval_state['status'] == "approved":
        # 이미 승인됨, 다음 단계로 진행
        return "continue"

    elif approval_state['status'] == "rejected":
        # 이전에 거부됨, 재시작 여부 확인
        return "ask_restart"

    elif approval_state['status'] == "modified":
        # 수정된 계획으로 진행
        return "continue_with_modifications"
```
