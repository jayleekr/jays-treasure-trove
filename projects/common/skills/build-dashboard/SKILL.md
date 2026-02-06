---
name: build-dashboard
description: Track and display build status across all servers and recent builds. Use for build monitoring and status checks.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash(ls *), Bash(cat *), Bash(find *), Bash(ssh *)
---

# Build Dashboard

전체 빌드 상태 대시보드.

## 📊 Active Builds

!`find claudedocs/build-logs -name "*.status" -mmin -60 2>/dev/null | while read f; do
  status=$(grep "^STATUS=" "$f" 2>/dev/null | cut -d= -f2)
  [ "$status" = "RUNNING" ] && cat "$f" | grep -E "^(STARTED|TYPE|TIER|STATUS)" | tr '\n' ' ' && echo ""
done || echo "No active builds"`

## ✅ Recent Completions (Last 24h)

!`find claudedocs/build-logs -name "*.status" -mtime -1 2>/dev/null | while read f; do
  status=$(grep "^STATUS=" "$f" 2>/dev/null | cut -d= -f2)
  if [ "$status" = "SUCCESS" ] || [ "$status" = "FAILED" ]; then
    name=$(basename "$f" .status)
    echo "$status: $name"
  fi
done | tail -10 || echo "No recent builds"`

## 🖥️ Server Status

!`for h in ccu2-builder yocto-builder test-runner; do
  echo -n "$h: "
  ssh -o ConnectTimeout=2 -o BatchMode=yes "$h" "uptime 2>/dev/null | awk '{print \$3,\$4,\$5}'" 2>/dev/null || echo "OFFLINE"
done`

## 📁 Build Artifacts

**Yocto (MOBIS)**:
!`ls -lh ~/CCU_GEN2.0_SONATUS.manifest/mobis/deploy/*.tar.gz 2>/dev/null | tail -3 | awk '{print $9, $5, $6, $7}' || echo "No artifacts"`

**Host Build**:
!`ls -lh ~/ccu-2.0/build/Debug/*/lib*.a 2>/dev/null | tail -5 | awk '{print $9, $5}' || echo "No artifacts"`

## Usage

```bash
# 대시보드 조회
/build-dashboard

# 특정 빌드 상태 확인
/build-dashboard container-manager
```

## Actions

- **빌드 시작**: `/snt-ccu2-yocto:build` 또는 `/snt-ccu2-host:build`
- **로그 분석**: `/snt-ccu2-yocto:analyze-build`
- **리모트 빌드**: `/remote-build <module> on <server>`
