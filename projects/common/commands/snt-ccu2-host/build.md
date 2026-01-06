---
name: snt-ccu2-host:build
description: "Smart host build orchestration with automatic scope detection. Analyzes changes to determine build scope and executes build.py with optimal configuration."
---

# /snt-ccu2-host:build - Smart Build Orchestrator

CCU-2.0 Host 빌드를 위한 스마트 빌드 오케스트레이션.

## Usage

```
/snt-ccu2-host:build [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--module <name>` | 특정 모듈만 빌드 |
| `--clean` | 클린 빌드 (cleansstate 후 빌드) |
| `--tests` | 테스트 포함 빌드 |
| `--coverage` | 코드 커버리지 생성 |
| `--release` | Release 빌드 |
| `--cross-compile` | 크로스 컴파일 모드 |
| `--ecu <type>` | ECU 타겟 (CCU2, CCU2_LITE, BCU) |
| `--dry-run` | 명령어만 출력, 실행하지 않음 |
| `--verbose` | 상세 출력 |

## Examples

```bash
# 자동 범위 결정 빌드
/snt-ccu2-host:build

# 특정 모듈 빌드
/snt-ccu2-host:build --module container-manager

# 클린 빌드
/snt-ccu2-host:build --module vam --clean

# 테스트 포함 빌드
/snt-ccu2-host:build --module container-manager --tests

# Release 빌드
/snt-ccu2-host:build --module container-manager --release

# 크로스 컴파일
/snt-ccu2-host:build --module vam --cross-compile --ecu CCU2
```

## Behavioral Flow

### 1. Change Detection (자동 범위 결정)

변경 파일 분석으로 빌드 범위 자동 결정:

```
변경 파일 분석 (git diff)
├── Source 변경 (*.cxx, *.cpp)
│   └── 해당 모듈 빌드
├── Header 변경 (*.hxx, *.hpp, *.h)
│   └── 의존 모듈 포함 빌드
├── CMakeLists.txt 변경
│   └── 클린 빌드 권장
├── Config 변경 (*.json, *.xml)
│   └── 해당 모듈 빌드
└── 변경 없음
    └── 마지막 빌드 컴포넌트 또는 사용자 선택
```

### 2. Module Detection

현재 디렉토리 또는 변경 파일에서 모듈 자동 감지:

```python
# 모듈 매핑
module_paths = {
    'container-manager': 'container-manager/',
    'container-app': 'container-app/',
    'vam': 'vam/',
    'dpm': 'dpm/',
    'diagnostic-manager': 'diagnostic-manager/',
    'libsntxx': 'libsntxx/',
    'libsntlogging': 'libsntlogging/',
    'libsnt_vehicle': 'libsnt_vehicle/',
    'ethnm': 'ethnm/',
    'soa': 'soa/',
    'seccommon': 'seccommon/',
    'rta': 'rta/',
}
```

### 3. Build Execution

```bash
# 프로젝트 루트에서
./build.py --module <component> [options]
```

## Build Commands Reference

### Module Build

```bash
# 단일 모듈 (Debug)
./build.py --module container-manager

# 단일 모듈 (Release)
./build.py --module container-manager --build-type Release

# 클린 후 빌드
./build.py --module container-manager --clean
```

### Test Build

```bash
# 테스트 빌드 및 실행
./build.py --module container-manager --tests

# 테스트 빌드만 (실행 안함)
./build.py --module container-manager --tests-build-only

# 커버리지 포함
./build.py --module container-manager --tests --coverage
```

### Cross-Compile Build

```bash
# CCU2 타겟
./build.py --module container-manager --cross-compile --ecu CCU2

# CCU2_LITE 타겟
./build.py --module container-manager --cross-compile --ecu CCU2_LITE

# BCU 타겟
./build.py --module diagnostic-manager --cross-compile --ecu BCU
```

### Variant Build

```bash
# MOBIS Tier
./build.py --module vam --tier MOBIS

# 특정 CAN DB 버전
./build.py --module vam --can-db-version 252Q

# AUTOSAR 플래그 활성화
./build.py --module container-manager --autosar --dlt
```

### Quality Checks

```bash
# 코드 포맷팅 체크
./build.py --module container-manager --clang-format

# 포맷팅 자동 적용
./build.py --module container-manager --clang-format-apply

# PR 검증
./build.py --module container-manager --pr-check
```

## Available Modules

**Core Infrastructure**:
- `container-manager` - Docker 컨테이너 오케스트레이션
- `container-app` - 컨테이너화된 애플리케이션
- `vam` - Vehicle Application Manager
- `dpm` - Data Path Manager

**Libraries**:
- `libsntxx` - C++ 유틸리티
- `libsntlogging` - 로깅 프레임워크
- `libsnt_vehicle` - 차량 인터페이스
- `libsnt_cantp`, `libsnt_doip` - 프로토콜 라이브러리

**Managers & Services**:
- `diagnostic-manager` - 차량 진단
- `ethnm` - Ethernet Network Management
- `seccommon` - 보안 공통 라이브러리
- `soa` - Service-Oriented Architecture
- `rta` - Runtime Aggregation

## Build Options

### Build Types (--build-type)
| Type | Description |
|------|-------------|
| `Debug` | 디버그 심볼, 최적화 없음 (기본값) |
| `Release` | 최적화, 디버그 심볼 없음 |
| `RelWithDebInfo` | 최적화 + 디버그 심볼 |

### Compilers (--compiler)
| Compiler | Description |
|----------|-------------|
| `CLANG` | clang-15/clang++-15 (기본값) |
| `GCC_10` | GCC 10.x |
| `GCC_11` | GCC 11.x |

