---
name: build-orchestrator
description: Orchestrate builds across multiple remote servers. Manage dependencies, monitor status, collect results, and alert on failures.
memory: project
context: fork
allowed-tools: Bash(ssh *), Bash(scp *), Read, Write, Grep
disable-model-invocation: false
---

# Build Orchestrator

여러 리모트 빌드 서버를 조율하는 오케스트레이터.

## 🖥️ Server Registry

| Alias | Host | Purpose | Build Type |
|-------|------|---------|------------|
| `yocto` | yocto-builder | Yocto 이미지 빌드 | bitbake (자체 병렬) |
| `host` | ccu2-builder | CCU2 Host 빌드 | build.py |
| `test` | test-runner | 통합 테스트 | pytest |

## 📊 Current Status

**Server Connectivity**:
!`for h in yocto-builder ccu2-builder test-runner; do echo -n "$h: "; ssh -o ConnectTimeout=2 -o BatchMode=yes $h "echo OK" 2>/dev/null || echo "OFFLINE"; done`

**Active Jobs**:
!`for h in yocto-builder ccu2-builder test-runner; do
  jobs=$(ssh -o ConnectTimeout=2 $h "pgrep -f 'bitbake|build.py|pytest' | wc -l" 2>/dev/null)
  [ "$jobs" != "" ] && [ "$jobs" != "0" ] && echo "$h: $jobs processes"
done || echo "No active jobs"`

## 🔧 Usage

### 단일 서버 빌드
```
/build-orchestrator yocto linux-s32
/build-orchestrator host container-manager
/build-orchestrator test container-manager
```

### 파이프라인 (의존성 관리)
```
/build-orchestrator pipeline:
  1. yocto: build linux-s32
  2. host: build container-manager (after 1)
  3. test: run tests (after 2)
```

### 병렬 빌드 (독립적)
```
/build-orchestrator parallel:
  - yocto: build linux-s32
  - host: build vam
  - host: build dpm
```

## 🔄 Workflow

### 1. Parse Request

사용자 요청에서 추출:
- **Servers**: 사용할 서버들
- **Tasks**: 각 서버에서 실행할 작업
- **Dependencies**: 작업 간 의존성
- **Mode**: sequential | parallel | pipeline

### 2. Start Remote Jobs

각 서버에 SSH로 작업 시작 (백그라운드):
```bash
# nohup으로 SSH 끊겨도 계속 실행
ssh $SERVER "nohup $COMMAND > /tmp/build-$TIMESTAMP.log 2>&1 &"

# 또는 tmux 세션으로
ssh $SERVER "tmux new -d -s build-$TIMESTAMP '$COMMAND'"
```

### 3. Monitor Progress

주기적으로 상태 확인:
```bash
# 프로세스 확인
ssh $SERVER "pgrep -f '$PATTERN'"

# 로그 tail
ssh $SERVER "tail -5 /tmp/build-$TIMESTAMP.log"

# 에러 체크
ssh $SERVER "grep -E 'ERROR|FAILED' /tmp/build-$TIMESTAMP.log | tail -3"
```

### 4. Handle Dependencies

```python
# 의존성 체크
while not all_done:
    for task in pending_tasks:
        if task.dependencies_complete():
            start_task(task)
    sleep(30)
    update_status()
```

### 5. Collect Results & Alert

```bash
# 결과 수집
scp $SERVER:/tmp/build-$TIMESTAMP.log ./results/

# Discord 알림 (OpenClaw 통해)
# message(action="send", target="jaylee_59200", message="✅ Build complete!")
```

## 📋 Pipeline Definition

### YAML 형식
```yaml
pipeline:
  name: ccu2-full-build
  
  stages:
    - name: yocto-image
      server: yocto-builder
      command: "./build.py -ncpb -j 16 -p 16"
      workdir: /workspace/CCU_GEN2.0_SONATUS.manifest/mobis
      timeout: 3h
      
    - name: host-build
      server: ccu2-builder
      command: "./build.py --module container-manager"
      workdir: /workspace/ccu-2.0
      depends_on: []  # 독립적
      timeout: 30m
      
    - name: integration-test
      server: test-runner
      command: "pytest -v test_container.py"
      workdir: /workspace/snt-integration-tests
      depends_on: [host-build]  # host-build 완료 후 실행
      timeout: 1h
      
  on_failure:
    - notify: discord
    - retry: 1
    
  on_success:
    - notify: discord
    - archive: true
```

### 실행
```
/build-orchestrator run pipeline.yaml
```

## 🔔 Notification Integration

