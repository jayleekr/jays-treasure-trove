# Claude Code "Warm" 전략 적용 업그레이드 플랜

> 작성일: 2026-02-06
> 대상: jays-treasure-trove
> 목표: Claude Code 최신 Best Practice 적용

---

## 📌 현재 상태 vs 최신 Best Practice

| 기능 | 현재 | 최신 Claude Code | 개선 필요 |
|------|------|------------------|----------|
| Memory 계층 | 단일 CLAUDE.md | 4단계 계층 + @import | ⚠️ |
| 모듈러 규칙 | 없음 | `.claude/rules/*.md` + paths: | 🔴 |
| 스킬 실행 | 인라인 | `context: fork` 서브에이전트 | ⚠️ |
| 영속 메모리 | 없음 | `memory: project/user` | 🔴 |
| 동적 컨텍스트 | 없음 | `!command` 전처리 | 🔴 |
| 도구 제한 | 없음 | `allowed-tools:` | ⚠️ |
| Agent Teams | 없음 | 병렬 분석 지원 | 🔴 |

---

## 🎯 Phase 1: Memory 계층 구조화

### 1.1 CLAUDE.md Import 문법 적용

**현재**:
```markdown
# CCU-2.0 Project Knowledge Base
(모든 내용이 한 파일에)
```

**개선**:
```markdown
# CCU-2.0 Project Knowledge Base

## Project Context
- @README.md for project overview
- @BUILD_LOGIC.md for build system details
- @ISIR_METHODOLOGY.md for MISRA compliance

## Quick References
- @docs/BUILD_SYSTEM_ARCHITECTURE.md
- @docs/TESTING_GUIDE.md
```

### 1.2 로컬 설정 분리

**새 파일**: `CLAUDE.local.md`
```markdown
# Local Development Settings (gitignored)

## My Environment
- Docker container name: jaylee-ccu2-dev
- SSH target: 192.168.1.100
- Preferred build flags: -j 16 -p 16

## Personal Shortcuts
- 자주 쓰는 모듈: container-manager, vam
- 기본 Tier: mobis
```

---

## 🎯 Phase 2: 모듈러 Rules 추가

### 2.1 디렉토리 구조

```
.claude/
├── CLAUDE.md              # 메인 설정
├── CLAUDE.local.md        # 개인 설정 (gitignored)
├── rules/
│   ├── yocto.md           # *.bb, *.bbappend 작업시
│   ├── cpp.md             # C++ 코드 작업시
│   ├── python.md          # Python 코드 작업시
│   ├── security.md        # seccomp, container 작업시
│   └── testing.md         # test.py, test_*.py 작업시
├── agents/
│   └── code-reviewer.md   # 코드 리뷰 서브에이전트
└── skills/
    └── ...
```

### 2.2 Path-specific Rules 예시

**`rules/yocto.md`**:
```markdown
---
paths:
  - "**/*.bb"
  - "**/*.bbappend"
  - "**/*.bbclass"
  - "**/meta-*/recipes-*/**"
---

# Yocto Recipe Rules

## Naming Conventions
- Recipe files: `<package>_<version>.bb`
- Append files: `<package>_%.bbappend` or `<package>_<version>.bbappend`

## Required Variables
- LICENSE: 필수 (MIT, Apache-2.0, GPLv2, etc.)
- LIC_FILES_CHKSUM: 라이선스 파일 체크섬
- SRC_URI: 소스 위치 + 체크섬

## Common Mistakes to Avoid
- FILESEXTRAPATHS 앞에 := 사용 (not =)
- SRC_URI 체크섬 누락
- do_install 에서 ${D} 미사용
```

**`rules/security.md`**:
```markdown
---
paths:
  - "**/container-manager/**"
  - "**/seccomp/**"
  - "**/*seccomp*"
---

# Container Security Rules

## PID 1 Session Leader Issue
컨테이너에서 seccomp 테스트시:
- PID 1은 항상 session leader
- setsid() 호출시 EPERM 반환 (seccomp 아님!)
- **해결책**: fork()로 자식 프로세스에서 테스트

## Error Code 해석
- EPERM: 프로세스 상태 문제 (session leader)
- EACCES: seccomp 차단
- errno 즉시 확인 필수!
```

---

## 🎯 Phase 3: 스킬 현대화

### 3.1 Persistent Memory 추가

**현재**:
```yaml
---
name: snt-ccu2-yocto
description: ...
---
```

**개선**:
```yaml
---
name: snt-ccu2-yocto
description: Yocto/Bitbake CCU2 development pipeline
memory: project
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash(./build.py *), Bash(./run-dev-container.sh *)
---
```

### 3.2 동적 컨텍스트 주입

**새 기능**: `!command` 전처리로 실시간 상태 주입

```markdown
---
name: snt-ccu2-yocto
description: Yocto build pipeline
---

## Current Project State
- Repo info: !`cat info/repo_info.json 2>/dev/null || echo "Not initialized"`
- Build info: !`cat info/build_info.json 2>/dev/null || echo "No build yet"`
- Current branch: !`git branch --show-current`
- Modified files: !`git status --short | head -20`

## Recent Build Errors
!`tail -50 build.log 2>/dev/null | grep -E "ERROR|FAILED" | tail -10`
```

