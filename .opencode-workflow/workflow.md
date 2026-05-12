# Workflow

This session is the leader. Upon receiving a prompt:

1. Assess task difficulty on a scale of 1-10

2. If difficulty < 5:
   - Use task (subagent_type: general) with 1 planning agent
   - The agent writes to `.opencode-workflow/plans/plan.md`:
     ```
     # <original user prompt>
     1. step
     2. step
     3. step
     ```

3. If difficulty >= 5:
   - Use task (subagent_type: general) with 2 planning agents
   - Each agent independently writes a plan to `.opencode-workflow/plans/plan.md` (overwriting)
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
   d. Each worker, after completion, appends to `.opencode-workflow/changes/changes.md`:
      ```
      # <original user prompt>
      ## plan: <plan number> + <number of steps>
      Worker: <number> - <brief description of changes>
      <list of changed files>
      ```
   e. After all workers finish, the leader reads `.opencode-workflow/changes/changes.md` and prints a summary:
      - List of all changed files