### Vehicle Variants

**Tier** (--tier):
- `LGE` (기본값)
- `MOBIS`

**CAN DB Version** (--can-db-version):
- `253Q` (기본값, 최신)
- `252Q`, `251Q` (이전 버전)

**Service Interface** (--service-if-version):
- `0.25.1` (기본값, 최신)
- `0.24.2`, `0.23.1` (이전 버전)

**ECU Type** (--ecu):
- `CCU2` (기본값)
- `CCU2_LITE`
- `BCU`

### Sanitizers (Debug 모드)
```bash
--asan    # Address Sanitizer
--tsan    # Thread Sanitizer
--ubsan   # Undefined Behavior Sanitizer
--lsan    # Leak Sanitizer
```

## Output

### 성공시 출력 예시
```
## Build Execution Summary

### Module: container-manager
### Build Type: Debug

### Command Executed:
./build.py --module container-manager --tests

### Build Time: 2m 34s

### Results:
- Compilation: SUCCESS
- Tests: 42 passed, 0 failed
- Coverage: 87.3%

### Artifacts:
- build/Debug/container-manager/libcontainer-manager.a
- build/Debug/container-manager/snt_cm

### Next Steps:
- 테스트 실행: /snt-ccu2-host:build --module container-manager --tests
- PR 검증: /snt-ccu2-host:build --module container-manager --pr-check
```

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Please run within docker" | Docker 환경 필요 | `./run-dev-container.sh` 실행 |
| CMake Error | CMake 설정 오류 | 캐시 삭제 후 재시도 |
| Compile Error | 문법/타입 에러 | 에러 위치 확인 및 수정 |
| Link Error | 의존성 누락 | 의존성 먼저 빌드 |
| Test Failed | 테스트 실패 | 실패 테스트 분석 |

### Error Recovery

**CMake 에러 복구:**
```bash
# CMake 캐시 삭제
rm -rf build/Debug/<component>/CMakeCache.txt
./build.py --module <component>
```

**의존성 에러 복구:**
```bash
# 의존성 먼저 빌드
./build.py --module libsntxx
./build.py --module libsntlogging
./build.py --module <component>
```

**전체 클린 빌드:**
```bash
rm -rf build/
./build.py --module <component>
```

## Script Integration

자동화된 빌드 실행을 위한 스크립트:

**Script Location:** `.claude/commands/snt-ccu2-host/scripts/host-build.sh`

### Script Usage

```bash
# 자동 범위 감지
.claude/commands/snt-ccu2-host/scripts/host-build.sh --scope auto

# 특정 모듈 클린 빌드
.claude/commands/snt-ccu2-host/scripts/host-build.sh --module container-manager --clean

# 테스트 포함 빌드
.claude/commands/snt-ccu2-host/scripts/host-build.sh --module vam --tests

# Dry run
.claude/commands/snt-ccu2-host/scripts/host-build.sh --module container-manager --dry-run
```

### Script Features

1. **Auto Module Detection**: git diff에서 변경된 모듈 자동 감지
2. **Dependency Analysis**: 역의존성 분석으로 빌드 순서 결정
3. **Error Recovery**: 빌드 실패시 자동 복구 시도
4. **Structured Output**: 파이프라인 연동을 위한 구조화된 출력

## Boundaries

**Will:**
- 변경 사항 분석 및 빌드 범위 결정
- build.py 명령 구성 및 실행
- 빌드 결과 파싱 및 보고
- 에러 분석 및 복구 제안

**Will Not:**
- 소스 코드 직접 수정
- 프로덕션 환경 배포
- 빌드 시스템 설정 변경
- Git 커밋/푸시 자동 실행

## Integration with snt-ccu2-host Pipeline

이 명령은 `/snt-ccu2-host` 파이프라인의 Build Mode에서 사용됩니다:

```
/snt-ccu2-host (Complete Mode)
├── Analysis Mode → 요구사항 분석
├── Implementation Mode → 코드 변경
├── Build Mode → /snt-ccu2-host:build 호출
└── Test Mode → 테스트 실행
```

### 연동 예시

```bash
# 티켓 분석 후 구현, 빌드까지 자동화
/snt-ccu2-host CCU2-12345

# Implementation 완료 후 빌드만 실행
/snt-ccu2-host:build --module container-manager --tests
```

## Automatic Code Formatting (Claude Hook)

빌드 완료 후 코드 포맷팅이 자동으로 적용됩니다.

### Hook 동작

Claude Code의 PostToolUse hook이 다음 상황에서 자동 실행:
- **Edit/Write 작업 후**: 파일 수정 후 포맷팅 적용
- **빌드 완료 후**: `build.py` 실행 후 포맷팅 적용

### 자동 실행 명령

```bash
./run-dev-container.sh -x 'python build.py -fac'
```

- `-f`: format (clang-format)
- `-a`: apply (변경사항 적용)
- `-c`: changed files only (변경된 파일만)

### Hook 설정 위치

`.claude/settings.local.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "command": "./run-dev-container.sh -x 'python build.py -fac'" }]
      },
      {
        "matcher": "Bash(./run-dev-container.sh*build.py*)",
        "hooks": [{ "command": "./run-dev-container.sh -x 'python build.py -fac'" }]
      }
    ]
  }
}
```

### 특징

- **수동 실행 불필요**: hook이 자동 처리
- **Docker 컨테이너 내 실행**: 일관된 clang-format 버전 사용
- **변경 파일만 포맷팅**: `-c` 옵션으로 효율적 처리