### 3.3 서브에이전트 모드

**Explore 에이전트로 분석**:
```yaml
---
name: yocto-analyzer
description: Analyze Yocto build errors and suggest fixes
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob, Bash(grep *), Bash(find *)
---

Analyze the Yocto build failure in $ARGUMENTS.

1. Read the build log
2. Identify the failing recipe
3. Check for common issues (missing deps, syntax errors)
4. Suggest fixes with specific file locations
```

---

## 🎯 Phase 4: Agent Teams 지원

### 4.1 MISRA 병렬 분석

```markdown
---
name: misra-team-analysis
description: Parallel MISRA analysis across multiple modules
disable-model-invocation: true
---

# MISRA Team Analysis

Create an agent team for parallel MISRA analysis:

1. **Security reviewer**: container-manager, seccomp modules
2. **Core reviewer**: vam, dpm, diagnostic-manager
3. **Library reviewer**: libsntxx, libsnt-vehicle
4. **Network reviewer**: ethnm, mqtt-middleware

Each teammate:
- Download violations: `./isir.py -m <module> -c MISRA -d`
- Categorize by severity
- Auto-suppress known patterns
- Report critical findings

Synthesize findings into unified report.
```

### 4.2 Code Review Team

```markdown
---
name: review-pr
description: Parallel PR review from multiple perspectives
context: fork
---

Create an agent team to review PR $ARGUMENTS:
- Security perspective (seccomp, container isolation)
- Performance perspective (memory, CPU usage)
- Maintainability perspective (code style, documentation)
- Testing perspective (coverage, edge cases)

Each reviewer works independently, then debates findings.
```

---

## 🎯 Phase 5: 디렉토리 구조 마이그레이션

### 현재 구조
```
~/.claude-config/projects/common/
├── CLAUDE.md
├── commands/
├── skills/
└── settings.local.json
```

### 목표 구조
```
~/.claude-config/projects/common/
├── CLAUDE.md                 # Main with @imports
├── CLAUDE.local.md           # Personal settings (gitignored)
├── rules/                    # NEW: Path-specific rules
│   ├── yocto.md
│   ├── cpp.md
│   ├── python.md
│   ├── security.md
│   └── testing.md
├── agents/                   # NEW: Custom subagents
│   ├── code-reviewer.md
│   ├── build-analyzer.md
│   └── misra-checker.md
├── agent-memory/             # NEW: Persistent agent memory
│   └── (auto-generated)
├── commands/                 # Existing (info/learning)
├── skills/                   # Existing (autonomous) + upgraded
└── settings.local.json
```

---

## 🧪 테스트 계획

### Test 1: Path-specific Rules
```bash
# Yocto 파일 열기
cd ~/CCU_GEN2.0_SONATUS.manifest/mobis/layers/meta-sonatus
claude

# 확인: yocto.md 규칙이 자동 로드되는지
/memory  # rules/yocto.md 표시되어야 함
```

### Test 2: Dynamic Context Injection
```bash
# 빌드 스킬 호출
/snt-ccu2-yocto:build -m container-manager

# 확인: 현재 repo 상태가 컨텍스트에 주입되는지
```

### Test 3: Persistent Memory
```bash
# 첫 세션에서 빌드
/snt-ccu2-yocto:build -m vam

# 새 세션 시작
claude

# 확인: 이전 빌드 히스토리 기억하는지
"지난번 빌드 어떻게 됐어?"
```

### Test 4: Agent Teams
```bash
# MISRA 팀 분석
/misra-team-analysis container-manager vam dpm

# 확인: 3개 에이전트가 병렬로 분석하는지
```

---

## 📅 마이그레이션 일정

| Phase | 작업 | 예상 시간 |
|-------|------|----------|
| 1 | Memory 계층화 | 30분 |
| 2 | Rules 추가 | 1시간 |
| 3 | 스킬 업그레이드 | 2시간 |
| 4 | Agent Teams | 1시간 |
| 5 | 테스트 & 검증 | 1시간 |

**총 예상 시간**: ~5시간

---

## 🔥 즉시 적용 가능한 Quick Wins

### 1. CLAUDE.local.md 추가 (5분)
```bash
cat > ~/.claude-config/projects/common/CLAUDE.local.md << 'EOF'
# Local Settings (gitignored)
- Preferred tier: mobis
- Default build jobs: 16
- SSH target: 192.168.1.100
EOF
echo "CLAUDE.local.md" >> ~/.claude-config/.gitignore
```

### 2. 간단한 Path Rule 추가 (10분)
```bash
mkdir -p ~/.claude-config/projects/common/rules
cat > ~/.claude-config/projects/common/rules/yocto.md << 'EOF'
---
paths:
  - "**/*.bb"
  - "**/*.bbappend"
---

# Yocto Recipe Rules
- Always include LICENSE and LIC_FILES_CHKSUM
- Use FILESEXTRAPATHS:prepend := (not =)
- Check SRC_URI checksums
EOF
```

### 3. 스킬에 memory 필드 추가 (5분)
각 스킬 SKILL.md frontmatter에:
```yaml
memory: project
```

---

*이 문서는 Claude Code 2026.2 기준 best practice를 반영합니다.*
