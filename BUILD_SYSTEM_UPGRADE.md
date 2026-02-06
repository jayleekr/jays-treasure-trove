# Build System Upgrade Plan

> 현재 빌드 시스템 분석 + Claude Code 2026.2 Best Practice 적용
> 작성일: 2026-02-06

---

## 📊 현재 빌드 시스템 분석

### 강점 ✅

1. **Smart Scope Detection** — git diff 분석으로 빌드 범위 자동 결정
2. **Branch Override** — 특정 브랜치에서 컴포넌트 빌드 지원
3. **Auto Retry** — fetch 실패시 자동 재시도 (DNS/네트워크)
4. **Docker Integration** — 컨테이너 내 빌드 자동화
5. **SDK Generation** — 크로스 컴파일 SDK 지원
6. **Detailed Logging** — 구조화된 로그 저장

### 개선 필요 ⚠️

| 영역 | 현재 | 목표 |
|------|------|------|
| 컨텍스트 | 정적 | 동적 주입 (`!command`) |
| 빌드 학습 | 없음 | 패턴 기억 (`memory:`) |
| 병렬 빌드 | 순차 | Agent Teams |
| 에러 분석 | 수동 | 서브에이전트 자동 분석 |
| 리모트 빌드 | 없음 | SSH + Claude 헤드리스 |

---

## 🚀 Phase 1: 동적 컨텍스트 주입

### 현재 SKILL.md
```yaml
---
name: snt-ccu2-yocto
description: ...
---
# 정적 내용만
```

