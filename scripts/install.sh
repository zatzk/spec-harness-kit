#!/bin/bash

# SPEC-HARNESS-KIT Global Agents Installation Script
# Centralized installation for Antigravity CLI Plugin, legacy AI CLIs, and global @-triggers

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$SCRIPT_DIR" )"

# Define Legacy CLI Global Agent Directories
declare -A CLI_PATHS
CLI_PATHS["gemini"]="$HOME/.gemini/agents"
CLI_PATHS["claude"]="$HOME/.claude/agents"
CLI_PATHS["codex"]="$HOME/.codex/agents"
CLI_PATHS["opencode"]="$HOME/.config/opencode/agent"

# Define Antigravity-specific Agent Directories (requires .agent.md suffix)
declare -A AGY_PATHS
AGY_PATHS["antigravity_gemini"]="$HOME/.gemini/antigravity/agents"
AGY_PATHS["antigravity_legacy"]="$HOME/.antigravity/agents"

# Function to copy assets
copy_agents() {
    local cli_name=$1
    local target_dir=$2
    local suffix=$3

    echo "--- Setting up $cli_name (Copying Agents to $target_dir) ---"
    mkdir -p "$target_dir"

    # Clean up any obsolete aiox/synkra files in the target directory
    rm -f "$target_dir"/aiox-*
    rm -f "$target_dir"/synkra-*
    rm -f "$target_dir"/spec-harness-kit-master*

    # Copy Agents
    for agent_file in "$REPO_ROOT/agents"/*.md; do
        basename_no_ext=$(basename "$agent_file" .md)
        filename="${basename_no_ext}${suffix}"
        target_path="$target_dir/$filename"
        
        # IMPORTANT: Remove the target if it exists (especially if it is a symlink)
        rm -f "$target_path"
        cp "$agent_file" "$target_path"
        echo "  Copied agent: $filename"
    done
}

# Execute Copying for legacy CLIs (.md suffix)
for cli in "gemini" "claude" "codex" "opencode"; do
    if [ -d "${CLI_PATHS[$cli]}" ] || [ "$cli" = "gemini" ] || [ "$cli" = "claude" ]; then
        copy_agents "$cli" "${CLI_PATHS[$cli]}" ".md"
    fi
done

# Execute Copying for Antigravity CLIs (.agent.md suffix)
for cli in "antigravity_gemini" "antigravity_legacy"; do
    copy_agents "$cli" "${AGY_PATHS[$cli]}" ".agent.md"
done

# Rules Setup (Symlinks for Legacy Gemini Rules)
echo "--- Setting up Global Rules (Symlinking) ---"
mkdir -p "$HOME/.gemini/rules"
mkdir -p "$HOME/.antigravity"
ln -sf "$REPO_ROOT/rules/rules.md" "$HOME/.gemini/rules/global-rules.md"
ln -sf "$REPO_ROOT/rules/constitution.md" "$HOME/.gemini/rules/constitution.md"
ln -sf "$REPO_ROOT/rules/rules.md" "$HOME/.antigravity/rules.md"

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

# Native Antigravity CLI Plugin Installation (for tools/skills/templates)
echo "--- Setting up Antigravity CLI (Native Plugin) ---"
if command -v agy >/dev/null 2>&1; then
    echo "Found Antigravity CLI ('agy'). Installing plugin locally..."
    agy plugin install "$REPO_ROOT"
    echo ""
    echo "Verifying registered plugins:"
    agy plugin list
else
    echo "Antigravity CLI ('agy') command not found."
    echo "If you have installed 'agy', please make sure it is in your PATH."
    echo "Staging symlink manually at ~/.gemini/config/plugins/spec-harness-kit for future use..."
    mkdir -p "$HOME/.gemini/config/plugins"
    ln -sfn "$REPO_ROOT" "$HOME/.gemini/config/plugins/spec-harness-kit"
fi

echo ""
echo "Done! SPEC-HARNESS-KIT has been successfully installed globally."
echo "Custom @-triggers (.agent.md) and legacy configurations are ready."
