# Integration Commands Reference

기존 JIRA 명령어 (`/jira-commit`, `/jira-pr`) 통합 방법 가이드.

## Overview

JIRA Workflow Agent는 기존 JIRA 명령어를 활용:
- **`/jira-commit`**: JIRA 티켓 ID 기반 커밋 생성
- **`/jira-pr`**: JIRA 티켓과 연동된 PR 생성

이 문서는 워크플로우 내에서 이러한 명령어를 효과적으로 통합하는 방법을 설명.

---

## /jira-commit Integration

### Command Overview

**위치**: `/Users/jaylee/.claude-config/projects/container-manager/commands/jira-commit.md`

**목적**: JIRA 티켓 ID를 포함한 표준화된 커밋 메시지 생성

**사용법**:
```bash
/jira-commit CCU2-17741
```

**커밋 메시지 형식**:
```
[CCU2-17741] {Summary from JIRA}

{Description derived from changes}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Integration in Mode 4 (SUBMIT)

```python
def execute_jira_commit(ticket_id, modified_files):
    """
    Mode 4에서 /jira-commit 명령어 실행
    """
    # Step 1: 변경된 파일 stage
    stage_changes(modified_files)

    # Step 2: 커밋 메시지 준비
    plan = read_memory(f"plan_{ticket_id}")
    impl = read_memory(f"impl_{ticket_id}")

    # /jira-commit은 자동으로 JIRA에서 summary를 가져오므로
    # 별도의 메시지 생성 불필요

    # Step 3: /jira-commit 명령어 실행
    # 옵션 1: Skill 도구 사용
    result = invoke_skill("jira-commit", args=ticket_id)

    # 옵션 2: Bash 도구 사용
    # result = run_bash(f"claude /jira-commit {ticket_id}")

    # Step 4: 커밋 해시 추출
    commit_hash = extract_commit_hash_from_output(result)

    # Step 5: 메모리에 저장
    write_memory(f"commit_{ticket_id}", {
        "hash": commit_hash,
        "timestamp": now(),
        "message": f"[{ticket_id}] {plan['summary']}"
    })

    return commit_hash
```

### Custom Commit Message

기본 `/jira-commit` 대신 커스텀 메시지를 사용하려면:

```python
def create_custom_commit(ticket_id, custom_message):
    """
    커스텀 커밋 메시지로 커밋 생성
    """
    plan = read_memory(f"plan_{ticket_id}")

    # 커밋 메시지 템플릿
    commit_message = f"""[{ticket_id}] {plan['summary']}

{custom_message}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
"""

    # git commit 직접 실행
    result = run_bash(f"""git commit -m "$(cat <<'EOF'
{commit_message}
EOF
)"
""")

    return extract_commit_hash_from_output(result)
```

### Stage Changes Helper

```python
def stage_changes(modified_files):
    """
    변경된 파일을 staging area에 추가
    """
    for file_info in modified_files:
        file_path = file_info['file']

        # 파일 존재 확인
        if not os.path.exists(file_path):
            print(f"⚠️ Warning: File not found: {file_path}")
            continue

        # git add 실행
        try:
            run_bash(f"git add {file_path}")
            print(f"✅ Staged: {file_path}")
        except Exception as e:
            print(f"❌ Failed to stage {file_path}: {e}")
            raise

    # 전체 상태 확인
    status = run_bash("git status --short")
    print("\n### Git Status:")
    print(status)
```

### Commit Hash Extraction

```python
def extract_commit_hash_from_output(git_output):
    """
    Git 출력에서 커밋 해시 추출
    """
    # 패턴 1: "abc123def" (short hash)
    # 패턴 2: "abc123def456..." (full hash)
    # 패턴 3: [master abc123d] Commit message

    patterns = [
        r'\[[\w/-]+\s+([a-f0-9]{7,40})\]',  # [branch hash]
        r'^([a-f0-9]{7,40})$',                # standalone hash
        r'commit\s+([a-f0-9]{7,40})'          # "commit abc123"
    ]

    for pattern in patterns:
        match = re.search(pattern, git_output, re.MULTILINE)
        if match:
            return match.group(1)

    # 대안: git log에서 최신 커밋 조회
    try:
        latest_commit = run_bash("git log -1 --format='%H'")
        return latest_commit.strip()
    except:
        raise ValueError("Could not extract commit hash")
