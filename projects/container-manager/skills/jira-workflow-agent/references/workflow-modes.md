# Workflow Modes Reference

5가지 워크플로우 모드의 상세 실행 로직 및 구현 가이드.

## Mode 1: ANALYZE (자동 실행)

**목적**: JIRA 티켓 분석 및 실행 계획 생성

### Input
- JIRA 티켓 URL: `https://sonatus.atlassian.net/browse/CCU2-XXXXX`
- 또는 티켓 ID: `CCU2-XXXXX`

### Execution Logic

```python
def execute_analyze_mode(ticket_url_or_id):
    """
    Mode 1: ANALYZE - 티켓 분석 및 실행 계획 생성
    """
    # Step 1: Ticket ID 추출 및 검증
    ticket_id = extract_ticket_id(ticket_url_or_id)
    if not validate_ticket_id(ticket_id):
        raise ValueError(f"Invalid ticket format: {ticket_id}")

    # Step 2: JIRA API 호출
    ticket_data = fetch_jira_ticket(ticket_id)

    # Step 3: 작업 유형 분류
    work_type = classify_work_type(
        issue_type=ticket_data['issuetype'],
        labels=ticket_data['labels'],
        summary=ticket_data['summary']
    )
    # Options: "feature", "bugfix", "refactor", "doc-update"

    # Step 4: 복잡도 추정
    complexity = estimate_complexity(
        description=ticket_data['description'],
        components=ticket_data['components'],
        issuelinks=ticket_data['issuelinks']
    )
    # Options: "low", "medium", "high"

    # Step 5: 요구사항 파싱
    acceptance_criteria = extract_acceptance_criteria(
        ticket_data['description']
    )

    # Step 6: 영향받는 파일/컴포넌트 식별
    affected_files = identify_affected_files(
        description=ticket_data['description'],
        components=ticket_data['components']
    )

    # Step 7: 실행 계획 생성
    execution_plan = generate_execution_plan(
        ticket_id=ticket_id,
        work_type=work_type,
        complexity=complexity,
        acceptance_criteria=acceptance_criteria,
        affected_files=affected_files,
        priority=ticket_data['priority']
    )

    # Step 8: Serena 메모리 저장
    write_memory(f"plan_{ticket_id}", execution_plan)
    write_memory(f"phase_1_analyze_{ticket_id}", {
        "status": "completed",
        "timestamp": now(),
        "outputs": {
            "work_type": work_type,
            "complexity": complexity,
            "affected_files": affected_files
        }
    })

    # Step 9: TodoWrite 체크박스 생성
    create_todo_checklist(execution_plan)

    # Step 10: 사용자에게 계획 표시
    display_execution_plan(execution_plan)

    return execution_plan
```

### Output Format

```markdown
## 📋 Execution Plan

**JIRA**: CCU2-17741 - Add config parameter for daemon startup
**Work Type**: Feature
**Priority**: High
**Complexity**: Medium

### Affected Files:
- src/daemon/main.cpp
- include/config.h

### Acceptance Criteria:
- [ ] Parameter configurable via config file
- [ ] Invalid values rejected
- [ ] Applied on daemon startup

### Implementation Plan:
1. Add CONFIG_STARTUP_DELAY to config.h
2. Update main.cpp to read parameter
3. Add validation logic (0-60 second range)

### Estimated Effort: 15-20 minutes

### Tasks:
- [ ] Analyze JIRA ticket CCU2-17741
- [ ] Generate implementation plan
- [ ] Create feature branch
- [ ] Implement code changes
- [ ] Run build & tests
- [ ] Commit changes
- [ ] Create pull request
```

### State Transitions

```
START
  ↓
[JIRA API Call] → ticket_data
  ↓
[Work Type Classification] → feature|bugfix|refactor|doc-update
  ↓
[Complexity Estimation] → low|medium|high
  ↓
[Requirements Parsing] → acceptance_criteria[]
  ↓
[File Identification] → affected_files[]
  ↓
[Plan Generation] → execution_plan
  ↓
[Memory Save] → write_memory("plan_CCU2-XXXXX", ...)
  ↓
[TodoWrite] → create_checklist()
  ↓
END (Mode 1 완료, Mode 2 준비)
```

### Error Handling

