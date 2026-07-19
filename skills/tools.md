---
name: tools
description: "Gestiona los CLIs de IA de asis-coder (claude, gemini, codex, aider): listar instalados, elegir cuál usa cada agente del swarm (o dejarlo en automático por tipo de tarea), instalarlos y verificar su salud. Triggers: qué tools hay, cambiar tool del agente, usar codex, usar claude, instalar gemini, tool automático."
user-invocable: true
---

# Gestión de AI CLI Tools

El usuario quiere ver o cambiar qué CLI de IA (claude/gemini/codex/aider) usan sus agentes del swarm. No le hagas memorizar comandos: pregunta y ejecuta.

## Flujo

### 1. Estado — ejecútalo SIEMPRE primero

```bash
coder swarm tool list
```

Muestra la tabla (instalado/no, versión, capacidades). Si hay proyectos swarm, lista también el tool actual de cada agente:

```bash
for f in ~/.config/coder-cli/swarm/projects/*.json; do
  [ -f "$f" ] || continue
  echo "── $(basename "$f" .json)"
  jq -r '.agents[] | "  \(.name): \(.tool // "auto")"' "$f"
done
```

### 2. Pregunta qué quiere hacer (AskUserQuestion)

- **Cambiar el tool de un agente** → pregunta proyecto/agente/tool (opciones: los instalados + `auto`), luego:
  `coder swarm tool set <proyecto> <agente> <tool>`
- **Volver a automático** → `coder swarm tool set <proyecto> <agente> auto`
- **Instalar un tool que falta** → `coder swarm tool install <tool>` (codex y gemini van por npm; claude requiere su instalador — muestra la instrucción que imprime el comando)
- **Verificar que responden** → `coder swarm tool test`
- **Ver el routing automático** → `coder swarm tool select <task-type>` con task-types: complex-refactor, quick-fix, large-analysis, documentation, security-audit, test-generation, research, new-feature

### Cómo funciona el modo `auto`

Sin tool fijado, al lanzar el agente el swarm infiere el tipo de tarea del texto (keywords es/en) y enruta con fallback a lo instalado:

- arreglos rápidos → aider → codex → claude
- docs / research / análisis grande → gemini → claude
- refactor / seguridad / tests / features → claude → …

### Advertencia importante

La selección mira los tools de ESTA máquina. Si el agente corre en un device remoto del swarm, verifica que el tool elegido esté instalado allí (`coder swarm tool test` en el device, o revisa `capabilities.tools` del child).
