# Build Reference - 빌드 시스템 패턴

## build.py 사용법

### 기본 명령어
```bash
./build.py --module <component> [options]
```

### 주요 옵션

#### Build Types (--build-type)
| Type | Description |
|------|-------------|
| `Debug` | 디버그 심볼, 최적화 없음 (기본값) |
| `Release` | 최적화, 디버그 심볼 없음 |
| `RelWithDebInfo` | 최적화 + 디버그 심볼 |

#### Compilers (--compiler)
| Compiler | Description |
|----------|-------------|
| `CLANG` | clang-15/clang++-15 (기본값) |
| `GCC_10` | GCC 10.x |
| `GCC_11` | GCC 11.x |

### 사용 가능한 모듈

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

## 일반 빌드 패턴

### 기본 개발 빌드
```bash
# Debug 빌드
./build.py --module container-manager

# Release 빌드
./build.py --module container-manager --build-type Release
```

### 클린 빌드
```bash
# 클린 후 빌드
./build.py --module container-manager --clean

# 전체 클린 (모든 빌드 아티팩트 삭제)
rm -rf build/
./build.py --module container-manager
```

### 테스트 포함 빌드
```bash
# 빌드 + 테스트 실행
./build.py --module container-manager --tests

# 빌드만, 테스트 실행 안함
./build.py --module container-manager --tests-build-only

# 커버리지 포함
./build.py --module container-manager --tests --coverage
```

### Cross-Compile
```bash
# CCU2 타겟
./build.py --module container-manager --cross-compile --ecu CCU2

# CCU2_LITE 타겟
./build.py --module container-manager --cross-compile --ecu CCU2_LITE

# BCU 타겟
./build.py --module diagnostic-manager --cross-compile --ecu BCU
```

## Vehicle Variants

### Tier Options (--tier)
- `LGE` (기본값)
- `MOBIS`

### CAN DB Version (--can-db-version)
- `253Q` (기본값, 최신)
- `252Q`, `251Q` (이전 버전)
- `253Q.WM` (특수 변형)

### Service Interface Version (--service-if-version)
- `0.25.1` (기본값, 최신)
- `0.24.2`, `0.23.1` (이전 버전)

### ECU Type (--ecu)
- `CCU2` (기본값)
- `CCU2_LITE`
- `BCU`

### 변형 조합 예시
```bash
# MOBIS Tier + 252Q CAN DB
./build.py --module vam --tier MOBIS --can-db-version 252Q

# Release + AUTOSAR
./build.py --module container-manager --build-type Release --autosar --dlt

# 모든 변형 빌드 (CI/CD)
./build.py --module container-manager --all-variants --output-junit
```

## 개발 옵션

### 디버깅 & 제어
| Flag | Description |
|------|-------------|
| `--verbose` | 상세 출력 |
| `--dry-run, -n` | 명령 표시만, 실행 안함 |
| `--trace-command` | 실행 명령 출력 |
| `--no-build, -nb` | CMake만, 빌드 스킵 |
| `--no-rdeps, -nr` | 역의존성 스킵 |
| `--keep-going` | 에러시 계속 진행 |

### Sanitizers (Debug 모드)
```bash
# Address Sanitizer
./build.py --module container-manager --asan

# Thread Sanitizer
./build.py --module container-manager --tsan

# Undefined Behavior Sanitizer
./build.py --module container-manager --ubsan

# Leak Sanitizer
./build.py --module container-manager --lsan
```

### 품질 & 분석
```bash
# 코드 포맷팅 체크
./build.py --module container-manager --clang-format

# 포맷팅 자동 적용
./build.py --module container-manager --clang-format-apply

# PR 검증 체크
./build.py --module container-manager --pr-check
```

## 빌드 출력

### 출력 구조
```
build/
├── Debug/
│   └── <component>/
│       ├── CMakeFiles/
│       ├── lib<component>.a
│       └── <executable>
├── Release/
└── autosar/
```

### 빌드 로그
```bash
# 빌드 출력 확인
cat build/Debug/<component>/CMakeFiles/CMakeOutput.log

# 에러 로그
cat build/Debug/<component>/CMakeFiles/CMakeError.log
```

## 에러 처리

### CMake 설정 에러
```
CMake Error at CMakeLists.txt:XX
```

**원인**: 잘못된 CMake 문법, 누락된 의존성

**해결**:
```bash
# CMake 캐시 삭제
rm -rf build/Debug/<component>/CMakeCache.txt
./build.py --module <component>
```

### 컴파일 에러
```
error: <message>
```

**해결**:
```bash
# 상세 출력으로 재빌드
./build.py --module <component> --verbose

# 특정 파일 확인
grep -n "error:" build/Debug/<component>/CMakeFiles/CMakeOutput.log
```

### 링크 에러
```
undefined reference to `symbol'
```

**원인**: 누락된 라이브러리, 의존성 순서

**해결**:
```bash
# 의존성 먼저 빌드
./build.py --module libsntxx
./build.py --module libsntlogging
./build.py --module <component>
```

## 의존성 관리

### 역의존성 (rdeps)
```bash
# 의존성 확인
./build.py --module container-manager --dry-run
# 출력: rdeps:{'container-manager', 'libsntxx', ...}
```

### 빌드 순서
1. 공통 라이브러리: `libsntxx`, `libsntlogging`
2. 도메인 라이브러리: `libsnt_vehicle`, `seccommon`
3. 애플리케이션: `vam`, `container-manager`

### 전체 재빌드
```bash
# 모든 의존성 포함 클린 빌드
./build.py --module <component> --clean

# 또는 전체 삭제 후 빌드
rm -rf build/
./build.py --module <component>
```

## CI/CD 패턴

### PR 검증 빌드
```bash
./build.py --module <component> --pr-check --output-junit
```

### 전체 변형 빌드
```bash
./build.py --module <component> --all-variants --output-junit
```

### 병렬 빌드 제어
```bash
# 기본: 24 jobs
./build.py --module <component> -j 24

# 리소스 제한
./build.py --module <component> -j 8
```
