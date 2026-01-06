# Error Recovery - 에러 복구 전략

## 에러 분류

| Category | Severity | Recovery |
|----------|----------|----------|
| JIRA Authentication | High | 인증 정보 재설정 |
| JIRA Not Found | Medium | ID 확인, 수동 입력 |
| Build Parse Error | High | 문법 수정 |
| Build Dependency | High | 의존성 설치/빌드 |
| Build Compile | High | 코드 수정 |
| Build Link | High | 라이브러리 확인 |
| Test Failure | Medium | 코드 또는 테스트 수정 |
| Git Conflict | Medium | 충돌 해결 |
| Network | Low | 재시도, 캐시 사용 |

## JIRA 에러

### Authentication Failure

**증상**: HTML 로그인 페이지 반환
```html
<!DOCTYPE html>
<html lang="en">
<head><title>Log in
```

**원인**:
- API Token 만료
- 잘못된 이메일
- .env 파일 누락

**복구 단계**:
1. .env 파일 존재 확인
   ```bash
   test -f .env && echo "EXISTS" || echo "MISSING"
   cat .env | grep JIRA
   ```

2. API Token 재생성 안내
   ```
   1. https://id.atlassian.com/manage-profile/security/api-tokens 접속
   2. "Create API token" 클릭
   3. 토큰 복사하여 .env 파일 업데이트
   ```

3. 테스트
   ```bash
   source <(grep -E '^JIRA_' .env | sed 's/^/export /')
   curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        "${JIRA_BASE_URL}rest/api/2/myself" | jq .displayName
   ```

**Fallback**: 수동 티켓 정보 입력 요청
```
JIRA 접근 불가. 티켓 정보를 직접 입력해주세요:
- Title:
- Description:
- Acceptance Criteria:
- Components:
```

### Ticket Not Found

**증상**:
```json
{"errorMessages":["Issue Does Not Exist"],"errors":{}}
```

**복구 단계**:
1. 티켓 ID 형식 확인
   ```regex
   ^(CCU2|SEB|CRM)-\d+$
   ```

2. 프로젝트 권한 확인
   ```bash
   # 프로젝트 접근 테스트
   curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
        "${JIRA_BASE_URL}rest/api/2/project/CCU2" | jq .name
   ```

3. 사용자에게 확인 요청

## 빌드 에러

### CMake Parse Error

**증상**:
```
CMake Error at <file>:<line>
  Parse error...
```

**복구 단계**:
1. 에러 위치 확인
   ```bash
   sed -n '<line-5>,<line+5>p' <file>
   ```

2. 일반적인 문법 오류:
   - 닫히지 않은 괄호
   - 누락된 인용부호
   - 잘못된 명령어 이름

3. CMake 캐시 삭제 후 재시도
   ```bash
   rm -rf build/Debug/<component>/CMakeCache.txt
   ./build.py --module <component>
   ```

### Missing Dependency

**증상**:
```
CMake Error: Could not find package <package>
```

또는 런타임:
```
error while loading shared libraries: lib<name>.so
```

**복구 단계**:
1. 의존성 패키지 확인
   ```bash
   apt-cache search <package>
   ```

2. 시스템 패키지 설치
   ```bash
   sudo apt-get install <package>
   ```

3. CCU-2.0 의존성인 경우
   ```bash
   ./build.py --module <dependency>
   ./build.py --module <component>
   ```

### Compile Error

**증상**:
```
error: <message>
<file>:<line>:<column>: error: <description>
```

**복구 단계**:
1. 에러 메시지 분석
   - `undefined reference`: 링크 에러, 라이브러리 확인
   - `no matching function`: 함수 시그니처 불일치
   - `expected`: 문법 에러
   - `cannot convert`: 타입 에러

2. 소스 코드 위치 확인
   ```bash
   sed -n '<line-5>,<line+5>p' <file>
   ```

3. 수정 제안 생성
   - 타입 캐스팅 필요
   - 헤더 include 누락
   - 함수 시그니처 수정

4. 수정 후 재빌드
   ```bash
   ./build.py --module <component>
   ```

### Link Error

