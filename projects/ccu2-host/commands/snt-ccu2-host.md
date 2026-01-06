---
description: JIRA 티켓 기반 CCU-2.0 파이프라인 - 요구사항 추출부터 테스트까지 통합 워크플로우
---

# SNT-CCU2-HOST Pipeline Command

JIRA 티켓에서 시작하여 요구사항 추출 → 구현 → 빌드 → 테스트까지 전체 개발 파이프라인을 실행합니다.

## Task

1. **Ticket Validation**
   - JIRA 티켓 ID 형식 검증 (CCU2-*, SEB-*, CRM-*)
   - `.env` 파일에서 JIRA 인증 정보 확인
   - 티켓 접근 가능 여부 확인

2. **Mode Selection**
   - 사용자가 지정한 모드 또는 기본값(complete) 선택
   - 모드: analyze, implement, build, test, complete

3. **Base Branch Sync (빌드/PR 전 필수)**
   - 최신 master 브랜치 fetch
   - 현재 브랜치가 master보다 뒤처진 경우 자동 rebase
   - Conflict 발생 시 중단 및 수동 해결 안내
   - `--no-sync` 옵션으로 스킵 가능 (권장하지 않음)

4. **Pipeline Execution**
   - 선택된 모드에 따라 `snt-ccu2-host` 스킬 호출
   - 각 단계 진행 상황 표시
   - 에러 발생시 복구 전략 적용

5. **Result Report**
   - 파이프라인 실행 결과 요약
   - 다음 단계 제안

## Usage

```bash
# 전체 파이프라인 실행 (기본)
/snt-ccu2-host CCU2-12345

# 특정 모드만 실행
/snt-ccu2-host CCU2-12345 --analyze     # 요구사항 분석만
/snt-ccu2-host CCU2-12345 --implement   # 구현만
/snt-ccu2-host CCU2-12345 --build       # 빌드만
/snt-ccu2-host CCU2-12345 --test        # 테스트만

# 컴포넌트 지정
/snt-ccu2-host CCU2-12345 --module container-manager
/snt-ccu2-host CCU2-12345 --module vam --build

# 옵션 조합
/snt-ccu2-host CCU2-12345 --build --test --coverage
```

## Mode Options

| Mode | Flag | Description |
|------|------|-------------|
| **Analyze** | `--analyze` | JIRA 티켓에서 요구사항 추출 및 구현 계획 생성 |
| **Implement** | `--implement` | 요구사항 기반 코드 변경 구현 |
| **Build** | `--build` | ./build.py로 컴포넌트 빌드 |
| **Test** | `--test` | 유닛 테스트 및 통합 테스트 실행 |
| **Complete** | (default) | 위 모든 단계 순차 실행 |

## Additional Options

| Option | Description |
|--------|-------------|
| `--module <name>` | 대상 컴포넌트 지정 |
| `--coverage` | 테스트 커버리지 생성 |
| `--clean` | 클린 빌드 실행 |
| `--verbose` | 상세 출력 |
| `--dry-run` | 실행 없이 계획만 표시 |
| `--no-sync` | master 동기화 스킵 (권장하지 않음) |
| `--merge` | rebase 대신 merge로 동기화 |

## Examples

### 전체 파이프라인
```bash
/snt-ccu2-host CCU2-17945
# 1. JIRA 티켓 조회 및 요구사항 분석
# 2. 코드 구현
# 3. Master 동기화 (rebase)
# 4. 빌드
# 5. 테스트
# 6. 결과 리포트
```

### 요구사항 분석만
```bash
/snt-ccu2-host SEB-1234 --analyze
# JIRA 티켓에서 요구사항 추출
# 구현 계획 제시
# 영향받는 파일 목록
```

### 빌드 및 테스트
```bash
/snt-ccu2-host CCU2-17945 --module container-manager --build --test
# container-manager 빌드
# 유닛 테스트 실행
# 결과 리포트
```

## Prerequisites

1. **JIRA 인증**: `.env` 파일에 설정
   ```
   JIRA_BASE_URL=https://sonatus.atlassian.net/
   JIRA_EMAIL=your.email@sonatus.com
   JIRA_API_TOKEN=your_api_token
   ```

2. **빌드 환경**: `build.py` 실행 가능

3. **Git**: Clean working directory 권장

## Output

실행 결과로 다음 정보 제공:
- JIRA 티켓 요약
- 요구사항 목록 (analyze 모드)
- 구현 변경사항 (implement 모드)
- 빌드 결과 및 아티팩트 위치 (build 모드)
- 테스트 결과 및 커버리지 (test 모드)
- 다음 단계 제안

## Troubleshooting

### JIRA 인증 실패
```bash
# .env 파일 확인
cat .env | grep JIRA

# API Token 테스트
curl -s -H "Authorization: Basic $(echo -n 'email:token' | base64)" \
     https://sonatus.atlassian.net/rest/api/2/myself
```

### 빌드 실패
```bash
# 클린 빌드 시도
/snt-ccu2-host CCU2-12345 --build --clean

# 상세 출력
/snt-ccu2-host CCU2-12345 --build --verbose
```

### 테스트 실패
```bash
# 커버리지와 함께 실행
/snt-ccu2-host CCU2-12345 --test --coverage

# 특정 컴포넌트만
/snt-ccu2-host CCU2-12345 --module <component> --test
```

### Rebase 충돌
```bash
# 충돌 파일 확인
git diff --name-only --diff-filter=U

# 충돌 해결 후
git add <resolved_files>
git rebase --continue

# 다시 실행
/snt-ccu2-host CCU2-12345 --build

# 또는 rebase 취소
git rebase --abort
```
