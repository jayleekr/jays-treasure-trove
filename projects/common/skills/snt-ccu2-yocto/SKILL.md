---
name: snt-ccu2-yocto
description: Yocto/Bitbake 기반 CCU2 임베디드 리눅스 개발 파이프라인. JIRA 연동, 레시피 작성, Docker 빌드, 이미지 검증 자동화. "yocto", "bitbake", "recipe", "임베디드" 키워드시 활성화
version: 2.0.0
author: CCU2 Team
tags: [yocto, bitbake, embedded, linux, recipe, pipeline]
# Claude Code Warm Strategy 2026.2 적용
memory: project
allowed-tools: Read, Grep, Glob, Bash(./build.py *), Bash(./run-dev-container.sh *), Bash(git *), Bash(find *), Bash(cat *)
---

# SNT-CCU2-YOCTO Pipeline Agent

JIRA 티켓부터 이미지 빌드까지 CCU2 Yocto 개발 파이프라인을 자동화하는 스킬.

## 📊 Dynamic Context (Auto-injected)

**Repository State**:
- Repo info: !`cat info/repo_info.json 2>/dev/null | head -5 || echo "Not initialized"`
- Current branch: !`git branch --show-current 2>/dev/null || echo "Unknown"`
- Modified files: !`git status --short 2>/dev/null | head -10 || echo "Not a git repo"`

**Last Build Status**:
!`cat build.log 2>/dev/null | tail -5 | grep -E "SUCCESS|FAILED|ERROR" || echo "No recent build"`

## When to Use This Skill

이 스킬은 다음 요청에서 활성화됩니다:
- Yocto 레시피 작성/수정 (`*.bb`, `*.bbappend`, `*.bbclass`)
- 커널 설정 변경 (`*.config`, `defconfig`)
- 임베디드 리눅스 이미지 빌드
- JIRA 티켓 기반 Yocto 기능 구현
- `/snt-ccu2-yocto` 명령어 호출

## Project Detection

이 스킬은 다음 경로 패턴에서 자동 활성화:
- `*CCU_GEN2.0_SONATUS*` - Yocto manifest 저장소
- `mobis/`, `lge/` 디렉토리 존재 시

## Prerequisites

### Environment Setup
1. **JIRA 인증**: `.env` 파일에 API Token 설정
   ```
   JIRA_BASE_URL=https://sonatus.atlassian.net/
   JIRA_EMAIL=your.email@sonatus.com
   JIRA_API_TOKEN=your_api_token
   ```

2. **Docker 환경**: `run-dev-container.sh` 실행 가능

3. **빌드 초기화**: `init.py` 완료 상태

### Directory Structure
```
CCU_GEN2.0_SONATUS.manifest/
├── mobis/                    # MOBIS Tier-1
│   ├── layers/
│   │   └── meta-sonatus/    # Sonatus 레이어
│   ├── build.py             # 빌드 스크립트
│   └── deploy/              # 빌드 결과물
├── lge/                      # LGE Tier-1
├── info/
│   ├── repo_info.json       # 버전 정보
│   └── build_info.json      # 빌드 정보
├── init.py                   # 초기화 스크립트
└── run-dev-container.sh      # Docker 진입
```

## Core Workflow

### 1. Understand User Intent

사용자 요청에서 다음 정보를 파악:
- **JIRA Ticket ID**: `CCU2-*`, `SEB-*`, `CRM-*` 형식
- **대상 Tier**: MOBIS 또는 LGE
- **변경 유형**: 레시피, 커널 설정, 패치, 이미지
- **빌드 범위**: 특정 모듈 또는 전체 이미지

필요시 질문:
- "어떤 Tier를 대상으로 할까요? (MOBIS/LGE)"
- "어떤 레시피를 수정할까요?"
- "전체 이미지 빌드가 필요할까요, 특정 모듈만 빌드할까요?"

### 2. Execute Appropriate Mode

#### Spec Mode (명세 모드)
요구사항을 구조화된 명세로 변환.

실행 단계:
1. JIRA 티켓 또는 요구사항 분석
2. 영향받는 레시피/레이어 식별
3. 구조화된 명세 생성