```

---

## /jira-pr Integration

### Command Overview

**위치**: `/Users/jaylee/.claude-config/projects/container-manager/commands/jira-pr.md`

**목적**: JIRA 티켓과 연동된 Pull Request 생성

**사용법**:
```bash
/jira-pr CCU2-17741
```

**PR 템플릿**:
```markdown
## Summary
{Derived from JIRA ticket}

## Changes
{List of modified files and changes}

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests passing
- [ ] Manual testing completed

## JIRA
- Ticket: [CCU2-17741](https://sonatus.atlassian.net/browse/CCU2-17741)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Integration in Mode 4 (SUBMIT)

```python
def execute_jira_pr(ticket_id):
    """
    Mode 4에서 /jira-pr 명령어 실행
    """
    # Step 1: 브랜치가 원격에 push되었는지 확인
    impl = read_memory(f"impl_{ticket_id}")
    branch_name = impl['branch']

    is_pushed = check_branch_pushed(branch_name)

    if not is_pushed:
        # 브랜치 push
        print(f"Pushing branch {branch_name} to remote...")
        run_bash(f"git push -u origin {branch_name}")

    # Step 2: /jira-pr 명령어 실행
    # 옵션 1: Skill 도구 사용
    result = invoke_skill("jira-pr", args=ticket_id)

    # 옵션 2: gh CLI 직접 사용
    # result = run_bash(f"gh pr create --title '[{ticket_id}] ...' --body '...'")

    # Step 3: PR URL 추출
    pr_url = extract_pr_url_from_output(result)
    pr_number = extract_pr_number_from_url(pr_url)

    # Step 4: 메모리에 저장
    write_memory(f"pr_{ticket_id}", {
        "url": pr_url,
        "number": pr_number,
        "created_at": now()
    })

    return {"url": pr_url, "number": pr_number}
```

### Custom PR Template

기본 템플릿 대신 커스텀 PR 생성:

```python
def create_custom_pr(ticket_id, pr_details):
    """
    커스텀 PR 상세 정보로 PR 생성
    """
    plan = read_memory(f"plan_{ticket_id}")
    impl = read_memory(f"impl_{ticket_id}")
    verify = read_memory(f"verify_{ticket_id}")

    # PR 제목
    pr_title = pr_details.get('title', f"[{ticket_id}] {plan['summary']}")

    # PR 설명
    pr_body = f"""## Summary
{plan['summary']}

## Changes
"""

    for file_info in impl['modified_files']:
        pr_body += f"- `{file_info['file']}` (+{file_info['additions']}/-{file_info['deletions']})\n"

    pr_body += f"""
## Testing
- {'✅' if verify['build']['success'] else '❌'} Build: {verify['build']['errors']} errors
- {'✅' if verify['tests']['success'] else '❌'} Tests: {verify['tests']['passed']}/{verify['tests']['tests_run']} passed
- {'✅' if verify.get('static_analysis', {}).get('passed', True) else '❌'} Static Analysis

## JIRA
- Ticket: [{ticket_id}](https://sonatus.atlassian.net/browse/{ticket_id})

🤖 Generated with [Claude Code](https://claude.com/claude-code)
"""

    # gh pr create 실행
    pr_body_escaped = pr_body.replace('"', '\\"')

    result = run_bash(f"""gh pr create \\
        --title "{pr_title}" \\
        --body "$(cat <<'EOF'
{pr_body}
EOF
)"
""")

    return extract_pr_url_from_output(result)
```

### Helper Functions

#### Check Branch Pushed

```python
def check_branch_pushed(branch_name):
    """
    브랜치가 원격에 push되었는지 확인
    """
    try:
        # 원격 브랜치 확인
        result = run_bash(f"git ls-remote --heads origin {branch_name}")
        return len(result.strip()) > 0
    except:
        return False
```

#### Extract PR URL

```python
def extract_pr_url_from_output(gh_output):
    """
    gh pr create 출력에서 PR URL 추출
    """
    # 패턴: https://github.com/org/repo/pull/123
    pattern = r'(https://github\.com/[\w-]+/[\w-]+/pull/\d+)'

    match = re.search(pattern, gh_output)

    if match:
        return match.group(1)

    raise ValueError("Could not extract PR URL from output")
```

#### Extract PR Number

```python
def extract_pr_number_from_url(pr_url):
    """
    PR URL에서 PR 번호 추출
    """
    # https://github.com/org/repo/pull/123 → 123
    match = re.search(r'/pull/(\d+)$', pr_url)

    if match:
        return int(match.group(1))

    raise ValueError("Could not extract PR number from URL")
```

---

## Integration Patterns

### Pattern 1: Direct Command Execution

가장 간단한 방법 - 명령어를 그대로 실행:

```python
def pattern_direct_execution(ticket_id):
    """패턴 1: 직접 실행"""

    # 커밋
    run_bash(f"git add .")
    commit_result = invoke_skill("jira-commit", args=ticket_id)

    # PR
    pr_result = invoke_skill("jira-pr", args=ticket_id)

    return {
        "commit": extract_commit_hash(commit_result),
        "pr": extract_pr_url(pr_result)
    }
```

**장점**: 간단, 빠름
**단점**: 커스터마이제이션 제한적

### Pattern 2: Wrapper with Customization

명령어를 wrapper 함수로 감싸고 커스터마이제이션 추가:

```python
def pattern_wrapper_customization(ticket_id, custom_options):
    """패턴 2: Wrapper로 커스터마이제이션"""

    # 1. 커스텀 준비 작업
    if custom_options.get('pre_commit_hook'):
        run_pre_commit_validation()

    # 2. 커밋 실행
    if custom_options.get('custom_commit_message'):
        commit_hash = create_custom_commit(
            ticket_id,
            custom_options['custom_commit_message']
        )
    else:
        result = invoke_skill("jira-commit", args=ticket_id)
        commit_hash = extract_commit_hash(result)

    # 3. PR 실행
    if custom_options.get('custom_pr_template'):
        pr_url = create_custom_pr(
            ticket_id,
            custom_options['custom_pr_template']
        )
    else:
        result = invoke_skill("jira-pr", args=ticket_id)
        pr_url = extract_pr_url(result)

    return {"commit": commit_hash, "pr": pr_url}
```

**장점**: 유연성
**단점**: 복잡도 증가

### Pattern 3: Conditional Integration

조건에 따라 다른 통합 방식 사용:

```python
def pattern_conditional_integration(ticket_id, workflow_config):
    """패턴 3: 조건부 통합"""

    plan = read_memory(f"plan_{ticket_id}")

    # 조건 1: 작업 유형에 따라
    if plan['work_type'] == 'hotfix':
        # Hotfix는 직접 master에 커밋
        return create_direct_commit(ticket_id)

    elif plan['work_type'] == 'feature':
        # Feature는 PR 생성
        commit_hash = invoke_skill("jira-commit", args=ticket_id)
        pr_url = invoke_skill("jira-pr", args=ticket_id)
        return {"commit": commit_hash, "pr": pr_url}

    # 조건 2: 복잡도에 따라
    elif plan['complexity'] == 'high':
        # High complexity는 더 상세한 PR 템플릿
        return create_detailed_pr(ticket_id)

    else:
        # 기본: 표준 명령어 사용
        return pattern_direct_execution(ticket_id)
```

**장점**: 상황별 최적화
**단점**: 유지보수 복잡

---

## Error Handling

### Commit Errors

```python
def handle_commit_error(ticket_id, error):
    """커밋 에러 처리"""

    error_guide = f"""
❌ Commit Failed

**Ticket**: {ticket_id}
**Error**: {str(error)}

**Common Issues**:

1. **No changes to commit**
   - Solution: Verify files are modified and staged
   - Check: `git status`

2. **Pre-commit hook failure**
   - Solution: Fix hook errors or skip with `--no-verify`
   - Check: Pre-commit output

3. **GPG signing failure**
   - Solution: Configure GPG or disable signing
   - Check: `git config --global commit.gpgsign`

**Recovery Options**:
- `retry` - Try again
- `manual` - Create commit manually
- `skip` - Skip commit step

**Your choice**: _
"""

    print(error_guide)
    choice = get_user_input("Recovery option: ")

    if choice == "retry":
        return execute_jira_commit(ticket_id, modified_files)
    elif choice == "manual":
        return "Please create commit manually using: git commit"
    elif choice == "skip":
        return "commit_skipped"
    else:
        raise error
```

### PR Errors

```python
def handle_pr_error(ticket_id, error):
    """PR 생성 에러 처리"""

    error_guide = f"""
❌ PR Creation Failed

**Ticket**: {ticket_id}
**Error**: {str(error)}

**Common Issues**:

1. **Branch not pushed**
   - Solution: Push branch first
   - Command: `git push -u origin <branch>`

2. **PR already exists**
   - Solution: Update existing PR or close it first
   - Check: `gh pr list`

3. **No commits on branch**
   - Solution: Create commits first
   - Check: `git log`

4. **GitHub CLI not authenticated**
   - Solution: Authenticate with `gh auth login`

**Recovery Options**:
- `retry` - Try again
- `manual` - Create PR manually
- `skip` - Skip PR creation

**Your choice**: _
"""

    print(error_guide)
    choice = get_user_input("Recovery option: ")

    if choice == "retry":
        return execute_jira_pr(ticket_id)
    elif choice == "manual":
        return "Please create PR manually using: gh pr create"
    elif choice == "skip":
        return "pr_skipped"
    else:
        raise error
```

---

## Advanced Integrations

### Auto-linking JIRA Ticket

PR 생성 후 JIRA 티켓에 자동으로 링크 추가:

```python
def link_pr_to_jira(ticket_id, pr_url):
    """
    JIRA 티켓에 PR 링크 추가
    """
    # JIRA REST API로 코멘트 추가
    comment_body = {
        "body": {
            "type": "doc",
            "version": 1,
            "content": [
                {
                    "type": "paragraph",
                    "content": [
                        {
                            "type": "text",
                            "text": f"Pull Request created: {pr_url}"
                        }
                    ]
                }
            ]
        }
    }

    response = requests.post(
        f"{JIRA_BASE_URL}/rest/api/3/issue/{ticket_id}/comment",
        headers={"Authorization": f"Basic {AUTH}"},
        json=comment_body
    )

    if response.status_code == 201:
        print(f"✅ PR link added to JIRA ticket {ticket_id}")
    else:
        print(f"⚠️ Failed to link PR to JIRA: {response.text}")
```

### Update JIRA Status

PR 생성 시 JIRA 티켓 상태 자동 업데이트:

```python
def update_jira_status(ticket_id, new_status):
    """
    JIRA 티켓 상태 업데이트
    """
    # 상태 전환 ID 조회 (프로젝트별로 다름)
    transition_map = {
        "In Review": "31",      # PR 생성 시
        "In Progress": "21",    # 구현 시작 시
        "Done": "41"            # 머지 후
    }

    transition_id = transition_map.get(new_status)

    if not transition_id:
        print(f"⚠️ Unknown status: {new_status}")
        return

    # 상태 전환 API 호출
    response = requests.post(
        f"{JIRA_BASE_URL}/rest/api/3/issue/{ticket_id}/transitions",
        headers={"Authorization": f"Basic {AUTH}"},
        json={"transition": {"id": transition_id}}
    )

    if response.status_code == 204:
        print(f"✅ JIRA ticket {ticket_id} status updated to '{new_status}'")
    else:
        print(f"⚠️ Failed to update JIRA status: {response.text}")
```

---

## Best Practices

### 1. Always Validate Before Integration

명령어 실행 전 사전 조건 확인:

```python
def validate_before_commit(ticket_id):
    """커밋 전 검증"""
    checks = {
        "files_staged": check_files_staged(),
        "branch_valid": check_on_feature_branch(),
        "no_conflicts": check_no_merge_conflicts()
    }

    if not all(checks.values()):
        failed = [k for k, v in checks.items() if not v]
        raise ValueError(f"Pre-commit validation failed: {failed}")

    return True
```

### 2. Capture Output for Debugging

명령어 출력을 항상 캡처하여 디버깅에 활용:

```python
def execute_with_logging(command, ticket_id):
    """로깅과 함께 명령어 실행"""
    print(f"Executing: {command}")

    result = run_bash(command)

    # 로그 저장
    write_memory(f"command_log_{ticket_id}", {
        "command": command,
        "output": result,
        "timestamp": now()
    })

    return result
```

### 3. Handle Partial Success

부분적 성공 시나리오 처리:

```python
def handle_partial_success(ticket_id, commit_success, pr_success):
    """부분 성공 처리"""

    if commit_success and not pr_success:
        # 커밋은 성공, PR은 실패
        print("✅ Commit created successfully")
        print("❌ PR creation failed")
        print("You can create PR manually later using:")
        print(f"  /jira-pr {ticket_id}")

    elif not commit_success and pr_success:
        # 이런 경우는 발생하지 않아야 함
        raise ValueError("Inconsistent state: PR without commit")

    elif commit_success and pr_success:
        # 완전 성공
        print("✅ Commit and PR created successfully")

    else:
        # 완전 실패
        raise ValueError("Both commit and PR creation failed")
```

### 4. Provide Manual Fallback

자동화 실패 시 수동 명령어 안내:

```python
def provide_manual_fallback(ticket_id, failed_step):
    """수동 대체 방법 안내"""

    if failed_step == "commit":
        print(f"""
Manual Commit Instructions:

1. Stage your changes:
   git add <files>

2. Create commit:
   /jira-commit {ticket_id}

   Or manually:
   git commit -m "[{ticket_id}] Your commit message"
""")

    elif failed_step == "pr":
        print(f"""
Manual PR Creation Instructions:

1. Push your branch:
   git push -u origin <branch-name>

2. Create PR:
   /jira-pr {ticket_id}

   Or manually:
   gh pr create --title "[{ticket_id}] ..." --body "..."
""")
```

---

## Testing Integration

### Mock Testing

통합 테스트용 mock 함수:

```python
def mock_jira_commit(ticket_id):
    """테스트용 mock 커밋"""
    print(f"[MOCK] Creating commit for {ticket_id}")
    return "abc123def456"  # Mock commit hash


def mock_jira_pr(ticket_id):
    """테스트용 mock PR"""
    print(f"[MOCK] Creating PR for {ticket_id}")
    return "https://github.com/org/repo/pull/123"  # Mock PR URL
```

### Integration Test

실제 통합 테스트:

```python
def test_integration(test_ticket_id="TEST-123"):
    """통합 테스트"""

    print("### Integration Test Start ###")

    # 1. 테스트 브랜치 생성
    run_bash(f"git checkout -b {test_ticket_id}-test")

    # 2. 더미 파일 수정
    write_file("test_file.txt", "Test content")
    run_bash("git add test_file.txt")

    # 3. 커밋 생성 테스트
    try:
        commit_hash = execute_jira_commit(test_ticket_id, [{"file": "test_file.txt"}])
        print(f"✅ Commit created: {commit_hash}")
    except Exception as e:
        print(f"❌ Commit failed: {e}")
        return False

    # 4. PR 생성 테스트
    try:
        pr_result = execute_jira_pr(test_ticket_id)
        print(f"✅ PR created: {pr_result['url']}")
    except Exception as e:
        print(f"❌ PR failed: {e}")
        return False

    # 5. 정리
    run_bash(f"git checkout master")
    run_bash(f"git branch -D {test_ticket_id}-test")

    print("### Integration Test Complete ###")
    return True
```
