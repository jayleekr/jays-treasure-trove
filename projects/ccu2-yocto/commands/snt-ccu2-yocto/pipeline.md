---
name: snt-ccu2-yocto:pipeline
description: "Full development pipeline auto-orchestration. Starting from Jira issue or requirements, automatically performs spec → implement → build → test in a single command."
---

# /snt-ccu2-yocto:pipeline - Master Orchestrator

CCU_GEN2.0_SONATUS 프로젝트를 위한 전체 개발 파이프라인 오케스트레이터.

## Usage

```bash
# 요구사항 텍스트로 실행
/snt-ccu2-yocto:pipeline "<요구사항>"

# Jira Issue ID로 실행 (자동으로 요구사항 가져오기)
/snt-ccu2-yocto:pipeline CCU2-12345

# JQL 쿼리로 여러 이슈 처리 (순차 실행)
/snt-ccu2-yocto:pipeline --jql "project=CCU2 AND fixVersion='2.5.0'"
```

### Options

| Option | Description |
|--------|-------------|
| `--jql <query>` | JQL 쿼리로 이슈 검색 후 순차 처리 |
| `--skip-jira` | Jira 조회 건너뛰기 (텍스트 요구사항 사용) |
| `--skip-build` | 빌드 단계 건너뛰기 |
| `--skip-test` | 테스트 단계 건너뛰기 |
| `--dry-run` | 명령만 출력, 실행하지 않음 |
| `--target-ip <ip>` | 타겟 보드 IP (테스트용) |

## Examples

```bash
# Jira 이슈에서 요구사항 가져와서 전체 파이프라인 실행
/snt-ccu2-yocto:pipeline CCU2-12345

# 텍스트 요구사항으로 전체 파이프라인 실행
/snt-ccu2-yocto:pipeline "cgroupv2 지원 추가"

# Jira 이슈 + 빌드 제외 (명세+구현만)
/snt-ccu2-yocto:pipeline CCU2-12345 --skip-build

# 이번 스프린트 이슈 모두 처리
/snt-ccu2-yocto:pipeline --jql "project=CCU2 AND sprint in openSprints() AND status='To Do'"

# 테스트 포함 (타겟 보드)
/snt-ccu2-yocto:pipeline CCU2-12345 --target-ip 192.168.1.100
```

## Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                       PIPELINE EXECUTION                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────┐    ┌─────────┐    ┌───────────┐    ┌───────┐    ┌─────┐ │
│  │  JIRA  │───▶│  SPEC   │───▶│ IMPLEMENT │───▶│ BUILD │───▶│TEST │ │
│  │(opt)   │    │         │    │           │    │       │    │     │ │
│  └────────┘    └─────────┘    └───────────┘    └───────┘    └─────┘ │
│       │             │               │               │           │    │
│       ▼             ▼               ▼               ▼           ▼    │
│   Jira API     명세 YAML      파일 생성/수정   Docker 빌드  검증 리포트│
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

Input Detection:
├── CCU2-XXXXX 형식 → Jira API 조회 → SPEC
├── JQL 쿼리 → Jira 검색 → 순차 처리
└── 텍스트 요구사항 → 직접 SPEC
```

## Phase Details

### Phase 0: JIRA (요구사항 조회, Optional)

**Trigger:** 입력이 Jira Issue ID 형식 (예: CCU2-12345) 또는 --jql 옵션

**Process:**
1. ~/.env에서 Jira 인증 정보 로드
2. Jira API로 이슈 조회
3. 요구사항 정보 추출 (Summary, Description, Acceptance Criteria)
4. spec 형식으로 변환

**API Call:**
```bash
curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}/rest/api/3/issue/CCU2-12345" \
  -H "Accept: application/json"
```

**Output:** Jira 이슈 데이터 → SPEC 단계로 전달

**Skill:** `/snt-ccu2-yocto:jira`

```yaml
jira_issue:
  key: CCU2-12345
  summary: "Add cgroupv2 support"
  description: "..."
  acceptance_criteria:
    - "cgroupv2 마운트 확인"
    - "컨테이너 정상 실행"
  components: [kernel, systemd]
