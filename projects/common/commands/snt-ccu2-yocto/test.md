---
name: snt-ccu2-yocto:test
description: "Multi-stage test pipeline for embedded Linux systems. Performs build verification, image validation, static analysis, and target board testing sequentially."
---

# /snt-ccu2-yocto:test - Multi-Stage Test Pipeline

CCU_GEN2.0_SONATUS 프로젝트를 위한 멀티스테이지 테스트 파이프라인.

## Usage

```
/snt-ccu2-yocto:test [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--stage <n>` | 특정 스테이지만 실행 (1-4) |
| `--skip-target` | 타겟 보드 테스트 건너뛰기 |
| `--target-ip <ip>` | 타겟 보드 IP 주소 |
| `--verbose` | 상세 출력 |

## Examples

```
# 전체 테스트 파이프라인
/snt-ccu2-yocto:test

# 빌드 검증만
/snt-ccu2-yocto:test --stage 1

# 타겟 테스트 제외
/snt-ccu2-yocto:test --skip-target

# 특정 타겟 보드 테스트
/snt-ccu2-yocto:test --target-ip 192.168.1.100
```

## Test Pipeline Stages

### Stage 1: Build Verification

빌드가 성공적으로 완료되었는지 확인.

```bash
# Check Points:
- [ ] bitbake 리턴 코드 확인 (0 = 성공)
- [ ] 빌드 로그 에러 없음
- [ ] 아티팩트 파일 존재
```

**Verification Commands:**
```bash
# 빌드 아티팩트 확인
ls -la mobis/deploy/*.tar.gz
ls -la mobis/deploy/fsl-image-ccu2-*.wic*

# 버전 파일 확인
cat mobis/deploy/build_info.json
```

**Expected Artifacts:**
| File | Description |
|------|-------------|
| `ccu-image.tar.gz` | 배포용 압축 이미지 (flash 입력용) |
| `fsl-image-ccu2-mobisccu2.wic` | 루트 파일시스템 (~30GB raw) |
| `fsl-image-ccu2-mobisccu2.tar.gz` | 압축 rootfs (~290MB) |
| `build_info.json` | 빌드 메타데이터 |

**Artifacts for Flash (extracted from ccu-image.tar.gz):**
| File | Flash Mode | Description |
|------|------------|-------------|
| `flash.bin` | MCU | MCU firmware (NOR Flash) |
| `fip.s32-sdcard` | UBOOT | U-Boot bootloader (eMMC) |
| `fsl-image-ccu2-mobisccu2.wic*-{partition}.ext4.simg` | AP | 파티션 이미지 (boot, rootfs, tee) |

### Stage 2: Image Validation

생성된 이미지의 구조 및 내용 검증.

```bash
# Check Points:
- [ ] Rootfs 디렉토리 구조 정상
- [ ] 필수 파일 존재
- [ ] 파일 권한 정상
- [ ] Symlink 유효
- [ ] 이미지 크기 적정
```

**Validation Commands:**
```bash
# Rootfs 구조 확인
ls -la mobis/rootfs/usr/bin/
ls -la mobis/rootfs/etc/systemd/system/
ls -la mobis/rootfs/lib/systemd/system/

# 필수 바이너리 확인
file mobis/rootfs/usr/bin/podman
file mobis/rootfs/usr/bin/systemctl

# Symlink 검증
readlink -f mobis/rootfs/etc/resolv.conf

# 이미지 크기
du -sh mobis/deploy/*.tar.gz
```

**Rootfs Structure Checks:**
```
mobis/rootfs/
├── etc/
│   ├── systemd/
│   └── containers/
├── usr/
│   ├── bin/
│   └── lib/
├── lib/
│   └── systemd/
└── var/
```

### Stage 3: Static Analysis

설정 및 레시피 정적 분석.

```bash
# Check Points:
- [ ] Recipe 문법 검증
- [ ] Config 파일 검증
- [ ] 의존성 그래프 정상
- [ ] 라이선스 컴플라이언스
```

**Analysis Commands:**
```bash
# 커널 config 확인 (inside container)
bitbake -e linux-s32 | grep DELTA_KERNEL_DEFCONFIG

# systemd PACKAGECONFIG 확인
bitbake -e systemd | grep PACKAGECONFIG

# 패키지 리스트 확인
cat mobis/deploy/images/*/installed-packages.txt
```

### Stage 4: Target Board Test (Optional)

실제 하드웨어에서의 기능 테스트.