**증상**:
```
undefined reference to `symbol'
```

**복구 단계**:
1. 심볼 정의 위치 찾기
   ```bash
   grep -r "symbol" --include="*.cxx" --include="*.hxx"
   ```

2. 라이브러리 링크 확인
   ```bash
   # CMakeLists.txt에서 target_link_libraries 확인
   grep -A10 "target_link_libraries" CMakeLists.txt
   ```

3. 빌드 순서 확인
   ```bash
   # 의존성 먼저 빌드
   ./build.py --module <dependency>
   ./build.py --module <component>
   ```

## 테스트 에러

### Test Failure

**증상**:
```
[  FAILED  ] TestSuite.TestCase (X ms)
```

**복구 단계**:
1. 실패 원인 분석
   ```bash
   # 상세 출력
   ./build.py --module <component> --tests --verbose

   # 또는 ctest 직접 실행
   cd build/Debug/<component>
   ctest -R "TestCase" --output-on-failure
   ```

2. Expected vs Actual 비교
   ```
   Expected: X
   Actual: Y
   ```

3. 관련 코드 검토
   - 구현 코드 확인
   - 테스트 기대값 확인
   - Mock 설정 확인

4. 수정 후 재테스트
   ```bash
   ./build.py --module <component> --tests
   ```

### Test Timeout

**증상**:
```
Test timeout after X seconds
```

**복구 단계**:
1. 무한 루프 또는 데드락 확인
2. 타임아웃 증가 시도
3. 테스트 격리 실행
   ```bash
   ctest -R "TestCase" --timeout 120
   ```

### Test Hang

**증상**: 테스트가 시작되었지만 완료되지 않음

**복구 단계**:
1. 프로세스 확인
   ```bash
   ps aux | grep <test_binary>
   ```

2. 강제 종료
   ```bash
   kill -9 <pid>
   ```

3. 데드락 분석
   ```bash
   gdb -p <pid>
   (gdb) thread apply all bt
   ```

## Git 에러

### Uncommitted Changes

**증상**:
```
error: Your local changes would be overwritten
```

**복구 옵션**:
1. Stash 저장
   ```bash
   git stash
   # 작업 후
   git stash pop
   ```

2. 커밋
   ```bash
   git add .
   git commit -m "WIP: <description>"
   ```

3. 폐기 (주의!)
   ```bash
   git checkout -- .
   ```

### Merge Conflict

**증상**:
```
CONFLICT (content): Merge conflict in <file>
```

**복구 단계**:
1. 충돌 파일 확인
   ```bash
   git status | grep "both modified"
   ```

2. 충돌 마커 확인
   ```bash
   grep -n "<<<<<<" <file>
   ```

3. 수동 해결
   ```
   <<<<<<< HEAD
   current version
   =======
   incoming version
   >>>>>>> branch
   ```

4. 해결 후 완료
   ```bash
   git add <file>
   git commit
   ```

### Detached HEAD

**증상**:
```
HEAD detached at <commit>
```

**복구**:
```bash
# 브랜치 생성
git checkout -b <new-branch>

# 또는 기존 브랜치로
git checkout <branch-name>
```

## 네트워크 에러

### Connection Timeout

**증상**:
```
curl: (28) Connection timed out
```

**복구 단계**:
1. 네트워크 확인
   ```bash
   ping -c 3 sonatus.atlassian.net
   ```

2. 재시도 (exponential backoff)
   ```bash
   for i in 1 2 4 8; do
       curl --connect-timeout 30 ... && break
       sleep $i
   done
   ```

3. 캐시 사용
   ```bash
   cat .claude/jira-cache/<ticket>.json
   ```

### SSL/TLS Error

**증상**:
```
SSL certificate problem
```

**복구**:
```bash
# CA 인증서 업데이트
sudo update-ca-certificates

# 또는 (임시, 보안 위험)
curl -k ...
```

## 복구 전략 요약

### 자동 복구 (3회 재시도)
- 네트워크 타임아웃
- 일시적 JIRA 응답 오류
- 테스트 flaky 실패

### 사용자 개입 필요
- 인증 실패 → 토큰 재생성
- 빌드 에러 → 코드 수정
- Git 충돌 → 수동 해결

### Graceful Degradation
- JIRA 접근 불가 → 수동 입력
- 빌드 실패 → 이전 단계로 롤백
- 테스트 실패 → 결과 문서화, 계속 진행 옵션

### 로깅
```bash
# 에러 로그 위치
.claude/yocto-pipeline.log

# 로그 포맷
[TIMESTAMP] [LEVEL] [PHASE] Message
[2026-01-05T10:30:00] [ERROR] [BUILD] Compile failed: undefined reference
```
