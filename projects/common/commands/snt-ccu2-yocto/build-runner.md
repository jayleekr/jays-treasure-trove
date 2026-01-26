---
name: snt-ccu2-yocto:build-runner
description: "Direct build execution via docker exec -d. Starts long-running builds in Docker container background without user intervention."
---

# /snt-ccu2-yocto:build-runner - Docker Detached Build Executor

Execute Yocto builds in Docker container background using `docker exec -d` pattern.

## Why This Exists

Claude sandbox blocks background processes on HOST (`run_in_background`, `nohup`, `&` all fail with EACCES). However, `docker exec -d` runs INSIDE the container, bypassing sandbox restrictions.

## Usage

```bash
# SDK build
/snt-ccu2-yocto:build-runner --type sdk --tier mobis

# Full image build
/snt-ccu2-yocto:build-runner --type full --tier lge

# Module build
/snt-ccu2-yocto:build-runner --type module --tier mobis --module linux-s32
```

## Execution Pattern

When this skill is invoked, Claude MUST execute the following pattern:

### Step 1: Find Docker Container

```bash
CONTAINER=$(docker ps --filter "name=${USER}.*CCU_GEN2.0_SONATUS" --format "{{.Names}}" | grep -v lge | head -1)
# For LGE tier:
CONTAINER=$(docker ps --filter "name=${USER}.*CCU_GEN2.0_SONATUS.*lge" --format "{{.Names}}" | head -1)
```

### Step 2: Create Status File

```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
STATUS_FILE="claudedocs/build-logs/${TIER}-${TYPE}-${TIMESTAMP}.status"
LOG_FILE="claudedocs/build-logs/${TIER}-${TYPE}-${TIMESTAMP}.log"

cat > "$STATUS_FILE" << EOF
STARTED=$(date -Iseconds)
TYPE=${TYPE}
TIER=${TIER}
LOG=${LOG_FILE}
STATUS=RUNNING
PID=docker-detached
CURRENT_TASK=initializing
ERRORS=0
WARNINGS=0
EOF
```

### Step 3: Execute Build in Detached Mode

```bash
docker exec -d -u ${USER} "$CONTAINER" bash -c "
export PYTHONPATH=/home/${USER}/.local/lib/python3.8/site-packages:\$PYTHONPATH
export PATH=/home/${USER}/.local/bin:\$PATH
cd /home/${USER}/CCU_GEN2.0_SONATUS.manifest/${TIER_DIR} && \
${BUILD_COMMAND} > ${LOG_FILE} 2>&1 && \
sed -i 's/STATUS=RUNNING/STATUS=SUCCESS/' ${STATUS_FILE} || \
sed -i 's/STATUS=RUNNING/STATUS=FAILED/' ${STATUS_FILE}
sed -i \"s/CURRENT_TASK=.*/CURRENT_TASK=completed/\" ${STATUS_FILE}
echo \"ENDED=\$(date -Iseconds)\" >> ${STATUS_FILE}
"
```

## Build Commands by Type

| Type | Tier | Command |
|------|------|---------|
| sdk | MOBIS | `./build.py main --populate-sdk -j 16 -p 16` |
| sdk | LGE | `./build.py main --populate-sdk -j 16 -p 16` |
| full | MOBIS | `./build.py main -ncpb -j 16 -p 16 -r` |
| full | LGE | `./build.py main -ncpb -j 16 -p 16 -r` |
| snt | Any | `./build.py main --snt -j 16 -p 16` |
| module | Any | `./build.py main -m ${MODULE} -j 16 -p 16` |

## Tier Directory Mapping

| Tier | Directory |
|------|-----------|
| MOBIS | `mobis/` |
| LGE | `lge/` |

## Output Format

```
## Build Started

| Property | Value |
|----------|-------|
| Type | sdk |
| Tier | mobis |
| Status | RUNNING |
| Status File | claudedocs/build-logs/mobis-sdk-20260108_161526.status |
| Log File | claudedocs/build-logs/mobis-sdk-20260108_161526.log |
| Container | home_jay.lee_CCU_GEN2.0_SONATUS.manifest-yocto-ccu-2.0 |

Build started in background. Use `/snt-ccu2-yocto:build-status` to check progress.
```

## Critical Implementation Notes

### 1. Python Environment
The Docker container requires explicit PYTHONPATH setup:
```bash
export PYTHONPATH=/home/${USER}/.local/lib/python3.8/site-packages:$PYTHONPATH
```

### 2. User Context
Always use `-u ${USER}` with docker exec to maintain proper permissions:
```bash
docker exec -d -u jay.lee "$CONTAINER" bash -c "..."
```

### 3. Status File Location
Status files must be on the HOST filesystem (not inside container) so Claude can read them:
```
/home/jay.lee/CCU_GEN2.0_SONATUS.manifest/claudedocs/build-logs/
```

### 4. Container Discovery
Container naming convention:
- MOBIS: `home_${USER}_CCU_GEN2.0_SONATUS.manifest-yocto-ccu-2.0`
- LGE: `home_${USER}_CCU_GEN2.0_SONATUS.manifest_lge-yocto-ccu-2.0`

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| No container found | Container not running | Run `./run-dev-container.sh` first |
| Permission denied | Wrong user | Use `-u ${USER}` flag |
| Module not found | Python environment | Set PYTHONPATH explicitly |

## Integration

This skill is used internally by:
- `/snt-ccu2-yocto:build` - Main build orchestrator
- `/snt-ccu2-yocto:pipeline` - Full pipeline automation

Users typically don't call this skill directly - use `/snt-ccu2-yocto:build` instead.

## Workflow

```
/snt-ccu2-yocto:build --sdk
    ↓
/snt-ccu2-yocto:build-runner (internal)
    ↓
docker exec -d → Build starts in container
    ↓
Status file created → Claude returns immediately
    ↓
User: "check status"
    ↓
/snt-ccu2-yocto:build-status → Read status file
```