```

### Phase 1: SPEC (명세 생성)

**Input:** Jira 이슈 데이터 또는 사용자 요구사항 (자연어)

**Process:**
1. 요구사항 파싱 및 분석
2. 영향 컴포넌트 식별
3. 구조화된 명세 생성

**Output:** YAML 형식 명세

**Skill:** `/snt-ccu2-yocto:spec`

```yaml
spec:
  name: "cgroupv2-support"
  recipe_changes: [...]
  kernel_configs: [...]
  code_changes: [...]
```

### Phase 2: IMPLEMENT (구현)

**Input:** Phase 1 명세 또는 직접 요구사항

**Process:**
1. 명세 기반 파일 생성/수정
2. Yocto 레시피 작성
3. 커널 config 생성
4. 코드 수정

**Output:** 생성/수정된 파일들

**Skill:** `/snt-ccu2-yocto:implement`

```
Created: linux-ccu2/cgroupv2.config
Modified: linux-s32_5.10.bbappend
Created: recipes-core/systemd/systemd_%.bbappend
```

### Phase 3: ANALYZE (변경 분석)

**Input:** Git diff (변경된 파일 목록)

**Process:**
1. 변경 파일 분류 (recipe/code/config)
2. dependency.json 참조
3. 영향 모듈 식별
4. 빌드 범위 결정

**Output:** 빌드 전략

```
Build Scope: MODULE
Affected: linux-s32, systemd
Order: linux-s32 → systemd → image
```

### Phase 4: BUILD (빌드)

**Input:** 빌드 전략 및 옵션

**Process:**
1. Docker 컨테이너 진입
2. 캐시 클린 (필요시)
3. bitbake 빌드 실행
4. 아티팩트 수집

**Output:** 빌드 아티팩트

**Skill:** `/snt-ccu2-yocto:build`

```bash
# Inside Docker container
cd mobis/
./build.py -m linux-s32 -c cleansstate
./build.py -m systemd -c cleansstate
./build.py -ncpb -j 16 -p 16
```

### Phase 5: TEST (테스트)

**Input:** 빌드 결과

**Process:**
1. 빌드 검증 (Stage 1)
2. 이미지 검증 (Stage 2)
3. 정적 분석 (Stage 3)
4. 타겟 테스트 (Stage 4, optional)

**Output:** 테스트 리포트

**Skill:** `/snt-ccu2-yocto:test`

```
Stage 1: ✅ Build Verification
Stage 2: ✅ Image Validation
Stage 3: ✅ Static Analysis
Stage 4: ⏭️ Target Test (skipped)
```

### Phase 6: REPORT (리포트)

**Input:** 전체 파이프라인 결과

**Output:** 최종 리포트

```
## Pipeline Execution Report

### Request
"cgroupv2 지원 추가"

### Phases Completed
1. SPEC: ✅ Generated cgroupv2-spec.yaml
2. IMPLEMENT: ✅ Created 3 files, Modified 1 file
3. ANALYZE: ✅ Build scope: MODULE (linux-s32, systemd)
4. BUILD: ✅ Completed in 1h 30m
5. TEST: ✅ All stages passed

### Files Changed
- Created: linux-ccu2/cgroupv2.config
- Modified: linux-s32_5.10.bbappend
- Created: systemd_%.bbappend
- Created: claudedocs/cgroupv2-migration.md

### Artifacts
- mobis/deploy/fsl-image-ccu2-mobisccu2.tar.gz
- mobis/deploy/build_info.json

