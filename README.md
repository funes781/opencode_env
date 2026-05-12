
# OpenCode Workflow

Multi-agent workflow for OpenCode with planning agents and worker agents.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/funes781/opencode_env/main/install.sh | bash
```

Or run locally:

```bash
chmod +x install.sh && ./install.sh
```

## How it works

1. **Leader** assesses task difficulty (1-10)
2. **Planning agents** create a plan in `.opencode/plans/plan.md`
3. **Leader** groups steps and spawns **worker agents**
4. **Workers** execute steps and log changes to `.opencode/changes/changes.md`
5. **Leader** summarizes all changed files
