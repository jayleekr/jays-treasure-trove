---
name: snt-ccu2-yocto:build
description: "Smart build orchestration with automatic scope detection. Analyzes changes to determine build scope (module/full) and executes bitbake builds inside Docker container."
---

# /snt-ccu2-yocto:build - Smart Build Orchestrator

CCU_GEN2.0_SONATUS 프로젝트를 위한 스마트 빌드 오케스트레이션.

## Usage

```
/snt-ccu2-yocto:build [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--module <name>` | 특정 모듈만 빌드 |
| `--snt` | Sonatus 모듈만 빌드 (--snt, 이미지 아님) |
| `--full` | 전체 이미지 빌드 (--snt 없이 풀빌드) |
| `--clean` | cleansstate 후 빌드 |
| `--dry-run` | 명령어만 출력, 실행하지 않음 |
| `--release` | Release 빌드 (-r 옵션) **[기본값]** |
| `--no-release` | Debug 빌드 (-r 없이) |
| `--mp` | MP Release 빌드 |

## Examples

```bash
# 자동 범위 결정 빌드 (기본: release)
/snt-ccu2-yocto:build

# 특정 모듈만 빌드
/snt-ccu2-yocto:build --module linux-s32

# 클린 빌드
/snt-ccu2-yocto:build --module systemd --clean

# SNT 모듈만 빌드 (이미지 제외)
/snt-ccu2-yocto:build --snt

# 전체 이미지 빌드 (release 기본)
/snt-ccu2-yocto:build --full

# 전체 이미지 Debug 빌드
/snt-ccu2-yocto:build --full --no-release

# MP Production 빌드
/snt-ccu2-yocto:build --full --mp
```

## Behavioral Flow

### 1. Change Detection

```
변경 파일 분석 (git diff)
├── Recipe 변경 (.bb, .bbappend, .inc)
│   └── dependency.json으로 영향 모듈 파악
├── Kernel Config 변경 (.config)
│   └── linux-s32 모듈 영향
├── Code 변경 (sources/*)
│   └── Path 매핑으로 모듈 식별
└── Config 변경 (build_info.json, local.conf)
    └── 전체 빌드 또는 영향 분석
```

### 2. Build Scope Decision

```
Build Scope 결정 로직:
├── 전체 빌드 필요:
│   ├── build_info.json 변경
│   ├── 기본 레시피 변경 (linux-s32, u-boot, fsl-image-*)
│   ├── 영향 모듈 > 5개
│   └── --full 옵션 지정
├── SNT 빌드:
│   ├── Sonatus 모듈만 변경
│   └── --snt 옵션 지정
└── 모듈 빌드:
    ├── 특정 모듈만 영향
    └── --module 옵션 지정
```

### 3. Docker Container Execution

빌드는 반드시 Docker 컨테이너 내에서 실행됨.

**Container Entry:**
```bash
# 프로젝트 루트에서
./run-dev-container.sh
```

**Build Execution (inside container):**
```bash
cd mobis/
./build.py [options]
```

## Build Commands Reference

### Module Build

```bash
# 단일 모듈
./build.py -m linux-s32

# 클린 후 빌드
./build.py -m linux-s32 -c cleansstate
./build.py -m linux-s32

# 다중 모듈 (순차)
./build.py -m linux-s32 && ./build.py -m systemd
```

### SNT Build

```bash
# 모든 Sonatus 모듈
./build.py --snt
```

### Full Image Build

> **Note:** 전체 이미지 빌드는 `--snt` 없이 실행. `--snt`는 모듈 빌드용.

```bash
# Release 빌드 (기본, 권장)
./build.py -ncpb -j 16 -p 16 -r

# Debug 빌드 (rm_work 비활성화)
./build.py -ncpb -j 16 -p 16

# MP Release 빌드 (Production)
./build.py --mp -j 16 -p 16
```

### Cache Management

```bash
# 특정 모듈 캐시 클린
./build.py -m linux-s32 -c cleansstate
./build.py -m systemd -c cleansstate

# 전체 캐시 클린
./build.py -cc
```