**JIRA API Errors**:
```python
def handle_jira_error(response):
    if response.status_code == 401:
        return "Authentication failed. Check JIRA credentials in ~/.env"
    elif response.status_code == 403:
        return "Access denied. Verify ticket permissions"
    elif response.status_code == 404:
        return "Ticket not found. Check ticket ID format"
    elif response.status_code == 429:
        return "Rate limited. Wait and retry"
    else:
        return f"JIRA API error: {response.text}"
```

---

## Mode 2: IMPLEMENT (승인 필요 ⚠️)

**목적**: 브랜치 생성 및 코드 구현

### Input
- Execution plan from Mode 1 (via memory)
- User approval at checkpoint 1

### Execution Logic

```python
def execute_implement_mode(ticket_id):
    """
    Mode 2: IMPLEMENT - 브랜치 생성 및 코드 구현
    """
    # Step 1: 실행 계획 불러오기
    execution_plan = read_memory(f"plan_{ticket_id}")
    if not execution_plan:
        raise ValueError(f"No execution plan found for {ticket_id}")

    # Step 2: Git 상태 확인
    git_status = check_git_status()
    if git_status['uncommitted_changes']:
        raise ValueError("Uncommitted changes detected. Please commit or stash first")

    current_branch = git_status['current_branch']
    if current_branch in ['main', 'master']:
        # Step 3: Feature 브랜치 생성
        branch_name = generate_branch_name(
            ticket_id=ticket_id,
            summary=execution_plan['summary']
        )
        # Format: CCU2-17741-add-config-parameter

        create_feature_branch(branch_name)
    else:
        branch_name = current_branch

    # Step 4: APPROVAL CHECKPOINT 1 ⚠️
    approval = request_implementation_approval(
        ticket_id=ticket_id,
        branch=branch_name,
        affected_files=execution_plan['affected_files'],
        implementation_approach=execution_plan['tasks']
    )

    if approval == "reject":
        rollback_branch(branch_name)
        return "Implementation rejected by user"

    if approval == "modify":
        # 사용자가 계획 수정 요청
        modified_plan = get_user_modifications()
        execution_plan = update_execution_plan(execution_plan, modified_plan)
        write_memory(f"plan_{ticket_id}", execution_plan)

    # Step 5: 승인된 경우 코드 구현
    implementation_results = implement_code_changes(
        work_type=execution_plan['work_type'],
        affected_files=execution_plan['affected_files'],
        acceptance_criteria=execution_plan['acceptance_criteria']
    )

    # Step 6: 구현 결과 메모리 저장
    write_memory(f"impl_{ticket_id}", {
        "status": "completed",
        "timestamp": now(),
        "branch": branch_name,
        "modified_files": implementation_results['files'],
        "changes_summary": implementation_results['summary']
    })

    # Step 7: TodoWrite 업데이트
    update_todo_status("Implement code changes", "completed")

    # Step 8: 사용자에게 결과 표시
    display_implementation_results(implementation_results)

    return implementation_results
```

### Approval Checkpoint 1 UI

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
  1. Add CONFIG_STARTUP_DELAY to config.h
  2. Update main.cpp to read parameter
  3. Add validation (0-60 second range)

- **Estimated Effort**: 15-20 minutes
- **Risk**: Low (isolated change)

### Acceptance Criteria:
- [ ] Parameter configurable via config file
- [ ] Invalid values rejected
- [ ] Applied on daemon startup

**Proceed with code implementation?**
- `approve` - Continue with implementation
- `modify` - Adjust the plan
- `reject` - Abort workflow
```

### State Transitions

```
START (from Mode 1)
  ↓
[Load Plan] → read_memory("plan_CCU2-XXXXX")
  ↓
[Git Status Check] → uncommitted? → Error
  ↓
[Branch Creation] → CCU2-XXXXX-brief-description
  ↓
[APPROVAL CHECKPOINT 1] → approve|modify|reject
  ↓                              ↓       ↓
approve                      modify   reject
  ↓                              ↓       ↓
[Code Implementation]      [Update Plan] [Rollback]
  ↓                              ↓       ↓
[Memory Save]              [Re-approve]  END
  ↓                              ↓
[TodoWrite Update]         [Continue]
  ↓                              ↓
