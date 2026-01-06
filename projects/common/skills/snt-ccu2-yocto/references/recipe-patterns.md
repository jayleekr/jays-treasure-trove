# Yocto Recipe Patterns Reference

## bbappend 작성 패턴

### 기본 구조
```bitbake
# FILESEXTRAPATHS 먼저 선언
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# 파일 추가
SRC_URI += "file://custom.config"
SRC_URI += "file://fix-issue.patch"

# 설정 추가
EXTRA_OECONF += "--enable-feature"
```

### 커널 config fragment
```bitbake
# linux-s32_5.10.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
FILESEXTRAPATHS:prepend := "${THISDIR}/linux-ccu2:"

SRC_URI += "file://cgroupv2.config"

# Config fragment 적용
do_configure:append() {
    cat ${WORKDIR}/cgroupv2.config >> ${B}/.config
}
```

### systemd 서비스 추가
```bitbake
# systemd_%.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://custom.service"

do_install:append() {
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/custom.service ${D}${systemd_unitdir}/system/
}

SYSTEMD_SERVICE:${PN} += "custom.service"
```

## Config Fragment 패턴

### 위치
```
meta-sonatus/recipes-kernel/linux/linux-ccu2/
├── cgroupv2.config
├── usb-gadget.config
└── debug.config
```

### 형식
```
# cgroupv2.config
CONFIG_CGROUP_V2=y
CONFIG_CGROUP_BPF=y
# CONFIG_CGROUP_DEBUG is not set
```

## 패치 파일 패턴

### 위치
```
meta-sonatus/recipes-kernel/linux/files/
├── 0001-fix-memory-leak.patch
└── 0002-add-driver-support.patch
```

### bbappend에서 적용
```bitbake
SRC_URI += "\
    file://0001-fix-memory-leak.patch \
    file://0002-add-driver-support.patch \
"
```

## 레이어 구조

```
meta-sonatus/
├── conf/
│   └── layer.conf
├── recipes-core/
│   ├── systemd/
│   └── base-files/
├── recipes-kernel/
│   └── linux/
│       ├── linux-s32_5.10.bbappend
│       ├── linux-ccu2/
│       └── files/
├── recipes-connectivity/
└── recipes-sonatus/
    └── container-manager/
```

## 변수 참조

| 변수 | 설명 |
|------|------|
| `${THISDIR}` | 현재 레시피 디렉토리 |
| `${PN}` | 패키지 이름 |
| `${PV}` | 패키지 버전 |
| `${WORKDIR}` | 작업 디렉토리 |
| `${S}` | 소스 디렉토리 |
| `${B}` | 빌드 디렉토리 |
| `${D}` | 설치 대상 디렉토리 |
