#!/bin/bash

# AIOX Global Agents Installation Script
# Maps centralized agents/rules to various AI CLIs

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$SCRIPT_DIR" )"

# Define CLI Global Agent Directories
declare -A CLI_PATHS
CLI_PATHS["gemini"]="$HOME/.gemini/agents"
CLI_PATHS["claude"]="$HOME/.claude/agents"
CLI_PATHS["antigravity"]="$HOME/.antigravity/agents"
CLI_PATHS["codex"]="$HOME/.codex/agents"
CLI_PATHS["opencode"]="$HOME/.config/opencode/agent"

# Function to copy assets (Agents require direct files in some CLIs)
copy_agents() {
    local cli_name=$1
    local target_dir=$2

    echo "--- Setting up $cli_name (Copying Agents) ---"
    mkdir -p "$target_dir"

    # Copy Agents
    for agent_file in "$REPO_ROOT/agents"/*.md; do
        filename=$(basename "$agent_file")
        target_path="$target_dir/$filename"
        
        # IMPORTANT: Remove the target if it exists (especially if it is a symlink)
        # cp -f follows symlinks, but we want to REPLACE symlinks with actual files.
        rm -f "$target_path"
        cp "$agent_file" "$target_path"
        echo "  Copied agent: $filename"
    done
}

# Execute Copying for Agents
for cli in "gemini" "claude" "antigravity" "codex" "opencode"; do
    copy_agents "$cli" "${CLI_PATHS[$cli]}"
done

# Rules Setup (Symlinks usually fine here)
echo "--- Setting up Global Rules (Symlinking) ---"
mkdir -p "$HOME/.gemini/rules"
mkdir -p "$HOME/.antigravity"
ln -sf "$REPO_ROOT/rules/rules.md" "$HOME/.gemini/rules/global-rules.md"
ln -sf "$REPO_ROOT/rules/rules.md" "$HOME/.antigravity/rules.md"
ln -sf "$REPO_ROOT/rules/constitution.md" "$HOME/.gemini/rules/constitution.md"

# Skills Setup (Gemini Specific - Symlinks work for skills)
echo "--- Setting up Global Skills (Gemini - Symlinking) ---"
mkdir -p "$HOME/.gemini/skills"
for skill_dir in "$REPO_ROOT/skills"/*; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        ln -sfn "$skill_dir" "$HOME/.gemini/skills/$skill_name"
        echo "  Linked skill: $skill_name"
    fi
done

echo ""
echo "Done! AIOX Global Agents are now available across all your CLIs."
echo "Note: Agents were COPIED to ensure compatibility. If you modify agents in the repo,"
echo "      please re-run this script to update your CLIs."