END (Mode 2 완료)           [Implement]
```

---

## Mode 3: VERIFY (자동 실행)

**목적**: 빌드 및 테스트 실행

### Input
- Implementation results from Mode 2 (via memory)
- Modified files list

### Execution Logic

```python
def execute_verify_mode(ticket_id):
    """
    Mode 3: VERIFY - 빌드 및 테스트 실행
    """
    # Step 1: 구현 상태 확인
    impl_state = read_memory(f"impl_{ticket_id}")
    if not impl_state or impl_state['status'] != 'completed':
        raise ValueError(f"No completed implementation for {ticket_id}")

    # Step 2: 빌드 시스템 감지
    build_system = detect_build_system()
    # Options: "cmake", "yocto", "npm", "cargo", "make"

    # Step 3: 빌드 실행
    build_result = execute_build(build_system)

    if build_result['success']:
        # Step 4: 테스트 실행
        test_result = execute_tests(build_system)

        # Step 5: 정적 분석 (C/C++인 경우 MISRA)
        static_analysis_result = None
        if is_cpp_project():
            static_analysis_result = run_misra_analysis(
                files=impl_state['modified_files']
            )
    else:
        test_result = {"skipped": True, "reason": "Build failed"}
        static_analysis_result = None

    # Step 6: 검증 리포트 생성
    verification_report = generate_verification_report(
        build=build_result,
        tests=test_result,
        static_analysis=static_analysis_result
    )

    # Step 7: 메모리 저장
    write_memory(f"verify_{ticket_id}", {
        "status": "completed" if build_result['success'] else "failed",
        "timestamp": now(),
        "build": build_result,
        "tests": test_result,
        "static_analysis": static_analysis_result,
        "overall_success": all([
            build_result['success'],
            test_result.get('success', False),
            static_analysis_result.get('passed', True) if static_analysis_result else True
        ])
    })

    # Step 8: TodoWrite 업데이트
    update_todo_status("Run build & tests", "completed")

    # Step 9: 검증 리포트 표시
    display_verification_report(verification_report)

    return verification_report
```

### Output Format

```markdown
## ✅ Verification Report

**JIRA**: CCU2-17741

### Build Results:
- **Status**: ✅ PASSED
- **Duration**: 45 seconds
- **Errors**: 0
- **Warnings**: 0
- **Build System**: CMake

### Test Results:
- **Status**: ✅ PASSED
- **Tests Run**: 15
- **Passed**: 15
- **Failed**: 0
- **Skipped**: 0
- **Coverage**: 92%

### Static Analysis (MISRA):
- **Status**: ✅ PASSED
- **Violations**: 0
- **Warnings**: 2 (informational)

### Overall Quality: Grade A

✅ Ready for submission.
```

### Build System Detection

```python
def detect_build_system():
    """빌드 시스템 자동 감지"""
    if file_exists("CMakeLists.txt"):
        return "cmake"
    elif file_exists("bitbake.conf") or dir_exists("poky"):
        return "yocto"
    elif file_exists("package.json"):
        return "npm"
    elif file_exists("Cargo.toml"):
        return "cargo"
    elif file_exists("Makefile"):
        return "make"
    else:
        raise ValueError("No supported build system detected")
```

### State Transitions

```
START (from Mode 2)
  ↓
[Load Impl State] → read_memory("impl_CCU2-XXXXX")
  ↓
[Detect Build System] → cmake|yocto|npm|cargo|make
  ↓
[Execute Build]
  ↓
  ├─ Success → [Run Tests] → [Static Analysis] → [Report]
  │                ↓              ↓
  │              Pass/Fail      Pass/Fail
  │                ↓              ↓
  │           [Overall Success Assessment]
  │                ↓
  └─ Failure → [Skip Tests] → [Report Build Failure]
                   ↓
              [Error Analysis]
                   ↓
              [Suggest Fixes]
  ↓
[Memory Save] → write_memory("verify_CCU2-XXXXX")
  ↓
[TodoWrite Update]
  ↓
