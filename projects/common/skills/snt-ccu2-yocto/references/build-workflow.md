# Yocto Build Workflow Reference

## Build System Overview

CCU2 Yocto 빌드는 Docker 컨테이너 내에서 bitbake를 실행합니다.

## Build Commands

### 전체 이미지 빌드
```bash
# Docker 컨테이너 진입
./run-dev-container.sh

# MOBIS 이미지 빌드
cd mobis/
./build.py -ncpb -j 16 -p 16

# LGE 이미지 빌드
cd lge/
./build.py -ncpb -j 16 -p 16
```

### 모듈 빌드
```bash
# 특정 레시피만 빌드
./build.py -m linux-s32
./build.py -m systemd
./build.py -m container-manager

# 클린 후 빌드
./build.py -m linux-s32 -c cleansstate
```

### build.py 옵션

| Option | Description |
|--------|-------------|
| `-m, --module` | 대상 레시피 |
| `-c, --clean` | cleansstate 실행 |
| `-j, --jobs` | 병렬 태스크 수 (기본: 24) |
| `-p, --parallel` | 병렬 레시피 수 (기본: 24) |
| `-ncpb` | 전체 이미지 빌드 |
| `--dry-run` | 명령만 출력 |
| `-d, --debug` | 디버그 모드 |

## Build Scope Detection

변경 파일에 따른 빌드 범위:

| 변경 파일 | 빌드 범위 |
|----------|----------|
| `*.bb`, `*.bbappend` | MODULE (해당 레시피) |
| `*.config`, `defconfig` | MODULE (linux-*) |
| `build_info.json` | FULL (전체 이미지) |
| `*.patch` | MODULE (해당 레시피) |

## Build Artifacts

빌드 결과물 위치:
```
mobis/deploy/
├── images/
│   └── fsl-image-ccu2-mobisccu2.tar.gz
├── sdk/
└── build_info.json

lge/deploy/
├── images/
└── build_info.json
```

## Dependency Management

레시피 의존성 확인:
```bash
# 의존성 그래프
bitbake -g <recipe>
cat task-depends.dot

# 역의존성 확인
bitbake-layers show-appends
```

## Common Build Issues

### 1. Checksum Mismatch
```
ERROR: linux-s32: do_fetch: Checksum mismatch
```
해결: SRC_URI의 체크섬 업데이트

### 2. License Warning
```
WARNING: linux-s32: Unable to get checksum of LICENSE
```
해결: LIC_FILES_CHKSUM 경로 확인

### 3. Dependency Error
```
ERROR: Nothing PROVIDES 'missing-recipe'
```
해결: DEPENDS 또는 RDEPENDS 확인
