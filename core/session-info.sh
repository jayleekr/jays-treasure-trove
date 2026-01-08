#!/bin/bash
# Display session information

source ~/.claude-config/core/detect-session.sh

show_session_info() {
  local session_type=$(detect_session_type)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Claude Code Session Information"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Session Type: $session_type"
  echo ""

  case "$session_type" in
    builder)
      echo "Capabilities:"
      echo "  ✅ Build execution (Yocto, Make, CMake, etc.)"
      echo "  ✅ Test execution"
      echo "  ✅ Code review and editing"
      echo "  ✅ JIRA integration"
      echo "  ✅ Git operations"
      ;;
    tester)
      echo "Capabilities:"
      echo "  ❌ Build execution (BLOCKED)"
      echo "  ✅ Test execution"
      echo "  ✅ Code review and editing"
      echo "  ✅ JIRA integration"
      echo "  ✅ Git operations"
      ;;
    normal)
      echo "Capabilities:"
      echo "  ❌ Build execution (BLOCKED)"
      echo "  ❌ Test execution (BLOCKED)"
      echo "  ✅ Code review and editing"
      echo "  ✅ JIRA integration"
      echo "  ✅ Git operations"
      echo "  ✅ Documentation"
      ;;
  esac

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

export -f show_session_info
