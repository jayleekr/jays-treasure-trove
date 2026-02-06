# Remote Agent Architecture Proposal

> 목표: 리모트 머신에서 Claude Code를 실행하여 빌드/테스트 수행
> 작성일: 2026-02-06

---

## 📌 요구사항

1. 로컬에서 리모트 머신에 빌드/테스트 요청
2. 리모트에서 **Claude Code가 직접 실행**되어 문제 해결
3. 결과를 로컬로 가져오기
4. 여러 리모트 머신에서 병렬 실행 가능

---

## 🏗️ Architecture Options

### Option 1: SSH + Claude Code CLI (Headless Mode)

```
┌─────────────┐     SSH      ┌─────────────────────┐
│  Local      │ ──────────►  │  Remote Machine     │
│  Orchestrator│              │  ┌─────────────────┐│
│             │◄───────────   │  │  Claude Code    ││
│             │   JSON Output │  │  (Headless)     ││
└─────────────┘               │  └─────────────────┘│
                              │  └──► Build/Test    │
                              └─────────────────────┘
```

**구현**:
```bash
# 리모트에서 Claude Code 실행
ssh build-server "cd /project && claude -p 'Build container-manager and fix any errors' \
  --allowedTools 'Bash,Read,Edit' \
  --output-format json \
  --max-turns 10"
```

**장점**:
- 간단한 구현
- 리모트에서 완전한 Claude Code 기능 사용
- 구조화된 JSON 출력

**단점**:
- 각 리모트에 Claude Code 설치 필요
- 인증 관리 복잡

---

### Option 2: Claude Code Web Sessions (추천 ⭐)

```
┌─────────────┐   --remote   ┌─────────────────────┐
│  Local      │ ──────────►  │  claude.ai Cloud    │
│  Terminal   │              │  ┌─────────────────┐│
│             │◄───────────   │  │  Claude Code    ││
│             │   Teleport    │  │  + GitHub Repo  ││
└─────────────┘               │  └─────────────────┘│
                              │  └──► Build/Test    │
                              └─────────────────────┘
```

**구현**:
```bash
# 로컬에서 웹 세션으로 빌드 요청
& cd /workspaces/ccu-2.0 && ./build.py -m container-manager && ./test.py

# 또는 CLI로
claude --remote "Build container-manager, run tests, fix any failures"

# 병렬 작업
& Fix test failures in container-manager
& Build and test vam module
& Run MISRA analysis on dpm
```

**장점**:
- 리모트 설치 불필요 (GitHub 연동만)
- 병렬 작업 자연스럽게 지원
- `/tasks`로 모니터링
- 완료시 PR 자동 생성

**단점**:
- GitHub 리포 필요
- 실제 빌드 머신이 아닌 Anthropic 클라우드에서 실행

---

### Option 3: OpenClaw Nodes (실제 빌드 머신용)

```
┌─────────────┐   nodes      ┌─────────────────────┐
│  OpenClaw   │ ──────────►  │  Build Server       │
│  (Mother)   │              │  ┌─────────────────┐│
│             │◄───────────   │  │  OpenClaw Node  ││
│             │   Results     │  └─────────────────┘│
└─────────────┘               │  └──► Real Build    │
                              └─────────────────────┘
```

**구현**:
```bash
# 빌드 서버에 OpenClaw 설치
openclaw node pair  # QR 코드 또는 토큰으로 페어링

# 로컬에서 리모트 빌드 요청
nodes(action="run", node="build-server", command=["./build.py", "-m", "container-manager"])
```

**장점**:
- 실제 빌드 머신 사용
- OpenClaw 생태계 활용
- 이미 설정된 환경 사용

**단점**:
- 빌드 서버에 Claude Code가 아닌 OpenClaw Node 실행
- 에러 자동 수정 어려움

---

### Option 4: Hybrid Architecture (가장 강력 🔥)

```
┌─────────────────────────────────────────────────────────┐
│                    LOCAL (Orchestrator)                  │
│  ┌─────────────┐                                        │
│  │  OpenClaw   │ ◄─── Discord/Telegram 알림             │
│  │  (Mother)   │                                        │
│  └──────┬──────┘                                        │
│         │                                                │
└─────────┼────────────────────────────────────────────────┘
          │
          ├──────────────┐
          ▼              ▼
┌─────────────────┐  ┌─────────────────┐
│  Build Server 1  │  │  Build Server 2  │
│  ┌─────────────┐ │  │  ┌─────────────┐ │
│  │ Claude Code │ │  │  │ Claude Code │ │
│  │ (Agent SDK) │ │  │  │ (Agent SDK) │ │
│  └─────────────┘ │  │  └─────────────┘ │
│  - CCU2 빌드     │  │  - Yocto 빌드    │
│  - Host 테스트   │  │  - 이미지 테스트  │
└─────────────────┘  └─────────────────┘
```

**구현 스택**:
1. **Local (OpenClaw/Mother)**: 오케스트레이션
2. **Remote (Claude Agent SDK)**: 각 빌드 서버에서 실행
3. **Communication**: SSH + JSON-RPC 또는 Message Queue

---

## 🛠️ 권장 구현: Option 4 Hybrid

### Phase 1: Remote Claude Code CLI Wrapper

**스킬 구조**:
```
skills/
└── remote-build/
    ├── SKILL.md
    ├── scripts/
    │   ├── remote-claude.sh      # SSH + Claude 래퍼
    │   ├── remote-build.py       # 빌드 오케스트레이터
    │   └── result-parser.py      # JSON 결과 파서
    └── references/
        ├── build-servers.md      # 빌드 서버 목록
        └── error-patterns.md     # 에러 패턴 매핑
```

