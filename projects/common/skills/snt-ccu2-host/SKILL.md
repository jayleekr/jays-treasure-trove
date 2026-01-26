---
name: snt-ccu2-host
description: JIRA 티켓 기반 CCU-2.0 구현 파이프라인. 요구사항 추출, 코드 구현, 빌드, 테스트를 자동화. "파이프라인", "워크플로우", "티켓 구현" 키워드시 활성화
version: 1.0.0
author: CCU-2.0 Team
tags: [pipeline, jira, host, implementation, automation]
---

# SNT-CCU2-HOST Pipeline Agent

JIRA 티켓부터 테스트까지 CCU-2.0 개발 파이프라인을 자동화하는 스킬.

## When to Use This Skill

이 스킬은 다음 요청에서 활성화됩니다:
- JIRA 티켓 기반 기능 구현 (`CCU2-*`, `SEB-*`, `CRM-*`)
- 요구사항 → 구현 → 빌드 → 테스트 전체 파이프라인 실행
- CCU-2.0 컴포넌트 빌드 및 테스트 자동화
- `/snt-ccu2-host` 명령어 호출

## When NOT to Use This Skill (Deactivation)

**Yocto 환경에서는 이 스킬이 비활성화됩니다:**

다음 조건 중 하나라도 충족되면 `/snt-ccu2-yocto` 스킬을 대신 사용하세요:

| Condition | Detection |
|-----------|-----------|
| 경로에 `CCU_GEN2.0_SONATUS` 포함 | `$PWD` 또는 `$CLAUDE_PROJECT_DIR` 확인 |
| `mobis/` 디렉토리 존재 | `test -d mobis/` |
| `lge/` 디렉토리 존재 | `test -d lge/` |
| `run-dev-container.sh` 존재 | `test -f run-dev-container.sh` |
| `mobis/build.py` 존재 | `test -f mobis/build.py` |

**Yocto 환경에서 사용할 명령:**
- `/snt-ccu2-yocto:build` - Yocto 빌드 오케스트레이션
- `/snt-ccu2-yocto:pipeline` - 전체 파이프라인
- `/snt-ccu2-yocto:spec` - 스펙 생성

**Host 환경 판별:**
- 경로에 `ccu-2.0` 포함 (Yocto 마커 없음)
- `build.py` 가 프로젝트 루트에 직접 존재 (mobis/ 아님)
- CMake 기반 빌드 시스템 (`CMakeLists.txt` 존재)

## Prerequisites

### Environment Setup
1. **JIRA 인증**: `.env` 파일에 API Token 설정
   ```
   JIRA_BASE_URL=https://sonatus.atlassian.net/
   JIRA_EMAIL=your.email@sonatus.com
   JIRA_API_TOKEN=your_api_token
   ```

2. **빌드 환경**: `build.py` 실행 가능 상태

3. **Git 설정**: Clean working directory

### Dependency Check
워크플로우 시작 전 확인:
```bash
# .env 파일 확인
test -f .env && echo "ENV: OK" || echo "ENV: MISSING"

# build.py 확인
test -f build.py && echo "BUILD: OK" || echo "BUILD: MISSING"

# git 상태 확인
git status --porcelain | wc -l
```

## Core Workflow

### 1. Understand User Intent

사용자 요청에서 다음 정보를 파악:
- **JIRA Ticket ID**: `CCU2-*`, `SEB-*`, `CRM-*` 형식
- **실행 범위**: 전체 파이프라인 또는 특정 단계
- **대상 컴포넌트**: container-manager, vam, libsntxx 등
- **테스트 요구사항**: 단위 테스트, 통합 테스트

필요시 질문:
- "어떤 JIRA 티켓을 구현할까요?"
- "전체 파이프라인을 실행할까요, 특정 단계만 실행할까요?"
- "어떤 컴포넌트를 빌드할까요?"

### 2. Execute Appropriate Mode

사용자 요구에 따라 5가지 모드 중 선택:

#### Analysis Mode (분석 모드)
JIRA 티켓 요구사항 분석이 필요할 때 사용.

실행 단계:
1. JIRA REST API로 티켓 조회
2. 티켓 정보 파싱:
   - Summary/Title
   - Description
   - Acceptance Criteria
   - Components
   - Priority, Assignee
   - Linked tickets
3. 요구사항 추출:
   - 기능적 요구사항
   - 기술적 제약사항
   - 영향받는 파일 예측
   - 테스트 기준
4. 요구사항 요약 및 구현 계획 제시

Reference: `references/jira-workflow.md`
Reference: `references/requirements-analysis.md`

#### Implementation Mode (구현 모드)
요구사항이 명확하고 코드 변경이 필요할 때 사용.

실행 단계:
1. Git clean 상태 확인
2. Feature branch 생성: `feature/<TICKET_ID>-description`
3. 요구사항 기반 수정 파일 식별
4. CCU-2.0 패턴에 따라 변경 구현:
   - C++ 소스 코드
   - 설정 파일
   - 테스트 코드
5. 문법 및 포맷팅 검증
6. 티켓 참조 커밋 생성

Reference: `references/git-workflow.md`

