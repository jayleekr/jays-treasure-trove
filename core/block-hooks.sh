#!/bin/bash
# Core hook blocking system for jays-treasure-trove
# Used by ALL projects

source ~/.claude-config/core/detect-session.sh

# Default blocked patterns (can be extended per project)
CORE_BLOCKED_PATTERNS=(
  "build.sh"
  "build.py"
  "make"
  "cmake"
  "bitbake"
  "yocto"
  "ninja"
  "gcc"
  "g++"
  "clang"
  "pytest"
  "gtest"
  "ctest"
  "test"
  "compile"
)

is_build_command() {
  local cmd=$1
  local session_type=$(detect_session_type)

  # Builders can execute anything
  if [[ "$session_type" == "builder" ]]; then
    return 1  # Not blocked
  fi

  # Testers can execute tests but not builds
  if [[ "$session_type" == "tester" ]]; then
    # Check if it's a build command
    for pattern in "build" "make" "cmake" "bitbake" "compile" "gcc" "g++" "clang"; do
      if [[ "$cmd" == *"$pattern"* ]]; then
        return 0  # Blocked
      fi
    done
    return 1  # Test commands allowed
  fi

  # Normal sessions: block all build and test commands
  for pattern in "${CORE_BLOCKED_PATTERNS[@]}"; do
    if [[ "$cmd" == *"$pattern"* ]]; then
      return 0  # Blocked
    fi
  done

  return 1  # Not blocked
}

block_execution_if_needed() {
  local cmd=$1
  local session_type=$(detect_session_type)

  if is_build_command "$cmd"; then
    echo "🚫 EXECUTION BLOCKED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Command: $cmd"
    echo "Session Type: $session_type"
    echo ""
    echo "This command is blocked in current session type."
    echo ""

    if [[ "$session_type" == "normal" ]]; then
      echo "Available options:"
      echo "  1. Use CI/CD (Jenkins) for builds/tests"
      echo "  2. Switch to Builder environment: export CLAUDE_SESSION_TYPE=builder"
      echo "  3. Continue with code review/JIRA integration"
    elif [[ "$session_type" == "tester" ]]; then
      echo "Tester sessions can run tests but not builds."
      echo "Switch to Builder: export CLAUDE_SESSION_TYPE=builder"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 1
  fi

  return 0
}

export -f is_build_command
export -f block_execution_if_needed