Decision: Success? → YES: Mode 4, NO: Abort with options
```

---

## Mode 4: SUBMIT (승인 필요 ⚠️)

**목적**: 커밋 및 PR 생성

### Input
- Verification results from Mode 3 (via memory)
- Build/test success confirmation

### Execution Logic

```python
def execute_submit_mode(ticket_id):
    """
    Mode 4: SUBMIT - 커밋 및 PR 생성
    """
    # Step 1: 검증 결과 확인
    verify_state = read_memory(f"verify_{ticket_id}")
    if not verify_state or not verify_state['overall_success']:
        raise ValueError(f"Verification failed for {ticket_id}. Cannot submit")

    # Step 2: 커밋 메시지 생성
    plan = read_memory(f"plan_{ticket_id}")
    impl = read_memory(f"impl_{ticket_id}")

    commit_message = generate_commit_message(
        ticket_id=ticket_id,
        summary=plan['summary'],
        work_type=plan['work_type'],
        changes=impl['changes_summary']
    )

    # Step 3: git add 및 /jira-commit 실행
    stage_changes(impl['modified_files'])
    commit_result = execute_jira_commit(ticket_id, commit_message)
    commit_hash = extract_commit_hash(commit_result)

    # Step 4: APPROVAL CHECKPOINT 2 ⚠️
    approval = request_pr_approval(
        ticket_id=ticket_id,
        branch=impl['branch'],
        commit_hash=commit_hash,
        verification=verify_state,
        files_changed=impl['modified_files']
    )

    if approval == "reject":
        # 커밋은 유지하지만 PR 생성하지 않음
        write_memory(f"submit_{ticket_id}", {
            "status": "commit_only",
            "commit_hash": commit_hash
        })
        return "PR creation rejected. Commit preserved on branch"

    if approval == "modify":
        # PR 상세 정보 수정
        pr_details = get_user_pr_modifications()
        commit_message = pr_details.get('commit_message', commit_message)

    # Step 5: 승인된 경우 /jira-pr 실행
    pr_result = execute_jira_pr(ticket_id)
    pr_url = extract_pr_url(pr_result)

    # Step 6: 최종 메모리 저장
    write_memory(f"submit_{ticket_id}", {
        "status": "completed",
        "timestamp": now(),
        "commit_hash": commit_hash,
        "pr_url": pr_url
    })

    # Step 7: TodoWrite 업데이트
    update_todo_status("Commit changes", "completed")
    update_todo_status("Create pull request", "completed")

    # Step 8: 최종 결과 표시
    display_submit_results(commit_hash, pr_url)

    return {"commit": commit_hash, "pr": pr_url}
```

### Approval Checkpoint 2 UI

```markdown
## 📤 Pull Request Review

**JIRA**: CCU2-17741 - Add config parameter for daemon startup
**Branch**: CCU2-17741-add-config-parameter
**Commit**: abc123def456

### Verification Results:
- ✅ Build: PASSED (0 errors, 0 warnings)
- ✅ Tests: PASSED (15/15 tests)
- ✅ MISRA: PASSED (0 violations)
- ✅ Quality: Grade A

### PR Details:
- **Title**: [CCU2-17741] Add config parameter for daemon startup
- **Files**: 2 modified (+45/-12 lines)
  - src/daemon/main.cpp (+30/-5)
  - include/config.h (+15/-7)

### Changes Summary:
- Added CONFIG_STARTUP_DELAY parameter
- Implemented validation logic (0-60s range)
- Applied parameter on daemon startup

**Create pull request?**
- `approve` - Create PR now
- `modify` - Edit PR details (title, description)
- `reject` - Keep commits on branch only (no PR)
```

### State Transitions

```
START (from Mode 3)
  ↓
[Load Verify State] → overall_success == true?
  ↓                           ↓
 YES                         NO → Error: Cannot submit
  ↓
[Generate Commit Message]
  ↓
[git add] → stage modified files
  ↓
[/jira-commit] → create commit
  ↓
[Extract Commit Hash]
  ↓
[APPROVAL CHECKPOINT 2] → approve|modify|reject
  ↓                           ↓         ↓
approve                    modify    reject
  ↓                           ↓         ↓
[/jira-pr]              [Modify PR]  [Commit Only]
  ↓                           ↓         ↓
[Extract PR URL]        [Re-approve]  END
  ↓                           ↓
[Memory Save]           [Create PR]
  ↓                           ↓
[TodoWrite Update]      [Continue]
  ↓