출력 예시:
```yaml
spec:
  name: "cgroupv2-support"
  tier: mobis
  recipe_changes:
    - layer: meta-sonatus
      recipe: linux-s32_5.10.bbappend
      action: modify
  kernel_configs:
    - file: cgroupv2.config
      options:
        - CONFIG_CGROUP_V2=y
  code_changes:
    - file: systemd_%.bbappend
      action: create
```

Reference: `references/spec-workflow.md`

#### Implement Mode (구현 모드)
명세에 따라 Yocto 파일 생성/수정.

실행 단계:
1. 레시피 파일 생성/수정
2. 커널 config fragment 작성
3. bbappend 파일 작성
4. 패치 파일 생성 (필요시)

Yocto 파일 패턴:
```bash
# bbappend 위치
meta-sonatus/recipes-*/*/
meta-sonatus/recipes-kernel/linux/

# Config fragment 위치
meta-sonatus/recipes-kernel/linux/files/
meta-sonatus/recipes-kernel/linux-ccu2/
```

Reference: `references/implement-workflow.md`

#### Build Mode (빌드 모드)
Docker 컨테이너에서 bitbake 빌드 실행.

**Slash Command**: `/snt-ccu2-yocto:build`

빌드 범위 결정:
- **MODULE**: 특정 레시피만 빌드 (`-m linux-s32`)
- **FULL**: 전체 이미지 빌드 (`-ncpb`)
- **BRANCH**: 특정 Git 브랜치에서 빌드 (`--branch <name>`)

실행 예시:
```bash
# Docker 컨테이너 진입
./run-dev-container.sh

# 컨테이너 내부에서
cd mobis/
./build.py -m linux-s32 -c cleansstate  # 클린
./build.py -ncpb -j 16 -p 16            # 전체 빌드
```

#### Branch Build Mode (브랜치 빌드 모드)
특정 Git 브랜치에서 Sonatus 컴포넌트를 빌드.

**사용법**:
```bash
/snt-ccu2-yocto:build --module container-manager --branch CCU2-16964-feature
/snt-ccu2-yocto:build -m vam -b feature-branch --keep-branch
```

**워크플로우**:
1. Recipe 파일 검색 및 백업 (`.bb.bak`)
2. `SNT_BRANCH ?= "master"` → `SNT_BRANCH = "branch-name"` 수정
3. `cleansstate` 실행 (캐시 무효화)
4. 빌드 실행
5. Recipe 복원 (기본) 또는 유지 (`--keep-branch`)

**지원 컴포넌트**:
- container-manager, vam, dpm, diagnostic-manager, ethnm
- libsntxx, libsnt-vehicle, libsnt-ehal, libsnt-cantp
- vcc, vdc, soa, mqtt-middleware, container-app

Reference: `references/build-workflow.md`

#### Test Mode (테스트 모드)
빌드 결과 검증.

테스트 단계:
1. **Stage 1**: 빌드 검증 - 에러/경고 확인
2. **Stage 2**: 이미지 검증 - 필수 패키지 포함 확인
3. **Stage 3**: 정적 분석 - 레시피 문법 검사
4. **Stage 4**: 타겟 테스트 - 실제 보드에서 실행 (optional)

Reference: `references/test-workflow.md`

#### Pipeline Mode (전체 파이프라인)
JIRA 티켓부터 테스트까지 전체 자동화.

```
JIRA → SPEC → IMPLEMENT → BUILD → TEST
```

**Slash Command**: `/snt-ccu2-yocto:pipeline`

### 3. Handle Errors Gracefully

**bitbake 파싱 에러**:
- bbappend 문법 확인
- FILESEXTRAPATHS 경로 확인
- SRC_URI 체크섬 확인

**빌드 실패**:
- 의존성 누락 확인
- LICENSE 파일 확인
- do_compile 로그 분석

**이미지 실패**:
- ROOTFS 크기 확인
- 패키지 충돌 확인

Reference: `references/error-recovery.md`

## Tool Integration

### JIRA API 사용
```bash
source <(grep -E '^JIRA_' .env | sed 's/^/export /')
curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}/rest/api/3/issue/${TICKET_ID}"
```

