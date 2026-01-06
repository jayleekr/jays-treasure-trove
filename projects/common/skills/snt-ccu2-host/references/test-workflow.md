# Test Workflow - 테스트 실행 패턴

## 테스트 프레임워크

### C++ Unit Tests
- **프레임워크**: Google Test (GTest) + Google Mock (GMock)
- **위치**: `<component>/tests/*.cxx`
- **실행**: `./build.py --module <component> --tests`

### Python Integration Tests
- **프레임워크**: `snt_test_framework`
- **위치**: `<component>/test.py`
- **실행**: `python3 <component>/test.py`

## Unit Test 실행

### 기본 실행
```bash
# 빌드 + 테스트
./build.py --module container-manager --tests

# 빌드만 (테스트 실행 안함)
./build.py --module container-manager --tests-build-only
```

### 상세 출력
```bash
./build.py --module container-manager --tests --verbose
```

### 커버리지 생성
```bash
./build.py --module container-manager --tests --coverage

# 커버리지 리포트 위치
# coverage/<component>/index.html
```

## ctest 직접 사용

### 테스트 목록 확인
```bash
cd build/Debug/<component>
ctest --show-only=json-v1
```

### 특정 테스트 실행
```bash
# 이름으로 필터
ctest -R "test_container"

# 패턴 매칭
ctest -R "policy.*"
```

### 실패 시 출력 표시
```bash
ctest --output-on-failure
```

### 재시도
```bash
# 3회까지 재시도
ctest --repeat-until-pass 3
```

## Integration Test 실행

### snt_test_framework 패턴
```python
# container-manager/test.py 예시
from snt_test_framework.core import executor
from snt_test_framework.core.api import cm_utils, test

@test.Case(11584)
class TestContainerDeployment(test.Test):
    def setup(self):
        # 테스트 준비
        pass

    def teardown(self):
        # 정리
        pass

    @test.Step(1)
    def test_deploy_container(self):
        # 테스트 로직
        assert result == expected
```

### 실행
```bash
# 컴포넌트 디렉토리에서
cd container-manager
python3 test.py

# 특정 테스트 케이스
python3 test.py --case 11584
```

## 테스트 구조

### 컴포넌트별 테스트 파일

**container-manager/tests/** (47 파일):
- `cm_application_tests.cxx` - 코어 기능
- `container_config_tests.cxx` - 설정
- `docker_client_tests.cxx` - Docker 통합
- `policy_tests.cxx` - 정책 로직
- `container_network_tests.cxx` - 네트워킹

**vam/tests/** (17+ 파일):
- `policy_parser_test.cxx` - 정책 파싱
- `policy_updater_test.cxx` - 정책 업데이트
- `actuation_test.cxx` - 액추에이션
- `context_test.cxx` - 컨텍스트

### Mock 객체
```
<component>/tests/mocks/
├── container_mocks.hxx
├── cri_mocks.hxx
├── policy_mocks.hxx
└── ...
```

## 테스트 결과 분석

### 성공/실패 패턴
```
[==========] Running 45 tests from 12 test suites.
[----------] 5 tests from PolicyTest
[ RUN      ] PolicyTest.ParseValidPolicy
[       OK ] PolicyTest.ParseValidPolicy (12 ms)
[ RUN      ] PolicyTest.ParseInvalidPolicy
[  FAILED  ] PolicyTest.ParseInvalidPolicy (5 ms)
```

### 결과 파싱
```bash
# 실패한 테스트 찾기
grep -E "^\[\s*FAILED\s*\]" test_output.log

# 테스트 수 확인
grep -E "^\[=+\].*tests" test_output.log
```

### JUnit XML 출력
```bash
./build.py --module container-manager --tests --output-junit

# 출력: build/Debug/<component>/junit.xml
```

## 커버리지 분석

### 커버리지 생성
```bash
./build.py --module container-manager --tests --coverage
```

### 커버리지 리포트
```
coverage/<component>/
├── index.html        # HTML 리포트
├── coverage.json     # JSON 데이터
└── ...
```

### 메트릭
- **Function coverage**: 함수 실행 비율
- **Line coverage**: 라인 실행 비율
- **Region coverage**: 코드 영역 커버리지
- **Branch coverage**: 분기 커버리지

## 테스트 디버깅

### 단일 테스트 디버깅
```bash
# 빌드
./build.py --module container-manager --tests-build-only

# gdb로 실행
cd build/Debug/container-manager
gdb ./cm_tests
(gdb) run --gtest_filter=PolicyTest.ParseValidPolicy
```

### 테스트 로그
```bash
# ctest 로그
cat build/Debug/<component>/Testing/Temporary/LastTest.log

# 상세 로그
cat ctest-output.log
```

### 실패 분석
1. 에러 메시지 확인
2. Expected vs Actual 비교
3. 관련 코드 위치 파악
4. Mock 설정 확인

## 테스트 스킵 조건

### 환경 기반 스킵
- 캐시된 결과가 유효할 때 (타임스탬프 기반)
- `ctest-success.log` 존재시

### 강제 재실행
```bash
# 테스트 캐시 삭제
rm -f build/Debug/<component>/ctest-*.log

# 재실행
./build.py --module container-manager --tests
```

## 테스트 Best Practices

### 테스트 작성
- 각 테스트는 독립적으로 실행 가능
- Setup/Teardown 명확히 구분
- Mock 사용으로 외부 의존성 격리

### 테스트 실행
- 변경된 컴포넌트 테스트 우선
- 실패시 상세 로그 확인
- 커버리지로 누락 영역 확인

### CI/CD 통합
```bash
# PR 검증
./build.py --module <component> --tests --output-junit

# 커버리지 리포트
./build.py --module <component> --tests --coverage
```

## Acceptance Criteria 검증

### TC → 테스트 매핑
```markdown
요구사항: [TC-1] 컨테이너 30초 내 시작
테스트: container_startup_tests.cxx::TestStartupTime

요구사항: [TC-2] 헬스체크 통과
테스트: container_health_tests.cxx::TestHealthCheck
```

### 검증 체크리스트
- [ ] 모든 TC에 해당 테스트 존재
- [ ] 테스트 통과 (또는 실패 사유 문서화)
- [ ] 커버리지 목표 달성
- [ ] 엣지 케이스 테스트 포함
