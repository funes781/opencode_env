#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

INSTALL_DIR="$(pwd)"
WORKFLOW_DIR="$INSTALL_DIR/.opencode-workflow"
WORKFLOW_FILE="$WORKFLOW_DIR/workflow.md"
PLANS_DIR="$WORKFLOW_DIR/plans"
PLAN_FILE="$PLANS_DIR/plan.md"
CHANGES_DIR="$WORKFLOW_DIR/changes"
CHANGES_FILE="$CHANGES_DIR/changes.md"
SKILLS_CONFIG_FILE="$INSTALL_DIR/skills-config.json"
SKILL_MANAGER_FILE="$INSTALL_DIR/scripts/manager.sh"
MANAGER_LINK="/usr/local/bin/manager"
SKILLMANAGER_LINK="/usr/local/bin/skillmanager"
CONFIG_FILE="$INSTALL_DIR/opencode.json"
RAW_URL="https://raw.githubusercontent.com/funes781/opencode_env/main"

echo -e "${BOLD}Installing OpenCode workflow...${NC}"

check_opencode() {
  local found=0
  if command -v opencode &>/dev/null; then
    found=1
  elif [ -x "$HOME/.opencode/bin/opencode" ]; then
    found=1
    export PATH="$HOME/.opencode/bin:$PATH"
  fi
  if [ "$found" -eq 1 ]; then
    echo -e "  ${GREEN}✔${NC} OpenCode CLI found"
    return
  fi
  echo ""
  echo -e "  ${YELLOW}OpenCode CLI is not installed. It is required.${NC}"
  read -r -p "  Install OpenCode now? [Y/n] " response
  case "${response:-Y}" in
    [Yy]*|"")
      echo -e "  ${CYAN}→${NC} Installing OpenCode..."
      if curl -fsSL https://opencode.ai/install | bash; then
        echo -e "  ${GREEN}✔${NC} OpenCode installed"
        if [ -x "$HOME/.opencode/bin/opencode" ]; then
          export PATH="$HOME/.opencode/bin:$PATH"
        fi
      else
        echo -e "  ${RED}✖${NC} Installation failed. Manual: https://opencode.ai/install"
      fi
      ;;
    *)
      echo -e "  ${YELLOW}⚠${NC} Skipping. Manual: https://opencode.ai/install"
      ;;
  esac
  echo ""
}
check_opencode

mkdir -p "$WORKFLOW_DIR" "$PLANS_DIR" "$CHANGES_DIR"

[ -f "$WORKFLOW_FILE" ] || curl -fsSL "$RAW_URL/.opencode-workflow/workflow.md" -o "$WORKFLOW_FILE"
[ -f "$PLAN_FILE" ] || touch "$PLAN_FILE"
[ -f "$CHANGES_FILE" ] || touch "$CHANGES_FILE"
[ -f "$SKILLS_CONFIG_FILE" ] || curl -fsSL "$RAW_URL/skills-config.json" -o "$SKILLS_CONFIG_FILE"

if [ ! -f "$SKILL_MANAGER_FILE" ]; then
  mkdir -p "$INSTALL_DIR/scripts"
  if curl -fsSL "$RAW_URL/scripts/manager.sh" -o "$SKILL_MANAGER_FILE"; then
    chmod +x "$SKILL_MANAGER_FILE"
    sed -i 's|SKILLS_CONFIG="../skills-config.json"|SKILLS_CONFIG="./skills-config.json"|' "$SKILL_MANAGER_FILE"
  fi
fi

ln -sf "$SKILL_MANAGER_FILE" "$INSTALL_DIR/scripts/manager" 2>/dev/null || true
ln -sf "$SKILL_MANAGER_FILE" "$INSTALL_DIR/scripts/skillmanager" 2>/dev/null || true

SHELLRC="$HOME/.bashrc"
[ -f "$SHELLRC" ] || SHELLRC="$HOME/.bash_profile"
if [ -f "$SHELLRC" ] && ! grep -q "scripts/manager" "$SHELLRC" 2>/dev/null; then
  echo "" >> "$SHELLRC"
  echo "# opencode_env" >> "$SHELLRC"
  echo "export PATH=\"\$PATH:$INSTALL_DIR/scripts\"" >> "$SHELLRC"
  echo -e "  ${CYAN}→${NC} Added scripts/ to PATH in $SHELLRC"
fi
export PATH="$PATH:$INSTALL_DIR/scripts"

if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'CEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    ".opencode-workflow/workflow.md"
  ]
}
CEOF
fi

echo ""
echo -e "${BOLD}${GREEN}✔ Installation complete!${NC}"
echo -e "  ${CYAN}→${NC} Commands: ${BOLD}manager${NC}, ${BOLD}skillmanager${NC}"
echo -e "  ${CYAN}→${NC} Config:   opencode.json → .opencode-workflow/workflow.md"
echo ""
echo -e "${YELLOW}⚠ THIS SHELL needs reload to use the commands:${NC}"
echo -e "  ${CYAN}→${NC} Run: ${BOLD}source ~/.bashrc${NC}"
echo -e "  ${CYAN}→${NC} Or open a new terminal"
