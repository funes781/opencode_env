# OpenCode Workflow

Multi-agent workflow for OpenCode with planning and worker agents.

## Usage

Run install.sh to set up the workflow:

```bash
curl -fsSL https://raw.githubusercontent.com/funes781/opencode_env/main/install.sh | sudo bash
```

Or locally:

```bash
chmod +x install.sh && ./install.sh
```

## Configuration

This repo does **not** include `opencode.json`. The install script creates it for you with the following content:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    ".opencode/workflow/workflow.md"
  ]
}
```

If you already have an existing `opencode.json`, add the workflow instructions entry manually.

See the [OpenCode configuration documentation](https://opencode.ai/docs/configuration) for more details.
