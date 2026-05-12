#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$(pwd)"
OPENCODE_DIR="$INSTALL_DIR/.opencode"
WORKFLOW_DIR="$OPENCODE_DIR/workflow"
PLANS_DIR="$OPENCODE_DIR/plans"
CHANGES_DIR="$OPENCODE_DIR/changes"
WORKFLOW_FILE="$WORKFLOW_DIR/workflow.md"
PLAN_FILE="$PLANS_DIR/plan.md"
CHANGES_FILE="$CHANGES_DIR/changes.md"
CONFIG_FILE="$INSTALL_DIR/opencode.json"

echo "Installing OpenCode workflow..."

check_opencode() {
  if ! command -v opencode &>/dev/null; then
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
  else
    echo "  [OK] OpenCode CLI found"
  fi
}

check_opencode

check_file() {
  if [ -f "$1" ]; then
    echo "  [OK] $1"
  else
    echo "  [CREATED] $1"
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
  cat > "$WORKFLOW_FILE" << 'WEOF'
# Workflow

This session is the leader. Upon receiving a prompt:

1. Assess task difficulty on a scale of 1-10

2. If difficulty < 5:
   - Use task (subagent_type: general) with 1 planning agent
   - The agent writes to `.opencode/plans/plan.md`:
     ```
     # <original user prompt>
     1. step
     2. step
     3. step
     ```

3. If difficulty >= 5:
   - Use task (subagent_type: general) with 2 planning agents
   - Each agent independently writes a plan to `.opencode/plans/plan.md` (overwriting)
   - Format:
     ```
     # <original user prompt>
     1. step
     2. step
     3. step
     ```

4. After receiving the plan(s):
   a. Leader chooses which plan to execute (if there were 2+ agents)
   b. Leader analyzes the steps and groups them into tasks for "worker" agents:
      - Related steps (e.g., 1,3,4 are dependent) → one worker
      - Independent steps → separate worker (unless both are simple - can be combined)
   c. For each worker, create a separate task (subagent_type: general) to execute assigned steps
   d. Each worker, after completion, appends to `.opencode/changes/changes.md`:
      ```
      # <original user prompt>
      ## plan: <plan number> + <number of steps>
      Worker: <number> - <brief description of changes>
      <list of changed files>
      ```
   e. After all workers finish, the leader reads `.opencode/changes/changes.md` and prints a summary:
      - List of all changed files
WEOF
  check_file "$WORKFLOW_FILE"
else
  check_file "$WORKFLOW_FILE"
fi

if [ ! -f "$PLAN_FILE" ]; then
  touch "$PLAN_FILE"
  check_file "$PLAN_FILE"
else
  check_file "$PLAN_FILE"
fi

if [ ! -f "$CHANGES_FILE" ]; then
  touch "$CHANGES_FILE"
  check_file "$CHANGES_FILE"
else
  check_file "$CHANGES_FILE"
fi

if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'CEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    ".opencode/workflow/workflow.md"
  ]
}
CEOF
  check_file "$CONFIG_FILE"
else
  check_file "$CONFIG_FILE"
fi

echo ""
echo "Installation complete!"
echo "Workflow file: $WORKFLOW_FILE"
echo "Plan file:     $PLAN_FILE"
echo "Changes file:  $CHANGES_FILE"
echo "Config:        $CONFIG_FILE"
