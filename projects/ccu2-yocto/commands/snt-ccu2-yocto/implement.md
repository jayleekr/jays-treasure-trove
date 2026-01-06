---
name: snt-ccu2-yocto:implement
description: "Implement Yocto recipes and code changes. Creates/modifies bbappend files, config fragments, C/C++ code, and configuration files based on spec or direct requirements."
---

# /snt-ccu2-yocto:implement - Implementation Generator

CCU_GEN2.0_SONATUS 프로젝트를 위한 Yocto 레시피 및 코드 구현기.

## Usage

```
/snt-ccu2-yocto:implement [spec.yaml | "<요구사항>"]
```

## Examples

```
# spec 파일 기반 구현
/snt-ccu2-yocto:implement claudedocs/cgroupv2-spec.yaml

# 직접 요구사항 입력
/snt-ccu2-yocto:implement "cgroupv2.config 커널 설정 파일 생성"
```

## Behavioral Flow

1. **입력 분석**
   - spec.yaml 파일 파싱 또는 요구사항 텍스트 분석
   - 변경 대상 파일 및 변경 내용 확인

2. **기존 코드 분석**
   - 영향 받는 파일들의 현재 상태 확인
   - 기존 패턴 및 코딩 스타일 파악
   - 의존성 및 영향 범위 확인

3. **구현 실행**
   - Yocto 레시피 생성/수정
   - 커널 config fragment 생성
   - 소스 코드 수정
   - 설정 파일 업데이트

4. **검증 준비**
   - 변경 사항 요약
   - 빌드 명령어 제안

## Capabilities

### Yocto Recipe Operations

```bash
# bbappend 파일 생성/수정
mobis/layers/meta-sonatus/recipes-*/.../*.bbappend

# 커널 config fragment
mobis/layers/meta-sonatus/.../linux-ccu2/*.config

# Systemd 설정
mobis/layers/meta-sonatus/recipes-core/systemd/
```

**Recipe Syntax Patterns:**

```bitbake
# SRC_URI 추가
SRC_URI:append += "\
    file://feature.config \
"

# PACKAGECONFIG 수정
PACKAGECONFIG:append = " feature"

# FILESEXTRAPATHS 설정
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
```

### Kernel Config Fragments

```bash
# Config fragment 생성
CONFIG_FEATURE=y
CONFIG_OPTION=n
# CONFIG_DISABLED is not set
```

### Python/C++ Code Changes

```python
# config.py 수정 예시
class NewType(str, Enum):
    VALUE1 = "value1"
    VALUE2 = "value2"
```

### Configuration Files

```json
// build_info.json 수정
{
  "build_option": {
    "new_field": "value"
  }
}
```

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `mobis/layers/meta-sonatus/` | Sonatus 커스텀 레시피 |
| `mobis/layers/meta-sonatus/recipes-tiers/mobis/recipes-kernel/` | 커널 관련 |
| `mobis/layers/meta-sonatus/recipes-core/` | 코어 패키지 (systemd 등) |
| `mobis/layers/meta-sonatus/recipes-thirdparty/` | 3rd party (podman, docker) |

## Workflow Patterns

### 1. Kernel Feature Addition

```
1. linux-ccu2/feature.config 생성
2. linux-s32_5.10.bbappend 수정 (SRC_URI, DELTA_KERNEL_DEFCONFIG)
```

### 2. Systemd Configuration

```
1. recipes-core/systemd/ 디렉토리 생성
2. systemd_%.bbappend 생성
3. PACKAGECONFIG 추가
```

### 3. New Package Addition

```
1. recipes-thirdparty/<package>/ 디렉토리 생성
2. <package>_<version>.bb 레시피 생성
3. 의존성 설정
```

## Boundaries

**Will:**
- Yocto bbappend/bb 파일 생성/수정
- 커널 config fragment 생성
- Python/C++ 소스 코드 수정
- JSON/YAML 설정 파일 업데이트
- 문서 파일 생성

**Will Not:**
- 빌드 실행 (build 단계에서 수행)
- Docker 컨테이너 관리
- 타겟 보드 배포
- 테스트 실행

## Output

구현 완료 후 다음 정보 제공:

```
## Implementation Summary

### Files Created:
- mobis/layers/meta-sonatus/.../cgroupv2.config

### Files Modified:
- mobis/layers/meta-sonatus/.../linux-s32_5.10.bbappend

### Next Steps:
빌드를 실행하려면:
/snt-ccu2-yocto:build

또는 전체 파이프라인:
/snt-ccu2-yocto:pipeline
```
