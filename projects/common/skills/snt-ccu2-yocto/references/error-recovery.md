# Yocto Error Recovery Reference

## 일반적인 에러 패턴

### 1. Recipe Parsing Error

**증상:**
```
ERROR: ParseError at /path/to/recipe.bbappend:10
```

**원인:**
- bbappend 문법 오류
- 변수 할당 오류
- 잘못된 override 문법

**해결:**
```bash
# 레시피 파싱 테스트
bitbake -e <recipe> | head -100

# 문법 확인 포인트
# - `:append` vs `_append` (Yocto 4.0+)
# - FILESEXTRAPATHS 경로
# - 따옴표 매칭
```

### 2. Checksum Mismatch

**증상:**
```
ERROR: Fetcher failure: Checksum mismatch!
File: '/path/to/file'
Expected: abc123...
Actual: def456...
```

**해결:**
```bitbake
# 체크섬 업데이트
SRC_URI[sha256sum] = "def456..."

# 또는 체크섬 비활성화 (개발용)
BB_STRICT_CHECKSUM = "0"
```

### 3. do_compile Failure

**증상:**
```
ERROR: linux-s32-5.10+git: do_compile failed
```

**디버깅:**
```bash
# 작업 디렉토리 진입
cd tmp/work/*/linux-s32/5.10+git*/

# 로그 확인
cat temp/log.do_compile

# 재시도 (디버그)
bitbake linux-s32 -c compile -v
```

**일반적인 원인:**
- 커널 config 충돌
- 패치 적용 실패
- 크로스 컴파일러 문제

### 4. do_fetch Failure

**증상:**
```
ERROR: Unable to fetch URL
```

**해결:**
```bash
# 네트워크 확인
ping downloads.yoctoproject.org

# 프록시 설정
export http_proxy=...
export https_proxy=...

# 미러 사용
PREMIRRORS = "git://.*/.* file:///local/mirror/"
```

### 5. License Warning

**증상:**
```
WARNING: Unable to get checksum of LICENSE
```

**해결:**
```bitbake
# LICENSE 파일 체크섬 추가
LIC_FILES_CHKSUM = "file://LICENSE;md5=abc123"

# 또는 COPYING 파일 사용
LIC_FILES_CHKSUM = "file://COPYING;md5=def456"
```

### 6. Package Conflict

**증상:**
```
ERROR: Multiple providers for <package>
```

**해결:**
```bitbake
# 선호 공급자 지정
PREFERRED_PROVIDER_<package> = "<recipe>"

# 또는 충돌 패키지 제외
PACKAGE_EXCLUDE += "conflicting-package"
```

## 빌드 클린업

### 특정 레시피 클린
```bash
./build.py -m <recipe> -c cleansstate
# 또는
bitbake <recipe> -c cleansstate
```

### 전체 클린
```bash
rm -rf tmp/
rm -rf sstate-cache/
```

### 부분 클린
```bash
# 특정 태스크만 재실행
bitbake <recipe> -c configure -f
bitbake <recipe> -c compile -f
```

## 디버깅 명령

```bash
# 환경 변수 확인
bitbake -e <recipe> | grep ^<VAR>=

# 의존성 확인
bitbake -g <recipe>

# 태스크 목록
bitbake -c listtasks <recipe>

# 상세 로그
bitbake <recipe> -v -D

# 작업 디렉토리 위치
bitbake -e <recipe> | grep ^WORKDIR=
```

## 롤백 절차

### 레시피 변경 롤백
```bash
# Git으로 되돌리기
git checkout -- mobis/layers/meta-sonatus/

# 특정 파일만
git checkout -- <file>
```

### sstate 캐시 문제
```bash
# 특정 레시피 sstate 삭제
rm -rf sstate-cache/*/<recipe>*

# 재빌드
./build.py -m <recipe>
```