END (Mode 4 완료)
```

---

## Mode 5: COMPLETE (오케스트레이터)

**목적**: 전체 파이프라인 실행 및 조율

### Input
- JIRA 티켓 URL 또는 ID
- Session resume check (기존 작업 확인)

### Execution Logic

```python
def execute_complete_mode(ticket_url_or_id):
    """
    Mode 5: COMPLETE - 전체 파이프라인 오케스트레이션
    """
    # Step 1: Session 초기화 및 Resume 확인
    ticket_id = extract_ticket_id(ticket_url_or_id)

    existing_memories = list_memories()
    resumable_work = check_resumable_work(ticket_id, existing_memories)

    if resumable_work:
        resume_decision = ask_user_resume(resumable_work)
        if resume_decision == "resume":
            return resume_workflow(ticket_id, resumable_work)
        elif resume_decision == "restart":
            cleanup_memories(ticket_id)

    # Step 2: Mode 1 (ANALYZE) 실행
    try:
        execution_plan = execute_analyze_mode(ticket_id)
    except Exception as e:
        handle_error("ANALYZE", e, ticket_id)
        return

    # Step 3: Mode 2 (IMPLEMENT) 실행
    try:
        impl_result = execute_implement_mode(ticket_id)
        if impl_result == "Implementation rejected by user":
            cleanup_and_exit(ticket_id, "User rejected implementation")
            return
    except Exception as e:
        handle_error("IMPLEMENT", e, ticket_id)
        offer_recovery_options(ticket_id, "IMPLEMENT")
        return

    # Step 4: Mode 3 (VERIFY) 실행
    try:
        verify_result = execute_verify_mode(ticket_id)

        if not verify_result['overall_success']:
            # 검증 실패 처리
            display_verification_failures(verify_result)
            recovery = offer_verification_recovery(ticket_id, verify_result)

            if recovery == "fix_manually":
                return "Please fix issues manually and re-run verification"
            elif recovery == "rollback":
                rollback_implementation(ticket_id)
                return "Rolled back implementation"
            elif recovery == "abort":
                return "Workflow aborted"
    except Exception as e:
        handle_error("VERIFY", e, ticket_id)
        offer_recovery_options(ticket_id, "VERIFY")
        return

    # Step 5: Mode 4 (SUBMIT) 실행
    try:
        submit_result = execute_submit_mode(ticket_id)

        if "commit_only" in str(submit_result):
            write_memory(f"workflow_complete_{ticket_id}", {
                "status": "commit_only",
                "timestamp": now(),
                "summary": "Committed but no PR created"
            })
            return submit_result
    except Exception as e:
        handle_error("SUBMIT", e, ticket_id)
        offer_recovery_options(ticket_id, "SUBMIT")
        return

    # Step 6: 워크플로우 완료 기록
    write_memory(f"workflow_complete_{ticket_id}", {
        "status": "completed",
        "timestamp": now(),
        "summary": {
            "ticket_id": ticket_id,
            "work_type": execution_plan['work_type'],
            "commit_hash": submit_result['commit'],
            "pr_url": submit_result['pr']
        }
    })

    # Step 7: 최종 요약 표시
    display_workflow_summary(ticket_id)

    return "Workflow completed successfully"
```

### Orchestration Flow Diagram

```
                    ┌─────────────────┐
                    │  START (Mode 5) │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Session Init   │
                    │  Resume Check?  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Mode 1:        │
                    │  ANALYZE        │
                    │  (Auto)         │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Mode 2:        │
                    │  IMPLEMENT      │
                    │  (Approval 1)   │
                    └────────┬────────┘
                             │
                     User Approval?
                      /     │     \
              approve/    reject   \modify
                    /       │       \
                   ↓        ↓        ↓
           Continue   Abort    Adjust Plan
                   ↓                 ↓
          ┌────────▼────────┐       │
          │  Mode 3:        │←──────┘
          │  VERIFY         │
          │  (Auto)         │
          └────────┬────────┘
                   │
            Build/Test Pass?
              /         \
            YES         NO
             │           │
             ↓           ↓
    ┌────────▼────────┐  Offer Recovery:
    │  Mode 4:        │  - Fix manually
    │  SUBMIT         │  - Rollback
    │  (Approval 2)   │  - Abort
    └────────┬────────┘
             │
      User Approval?
       /     │     \
approve/   reject   \modify
     /       │       \
    ↓        ↓        ↓
Create PR  Commit   Adjust PR
           Only      Details
    │        │        │
    └────────┴────────┘
             │
    ┌────────▼────────┐
    │  Workflow       │
    │  Complete       │
    │  (Memory Save)  │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │  Display        │
    │  Summary        │
    └─────────────────┘
```

### Resume Workflow Logic

```python
def resume_workflow(ticket_id, resumable_work):
    """중단된 워크플로우 재개"""
    last_phase = resumable_work['last_completed_phase']

    if last_phase == "ANALYZE":
        # 분석 완료, 구현 시작
        return execute_implement_mode(ticket_id)

    elif last_phase == "IMPLEMENT":
        # 구현 완료, 검증 시작
        return execute_verify_mode(ticket_id)

    elif last_phase == "VERIFY":
        # 검증 완료, 제출 시작
        return execute_submit_mode(ticket_id)

    else:
        # 알 수 없는 상태, 처음부터 재시작 권장
        return "Unknown state. Recommend restarting from ANALYZE"
