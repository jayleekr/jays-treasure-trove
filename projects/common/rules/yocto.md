---
paths:
  - "**/*.bb"
  - "**/*.bbappend"
  - "**/*.bbclass"
  - "**/meta-*/recipes-*/**"
  - "**/conf/*.conf"
---

# Yocto Recipe Development Rules

## File Naming Conventions
- Recipe: `<package>_<version>.bb` (예: `container-manager_1.0.bb`)
- Append: `<package>_%.bbappend` 또는 `<package>_<version>.bbappend`
- Class: `<name>.bbclass`

## Required Variables (모든 레시피 필수)

```bitbake
LICENSE = "MIT"  # 또는 Apache-2.0, GPLv2, etc.
LIC_FILES_CHKSUM = "file://LICENSE;md5=..."
SRC_URI = "git://...;branch=master;protocol=https"
SRCREV = "${AUTOREV}"  # 또는 specific commit
```

## FILESEXTRAPATHS 규칙

**올바른 사용**:
```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
```

**흔한 실수**:
```bitbake
# ❌ 잘못됨 - = 대신 := 사용
FILESEXTRAPATHS:prepend = "${THISDIR}/files:"

# ❌ 잘못됨 - 콜론 누락
FILESEXTRAPATHS:prepend := "${THISDIR}/files"
```

## SRC_URI Checksum

모든 외부 소스에 체크섬 필수:
```bitbake
SRC_URI = "https://example.com/file.tar.gz"
SRC_URI[md5sum] = "..."
SRC_URI[sha256sum] = "..."
```

## do_install 패턴

```bitbake
do_install() {
    # ${D}는 destination root
    install -d ${D}${bindir}
    install -m 0755 ${B}/mybin ${D}${bindir}/
    
    # 설정 파일
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/config.json ${D}${sysconfdir}/
}
```

## 흔한 에러와 해결책

| 에러 | 원인 | 해결 |
|------|------|------|
| `do_fetch: Fetcher failure` | 체크섬 불일치 | SRC_URI 체크섬 업데이트 |
| `Nothing PROVIDES` | 의존성 없음 | DEPENDS에 패키지 추가 |
| `do_package: QA Issue` | 파일 경로 문제 | FILES:${PN} 확인 |
| `LICENSE not set` | 라이선스 누락 | LICENSE 변수 추가 |

## 빌드 명령 참조

```bash
# 단일 레시피 빌드
./build.py -m <recipe-name>

# 클린 후 빌드
./build.py -m <recipe-name> -c cleansstate

# 전체 이미지
./build.py -ncpb -j 16 -p 16
```
