---
name: swarm
description: Orchestrate distributed Claude agents across Raspberry Pi devices in a parent/child swarm architecture
---

# Swarm Orchestration Skill

Execute tasks across multiple physical devices (Raspberry Pis) in parallel using the asis-coder swarm infrastructure.

## Architecture

- **Parent**: AGX device at 192.168.50.1 (orchestrator with Redis broker)
- **Children**: Raspberry Pi workers (RB001, RB02, RB03, RB00)
- **Communication**: Redis pub/sub + command queues
- **Isolation**: Git worktrees per agent for parallel branch development

## Available Commands

### Device Management

```bash
# List all devices in swarm
coder swarm device list

# Test device connectivity
coder swarm device test <device-name>

# Add new device
coder swarm device add <name> <ip> --type rpi --user <user>
```

### Project & Agent Management

```bash
# Create project
coder swarm project create <project-name> --repo <git-url>

# List projects
coder swarm project list

# Add agent to device
coder swarm agent add <project> <agent-name> --device <device> --branch <branch> --task "<description>"

# List agents in project
coder swarm agent list <project>
```

### Execution (MOST IMPORTANT)

```bash
# Execute command on a specific device via agent
coder swarm run <project> <agent> "<shell-command>"

# Example: Run command on RB001
coder swarm run test-proyecto agente1 "ls -la && hostname"

# Start persistent Claude agent session
coder swarm start <project> <agent>

# Stop agent
coder swarm stop <project> <agent>

# View agent logs
coder swarm logs <project> <agent> [--follow]

# Check status
coder swarm status [project]
```

### Parallel Execution Pattern

To run tasks in parallel across multiple devices:

```bash
# Execute on multiple Raspberries simultaneously
(coder swarm run proj agent1 "cmd1") &
(coder swarm run proj agent2 "cmd2") &
(coder swarm run proj agent3 "cmd3") &
wait
```

## When to Use This Skill

Use this skill when:
- User asks to run something "on the Raspberries" or "on the swarm"
- User wants to execute tasks in parallel across devices
- User mentions distributed computing, cluster, or multi-device work
- User wants to test/deploy code on physical hardware
- User asks about device status, connectivity, or resources

## Current Active Devices

Based on `coder swarm device list`:
- **RB001** (192.168.50.10) - Raspberry Pi, user: pi, status: online
- **RB02** (192.168.50.11) - Raspberry Pi, user: pi, status: online
- **RB03** (192.168.50.12) - Raspberry Pi, user: pi, status: online
- **RB00** (192.168.50.13) - Raspberry Pi, user: pi, status: online

## Example Workflows

### 1. Quick Command Execution

```bash
# Setup (if not exists)
coder swarm project create quick-test --repo https://github.com/johnolven/asis-coder.git
coder swarm agent add quick-test agent1 --device RB001 --branch main --task "Quick test"

# Execute
coder swarm run quick-test agent1 "echo 'Hello from RB001'"
```

### 2. Parallel System Monitoring

```bash
# Create agents on multiple devices
coder swarm agent add monitoring mon1 --device RB001 --branch main --task "Monitor"
coder swarm agent add monitoring mon2 --device RB02 --branch main --task "Monitor"
coder swarm agent add monitoring mon3 --device RB03 --branch main --task "Monitor"

# Run in parallel
(coder swarm run monitoring mon1 "free -h") &
(coder swarm run monitoring mon2 "df -h") &
(coder swarm run monitoring mon3 "uptime") &
wait
```

### 3. Distributed Development

```bash
# Create project
coder swarm project create myapp --repo https://github.com/user/myapp.git

# Assign different features to different devices
coder swarm agent add myapp auth --device RB001 --branch feat/auth --task "Auth system"
coder swarm agent add myapp api --device RB02 --branch feat/api --task "REST API"
coder swarm agent add myapp ui --device RB03 --branch feat/ui --task "Frontend"

# Start persistent Claude sessions on each
coder swarm start myapp auth
coder swarm start myapp api
coder swarm start myapp ui

# Check status
coder swarm status myapp
```

## Important Notes

- All commands run FROM the parent (AGX at 192.168.50.1)
- Each agent gets isolated git worktree on its device
- Use `coder swarm run` for one-off commands
- Use `coder swarm start` for persistent Claude Code sessions
- Output is streamed back to parent in real-time
- Daemons on children automatically process commands from Redis queues

## Proactive Usage

When user mentions:
- "test this on multiple devices"
- "run this in parallel"
- "check all Raspberries"
- "distribute this task"

→ Automatically suggest or use `coder swarm run` with parallel execution pattern.

## Error Handling

If a command fails:
1. Check device status: `coder swarm device test <device>`
2. View daemon logs: `ssh <user>@<ip> "sudo journalctl -u asis-coder-daemon -n 50"`
3. Verify Redis: `redis-cli -h 192.168.50.1 ping`
4. Test SSH: `ssh <user>@<ip> "echo ok"`
