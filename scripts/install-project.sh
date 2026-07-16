#!/bin/bash

# SPEC-HARNESS-KIT Project-Level Installation Script
# Installs agents, rules, and skills locally inside a target project's `.agents/` folder.

set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( dirname "$SCRIPT_DIR" )"

# Default values
SYMLINK_MODE=false
TARGET_DIR=""

show_usage() {
    echo "Usage: $0 [options] [target_project_directory]"
    echo ""
    echo "Options:"
    echo "  -s, --symlink   Use symbolic links instead of copying files (best for development)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "If no target directory is specified, the current directory will be used."
    exit 0
}

# Parse options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--symlink) SYMLINK_MODE=true; shift ;;
        -h|--help) show_usage ;;
        -*) echo -e "${RED}Unknown option: $1${NC}" >&2; show_usage ;;
        *) if [ -z "$TARGET_DIR" ]; then TARGET_DIR="$1"; else echo -e "${RED}Multiple target directories specified.${NC}" >&2; exit 1; fi; shift ;;
    esac
done

# Default to current directory if not specified
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$PWD"
fi

# Convert TARGET_DIR to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   SPEC-HARNESS-KIT Project Local Installer    ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "Target Directory: ${YELLOW}$TARGET_DIR${NC}"
echo -e "Installation Mode: $( $SYMLINK_MODE && echo -e "${GREEN}Symlink Mode (Development)${NC}" || echo -e "${GREEN}Copy Mode (Self-contained)${NC}" )"
echo ""

# Validate target directory
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Target directory does not exist: $TARGET_DIR${NC}" >&2
    exit 1
fi

# Warning if not a git repository or npm project (but still proceed)
if [ ! -d "$TARGET_DIR/.git" ] && [ ! -f "$TARGET_DIR/package.json" ]; then
    echo -e "${YELLOW}Warning: Target directory does not contain .git or package.json.${NC}"
    echo -e "Proceeding with installation anyway..."
    echo ""
fi

# Define local directories under .agents/
AGENTS_DIR="$TARGET_DIR/.agents/agents"
RULES_DIR="$TARGET_DIR/.agents/rules"
SKILLS_DIR="$TARGET_DIR/.agents/skills"
WORKFLOWS_DIR="$TARGET_DIR/.agents/workflows"

# Create directories
mkdir -p "$AGENTS_DIR"
mkdir -p "$RULES_DIR"
mkdir -p "$SKILLS_DIR"
mkdir -p "$WORKFLOWS_DIR"

# Clean up previous symlinks or files that might conflict
echo -e "${BLUE}--- Cleaning up previous target configurations ---${NC}"
rm -rf "$AGENTS_DIR"/*
rm -rf "$RULES_DIR"/*
rm -rf "$SKILLS_DIR"/*
rm -rf "$WORKFLOWS_DIR"/*

# 1. Setup Agents (both as Agents and as Rules for @-mention triggers)
echo -e "\n${BLUE}--- Setting up Local Agents & Rules ---${NC}"
for agent_file in "$REPO_ROOT/agents"/*.md; do
    if [ -f "$agent_file" ]; then
        basename_no_ext=$(basename "$agent_file" .md)
        
        target_md="$AGENTS_DIR/${basename_no_ext}.md"
        target_agent_md="$AGENTS_DIR/${basename_no_ext}.agent.md"
        target_rule_md="$RULES_DIR/${basename_no_ext}.md"
        
        if $SYMLINK_MODE; then
            ln -sf "$agent_file" "$target_md"
            ln -sf "$agent_file" "$target_agent_md"
            ln -sf "$agent_file" "$target_rule_md"
            echo "  Linked agent: ${basename_no_ext} (.md, .agent.md, and rule)"
        else
            cp "$agent_file" "$target_md"
            cp "$agent_file" "$target_agent_md"
            cp "$agent_file" "$target_rule_md"
            echo "  Copied agent: ${basename_no_ext} (.md, .agent.md, and rule)"
        fi
    fi
done

# 2. Setup Rules
echo -e "\n${BLUE}--- Setting up Local Rules ---${NC}"
if $SYMLINK_MODE; then
    for rule_item in "$REPO_ROOT/rules"/*; do
        basename_item=$(basename "$rule_item")
        ln -sfn "$rule_item" "$RULES_DIR/$basename_item"
        echo "  Linked rule/preset: $basename_item"
    done
else
    cp -r "$REPO_ROOT/rules"/* "$RULES_DIR/"
    echo "  Copied rules, tech-presets, and templates to .agents/rules/"
fi

# 3. Setup Skills (Legacy CLI) and Workflows (Antigravity 2.0 / IDE)
echo -e "\n${BLUE}--- Setting up Local Skills & Workflows ---${NC}"

setup_skill() {
    local src_dir=$1
    local name=$2
    
    # 3a. Legacy Skills setup
    if $SYMLINK_MODE; then
        ln -sfn "$src_dir" "$SKILLS_DIR/$name"
        echo "  Linked legacy skill: $name"
    else
        cp -r "$src_dir" "$SKILLS_DIR/"
        echo "  Copied legacy skill: $name"
    fi

    # 3b. Workflows setup (extract SKILL.md to .agents/workflows/<name>.md)
    if [ -f "$src_dir/SKILL.md" ]; then
        if $SYMLINK_MODE; then
            ln -sf "$src_dir/SKILL.md" "$WORKFLOWS_DIR/${name}.md"
            echo "  Linked workflow: ${name}.md"
        else
            cp "$src_dir/SKILL.md" "$WORKFLOWS_DIR/${name}.md"
            echo "  Copied workflow: ${name}.md"
        fi
    fi
}

# Process global skills (excluding projects directory)
for skill_dir in "$REPO_ROOT/skills"/*; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        if [ "$skill_name" != "projects" ]; then
            setup_skill "$skill_dir" "$skill_name"
        fi
    fi
done

# Process project-specific skills
if [ -d "$REPO_ROOT/skills/projects" ]; then
    for skill_dir in "$REPO_ROOT/skills/projects"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            setup_skill "$skill_dir" "$skill_name"
        fi
    done
fi

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}   Installation Completed Successfully!        ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo -e "SPEC-HARNESS-KIT has been configured locally in this project."
echo -e "The Antigravity IDE and CLI will now find all local agents and skills."
echo ""
echo -e "Next steps to verify inside your project:"
echo -e "  1. Run ${YELLOW}agy plugin list${NC} or start Antigravity inside this project."
echo -e "  2. You can trigger agents by using their local personas (e.g. ${YELLOW}@spec-master${NC})."
echo ""
