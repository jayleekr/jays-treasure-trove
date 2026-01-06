---
name: snt-ccu2-yocto:spec
description: "Generate integrated specifications for Yocto embedded Linux projects. Creates structured specs covering recipe changes, code modifications, configurations, and documentation."
---

# /snt-ccu2-yocto:spec - Integrated Specification Generator

CCU_GEN2.0_SONATUS 프로젝트를 위한 통합 요구사항 명세 생성기.

## Usage

```
/snt-ccu2-yocto:spec "<기능 요구사항>"
```

## Examples

```
/snt-ccu2-yocto:spec "cgroupv2 지원 추가"
/snt-ccu2-yocto:spec "CAN DB 버전 253Q 지원"
/snt-ccu2-yocto:spec "Podman 5.0 업그레이드"
```

## Behavioral Flow

1. **요구사항 분석**
   - 사용자 입력을 파싱하여 기능 요구사항 식별
   - 영향 받는 컴포넌트 분석 (커널, userspace, 설정 등)

2. **변경 범위 결정**
   - Yocto 레이어 분석 (meta-sonatus, meta-ccu2-bsp 등)
   - 영향 받는 모듈 식별 (dependency.json 참조)
   - 필요한 변경 유형 분류

3. **명세 생성**
   - 구조화된 YAML 형식으로 명세 출력
   - 각 변경 항목에 대한 상세 설명 포함

## Output Format

명세는 다음 YAML 스키마를 따름:

```yaml
spec:
  name: "<기능명>"
  description: "<기능 설명>"

  recipe_changes:
    - file: "path/to/recipe.bbappend"
      action: "create|modify|delete"
      layer: "meta-sonatus"
      description: "변경 설명"
      content: |
        # 실제 내용 또는 변경 diff

  kernel_configs:
    - file: "linux-ccu2/feature.config"
      action: "create|modify"
      configs:
        - "CONFIG_FEATURE=y"
        - "CONFIG_OPTION=n"

  code_changes:
    - file: "path/to/source.py"
      action: "modify"
      description: "변경 설명"
      changes:
        - location: "class/function"
          type: "add|modify|remove"
          description: "상세 설명"

  config_changes:
    - file: "build_info.json"
      action: "modify"
      fields:
        - path: "build_option.new_field"
          value: "value"

  documentation:
    - file: "claudedocs/feature-guide.md"
      action: "create"
      description: "문서 내용 설명"

  dependencies:
    modules_affected:
      - "linux-s32"
      - "systemd"
    build_order:
      - "linux-s32"
      - "systemd"
      - "fsl-image-ccu2"

  validation:
    build_verification:
      - "bitbake linux-s32 성공"
    runtime_verification:
      - "cat /proc/filesystems | grep cgroup2"
```

## Key Files to Reference

프로젝트 분석 시 참조할 파일들:

1. **빌드 시스템**
   - `build.py` - 빌드 옵션 및 모듈 정의
   - `config.py` - TierType, ECUType, Module 클래스
   - `mobis/build_info.json` - 현재 빌드 설정

2. **Yocto 레이어**
   - `mobis/layers/meta-sonatus/` - Sonatus 커스텀 레시피
   - `mobis/layers/meta-ccu2-bsp/` - CCU2 BSP 레시피

3. **의존성**
   - `mobis/dependency.json` - 모듈 간 의존성 정의

4. **문서**
   - `claudedocs/build-system-guide.md` - 빌드 시스템 가이드
   - `claudedocs/cgroupv1-to-cgroupv2-migration.md` - 마이그레이션 예시

## Boundaries

**Will:**
- 요구사항을 구조화된 명세로 변환
- 영향 받는 모듈 및 파일 식별
- 변경 순서 및 의존성 분석
- 검증 방법 제안

**Will Not:**
- 실제 파일 수정 (implement 단계에서 수행)
- 빌드 실행 (build 단계에서 수행)
- 테스트 실행 (test 단계에서 수행)