```bash
# Prerequisites:
- 타겟 보드 전원 ON
- SSH 접근 가능
- 이미지 플래싱 완료

# Check Points:
- [ ] SSH 연결 성공
- [ ] 서비스 시작 정상
- [ ] 기능 테스트 통과
```

**Target Test Commands:**
```bash
# SSH 연결 테스트
ssh root@${TARGET_IP} "hostname"

# 서비스 상태 확인
ssh root@${TARGET_IP} "systemctl status podman"
ssh root@${TARGET_IP} "systemctl status containerd"

# cgroup 버전 확인 (cgroupv2 테스트 예시)
ssh root@${TARGET_IP} "cat /proc/filesystems | grep cgroup"
ssh root@${TARGET_IP} "mount | grep cgroup"
ssh root@${TARGET_IP} "cat /sys/fs/cgroup/cgroup.controllers"

# 컨테이너 런타임 테스트
ssh root@${TARGET_IP} "podman run --rm alpine echo 'Hello from container'"
```

## Test Report Format

```
## Test Report

### Stage 1: Build Verification
Status: ✅ PASSED
- bitbake exit code: 0
- Artifacts found: 4/4
- Build time: 2h 15m

### Stage 2: Image Validation
Status: ✅ PASSED
- Rootfs structure: Valid
- Required binaries: 15/15
- Symlinks: Valid
- Image size: 450MB (within limit)

### Stage 3: Static Analysis
Status: ✅ PASSED
- Recipe syntax: No errors
- Config validation: Passed
- License check: Compliant

### Stage 4: Target Board Test
Status: ⏭️ SKIPPED (no hardware)
- SSH connection: N/A
- Service status: N/A
- Functionality: N/A

---

### Overall Result: ✅ PASSED (3/3 stages)

### Recommendations:
- 타겟 보드에서 cgroupv2 기능 검증 권장
- 장기 안정성 테스트 필요
```

## Boundaries

**Will:**
- 빌드 아티팩트 존재 및 무결성 검증
- Rootfs 구조 및 파일 검증
- 설정 파일 정적 분석
- 타겟 보드 SSH 기반 테스트 (가능 시)

**Will Not:**
- 빌드 실행 (build 단계에서 수행)
- 이미지 플래싱 자동화
- 성능 벤치마크 (별도 도구 필요)
- 보안 스캔 (별도 도구 필요)

## Script Integration

This command uses a bundled script for automated test execution:

**Script Location:** `.claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh`

### Script Usage

```bash
# Run stages 1,2,3 (default - no target board)
.claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh

# Run specific stages
.claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh --stages 1,2

# Run all stages including target board test
.claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh --stages 1,2,3,4 --target-ip 192.168.1.100

# Verbose output for debugging
.claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh --stages 1,2,3 --verbose
```

### Script Features

1. **Stage Selection**: Run specific stages or all stages
2. **Target Board Integration**: SSH-based testing with IP specification
3. **Automated Validation**: Build verification, image validation, static analysis
4. **Structured Reporting**: Summary report with pass/fail status per stage
5. **Pipeline Integration**: Returns structured output for orchestration

### Execution Pattern

Claude should execute tests using:
```python
# In pipeline context
Bash(".claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh --stages 1,2,3")

# With target board
Bash(".claude/commands/snt-ccu2-yocto/scripts/yocto-test.sh --stages 1,2,3,4 --target-ip 192.168.1.100")
```

## Error Handling

| Stage | Common Error | Solution |
|-------|--------------|----------|
| 1 | Artifacts not found | 빌드 재실행 |
| 2 | Missing binaries | 레시피 IMAGE_INSTALL 확인 |
| 3 | Recipe syntax error | bbappend 문법 수정 |
| 4 | SSH connection failed | 네트워크/IP 확인 |

---

## Flashing Guide for Testers

빌드 완료 후 타겟 보드에 이미지를 플래싱하는 방법.

### Flash Tool Location

```bash
/qatools/flash-boards/flash.py
```

### Required Artifacts (MOBIS CCU2)

빌드 아티팩트 → TFTP 서버 (`/var/lib/tftpboot`)로 복사 후 flash 실행.

| Artifact | Pattern | Flash Mode |
|----------|---------|------------|
| Main Archive | `ccu-image.tar.gz` | image_source 입력 |
| MCU Firmware | `flash.bin` | `-m mcu` |
| U-Boot | `fip.s32-sdcard` | `-m uboot` |
| AP Partitions | `fsl-image-ccu2-mobisccu2.wic*-{partition}.ext4.simg` | `-m ap` |

**Partition Mapping (AP Flash):**
```yaml
boot_a, boot_b    → boot_ab
root_a, root_b    → rootfs_ab
tee_a, tee_b      → tee_ab
```

