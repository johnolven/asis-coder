
## Claude Code Skills — todo se usa desde `/`

Asis-coder includes **5 Claude Code skills**. No hay que memorizar comandos: teclea `/` en Claude Code y aparecen listadas. Si no sabes por dónde empezar, usa **`/coder`**.

| Skill | Qué hace |
|---|---|
| **`/coder`** | 🏠 Menú principal — lista todo lo que se puede hacer y te guía |
| **`/tools`** | Elegir qué CLI de IA usa cada agente (claude/gemini/codex/aider), instalarlos, o dejarlo en `auto` (routing por tipo de tarea) |
| **`/swarm`** | Orquestar agentes distribuidos en las Raspberry Pi |
| **`/prd`** | Generar Product Requirements Documents interactivamente |
| **`/ralph`** | Convertir PRDs a formato Ralph JSON para ejecución autónoma |

**Selección de tool por agente:** cada agente del swarm puede usar un CLI fijo (`/tools` → elegir) o modo `auto`, donde el swarm enruta según la tarea: quick-fixes → codex/aider, docs y research → gemini, refactors/seguridad/tests → claude.

### Automatic Installation

All skills are **automatically installed** to `~/.claude/skills/` during:
- `./install.sh` (local installation)
- `curl ... | bash` (bootstrap-parent.sh / bootstrap-child.sh)

No manual steps required! After installation, skills are immediately available in Claude Code.

### Manual Installation

If needed, copy skills manually:

```bash
cp skills/*.md ~/.claude/skills/
```

### Complete Workflow: Autonomous Feature Development

```bash
# 1. Ask Claude to create a PRD
"Create a PRD for a user authentication system"
# → Claude invokes /prd skill
# → Asks you clarifying questions (with A/B/C options)
# → Saves to tasks/prd-auth.md

# 2. Ask Claude to convert to Ralph format
"Convert this PRD to Ralph JSON format"
# → Claude invokes /ralph skill
# → Generates prd.json with all user stories

# 3. Deploy to Raspberry Pi (autonomous execution)
coder swarm ralph start myapp auth-agent --prd prd.json
# → Ralph runs Claude Code repeatedly on the Raspberry
# → Completes all PRD items autonomously
# → You wake up with a finished feature
```

**Result:** Feature developed overnight while you sleep!

### Usage in Claude Code

Claude will automatically recognize and use these skills. You can:

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
