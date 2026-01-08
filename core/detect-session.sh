#!/bin/bash
# Core session type detection for jays-treasure-trove
# Used by ALL projects

detect_session_type() {
  # Priority 1: Explicit environment variable (highest priority)
  if [[ -n "${CLAUDE_SESSION_TYPE:-}" ]]; then
    echo "$CLAUDE_SESSION_TYPE"
    return 0
  fi

  # Priority 2: Hostname pattern detection (most reliable)
  local hostname=$(hostname -s 2>/dev/null || hostname)

  # Builder pattern: builder-kr-*, builder*, *-builder-*
  if [[ "$hostname" =~ ^builder ]] || [[ "$hostname" =~ -builder- ]]; then
    echo "builder"
    return 0
  fi

  # Tester pattern: *-tester-*, ccu2-tester-*, bcu-tester-*
  if [[ "$hostname" =~ -tester- ]]; then
    echo "tester"
    return 0
  fi

  # Priority 3: Build environment markers
  if [[ -n "${YOCTO_SDK:-}" ]] || [[ -n "${OECORE_NATIVE_SYSROOT:-}" ]]; then
    echo "builder"
    return 0
  fi

  # Priority 4: Build tools available
  if command -v bitbake &> /dev/null; then
    echo "builder"
    return 0
  fi

  # Priority 5: Test environment markers
  if [[ -n "${PYTEST_CURRENT_TEST:-}" ]] || [[ -n "${GTEST_OUTPUT:-}" ]]; then
    echo "tester"
    return 0
  fi

  # Default: normal development session (local machine, no build/test capability)
  echo "normal"
  return 0
}

is_builder_session() {
  [[ "$(detect_session_type)" == "builder" ]]
}

is_tester_session() {
  [[ "$(detect_session_type)" == "tester" ]]
}

is_normal_session() {
  [[ "$(detect_session_type)" == "normal" ]]
}

# Export for use in all projects
export -f detect_session_type
export -f is_builder_session
export -f is_tester_session
export -f is_normal_session
