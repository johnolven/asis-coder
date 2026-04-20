
## Claude Code Skill: Swarm Orchestration

Asis-coder includes a Claude Code skill (`/swarm`) that enables Claude to orchestrate tasks across your Raspberry Pi swarm.

### Installation

The skill is automatically installed to `~/.claude/skills/swarm.md` during setup. To manually install:

```bash
cp skills/swarm.md ~/.claude/skills/
```

### Usage in Claude Code

Once installed, Claude will automatically recognize swarm commands. You can:

**Invoke the skill directly:**
```
/swarm
```

**Or ask Claude naturally:**
- "Show me the status of all devices in the swarm"
- "Execute 'free -h' on all Raspberries in parallel"
- "Run a test on RB001"
- "Start a Claude agent on RB02 to work on the auth feature"

### Key Capabilities

- **Device Management**: List, test, and manage Raspberry Pi workers
- **Parallel Execution**: Run commands simultaneously across multiple devices
- **Agent Orchestration**: Deploy persistent Claude Code sessions on specific devices
- **Git Worktrees**: Each agent gets isolated branch workspace
- **Real-time Streaming**: Command output streams back to parent in real-time

### Examples

```bash
# Claude will understand and execute:
"Check free memory on all 4 Raspberries in parallel"

# Which translates to:
(coder swarm run proj agent1 "free -h") &
(coder swarm run proj agent2 "free -h") &
(coder swarm run proj agent3 "free -h") &
(coder swarm run proj agent4 "free -h") &
wait
```

See `skills/swarm.md` for complete documentation.
