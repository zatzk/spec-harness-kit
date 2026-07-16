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
CLI_PATHS["pi"]="$HOME/.pi/agent/agents"

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

    # Clean up any obsolete files in the target directory
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
for cli in "gemini" "claude" "codex" "opencode" "pi"; do
    if [ -d "${CLI_PATHS[$cli]}" ] || [ "$cli" = "gemini" ] || [ "$cli" = "claude" ] || [ "$cli" = "pi" ]; then
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
mkdir -p "$HOME/.pi/agent"
ln -sf "$REPO_ROOT/rules/rules.md" "$HOME/.gemini/rules/global-rules.md"
ln -sf "$REPO_ROOT/rules/constitution.md" "$HOME/.gemini/rules/constitution.md"
ln -sf "$REPO_ROOT/rules/rules.md" "$HOME/.antigravity/rules.md"
ln -sf "$REPO_ROOT/rules/rules.md" "$HOME/.pi/agent/append-system.md"

# Skills Setup (Gemini and Pi Specific - Symlinks work for skills)
echo "--- Setting up Global Skills (Gemini & Pi - Symlinking) ---"
mkdir -p "$HOME/.gemini/skills"
mkdir -p "$HOME/.pi/agent/skills"

# Helper function to link a skill
link_skill() {
    local src_dir=$1
    local name=$2
    ln -sfn "$src_dir" "$HOME/.gemini/skills/$name"
    ln -sfn "$src_dir" "$HOME/.pi/agent/skills/$name"
    echo "  Linked skill: $name"
}

# Link global skills (excluding projects directory)
for skill_dir in "$REPO_ROOT/skills"/*; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        if [ "$skill_name" != "projects" ]; then
            link_skill "$skill_dir" "$skill_name"
        fi
    fi
done

# Link project-specific skills
if [ -d "$REPO_ROOT/skills/projects" ]; then
    for skill_dir in "$REPO_ROOT/skills/projects"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            link_skill "$skill_dir" "$skill_name"
        fi
    done
fi

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
fi

# Sync Antigravity IDE Plugin Config (keeps the local-install source in sync with the repo)
echo ""
echo "--- Syncing Antigravity IDE Plugin Config (~/.gemini/config/plugins/spec-harness-kit) ---"
AGY_PLUGIN_DIR="$HOME/.gemini/config/plugins/spec-harness-kit"
if [ -d "$AGY_PLUGIN_DIR" ]; then
    # Sync agents
    cp "$REPO_ROOT/agents/"*.md "$AGY_PLUGIN_DIR/agents/" 2>/dev/null && echo "  Synced agents"
    # Sync skills
    cp -r "$REPO_ROOT/skills/"* "$AGY_PLUGIN_DIR/skills/" 2>/dev/null && echo "  Synced skills"
else
    echo "  Plugin config dir not found at $AGY_PLUGIN_DIR, skipping sync."
fi

echo ""
echo "Done! SPEC-HARNESS-KIT has been successfully installed globally."
echo "Custom @-triggers (.agent.md) and legacy configurations are ready."