### Flash Commands

```bash
# 전체 플래싱 (MCU + UBOOT + AP + Switch)
/qatools/flash-boards/flash.py -t ccu2-<ID> -m all -i ccu-image.tar.gz

# AP만 플래싱 (가장 일반적)
/qatools/flash-boards/flash.py -t ccu2-<ID> -m ap -i ccu-image.tar.gz

# 개별 모드 플래싱
/qatools/flash-boards/flash.py -t ccu2-<ID> -m mcu -i ccu-image.tar.gz
/qatools/flash-boards/flash.py -t ccu2-<ID> -m uboot -i ccu-image.tar.gz
/qatools/flash-boards/flash.py -t ccu2-<ID> -m switch -i ccu-image.tar.gz

# 로컬 이미지 경로로 플래싱
/qatools/flash-boards/flash.py -t ccu2-<ID> -m ap -i /path/to/ccu-image.tar.gz

# Jenkins 빌드에서 플래싱
/qatools/flash-boards/flash.py -t ccu2-<ID> -m ap -i ccu2-image-mobis

# 마지막 이미지로 재플래싱
/qatools/flash-boards/flash.py -t ccu2-<ID> -m ap --reflash

# Debug 로그 출력
/qatools/flash-boards/flash.py -t ccu2-<ID> -m all -i ccu-image.tar.gz -l DEBUG
```

### Flash Modes

| Mode | Description | Duration |
|------|-------------|----------|
| `all` | MCU → UBOOT → AP → Switch 순차 플래싱 | ~15-20분 |
| `ap` | AP 파티션만 플래싱 (rootfs, boot, tee) | ~5-10분 |
| `mcu` | MCU firmware 플래싱 (NOR Flash via UART) | ~2-3분 |
| `uboot` | U-Boot bootloader 플래싱 | ~1-2분 |
| `switch` | Ethernet switch firmware 업데이트 | ~3-5분 |

### Flash Options

| Option | Description |
|--------|-------------|
| `-t, --testbed` | 타겟 보드 이름 (예: ccu2-1, ccu2-4) |
| `-m, --mode` | Flash 모드 (all, ap, mcu, uboot, switch) |
| `-i, --image_source` | 이미지 경로 또는 Jenkins job 이름 |
| `-l, --logging_level` | 로그 레벨 (DEBUG, INFO, WARNING, ERROR) |
| `-r, --reflash` | 마지막 다운로드 이미지로 재플래싱 |
| `--skip-image-check` | 이미지 검증 건너뛰기 |
| `--perf` | LGE perf 이미지 플래싱 |

### TFTP Directory

플래싱 시 이미지가 추출되는 위치:
```
/var/lib/tftpboot/
├── flash.bin                                    # MCU firmware
├── fip.s32-sdcard                              # U-Boot
├── fsl-image-ccu2-mobisccu2.wic*-boot_ab.ext4.simg    # Boot partition
├── fsl-image-ccu2-mobisccu2.wic*-rootfs_ab.ext4.simg  # Rootfs partition
├── fsl-image-ccu2-mobisccu2.wic*-tee_ab.ext4.simg     # TEE partition
└── ...
```

### Board Type Configuration

| Board Type | HW Type | Flash Core | Config |
|------------|---------|------------|--------|
| ccu2 | MBS (MOBIS) | flash_mobis | config.yaml → board.ccu2.mobis |
| ccu2 | LGE | flash_lge | config.yaml → board.ccu2.lge |
| bcu | - | flash_mobis | config.yaml → board.bcu |

### Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| SSH connection failed | 보드 부팅 안됨 | 전원 확인, 시리얼 콘솔 확인 |
| Image extraction failed | 잘못된 아카이브 | ccu-image.tar.gz 재생성 |
| Fastboot timeout | U-Boot 진입 실패 | 전원 사이클, 시리얼 부트모드 확인 |
| Partition flash failed | 파티션 이미지 없음 | 빌드 아티팩트 확인 |
| Switch update stuck | Switch 통신 실패 | 전원 사이클 후 재시도 |

### Post-Flash Verification

```bash
# SSH 연결 확인
ssh root@10.0.6.0 "hostname"

# 부트 파티션 확인
ssh root@10.0.6.0 "cat /proc/cmdline"

# 버전 확인
ssh root@10.0.6.0 "cat /etc/version"

# cgroup 버전 확인 (cgroupv2 테스트)
ssh root@10.0.6.0 "cat /sys/fs/cgroup/cgroup.controllers"
```