### Status: SUCCESS ✅
```

## Execution Architecture

### Sub-Agent Delegation Pattern

When executing this pipeline, Claude MUST use the Task tool to delegate phases to sub-agents for parallel/sequential execution:

```
Pipeline Execution Flow:
┌─────────────────────────────────────────────────────────────────┐
│  Claude (Orchestrator)                                          │
│                                                                  │
│  1. Task(Explore) ─────► Jira API 조회 (if issue ID provided)   │
│         ↓                                                       │
│  2. Task(Plan) ────────► Spec 생성 (영향 분석)                   │
│         ↓                                                       │
│  3. Direct Edit ───────► Implement (파일 생성/수정)              │
│         ↓                                                       │
│  4. Bash(script) ──────► Build (yocto-build.sh 실행)            │
│         ↓                                                       │
│  5. Bash(script) ──────► Test (yocto-test.sh 실행)              │
└─────────────────────────────────────────────────────────────────┘
```

### Script Integration

Build and Test phases use bundled scripts for reliable execution:

**Build Script:**
```bash
# Located at: .claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --scope auto
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --module linux-s32,systemd --clean
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --scope full --release
```

**Test Script:**
```bash
# Located at: .claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh
.claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh --stages 1,2,3
.claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh --stages 1,2,3,4 --target-ip 192.168.1.100
```

### Container Execution

The build script automatically handles Docker container execution:
- If outside container: Uses `./run-dev-container.sh -x "command"`
- If inside container: Executes directly

## Sub-Commands

각 단계는 개별 커맨드로도 실행 가능:

| Command | Description |
|---------|-------------|
| `/snt-ccu2-yocto:jira` | Jira 이슈 조회 |
| `/snt-ccu2-yocto:spec` | 명세 생성만 |
| `/snt-ccu2-yocto:implement` | 구현만 |
| `/snt-ccu2-yocto:build` | 빌드만 |
| `/snt-ccu2-yocto:test` | 테스트만 |

## Auto-Triggering

다음 상황에서 파이프라인 자동 제안:

```yaml
triggers:
  suggest_pipeline:
    - condition: "새 기능 요청"
      action: "/snt-ccu2-yocto:pipeline 제안"

    - condition: "버그 수정 요청"
      action: "수정 후 /snt-ccu2-yocto:build + test 제안"

    - condition: "build_info.json 변경"
      action: "전체 빌드 필요 알림"
```

## Boundaries

**Will:**
- 전체 파이프라인 자동 오케스트레이션
- 각 단계 순차 실행 및 결과 전달
- 에러 발생 시 중단 및 보고
- 상세 실행 리포트 생성

**Will Not:**
- 프로덕션 환경 직접 배포
- Git commit/push 자동화 (사용자 확인 필요)
- 빌드 시스템 설정 변경

## Error Handling

파이프라인 중 에러 발생 시:

```
## Pipeline Error Report

### Failed Phase: BUILD

### Error:
bitbake exited with code 1
Recipe parsing error in linux-s32_5.10.bbappend

### Suggestion:
1. bbappend 문법 확인
2. SRC_URI 경로 확인
3. /snt-ccu2-yocto:implement로 수정 후 재시도

### Rollback:
변경 사항을 되돌리려면:
git checkout -- mobis/layers/meta-sonatus/
```

## Example Execution

### Example 1: Jira Issue 기반 파이프라인

```
User: /snt-ccu2-yocto:pipeline CCU2-12345

Claude:
파이프라인을 시작합니다.

## Phase 0: JIRA
Jira 이슈 CCU2-12345를 조회합니다...
- Summary: Add cgroupv2 support for container runtime
- Components: kernel, systemd, container
- Acceptance Criteria: 3개 항목
✅ Jira 조회 완료

## Phase 1: SPEC
Jira 요구사항을 분석하여 명세를 생성합니다...
- Source: CCU2-12345
- Recipe changes: 2개
- Kernel configs: 1개
✅ 명세 생성 완료

## Phase 2: IMPLEMENT
명세에 따라 파일을 생성/수정합니다...
- Created: linux-ccu2/cgroupv2.config
- Modified: linux-s32_5.10.bbappend
- Created: systemd_%.bbappend
✅ 구현 완료

## Phase 3: ANALYZE
변경 사항을 분석합니다...
- 영향 모듈: linux-s32, systemd
- 빌드 범위: MODULE
✅ 분석 완료

## Phase 4: BUILD
Docker 컨테이너에서 빌드를 실행합니다...
[빌드 명령어 및 진행 상황]
✅ 빌드 완료 (1h 30m)

## Phase 5: TEST
테스트 파이프라인을 실행합니다...
- Stage 1: ✅ Build Verification
- Stage 2: ✅ Image Validation
- Stage 3: ✅ Static Analysis
✅ 테스트 완료

## Pipeline Complete ✅
CCU2-12345 요구사항이 성공적으로 구현되었습니다.
Jira 이슈 링크: https://sonatus.atlassian.net/browse/CCU2-12345
```

### Example 2: 텍스트 요구사항 기반 파이프라인

```
User: /snt-ccu2-yocto:pipeline "cgroupv2 지원 추가"

Claude:
파이프라인을 시작합니다.

## Phase 1: SPEC
요구사항을 분석하여 명세를 생성합니다...
✅ 명세 생성 완료

[이하 동일...]
```
