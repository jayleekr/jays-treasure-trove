# Git Workflow - 브랜치 관리 패턴

## 브랜치 전략

### 브랜치 명명 규칙
```
feature/<TICKET_ID>-<short-description>
bugfix/<TICKET_ID>-<short-description>
hotfix/<TICKET_ID>-<short-description>
```

예시:
```
feature/CCU2-17945-container-health-check
bugfix/SEB-1234-fix-policy-parser
hotfix/CRM-567-urgent-security-fix
```

### 메인 브랜치
- `master` - 프로덕션 릴리스
- `develop` - 개발 통합 (있는 경우)

## 워크플로우 단계

### 1. 작업 시작

```bash
# 최신 상태 동기화
git fetch origin
git checkout master
git pull origin master

# Feature 브랜치 생성
git checkout -b feature/<TICKET_ID>-<description>
```

### 2. 개발 중

```bash
# 상태 확인
git status

# 변경사항 스테이징
git add <files>
# 또는 전체
git add .

# 커밋
git commit -m "[<TICKET_ID>] <description>"
```

### 3. 원격 푸시

```bash
# 처음 푸시 (upstream 설정)
git push -u origin feature/<TICKET_ID>-<description>

# 이후 푸시
git push
```

### 4. PR 생성

```bash
# GitHub CLI 사용
gh pr create --title "[<TICKET_ID>] <description>" \
    --body "## Summary
<changes description>

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

## 커밋 메시지 포맷

### 기본 포맷
```
[<TICKET_ID>] <Brief description>

<Optional detailed description>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### 예시
```
[CCU2-17945] Add container health check endpoint

- Implement /health endpoint for container monitoring
- Add configurable timeout parameter
- Include unit tests for health check logic

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### 커밋 타입 (선택적)
```
[CCU2-12345] feat: Add new feature
[CCU2-12345] fix: Fix bug
[CCU2-12345] refactor: Code refactoring
[CCU2-12345] test: Add tests
[CCU2-12345] docs: Update documentation
```

## 일반 작업

### 변경사항 확인
```bash
# 워킹 디렉토리 변경
git diff

# 스테이징된 변경
git diff --staged

# 최근 커밋과 비교
git diff HEAD~1
```

### 커밋 수정

```bash
# 마지막 커밋 메시지 수정
git commit --amend -m "New message"

# 마지막 커밋에 파일 추가
git add <file>
git commit --amend --no-edit
```

**주의**: 이미 푸시한 커밋은 amend 하지 않기

### 변경사항 임시 저장
```bash
# Stash 저장
git stash

# Stash 목록
git stash list

# Stash 복원
git stash pop

# 특정 stash 복원
git stash apply stash@{0}
```

### 브랜치 관리
```bash
# 브랜치 목록
git branch -a

# 브랜치 삭제 (로컬)
git branch -d <branch>

# 브랜치 삭제 (원격)
git push origin --delete <branch>
```

## 동기화 패턴

### master와 동기화
```bash
# master 업데이트
git checkout master
git pull origin master

# feature 브랜치로 돌아가서 rebase
git checkout feature/<branch>
git rebase master
```

### Rebase 충돌 해결
```bash
# 충돌 발생 시
# 1. 파일 수정
# 2. 스테이징
git add <file>
# 3. 계속
git rebase --continue

# 또는 취소
git rebase --abort
```

## 안전 규칙

### 하지 말아야 할 것
```bash
# ❌ master에 직접 커밋
git checkout master
git commit ...  # NO!

# ❌ force push to master
git push --force origin master  # NEVER!

# ❌ 푸시된 커밋 rewrite
git rebase -i HEAD~5  # after push, NO!
```

### 해야 할 것
```bash
# ✅ 항상 feature 브랜치 사용
git checkout -b feature/<ticket>

# ✅ 커밋 전 diff 확인
git diff
git diff --staged

# ✅ 푸시 전 테스트
./build.py --module <component> --tests
```

## 히스토리 확인

### 로그 보기
```bash
# 기본 로그
git log

# 한 줄씩
git log --oneline

# 그래프
git log --oneline --graph --all

# 특정 파일 히스토리
git log --follow <file>
```

### 최근 커밋
```bash
# 최근 5개
git log -5

# 특정 저자
git log --author="name"

# 날짜 범위
git log --since="2025-01-01" --until="2025-01-31"
```

## PR 워크플로우

### PR 생성
```bash
gh pr create --title "[CCU2-17945] Feature description" \
    --body "$(cat <<'EOF'
## Summary
- Change 1
- Change 2

## Test Plan
- [ ] Unit tests pass
- [ ] Build succeeds

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### PR 상태 확인
```bash
# PR 목록
gh pr list

# PR 상세
gh pr view <number>

# PR 체크 상태
gh pr checks <number>
```

### PR 업데이트
```bash
# 추가 커밋 후 푸시
git add .
git commit -m "[CCU2-17945] Address review comments"
git push
```

## 롤백 패턴

### 워킹 디렉토리 롤백
```bash
# 특정 파일
git checkout -- <file>

# 전체 (주의!)
git checkout -- .
```

### 커밋 롤백
```bash
# 마지막 커밋 취소 (변경사항 유지)
git reset --soft HEAD~1

# 마지막 커밋 완전 삭제 (주의!)
git reset --hard HEAD~1
```

### Revert (안전한 롤백)
```bash
# 특정 커밋 되돌리기 (새 커밋 생성)
git revert <commit-hash>
```

## 클린업

### 머지된 브랜치 삭제
```bash
# 로컬
git branch --merged | grep -v "master\|main" | xargs git branch -d

# 원격 참조 정리
git remote prune origin
```

### 추적되지 않는 파일 삭제
```bash
# 확인
git clean -n

# 삭제
git clean -f

# 디렉토리 포함
git clean -fd
```

## 체크리스트

### 커밋 전
- [ ] `git status` 확인
- [ ] `git diff` 리뷰
- [ ] 테스트 통과

### 푸시 전
- [ ] 커밋 메시지 형식 확인
- [ ] 빌드 성공
- [ ] 테스트 통과

### PR 전
- [ ] master와 동기화
- [ ] 모든 체크 통과
- [ ] PR 설명 작성
