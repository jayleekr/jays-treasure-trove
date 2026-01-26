---
name: snt-ccu2-yocto:build-status
description: "Quick build status check (~200 tokens). Reads status files for efficient progress monitoring without loading full logs."
---

# /snt-ccu2-yocto:build-status - Quick Status Check

Token-efficient build status monitoring for the Fire-and-Monitor pattern.

## Usage

```bash
# Check latest build status
/snt-ccu2-yocto:build-status

# Check specific tier
/snt-ccu2-yocto:build-status --tier mobis

# Check specific build
/snt-ccu2-yocto:build-status <status-file>
```

## Purpose

This skill provides quick (~200 token) status checks by reading small status files instead of parsing multi-MB log files. Use this for efficient progress monitoring during long-running builds.

## Token Efficiency

| Operation | Tokens |
|-----------|--------|
| Status check | ~200 |
| Full log analysis | ~15K |
| **Savings** | **98.7%** |

## Execution Pattern

When this skill is invoked, Claude MUST:

1. **Find status file** (~100 tokens):
```bash
# Find latest status file
ls -t claudedocs/build-logs/*.status 2>/dev/null | head -1
```

2. **Read status file** (~50 tokens):
```bash
# Read status (10 lines max)
cat <status-file>
```

3. **Report** (~50 tokens):
```
Build: mobis-sdk-20260108_150000
├── Status: RUNNING (42 min elapsed)
├── Current: do_compile (rocksdb)
├── Errors: 0
└── Warnings: 12
```

## Status File Format

Status files are created by `/snt-ccu2-yocto:build` (via docker exec -d) and contain:

```ini
STARTED=2026-01-08T15:00:00+09:00
TYPE=sdk
TIER=mobis
LOG=claudedocs/build-logs/mobis-sdk-20260108_150000.log
STATUS=RUNNING
PID=docker-detached
CURRENT_TASK=do_compile:rocksdb
ERRORS=0
WARNINGS=12
ENDED=
```

## Status Values

| Status | Meaning | Action |
|--------|---------|--------|
| `INITIALIZING` | Build starting | Wait |
| `RUNNING` | Build in progress | Check again later |
| `SUCCESS` | Build completed | Run `/snt-ccu2-yocto:analyze-build` |
| `FAILED` | Build failed | Run `/snt-ccu2-yocto:analyze-build` |
| `WAITING_DOCKER` | Needs Docker container | Guide user to run in container |
| `DRY_RUN` | Dry run completed | Review commands |

## Output Format

### Running Build
```
## Build Status: mobis-sdk-20260108

| Property | Value |
|----------|-------|
| Status | RUNNING |
| Type | sdk |
| Tier | mobis |
| Elapsed | 42 min |
| Current | do_compile:rocksdb |
| Errors | 0 |
| Warnings | 12 |

Build is in progress. Check again later or wait for completion.
```

### Completed Build
```
## Build Status: mobis-sdk-20260108

| Property | Value |
|----------|-------|
| Status | SUCCESS |
| Type | sdk |
| Tier | mobis |
| Duration | 2h 15m |
| Errors | 0 |
| Warnings | 45 |

Build completed successfully.
Run `/snt-ccu2-yocto:analyze-build --latest` for detailed analysis.
```

### Failed Build
```
## Build Status: mobis-full-20260108

| Property | Value |
|----------|-------|
| Status | FAILED |
| Type | full |
| Tier | mobis |
| Duration | 45 min |
| Errors | 3 |
| Warnings | 28 |

Build failed. Run `/snt-ccu2-yocto:analyze-build --latest` for error details.
```

### No Active Build
```
## Build Status

No active or recent builds found.

To start a build, ask Claude:
- "Build MOBIS SDK"
- "/snt-ccu2-yocto:build --sdk --tier mobis"

Then check status with: /snt-ccu2-yocto:build-status
```

## Workflow Integration

### Docker Detached Mode Pattern (Fully Automated)

```
1. User requests build (Claude session):
   User: "Build MOBIS SDK"
   Claude: /snt-ccu2-yocto:build --sdk → docker exec -d (background)
   → "Build started, status file: claudedocs/build-logs/..."

2. User checks status:
   User: "Check build status"
   Claude: /snt-ccu2-yocto:build-status
   → "RUNNING, 45 min, 0 errors" (~200 tokens)

3. User checks again later:
   User: "Check build status"
   Claude: /snt-ccu2-yocto:build-status
   → "SUCCESS, 2h 15m, 0 errors" (~200 tokens)

4. User requests analysis:
   User: "Analyze the build"
   Claude: /snt-ccu2-yocto:analyze-build --latest
   → Detailed error/warning analysis (~2K tokens)
```

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  CLAUDE SESSION (Single Session Control)                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐        │
│  │ /build --sdk │────▶│ docker exec  │────▶│   Docker     │        │
│  │              │     │     -d       │     │  Container   │        │
│  └──────────────┘     └──────────────┘     └──────────────┘        │
│         │                                         │                  │
│         ▼                                         ▼                  │
│  ┌──────────────┐                      ┌──────────────────┐         │
│  │ Status File  │◄─────────────────────│  Background      │         │
│  │ (10 lines)   │                      │  Yocto Build     │         │
│  └──────────────┘                      └──────────────────┘         │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐        │
│  │ /build-status│────▶│ Read Status  │────▶│   Report     │        │
│  │ (~200 tokens)│     │ (10 lines)   │     │  to User     │        │
│  └──────────────┘     └──────────────┘     └──────────────┘        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Boundaries

**Will:**
- Read status files for quick progress reports
- Calculate elapsed/total build time
- Report error/warning counts
- Guide to next actions

**Will Not:**
- Parse full log files (use `/snt-ccu2-yocto:analyze-build`)
- Start or stop builds
- Modify build configuration
- Access Docker container directly

## Related Skills

| Skill | Purpose |
|-------|---------|
| `/snt-ccu2-yocto:build` | Start and configure builds |
| `/snt-ccu2-yocto:analyze-build` | Detailed log analysis |
| `/snt-ccu2-yocto:pipeline` | Full pipeline orchestration |
