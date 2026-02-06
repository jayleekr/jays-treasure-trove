---
paths:
  - "**/container-manager/**"
  - "**/seccomp/**"
  - "**/*seccomp*"
  - "**/container-app/**"
---

# Container Security Development Rules

## ⚠️ PID 1 Session Leader Issue

### 문제
컨테이너의 PID 1은 항상 **session leader**입니다.
`setsid()` 호출시 **EPERM** 반환 — 이건 seccomp 차단이 아님!

### 해결책
```cpp
pid_t child = fork();
if (child == 0) {
    // 자식 프로세스는 session leader가 아님
    int result = setsid();
    if (result < 0) {
        // 이제 진짜 seccomp 에러 감지 가능
        if (errno == EACCES) {
            // seccomp 차단됨
        }
    }
    _exit(0);
}
waitpid(child, &status, 0);
```

## errno 해석

| errno | 의미 | 원인 |
|-------|------|------|
| `EPERM` | Operation not permitted | Session leader 상태 |
| `EACCES` | Permission denied | **Seccomp 차단** |
| `ENOSYS` | Function not implemented | Syscall 비활성화 |

**중요**: errno는 syscall 직후 즉시 확인! 다른 함수 호출하면 덮어씌워짐.

## Seccomp Profile 구조

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write", "open"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

## 테스트 패턴

```python
# container-manager/test.py 패턴
@test.Case(11584)
class SeccompTest(test.Test):
    def setup(self):
        self.container = start_container_with_seccomp()
    
    def teardown(self):
        self.container.stop()
    
    @test.Step(1)
    def test_blocked_syscall(self):
        result = self.container.exec("test_setsid")
        assert result.errno == errno.EACCES
```

## 보안 체크리스트

- [ ] Fork 기반 syscall 테스트 사용
- [ ] errno 즉시 확인
- [ ] Seccomp profile JSON 검증
- [ ] Container isolation 테스트
- [ ] Capability 제한 확인