### 개선된 SKILL.md
```yaml
---
name: snt-ccu2-yocto
description: Yocto/Bitbake CCU2 development pipeline
memory: project
allowed-tools: Read, Grep, Bash(./build.py *), Bash(./run-dev-container.sh *)
---

## 📊 Current Build State

**Repository**:
- Branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
- Modified: !`git status --short 2>/dev/null | wc -l` files
- Last commit: !`git log -1 --format="%s (%cr)" 2>/dev/null || echo "unknown"`

**Docker Container**:
!`docker ps --filter "name=.*CCU_GEN2.0_SONATUS" --format "✅ {{.Names}} ({{.Status}})" 2>/dev/null | head -1 || echo "❌ No container running"`

**Last Build**:
!`ls -t claudedocs/build-logs/*.status 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "No recent build"`

**Disk Space**:
!`df -h /workspace 2>/dev/null | tail -1 | awk '{print "Used: " $3 "/" $2 " (" $5 ")"}' || echo "Unknown"`
```

---

## 🚀 Phase 2: 빌드 패턴 학습 (Persistent Memory)

### 스킬에 메모리 활성화
```yaml
---
name: snt-ccu2-yocto
memory: project
---
```

### 에이전트 메모리 디렉토리
```
.claude/agent-memory/snt-ccu2-yocto/
├── MEMORY.md              # 빌드 패턴 요약
├── error-patterns.md      # 반복 에러 패턴
├── build-times.json       # 모듈별 빌드 시간
└── fix-history.md         # 성공한 수정 이력
```

### MEMORY.md 예시
```markdown
# Yocto Build Agent Memory

## Learned Patterns

### Fetch Failures
- DNS 이슈는 보통 3회 재시도로 해결
- VPN 연결 확인 필요시 있음

### Common Build Errors
1. **linux-s32 dtc warning** — 무시 가능, 빌드 성공에 영향 없음
2. **container-manager sstate** — 브랜치 변경시 항상 cleansstate 필요
3. **systemd bbappend** — FILESEXTRAPATHS:prepend := 형식 필수

### Optimal Settings
- mobis: -j 16 -p 16 적정 (메모리 32GB 기준)
- lge: -j 12 -p 12 권장 (빌드 서버 부하 고려)

### Module Build Times (Average)
- linux-s32: 45분
- systemd: 15분
- container-manager: 8분
- full image: 2시간 30분
```

---

## 🚀 Phase 3: 빌드 분석 서브에이전트

### agents/build-analyzer.md (기존 → 개선)

```yaml
---
name: build-analyzer
description: Analyze build failures and suggest fixes. Invoked automatically on build errors.
tools: Read, Grep, Glob, Bash(grep *), Bash(tail *), Bash(cat *)
model: haiku
memory: project
---

You are a Yocto/CMake build failure specialist for CCU2.

## On Invocation

1. **Read the build log** (last 500 lines)
2. **Identify the failing task** (do_fetch, do_compile, do_install, etc.)
3. **Categorize the error**:
   - Fetch: Network/DNS, checksum mismatch, branch not found
   - Compile: Syntax error, missing header, type mismatch
   - Link: Missing library, symbol not found
   - Package: File conflict, missing files

4. **Check memory for similar past errors**
5. **Suggest fix** with specific file and line

## Output Format

```markdown
## 🔍 Build Failure Analysis

**Task**: do_compile (linux-s32)
**Error Type**: Syntax Error
**Severity**: Critical

### Error Details
```
/path/to/file.c:142: error: expected ';' before '}'
```

### Root Cause
Missing semicolon after struct declaration.

### Suggested Fix
```diff
-  int value
+  int value;
}
```

### Verify
```bash
./build.py -m linux-s32
```
```

## Memory Update

After each analysis, update agent memory with:
- New error pattern (if novel)
- Successful fix (if resolved)
- Build time data
```

---

## 🚀 Phase 4: 병렬 빌드 (Agent Teams 스타일)

### 로컬 병렬 빌드

```bash
# 독립적인 모듈들 병렬 빌드 (웹 세션 활용)
& Build container-manager in mobis tier
& Build vam in mobis tier
& Build dpm in mobis tier

# 모니터링
/tasks
```

### 리모트 병렬 빌드

```markdown
---
name: parallel-build
description: Build multiple modules in parallel across remote servers
context: fork
---

# Parallel Build Orchestrator

## Servers
- ccu2-builder-1: mobis tier (container-manager, vam)
- ccu2-builder-2: mobis tier (dpm, ethnm)
- yocto-builder: full image

## Execution

1. SSH로 각 서버에 Claude Code 헤드리스 모드 실행
2. 각 빌드 독립적으로 진행
3. 결과 수집 및 종합

## Example

```bash
# 서버 1: container-manager + vam
ssh ccu2-builder-1 "claude -p 'Build container-manager and vam' --output-format json" &

# 서버 2: dpm + ethnm  
ssh ccu2-builder-2 "claude -p 'Build dpm and ethnm' --output-format json" &

# 결과 대기
wait
```
```

---

## 🚀 Phase 5: 리모트 빌드 통합

### remote-build 스킬 강화

```yaml
---
name: remote-build
description: Execute builds on remote servers with Claude Code
memory: project
context: fork
hooks:
  PostToolUse:
    - matcher: "Bash(ssh *)"
      hooks:
        - type: command
          command: "./scripts/parse-remote-result.sh"
---
```

### 리모트 빌드 워크플로우

```
┌─────────────┐        ┌─────────────────┐
│   Local     │  SSH   │  Build Server   │
│   Claude    │───────▶│  Claude Code    │
│   (Mother)  │        │  (Headless)     │
└─────────────┘        └─────────────────┘
      │                       │
      │   JSON Result         │
      │◀──────────────────────│
      │                       │
      ▼                       ▼
┌─────────────┐        ┌─────────────────┐
│  Parse &    │        │  Build & Fix    │
│  Report     │        │  (Autonomous)   │
└─────────────┘        └─────────────────┘
```

---

## 🚀 Phase 6: 통합 빌드 대시보드

### 상태 추적 스킬

```yaml
---
name: build-dashboard
description: Track and display build status across all servers
user-invocable: true
disable-model-invocation: true
---

# Build Dashboard

## Active Builds

!`find claudedocs/build-logs -name "*.status" -mmin -60 -exec cat {} \; 2>/dev/null | grep -E "^(STARTED|TYPE|TIER|STATUS)" | paste - - - - | column -t`

## Recent Completions (Last 24h)

!`find claudedocs/build-logs -name "*.status" -mtime -1 -exec grep -l "SUCCESS\|FAILED" {} \; | tail -10 | while read f; do echo "$(basename $f .status): $(grep STATUS $f)"; done`

## Server Status

!`for h in ccu2-builder yocto-builder test-runner; do echo -n "$h: "; ssh -o ConnectTimeout=2 $h "uptime 2>/dev/null | awk '{print \$3,\$4,\$5}'" || echo "OFFLINE"; done`
```

---

## 📋 마이그레이션 체크리스트

### Phase 1: 동적 컨텍스트 (1시간)
- [ ] snt-ccu2-yocto/SKILL.md에 `!command` 추가
- [ ] snt-ccu2-host/SKILL.md에 `!command` 추가
- [ ] 테스트: 스킬 로드시 현재 상태 표시 확인

### Phase 2: 메모리 (30분)
- [ ] 스킬 frontmatter에 `memory: project` 추가
- [ ] agent-memory 디렉토리 구조 설명 추가
- [ ] 초기 MEMORY.md 생성

### Phase 3: 분석 서브에이전트 (1시간)
- [ ] build-analyzer.md 개선
- [ ] 에러 패턴 매칭 로직 추가
- [ ] 메모리 업데이트 로직 추가

### Phase 4: 병렬 빌드 (2시간)
- [ ] parallel-build 스킬 생성
- [ ] 웹 세션 연동 (`&` prefix)
- [ ] 결과 취합 로직

### Phase 5: 리모트 빌드 (완료 ✅)
- [x] remote-build 스킬 생성
- [x] remote-claude.sh 스크립트
- [x] result-parser.py

### Phase 6: 대시보드 (30분)
- [ ] build-dashboard 스킬 생성
- [ ] 상태 파일 파싱 로직
- [ ] Discord 알림 연동

---

## 🔧 즉시 적용

### 1. SKILL.md 업데이트 (snt-ccu2-yocto)

이미 적용됨:
```yaml
memory: project
allowed-tools: Read, Grep, Glob, Bash(./build.py *)...
```

### 2. 동적 컨텍스트 추가

```bash
# SKILL.md 상단에 추가
## Current State
- Branch: !`git branch --show-current`
- Container: !`docker ps --filter "name=.*CCU" --format "{{.Names}}" | head -1`
```

### 3. 빌드 후 자동 분석 훅

`.claude/settings.local.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash(*build.py*)",
        "hooks": [
          {
            "type": "command",
            "command": "if grep -q 'ERROR\\|FAILED' /tmp/last-build.log 2>/dev/null; then echo 'ANALYZE_BUILD'; fi"
          }
        ]
      }
    ]
  }
}
```

---

*Build System Upgrade Plan v1.0 | 2026-02-06*
