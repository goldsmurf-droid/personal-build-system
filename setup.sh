#!/bin/bash
# setup.sh — bootstrap personal-build-system
# Run once on a new machine after cloning, or to initialize from scratch.
# Usage: bash setup.sh [--remote git@github.com:YOU/personal-build-system.git]

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$HOME/projects"

echo "=== personal-build-system setup ==="
echo ""

# 1. Create projects directory structure
echo "→ Creating ~/projects structure..."
mkdir -p "$PROJECTS_DIR/active"
mkdir -p "$PROJECTS_DIR/archive"
echo "  ~/projects/active/   (in-flight projects)"
echo "  ~/projects/archive/  (completed or abandoned)"
echo ""

# 2. Verify Python version
echo "→ Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 11 ]); then
  echo "  WARNING: Python $PYTHON_VERSION found. Python 3.11+ required."
  echo "  Install 3.11+ before building projects."
else
  echo "  Python $PYTHON_VERSION — OK"
fi
echo ""

# 3. Check for Claude Code
echo "→ Checking for Claude Code..."
if command -v claude &> /dev/null; then
  echo "  claude found at $(which claude) — OK"
else
  echo "  WARNING: 'claude' not found in PATH."
  echo "  Install Claude Code: https://docs.claude.ai/claude-code"
fi
echo ""

# 4. Initialize git if not already a repo
echo "→ Checking git status of this directory..."
if [ -d "$REPO_DIR/.git" ]; then
  echo "  Already a git repo — skipping init"
else
  echo "  Initializing git repo..."
  git init "$REPO_DIR"
  git -C "$REPO_DIR" add .
  git -C "$REPO_DIR" commit -m "init: personal-build-system"
  echo "  Git repo initialized and initial commit created."
fi
echo ""

# 5. Optionally add remote
if [ "$1" = "--remote" ] && [ -n "$2" ]; then
  echo "→ Adding remote origin: $2"
  git -C "$REPO_DIR" remote add origin "$2" 2>/dev/null || \
    git -C "$REPO_DIR" remote set-url origin "$2"
  echo "  To push: git push -u origin main"
  echo ""
fi

# 6. Remind about infra-defaults
echo "→ Action required: fill out infra-defaults.md"
echo "  Open $REPO_DIR/infra-defaults.md and add your machine inventory,"
echo "  VM details, and git remote preferences. The spec builder reads this."
echo ""

echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Fill out infra-defaults.md with your machine and VM details"
echo "  2. Create a Claude Project and paste spec-builder-prompt.md as the system prompt"
echo "  3. Start a new project: open Claude, drop your idea"
echo "  4. Save the output SPEC.md to ~/projects/active/<slug>/SPEC.md"
echo "  5. cd into it, run: claude \"Read SPEC.md and build this. Write assumptions to claude.md.\""
echo ""
echo "  Full instructions: README.md"