### build.py 사용
```bash
# 모듈 빌드
./build.py -m <recipe> [options]

# 전체 이미지 빌드
./build.py -ncpb -j 16 -p 16

# 클린 빌드
./build.py -m <recipe> -c cleansstate
```

주요 옵션:
- `-m, --module` - 대상 레시피
- `-c, --clean` - cleansstate 실행
- `-j, --jobs` - 병렬 태스크 수
- `-p, --parallel` - 병렬 레시피 수
- `-ncpb` - 전체 이미지 빌드
- `--dry-run` - 명령만 출력

### 브랜치 빌드 스크립트
```bash
# 특정 브랜치에서 빌드
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --module container-manager --branch CCU2-16964-feature

# 빌드 후 레시피 유지
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh -m vam -b feature-branch --keep-branch

# LGE Tier 빌드
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --module dpm --branch hotfix --tier lge
```

브랜치 빌드 옵션:
- `--branch, -b` - Git 브랜치 이름
- `--keep-branch, -k` - 빌드 후 레시피 복원 안함
- `--tier, -t` - 대상 Tier (mobis/lge)

### Docker 컨테이너
```bash
# 컨테이너 진입
./run-dev-container.sh

# 컨테이너 내 명령 실행
./run-dev-container.sh -x "cd mobis && ./build.py -ncpb"
```

## Communication Patterns

### 명세 생성 결과
```
## Spec Generated: cgroupv2-support

### Recipe Changes
| Layer | Recipe | Action |
|-------|--------|--------|
| meta-sonatus | linux-s32_5.10.bbappend | modify |
| meta-sonatus | systemd_%.bbappend | create |

### Kernel Configs
- cgroupv2.config: CONFIG_CGROUP_V2=y

### Implementation Ready
다음 명령으로 구현을 시작하세요:
/snt-ccu2-yocto:implement
```

### 빌드 진행 상황
```
## Build Progress

Tier: MOBIS
Scope: MODULE (linux-s32)

[1/3] ✅ cleansstate 완료
[2/3] 🔄 do_compile 진행 중...
[3/3] ⏳ do_deploy 대기

예상 완료: 45분
```

### 테스트 결과
```
## Test Results

Stage 1: ✅ Build Verification
  - Errors: 0
  - Warnings: 3 (non-critical)

Stage 2: ✅ Image Validation
  - Size: 512MB (limit: 1GB)
  - Required packages: All present

Stage 3: ✅ Static Analysis
  - Recipe syntax: OK
  - License compliance: OK

Overall: PASSED ✅
```

## Success Criteria

태스크 완료 전 다음 확인:
- ✅ Yocto 레시피 문법 검증
- ✅ 빌드 에러 없이 완료
- ✅ 이미지 크기 제한 이내
- ✅ 필수 패키지 포함 확인
- ✅ 테스트 통과 (또는 실패 문서화)

## Important Constraints

### What This Skill Can Do
- Yocto 레시피/bbappend 작성
- 커널 config fragment 생성
- Docker 컨테이너에서 빌드 실행
- 빌드 결과 분석 및 리포트
- JIRA 티켓 연동

### What This Skill Cannot Do
- 프로덕션 이미지 직접 배포
- 타겟 보드 플래싱 (수동 필요)
- Yocto 메타 레이어 구조 변경
- 빌드 시스템 자체 수정

### Assumptions
- Docker 환경 설정 완료
- `init.py` 실행으로 저장소 동기화 완료
- 빌드 호스트에 충분한 디스크 공간 (최소 100GB)
- 네트워크 접근 가능 (패키지 다운로드)

## Available Slash Commands

| Command | Description |
|---------|-------------|
| `/snt-ccu2-yocto:pipeline` | 전체 파이프라인 (JIRA→빌드→테스트) |
| `/snt-ccu2-yocto:spec` | 명세 생성 |
| `/snt-ccu2-yocto:implement` | 레시피/설정 구현 |
| `/snt-ccu2-yocto:build` | Docker 빌드 실행 |
| `/snt-ccu2-yocto:test` | 테스트 파이프라인 |
| `/snt:jira` | JIRA 이슈 조회/생성 |

## Version History

- 1.0.0 (2026-01-06): 초기 릴리스
