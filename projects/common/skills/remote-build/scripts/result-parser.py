#!/usr/bin/env python3
"""
Parse Claude Code JSON output from remote execution.

Usage:
    ssh server "claude -p '...' --output-format json" | ./result-parser.py
    cat result.json | ./result-parser.py
"""

import json
import sys
from typing import Any

def parse_claude_output(json_str: str) -> dict[str, Any]:
    """Parse Claude Code JSON output into structured result."""
    try:
        data = json.loads(json_str)
    except json.JSONDecodeError as e:
        return {
            "status": "error",
            "error": f"JSON parse error: {e}",
            "raw": json_str[:500]
        }
    
    # Extract key fields
    result = {
        "status": "success" if data.get("result") else "unknown",
        "result": data.get("result", ""),
        "session_id": data.get("session_id", ""),
        "model": data.get("model", ""),
        "cost": 0.0,
        "tokens": {
            "input": 0,
            "output": 0,
            "total": 0
        }
    }
    
    # Parse usage if available
    usage = data.get("usage", {})
    if usage:
        result["tokens"] = {
            "input": usage.get("input_tokens", 0),
            "output": usage.get("output_tokens", 0),
            "total": usage.get("total_tokens", 0)
        }
        
        # Estimate cost (Claude Sonnet pricing)
        input_cost = result["tokens"]["input"] * 0.003 / 1000
        output_cost = result["tokens"]["output"] * 0.015 / 1000
        result["cost"] = round(input_cost + output_cost, 4)
    
    # Check for errors in result
    result_text = result["result"].lower()
    if any(word in result_text for word in ["error", "failed", "failure"]):
        result["status"] = "failed"
    elif any(word in result_text for word in ["success", "passed", "complete"]):
        result["status"] = "success"
    
    return result


def format_report(parsed: dict[str, Any]) -> str:
    """Format parsed result into human-readable report."""
    status_emoji = {
        "success": "✅",
        "failed": "❌",
        "error": "🚨",
        "unknown": "❓"
    }
    
    emoji = status_emoji.get(parsed["status"], "❓")
    
    report = f"""
## {emoji} Build Result

**Status**: {parsed["status"].upper()}
**Session ID**: {parsed["session_id"] or "N/A"}
**Model**: {parsed["model"] or "N/A"}

### Token Usage
- Input: {parsed["tokens"]["input"]:,}
- Output: {parsed["tokens"]["output"]:,}
- Total: {parsed["tokens"]["total"]:,}
- Est. Cost: ${parsed["cost"]:.4f}

### Result
{parsed["result"][:2000]}
"""
    return report.strip()


def main():
    # Read from stdin
    input_data = sys.stdin.read().strip()
    
    if not input_data:
        print("Error: No input provided", file=sys.stderr)
        sys.exit(1)
    
    # Parse
    parsed = parse_claude_output(input_data)
    
    # Output options
    if "--json" in sys.argv:
        print(json.dumps(parsed, indent=2))
    elif "--report" in sys.argv:
        print(format_report(parsed))
    else:
        # Default: JSON
        print(json.dumps(parsed, indent=2))


if __name__ == "__main__":
    main()