#### Sync Mode (동기화 모드)
빌드 또는 PR 생성 전 base 브랜치와 동기화가 필요할 때 사용.

**IMPORTANT**: 빌드 및 PR 전에 반드시 실행하여 conflict를 미리 방지.

실행 단계:
1. Remote 식별 (origin 또는 ccu)
2. 최신 base 브랜치 fetch: `git fetch <remote> master`
3. 현재 브랜치가 뒤처진 커밋 수 확인
4. 뒤처진 경우 자동 rebase 시도:
   ```bash
   git rebase <remote>/master
   ```
5. Conflict 발생 시:
   - 충돌 파일 목록 표시
   - 수동 해결 안내 제공
   - 워크플로우 일시 중단
6. Rebase 성공 시 다음 단계 진행

**Conflict 해결 워크플로우**:
```bash
# 1. 충돌 파일 확인
git diff --name-only --diff-filter=U

# 2. 파일 수정하여 충돌 해결

# 3. 해결된 파일 스테이징
git add <resolved_files>

# 4. Rebase 계속
git rebase --continue

# 5. 파이프라인 재실행
/snt-ccu2-host CCU2-12345 --build
```

**옵션**:
- `--no-sync`: 동기화 스킵 (권장하지 않음)
- `--merge`: rebase 대신 merge 사용 (히스토리 보존)

Reference: `references/git-workflow.md`

#### Build Mode (빌드 모드)
구현 완료 후 빌드가 필요할 때 사용.

**Slash Command**: `/snt-ccu2-host:build`

실행 단계:
1. 구현 변경사항 커밋 확인
2. `/snt-ccu2-host:build` 명령 또는 직접 빌드 실행:
   ```bash
   # Slash command 사용 (권장)
   /snt-ccu2-host:build --module <component>
   /snt-ccu2-host:build --module <component> --tests
   /snt-ccu2-host:build --module <component> --clean --release

   # 또는 직접 실행
   ./build.py --module <component> --build-type Debug
   ./build.py --module <component> --clean
   ./build.py --module <component> --cross-compile --ecu CCU2
   ```
3. 빌드 진행 모니터링
4. 빌드 출력에서 에러/경고 파싱
5. 빌드 결과 및 아티팩트 위치 보고

Reference: `references/build-reference.md`
Slash Command: `.claude/commands/snt-ccu2-host/build.md`

#### Test Mode (테스트 모드)
빌드 성공 후 검증이 필요할 때 사용.

실행 단계:
1. 티켓에서 테스트 요구사항 식별
2. 적절한 테스트 실행:
   - Unit tests: `./build.py --module <component> --tests`
   - Coverage: `./build.py --module <component> --tests --coverage`
   - Integration: `python3 <component>/test.py`
3. 테스트 결과 파싱
4. 테스트 리포트 생성
5. Acceptance criteria 충족 여부 검증

Reference: `references/test-workflow.md`

#### Complete Mode (전체 모드)
티켓부터 PR까지 전체 자동 워크플로우가 필요할 때 사용.

실행 단계:
1. Analysis mode 실행 → 요구사항 이해
2. Implementation mode 실행 → 코드 변경
3. **Sync mode 실행 → master와 동기화 (conflict 방지)**
4. Build mode 실행 → 컴파일/빌드
5. Test mode 실행 → 검증
6. Summary report 생성
7. PR 생성 (`/jira-pr` 호출)

### 3. Handle Errors Gracefully

에러 발생 시 복구 전략 적용:

**JIRA 인증 실패**:
- .env 파일 존재 확인
- API Token 유효성 확인
- 수동 티켓 정보 입력 안내

**빌드 실패**:
- 빌드 에러 출력 파싱
- 원인 식별 (문법 에러, 의존성, 타입 에러)
- 수정 제안
- 사용자 확인 후 재시도

**테스트 실패**:
- 전체 테스트 출력 캡처
- 실패한 테스트 케이스 식별
- 실패를 구현 변경에 매핑
- 디버깅 단계 제안

**Git 충돌 (Sync/Rebase)**:
- Rebase 충돌 자동 감지
- 충돌 파일 목록 표시: `git diff --name-only --diff-filter=U`
- 충돌 해결 가이드 제공:
  ```
  1. 충돌 파일 수정
  2. git add <resolved_files>
  3. git rebase --continue
  4. /snt-ccu2-host 재실행
  ```
- `git rebase --abort`로 취소 가능
- 해결 후 워크플로우 재개

Reference: `references/error-recovery.md`
Reference: `references/git-workflow.md`

## Tool Integration

### JIRA API 사용

`.env` 파일에서 인증 정보 로드하여 REST API 호출:

```bash
# .env 파일 읽기
source <(grep -E '^JIRA_' .env | sed 's/^/export /')

# API 호출 (Basic Auth)
AUTH=$(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)
curl -s -L \
    -H "Authorization: Basic ${AUTH}" \
    -H "Accept: application/json" \
    "${JIRA_BASE_URL}rest/api/2/issue/${TICKET_ID}"
```