### Discord (via OpenClaw)
```python
# 빌드 시작
message(action="send", channel="discord", target="jaylee_59200",
        message="🚀 Pipeline started: ccu2-full-build")

# 단계 완료
message(action="send", channel="discord", target="jaylee_59200",
        message="✅ Stage 1/3 complete: yocto-image (45min)")

# 실패
message(action="send", channel="discord", target="jaylee_59200",
        message="❌ Stage 2 FAILED: host-build\nError: CMake error in container-manager")

# 전체 완료
message(action="send", channel="discord", target="jaylee_59200",
        message="🎉 Pipeline complete: ccu2-full-build (2h 15min)")
```

## 📊 Status Dashboard

실시간 상태 확인:
```
/build-orchestrator status

┌─────────────────────────────────────────────────────┐
│  CCU2 Full Build Pipeline                           │
├─────────────────────────────────────────────────────┤
│  Stage 1: yocto-image    [████████░░] 80%  45min   │
│  Stage 2: host-build     [waiting]                  │
│  Stage 3: integration    [waiting]                  │
├─────────────────────────────────────────────────────┤
│  Errors: 0  Warnings: 12  ETA: 1h 30min            │
└─────────────────────────────────────────────────────┘
```

## 🛠️ Scripts

### orchestrator.py
```python
#!/usr/bin/env python3
"""Build Orchestrator - Manage builds across remote servers"""

import subprocess
import json
import time
from dataclasses import dataclass
from typing import List, Dict, Optional

@dataclass
class Task:
    name: str
    server: str
    command: str
    workdir: str
    depends_on: List[str]
    timeout: int
    status: str = "pending"
    pid: Optional[int] = None
    log_file: Optional[str] = None

class Orchestrator:
    def __init__(self, pipeline_file: str):
        self.tasks: Dict[str, Task] = {}
        self.load_pipeline(pipeline_file)
    
    def load_pipeline(self, path: str):
        """Load pipeline from YAML"""
        pass
    
    def start_task(self, task: Task):
        """Start task on remote server"""
        timestamp = int(time.time())
        log_file = f"/tmp/build-{task.name}-{timestamp}.log"
        
        cmd = f"ssh {task.server} 'cd {task.workdir} && nohup {task.command} > {log_file} 2>&1 & echo $!'"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        task.pid = int(result.stdout.strip())
        task.log_file = log_file
        task.status = "running"
    
    def check_status(self, task: Task) -> str:
        """Check if task is still running"""
        cmd = f"ssh {task.server} 'ps -p {task.pid} > /dev/null 2>&1 && echo running || echo done'"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip()
    
    def get_result(self, task: Task) -> str:
        """Get task result (success/failed)"""
        cmd = f"ssh {task.server} 'tail -1 {task.log_file} | grep -q SUCCESS && echo success || echo failed'"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip()
    
    def run(self):
        """Run the pipeline"""
        while not all(t.status == "done" for t in self.tasks.values()):
            for task in self.tasks.values():
                if task.status == "pending":
                    deps_done = all(
                        self.tasks[d].status == "done" 
                        for d in task.depends_on
                    )
                    if deps_done:
                        self.start_task(task)
                
                elif task.status == "running":
                    if self.check_status(task) == "done":
                        task.status = "done"
                        result = self.get_result(task)
                        print(f"Task {task.name}: {result}")
            
            time.sleep(30)
```

## ⚠️ Error Handling

| 상황 | 처리 |
|------|------|
| SSH 연결 실패 | 3회 재시도 후 알림 |
| 빌드 실패 | 로그 수집 → 알림 → 선택적 재시도 |
| 타임아웃 | 프로세스 kill → 알림 |
| 서버 다운 | 대체 서버 사용 (설정된 경우) |

## 🔧 Configuration

`~/.build-orchestrator/config.yaml`:
```yaml
servers:
  yocto-builder:
    host: 192.168.1.101
    user: build
    workdir: /workspace/CCU_GEN2.0_SONATUS.manifest
    
  ccu2-builder:
    host: 192.168.1.102
    user: build
    workdir: /workspace/ccu-2.0
    
  test-runner:
    host: 192.168.1.103
    user: test
    workdir: /workspace/snt-integration-tests

notifications:
  discord:
    enabled: true
    target: jaylee_59200
    
  telegram:
    enabled: true
    chat_id: 514675395

defaults:
  timeout: 2h
  retry: 1
  parallel_limit: 3
```

---

*Build Orchestrator v1.0 | 리모트 서버 오케스트레이션*
