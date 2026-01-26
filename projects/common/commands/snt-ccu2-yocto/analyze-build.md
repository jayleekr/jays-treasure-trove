---
name: snt-ccu2-yocto:analyze-build
description: "Analyze Yocto build logs and results. Parse errors, warnings, build time, and verify artifacts."
---

# /snt-ccu2-yocto:analyze-build - Build Result Analyzer

빌드 로그 분석 및 결과 리포팅.

## Usage

```bash
# 최신 로그 분석
/snt-ccu2-yocto:analyze-build --latest

# 특정 로그 파일 분석
/snt-ccu2-yocto:analyze-build claudedocs/build-logs/build_20260108_120000.log

# 백그라운드 빌드 결과 분석
/snt-ccu2-yocto:analyze-build --task-id <task_id>
```

## Analysis Features

### 1. Build Status Detection

```
빌드 상태 판단:
├── SUCCESS: "Build completed" 또는 exit code 0
├── FAILED: "ERROR:" 패턴 또는 non-zero exit
└── PARTIAL: 일부 모듈만 성공
```

### 2. Error Extraction

```
에러 패턴 추출:
├── bitbake 에러: "ERROR: Task ... failed"
├── 컴파일 에러: "error:" (GCC/Clang)
├── 링크 에러: "undefined reference"
├── fetch 에러: "Fetcher failure"
└── recipe 에러: "ParseError"
```

### 3. Warning Analysis

```
경고 분류:
├── Deprecation warnings
├── Compiler warnings (-W*)
├── QA warnings (do_package_qa)
└── License warnings
```

### 4. Build Time Analysis

```
빌드 시간 분석:
├── Total duration
├── Per-task breakdown
└── Bottleneck identification
```

### 5. Artifact Verification

```
아티팩트 검증:
├── Image files (.wic.xz, .tar.gz)
├── Kernel/DTB
├── Deploy directory structure
└── File sizes and checksums
```

## Output Format

```markdown
## Build Analysis Report

### Summary
| Item | Value |
|------|-------|
| Status | SUCCESS / FAILED |
| Duration | 1h 30m 45s |
| Errors | 0 |
| Warnings | 12 |

### Errors (if any)
1. ERROR: linux-s32-5.10.0+gitAUTOINC+...: do_compile failed
   - Root cause: Missing kernel config
   - Suggestion: Check kernel defconfig

### Warnings
- QA warnings: 5
- Compiler warnings: 7

### Artifacts
| File | Size | Status |
|------|------|--------|
| fsl-image-ccu2-mobisccu2.wic.xz | 450MB | OK |
| fsl-image-ccu2-mobisccu2.tar.gz | 1.2GB | OK |

### Recommendations
- Consider fixing QA warnings in next iteration
- Build time can be reduced by using sstate-cache
```

## Log Patterns

### Error Detection Regex

```python
error_patterns = [
    r"ERROR: .*",
    r"error: .*",
    r"FAILED: .*",
    r"fatal: .*",
    r"undefined reference to.*",
    r"Fetcher failure.*",
    r"ParseError.*",
]
```

### Success Detection

```python
success_patterns = [
    r"\[SUCCESS\] Build completed",
    r"Build Configuration:",
    r"NOTE: Tasks Summary:.*succeeded",
]
```

## Integration with Background Builds

### Check Background Build Status

```python
# 1. 빌드가 백그라운드로 실행 중인 경우
TaskOutput(task_id="...", block=False)

# 2. 완료 후 분석
/snt-ccu2-yocto:analyze-build --latest
```

### Log File Locations

```
claudedocs/build-logs/
├── build_YYYYMMDD_HHMMSS.log    # Standard build logs
├── test_YYYYMMDD_HHMMSS.log     # Test logs
└── init_YYYYMMDD_HHMMSS.log     # Init logs
```

## Claude Execution Pattern

When analyzing builds, Claude should:

```python
# 1. Find latest log file
logs = Glob("claudedocs/build-logs/build_*.log")
latest_log = logs[-1]  # Most recent

# 2. Read and parse log
log_content = Read(latest_log)

# 3. Extract key information
- Search for "ERROR:" lines
- Search for "WARNING:" lines
- Search for "SUCCESS" or "FAILED"
- Extract build duration

# 4. Check artifacts
artifacts = Bash("ls -la mobis/deploy/")

# 5. Generate report
```

## Example Analysis

### Input: Build Log

```
[INFO] Starting build...
[STEP] Build scope: FULL
...
NOTE: Executing Tasks
NOTE: Tasks Summary: Attempted 1234 tasks of which 1200 didn't need to be rerun and all succeeded.
[SUCCESS] Build completed in 1h 30m
```

### Output: Analysis Report

```markdown
## Build Analysis Report

### Summary
| Item | Value |
|------|-------|
| Status | SUCCESS |
| Duration | 1h 30m |
| Tasks | 1234 attempted, 1200 cached |
| Errors | 0 |

### Artifacts Verified
- fsl-image-ccu2-mobisccu2.wic.xz (450MB)
- fsl-image-ccu2-mobisccu2.tar.gz (1.2GB)

### Next Steps
- Run /snt-ccu2-yocto:test for validation
- Or flash to target board
```

## Boundaries

**Will:**
- 빌드 로그 파싱 및 분석
- 에러/경고 추출 및 분류
- 아티팩트 검증
- 분석 리포트 생성

**Will Not:**
- 빌드 자체 실행 (use /snt-ccu2-yocto:build)
- 에러 자동 수정
- 프로덕션 배포