```

### Error Recovery Decision Tree

```
Error Detected in Phase X
         │
         ▼
┌────────────────┐
│ Transient?     │
│ (API timeout,  │
│  network)      │
└───┬────────┬───┘
    │        │
   YES       NO
    │        │
    ↓        ↓
Retry 3x  ┌──────────────┐
with      │ User Error?  │
backoff   │ (Invalid ID, │
    │     │  missing cfg)│
    │     └───┬──────┬───┘
    │         │      │
    │        YES     NO
    │         │      │
    │         ↓      ↓
    │     Show    ┌────────────┐
    │     Guide   │State Error?│
    │             │(Build fail,│
    │             │ test fail) │
    │             └───┬────┬───┘
    │                 │    │
    │                YES   NO
    │                 │    │
    │                 ↓    ↓
    │            Offer  Unknown
    │            Recovery Error
    │            Options   │
    │                 │    │
    └─────────────────┴────┘
              │
              ▼
    Recovery Options:
    1. Fix manually + retry
    2. Rollback (Level 1-4)
    3. Abort workflow
```

### State Transitions

```
START
  ↓
[Session Init] → list_memories()
  ↓
[Resume Check] → resumable? → YES → [Resume from last phase]
  ↓                              ↓
  NO                         Continue from checkpoint
  ↓
[Mode 1: ANALYZE] → Success? → NO → [Error Handler] → END
  ↓                              ↓
 YES                          Retry/Abort
  ↓
[Mode 2: IMPLEMENT] → Approved? → NO → [Cleanup] → END
  ↓                              ↓
 YES                          Abort
  ↓
[Mode 3: VERIFY] → Success? → NO → [Recovery Options]
  ↓                              ↓
 YES                          Fix/Rollback/Abort
  ↓
[Mode 4: SUBMIT] → Approved? → NO → [Commit Only] → END
  ↓                              ↓
 YES                          Save state
  ↓
[Workflow Complete] → write_memory("workflow_complete_...")
  ↓
[Display Summary]
  ↓
END
```

## Best Practices

### Mode Selection Guidelines

| User Intent | Recommended Mode | Reasoning |
|-------------|------------------|-----------|
| "이 티켓 분석해줘" | Mode 1 (ANALYZE) | 분석만 필요 |
| "이 티켓 구현해줘" | Mode 5 (COMPLETE) | 전체 파이프라인 |
| "브랜치 생성하고 코드만 작성" | Mode 2 (IMPLEMENT) | 구현만 필요 |
| "빌드 테스트만 돌려줘" | Mode 3 (VERIFY) | 검증만 필요 |
| "커밋하고 PR 생성" | Mode 4 (SUBMIT) | 제출만 필요 |
| "JIRA 티켓 URL 제공 (전체 작업)" | Mode 5 (COMPLETE) | 오케스트레이션 |

### Memory Key Naming Convention

```
plan_{ticket_id}             # 실행 계획
phase_{N}_{mode}_{ticket_id} # 페이즈별 상태
impl_{ticket_id}             # 구현 결과
verify_{ticket_id}           # 검증 결과
submit_{ticket_id}           # 제출 결과
checkpoint_{timestamp}_{id}  # 체크포인트
workflow_complete_{id}       # 완료 기록
```

### Error Message Templates

**User Error (Guide)**:
```
❌ Invalid ticket format

Expected: CCU2-XXXXX or https://sonatus.atlassian.net/browse/CCU2-XXXXX
Received: {user_input}

Please provide a valid JIRA ticket ID or URL.
```

**Build Failure (Recovery)**:
```
❌ Build failed with 3 errors

### Errors:
1. src/main.cpp:45 - undefined reference to 'foo'
2. include/config.h:12 - syntax error
3. src/daemon.cpp:78 - type mismatch

### Recovery Options:
- `fix` - Fix errors manually, then re-run verification
- `rollback` - Rollback code changes (git reset --hard HEAD)
- `abort` - Abort workflow and preserve current state

What would you like to do?
```

**API Timeout (Retry)**:
```
⚠️ JIRA API timeout (attempt 1/3)

Retrying in 5 seconds...
```
