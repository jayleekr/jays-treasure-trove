#!/bin/bash
# SuperClaude One-Line Installer
# Usage: curl -sSL https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/install-superclaude.sh | bash

set -e

echo "🚀 Installing SuperClaude..."

# Create .claude directory if it doesn't exist
mkdir -p ~/.claude

# Download all SuperClaude files
SUPERCLAUDE_FILES=(
    "CLAUDE.md"
    "COMMANDS.md"
    "FLAGS.md"
    "PRINCIPLES.md"
    "RULES.md"
    "MCP.md"
    "PERSONAS.md"
    "ORCHESTRATOR.md"
    "MODES.md"
)

# Base URL for SuperClaude files (you can host these in your repo)
BASE_URL="https://raw.githubusercontent.com/jayleekr/jays-treasure-trove/main/superclaude"

for file in "${SUPERCLAUDE_FILES[@]}"; do
    echo "📥 Downloading $file..."
    curl -sSL "$BASE_URL/$file" -o ~/.claude/"$file"
done

echo "✅ SuperClaude installed successfully!"
echo "📍 Location: ~/.claude/"
echo "🎯 SuperClaude is now active in all your Claude Code sessions!"