주요 필드 파싱:
```bash
# jq로 JSON 파싱
jq -r '.fields.summary' ticket.json
jq -r '.fields.description // "No description"' ticket.json
jq -r '.fields.components[].name' ticket.json
jq -r '.fields.status.name' ticket.json
```

Reference: `references/jira-workflow.md`

### build.py 사용

CCU-2.0 컴포넌트 빌드:
```bash
./build.py --module <component> [options]
```

주요 옵션:
- `--build-type Debug|Release` - 빌드 타입
- `--clean, -c` - 클린 빌드
- `--tests` - 유닛 테스트 실행
- `--coverage` - 코드 커버리지 생성
- `--cross-compile --ecu CCU2` - 크로스 컴파일
- `--verbose` - 상세 출력
- `--jobs N, -j N` - 병렬 빌드 (기본: 24)

Reference: `references/build-reference.md`

### Git 워크플로우 관리

브랜치 전략:
```bash
# Feature branch 생성
git checkout -b feature/<TICKET_ID>-<description>

# 변경사항 커밋
git add .
git commit -m "[<TICKET_ID>] Description"

# Remote push
git push -u origin feature/<TICKET_ID>-<description>
```

커밋 메시지 포맷:
```
[CCU2-12345] Brief description

- Detail 1
- Detail 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Reference: `references/git-workflow.md`

## Communication Patterns

### 요구사항 분석 결과 표시

```
JIRA Ticket Analysis: <TICKET_ID>
=============================================

Title: <Summary>
Status: <Status> | Priority: <Priority>
Assignee: <Name>

Description:
<Description 내용>

Requirements Extracted:
  1. [FR-1] <기능적 요구사항>
  2. [TR-1] <기술적 제약사항>
  3. [TC-1] <테스트 기준>

Files Likely Affected:
  - <component>/src/file.cxx
  - <component>/config/config.json

Implementation Plan:
  1. <Step 1>
  2. <Step 2>
  ...
```

### 사용자 결정 안내

워크플로우에서 사용자 입력이 필요할 때:
- "티켓에 CCU2와 CCU2_LITE 둘 다 언급되어 있습니다. 어떤 타겟을 우선할까요?"
- "빌드가 성공했습니다. 테스트를 실행할까요, PR을 생성할까요?"
- "3개의 테스트 실패가 발견되었습니다. 수정 후 계속할까요?"

### 진행 상황 추적

다단계 워크플로우에서 TodoWrite로 진행 추적:
- 각 파이프라인 단계별 todo 생성
- 완료된 단계 즉시 마킹
- 전체 진행률 사용자에게 표시

## Success Criteria

파이프라인 태스크 완료 전 다음 확인:
- ✅ JIRA 티켓 요구사항 추출 및 문서화
- ✅ 구현이 모든 acceptance criteria 충족
- ✅ 모든 변경사항 티켓 참조로 커밋
- ✅ 빌드 에러 없이 완료
- ✅ 테스트 통과 (또는 실패 문서화)
- ✅ PR 생성 (요청시) 적절한 포맷으로

## Integration with Other Workflows

### MISRA Compliance Integration
C++ 변경 후 MISRA 위반 체크:
```bash
./isir.py -m <module> -c MISRA -d
```

### Container Test Integration
컨테이너 관련 변경시:
```bash
/container-test --validate
```

### Build Component Integration
표준 컴포넌트 빌드:
```bash
# Slash command (권장)
/snt-ccu2-host:build --module <component>

# 또는 기존 명령
/build-component <component>
```

### Available Slash Commands
| Command | Description |
|---------|-------------|
| `/snt-ccu2-host` | 전체 파이프라인 (분석→구현→빌드→테스트) |
| `/snt-ccu2-host:build` | 스마트 빌드 오케스트레이션 |
| `/build-component` | 기본 컴포넌트 빌드 |
| `/jira-commit` | JIRA 티켓 기반 커밋 |

## Important Constraints

### What This Skill Can Do
- JIRA 티켓 정보 조회 및 파싱
- 요구사항 분석 및 구현 계획 생성
- CCU-2.0 컴포넌트 빌드 실행
- 테스트 실행 및 결과 파싱
- Git 워크플로우 및 PR 관리
- 일반적인 에러 시나리오 처리

### What This Skill Cannot Do
- 유효한 인증 없이 JIRA 접근
- 보안 또는 컴플라이언스 체크 우회
- PR 자동 머지 (사람 리뷰 필요)
- 빌드 환경 없이 빌드 실행

### Assumptions
- `.env` 파일에 유효한 JIRA 인증 정보 존재
- `build.py`가 적절히 설정됨
- 저장소에 Git 쓰기 권한 보유
- 개발 환경에 필요한 의존성 설치됨

## Metrics and Reporting

파이프라인 리포트 생성시 포함:
- Ticket ID 및 summary
- 요구사항 커버리지 (충족/전체)
- 구현 변경 (파일 수, 라인 수)
- 빌드 상태 및 소요 시간
- 테스트 결과 (pass/fail/skip)
- 수동 대비 절약 시간 추정

## Version History

- 1.0.0 (2026-01-05): 5개 워크플로우 모드로 초기 릴리스