## Build Scope Detection Algorithm

```python
def determine_build_scope(changed_files):
    # 전체 빌드 트리거
    full_image_triggers = [
        'build_info.json',
        'linux-s32',
        'u-boot',
        'fsl-image-ccu2',
        'fsl-image-base',
        'local.conf',
    ]

    if any(trigger in file for file in changed_files
           for trigger in full_image_triggers):
        return "FULL_IMAGE"

    # 영향 모듈 분석
    affected_modules = analyze_dependencies(changed_files)

    if len(affected_modules) > 5:
        return "FULL_IMAGE"

    if all(is_sonatus_module(m) for m in affected_modules):
        return "SNT"

    return f"MODULES: {affected_modules}"
```

## Output

```
## Build Execution Summary

### Build Scope: Module (linux-s32, systemd)

### Commands Executed:
1. ./run-dev-container.sh
2. cd mobis/
3. ./build.py -m linux-s32 -c cleansstate
4. ./build.py -m systemd -c cleansstate
5. ./build.py -ncpb -j 16 -p 16

### Build Time: 45 minutes

### Artifacts:
- mobis/deploy/fsl-image-ccu2-mobisccu2.tar.gz
- mobis/deploy/fsl-image-ccu2-mobisccu2.wic.xz

### Next Steps:
테스트를 실행하려면:
/snt-ccu2-yocto:test
```

## Boundaries

**Will:**
- 변경 사항 분석 및 빌드 범위 결정
- Docker 컨테이너 진입 안내
- 적절한 빌드 명령어 생성 및 실행
- 빌드 결과 및 아티팩트 확인

**Will Not:**
- 컨테이너 외부에서 빌드 실행 시도
- 프로덕션 환경 직접 배포
- 빌드 시스템 설정 변경

## Script Integration

This command uses a bundled script for automated build execution:

**Script Location:** `.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh`

### Script Usage

```bash
# Auto-detect build scope (release by default)
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --scope auto

# Specific modules with clean
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --module linux-s32,systemd --clean

# Full image release build (기본)
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --scope full

# Full image debug build
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --scope full --no-release

# Dry run (show commands without executing)
.claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --scope auto --dry-run
```

### Script Features

1. **Auto Container Detection**: Automatically handles Docker container execution
2. **Change Analysis**: Analyzes git diff to determine affected modules
3. **Smart Scope Selection**: Chooses module/SNT/full build based on changes
4. **Clean Build Support**: Optional cleansstate before build
5. **Fetch Retry**: Auto-retry on fetch failures (DNS issues) - up to 3 retries
6. **Structured Output**: Returns summary for pipeline integration

### Execution Pattern

Claude should execute builds using:
```python
# In pipeline context
Bash(".claude/commands/snt-ccu2-yocto/scripts/yocto-build.sh --scope auto")
```

## Error Handling

### Auto-Retry for Fetch Failures

Fetch 실패 시 (DNS/네트워크 이슈) 자동으로 최대 3회 재시도:

```
[WARNING] Fetch failed (possibly DNS issue). Retrying... (1/3)
[WARNING] Fetch failed (possibly DNS issue). Retrying... (2/3)
[SUCCESS] Build completed
```

감지되는 fetch 오류 패턴:
- `do_fetch` 태스크 실패
- `Fetcher failure`
- `Unable to fetch`
- `Could not resolve host` (DNS)
- `Connection timed out`
- `Network is unreachable`

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Please run within docker" | 컨테이너 외부 실행 | `./run-dev-container.sh` 실행 |
| Fetch failed (after retries) | 지속적 네트워크 이슈 | VPN/DNS 확인, 수동 재시도 |
| Recipe parsing failed | bbappend 문법 오류 | 레시피 문법 확인 |
| Dependency not found | 의존성 누락 | dependency.json 확인 |
| Build failed | 컴파일 에러 | 에러 로그 분석, cleansstate 시도 |