**remote-claude.sh**:
```bash
#!/bin/bash
# 리모트에서 Claude Code 실행

REMOTE_HOST=$1
PROMPT=$2
WORKDIR=${3:-"/workspace"}

ssh -o ConnectTimeout=10 "$REMOTE_HOST" << EOF
cd "$WORKDIR"
claude -p "$PROMPT" \
  --allowedTools "Bash,Read,Edit,Grep,Glob" \
  --output-format json \
  --max-turns 15 \
  --dangerously-skip-permissions
EOF
```

**SKILL.md**:
```yaml
---
name: remote-build
description: Execute builds and tests on remote servers with Claude Code
memory: project
context: fork
agent: general-purpose
allowed-tools: Bash(ssh *), Bash(scp *), Read, Write
---

# Remote Build Agent

## Available Servers
- `ccu2-builder`: CCU2 Host 빌드 서버
- `yocto-builder`: Yocto 이미지 빌드 서버
- `test-runner`: 테스트 실행 서버

## Workflow

1. **Request Build**
   ```
   /remote-build container-manager on ccu2-builder
   ```

2. **Execute Remote Claude**
   - SSH로 빌드 서버 접속
   - Claude Code 실행 (headless)
   - 빌드/테스트 수행
   - 에러 발생시 Claude가 자동 수정

3. **Get Results**
   - JSON 출력 파싱
   - 성공/실패 리포트
   - 로그 저장

## Example

!`ssh ccu2-builder "cd /workspace/ccu-2.0 && git status --short | head -5"`
```

### Phase 2: Agent SDK Integration

**Python Agent SDK로 더 정교한 제어**:

```python
# remote_agent.py
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions
import asyncio
import subprocess

async def run_remote_build(host: str, project: str, task: str):
    """리모트에서 Claude Agent SDK 실행"""
    
    # SSH로 Agent SDK 스크립트 실행
    result = subprocess.run([
        "ssh", host, f"""
        cd /workspace/{project}
        python3 << 'AGENT'
import anyio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    options = ClaudeAgentOptions(
        allowed_tools=["Read", "Write", "Bash", "Edit"],
        permission_mode='acceptEdits',
        max_turns=20
    )
    
    result = []
    async for message in query(prompt="{task}", options=options):
        result.append(str(message))
    
    print("RESULT:", "\\n".join(result))

anyio.run(main)
AGENT
        """
    ], capture_output=True, text=True)
    
    return result.stdout

# 병렬 실행
async def parallel_builds():
    tasks = [
        run_remote_build("ccu2-builder", "ccu-2.0", "Build container-manager"),
        run_remote_build("yocto-builder", "CCU_GEN2.0_SONATUS.manifest", "Build mobis image"),
        run_remote_build("test-runner", "snt-integration-tests", "Run container tests"),
    ]
    results = await asyncio.gather(*tasks)
    return results
```

### Phase 3: OpenClaw Integration

**Mother가 리모트 Claude 세션들을 관리**:

```python
# OpenClaw에서 리모트 빌드 관리

# 1. 서브에이전트로 리모트 빌드 spawn
sessions_spawn(
    task="""
    SSH로 ccu2-builder에 접속해서:
    1. cd /workspace/ccu-2.0
    2. Claude Code 실행: claude -p "Build and test container-manager"
    3. 결과 JSON 파싱
    4. 성공/실패 리포트
    """,
    label="remote-build-cm"
)

# 2. 결과 모니터링
sessions_list(kinds=["spawn"], activeMinutes=30)

# 3. Discord/Telegram으로 결과 알림
message(action="send", channel="discord", target="jaylee_59200", 
        message="✅ container-manager 빌드 완료!")
```

---

## 📋 Prerequisites

### 빌드 서버 설정

1. **Claude Code 설치**:
```bash
curl -fsSL https://claude.ai/install.sh | bash
claude auth login  # API key 설정
```

2. **SSH 키 설정**:
```bash
ssh-copy-id build-user@ccu2-builder
ssh-copy-id build-user@yocto-builder
```

3. **환경 변수**:
```bash
# ~/.bashrc on remote
export ANTHROPIC_API_KEY="sk-..."
export CLAUDE_CODE_ACCEPT_EDITS=1
```

4. **Claude Agent SDK 설치** (optional):
```bash
pip install claude-agent-sdk
```

---

## 🧪 Quick Test

```bash
# 1. SSH로 리모트 Claude Code 테스트
ssh ccu2-builder "claude -p 'What is 2+2?' --output-format json"

# 2. 실제 빌드 테스트
ssh ccu2-builder "cd /workspace/ccu-2.0 && claude -p 'Run ./build.py --help and explain the options' --output-format json"
```

---

## 🔮 Future: Agent Teams on Remote Machines

```
┌─────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR                          │
│                    (Agent Team Lead)                     │
└───────────────────────────┬─────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  CCU2 Builder │   │  Yocto Builder│   │  Test Runner  │
│  (Teammate)   │   │  (Teammate)   │   │  (Teammate)   │
│               │   │               │   │               │
│  - Build      │   │  - Build      │   │  - Run tests  │
│  - Fix errors │   │  - Generate   │   │  - Report     │
│  - Push       │   │    image      │   │    results    │
└───────────────┘   └───────────────┘   └───────────────┘
```

이건 Claude Code의 Agent Teams가 분산 환경을 지원하게 되면 가능할 예정.

---

*작성: Mother | 2026-02-06*
