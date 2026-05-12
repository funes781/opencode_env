#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(pwd)"
WORKFLOW_DIR="$INSTALL_DIR/.opencode-workflow"
PLANS_DIR="$WORKFLOW_DIR/plans"
CHANGES_DIR="$WORKFLOW_DIR/changes"
WORKFLOW_FILE="$WORKFLOW_DIR/workflow.md"
PLAN_FILE="$PLANS_DIR/plan.md"
CHANGES_FILE="$CHANGES_DIR/changes.md"
SKILLS_CONFIG_FILE="$INSTALL_DIR/skills-config.json"
SKILL_MANAGER_FILE="$INSTALL_DIR/scripts/manager.sh"
MANAGER_LINK="/usr/local/bin/manager"
CONFIG_FILE="$INSTALL_DIR/opencode.json"
RAW_URL="https://raw.githubusercontent.com/funes781/opencode_env/main"

echo "Installing OpenCode workflow..."

check_opencode() {
  local found=0
  if command -v opencode &>/dev/null; then
    found=1
  elif [ -x "$HOME/.opencode/bin/opencode" ]; then
    found=1
    export PATH="$HOME/.opencode/bin:$PATH"
  fi

  if [ "$found" -eq 1 ]; then
    echo "  [OK] OpenCode CLI found"
    return
  fi

  echo ""
  echo "  OpenCode CLI is not installed."
  echo "  It is required to use this workflow."
  echo ""
  read -r -p "  Install OpenCode now? [Y/n] " response
  case "${response:-Y}" in
    [Yy]*|"")
      echo "  Installing OpenCode..."
      if curl -fsSL https://opencode.ai/install | bash; then
        echo "  [OK] OpenCode installed"
        if [ -x "$HOME/.opencode/bin/opencode" ]; then
          export PATH="$HOME/.opencode/bin:$PATH"
        fi
      else
        echo "  [WARN] Installation failed. Install manually: https://opencode.ai/install"
      fi
      ;;
    *)
      echo "  [WARN] Skipping OpenCode installation."
      echo "         Install manually: https://opencode.ai/install"
      ;;
  esac
  echo ""
}

check_opencode

check_file() {
  if [ -f "$1" ]; then
    echo "  [OK] $1"
  fi
}

check_dir() {
  if [ -d "$1" ]; then
    echo "  [OK] $1"
  else
    echo "  [CREATED] $1"
    mkdir -p "$1"
  fi
}

check_dir "$WORKFLOW_DIR"
check_dir "$PLANS_DIR"
check_dir "$CHANGES_DIR"

if [ ! -f "$WORKFLOW_FILE" ]; then
  curl -fsSL "$RAW_URL/.opencode-workflow/workflow.md" -o "$WORKFLOW_FILE"
  echo "  [DOWNLOADED] $WORKFLOW_FILE"
else
  check_file "$WORKFLOW_FILE"
fi

if [ ! -f "$PLAN_FILE" ]; then
  touch "$PLAN_FILE"
  echo "  [CREATED] $PLAN_FILE"
else
  check_file "$PLAN_FILE"
fi

if [ ! -f "$CHANGES_FILE" ]; then
  touch "$CHANGES_FILE"
  echo "  [CREATED] $CHANGES_FILE"
else
  check_file "$CHANGES_FILE"
fi

if [ ! -f "$SKILLS_CONFIG_FILE" ]; then
  curl -fsSL "$RAW_URL/skills-config.json" -o "$SKILLS_CONFIG_FILE"
  echo "  [DOWNLOADED] $SKILLS_CONFIG_FILE"
else
  check_file "$SKILLS_CONFIG_FILE"
fi

if [ ! -f "$SKILL_MANAGER_FILE" ]; then
  mkdir -p "$INSTALL_DIR/scripts"
  if curl -fsSL "$RAW_URL/scripts/manager.sh" -o "$SKILL_MANAGER_FILE"; then
    chmod +x "$SKILL_MANAGER_FILE"
    echo "  [DOWNLOADED] $SKILL_MANAGER_FILE"
  else
    echo "  [WARN] scripts/manager.sh not found in repo, skipping"
    rm -f "$SKILL_MANAGER_FILE"
  fi
else
  check_file "$SKILL_MANAGER_FILE"
fi

if [ ! -L "$MANAGER_LINK" ] && [ ! -f "$MANAGER_LINK" ]; then
  if [ -w /usr/local/bin ]; then
    ln -sf "$SKILL_MANAGER_FILE" "$MANAGER_LINK"
    echo "  [LINKED] $MANAGER_LINK"
  elif command -v sudo &>/dev/null; then
    sudo ln -sf "$SKILL_MANAGER_FILE" "$MANAGER_LINK"
    echo "  [LINKED] $MANAGER_LINK"
  else
    echo "  [WARN] Cannot create /usr/local/bin/manager (no sudo)."
    echo "         Run: sudo ln -sf $SKILL_MANAGER_FILE $MANAGER_LINK"
  fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'CEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    ".opencode-workflow/workflow.md"
  ]
}
CEOF
  echo "  [CREATED] $CONFIG_FILE"
else
  check_file "$CONFIG_FILE"
fi

echo ""
echo "Installation complete!"
echo "Workflow file:       $WORKFLOW_FILE"
echo "Plan file:           $PLAN_FILE"
echo "Changes file:        $CHANGES_FILE"
echo "Skills config:       $SKILLS_CONFIG_FILE"
echo "Scripts:             $SKILL_MANAGER_FILE"
echo "Command:             $MANAGER_LINK"
echo "Config:              $CONFIG_FILE"
