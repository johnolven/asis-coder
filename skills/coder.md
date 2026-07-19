---
name: coder
description: "Menú principal de asis-coder. Lista TODO lo que se puede hacer (gestión de tools IA, swarm, agentes, PRDs, Ralph) y guía la elección paso a paso. Úsalo cuando no recuerdes el comando exacto. Triggers: menu, opciones de coder, qué puedo hacer, ayuda coder."
user-invocable: true
---

# Asis-coder — Menú Principal

Eres el punto de entrada a asis-coder. El usuario NO recuerda los comandos: tu trabajo es listar las opciones, dejarle elegir, y ejecutar el comando correcto por él.

## Paso 1 — Muestra el estado actual

Ejecuta y resume en una tabla compacta:

```bash
coder swarm tool list        # tools IA instalados (claude/gemini/codex/aider)
ls ~/.config/coder-cli/swarm/projects/*.json 2>/dev/null   # proyectos swarm
```

## Paso 2 — Ofrece el menú

Usa AskUserQuestion con estas áreas (multiSelect: false):

1. **Tools IA** — ver, elegir o instalar los CLIs (claude/gemini/codex/aider) que usan los agentes → sigue con la skill `/tools`
2. **Swarm** — lanzar/gestionar agentes distribuidos → sigue con la skill `/swarm`
3. **Nueva feature (PRD)** — planificar una feature → sigue con la skill `/prd`
4. **Ralph autónomo** — convertir un PRD a ejecución autónoma → sigue con la skill `/ralph`

Si el usuario ya dijo qué quiere en su mensaje, sáltate el menú y ve directo.

## Chuleta de comandos (para ejecutarlos tú, no para dictárselos)

| Acción | Comando |
|---|---|
| Ver tools IA instalados | `coder swarm tool list` |
| Elegir tool de un agente (menú) | `coder swarm tool choose <proyecto> <agente>` |
| Fijar tool directo | `coder swarm tool set <proyecto> <agente> <claude\|gemini\|codex\|aider\|auto>` |
| Ver qué tool usaría una tarea | `coder swarm tool select <task-type>` |
| Instalar un tool | `coder swarm tool install <tool>` |
| Salud de los tools | `coder swarm tool test` |
| Elegir LLM de API (chat de coder) | `coder --llm` |
| Estado del swarm | `coder swarm status` |

Notas:
- `auto` = el swarm elige el tool según el tipo de tarea (routing en `lib/cli_orchestrator.sh`: quick-fix→aider/codex, docs/research→gemini, refactor/seguridad→claude).
- El tool fijado por agente siempre gana sobre el automático.
- Los comandos `coder swarm tool choose` son interactivos: si los ejecutas tú, pasa la selección por stdin (`echo N | coder swarm tool choose ...`) tras preguntar al usuario con AskUserQuestion.
