#!/usr/bin/env bash
# ============================================================
# CLI Orchestrator Module for asis-coder
# Manages discovery, health-check, selection, and invocation
# of multiple AI coding CLI tools (claude, gemini, codex, aider)
# ============================================================

CLI_TOOLS_CONFIG="${CONFIG_DIR:-$HOME/.config/coder-cli}/cli_tools.json"

# ─── Tool Definitions ─────────────────────────────────────────

declare -A CLI_BINARIES=(
  [claude]="claude"
  [gemini]="gemini"
  [codex]="codex"
  [aider]="aider"
)

declare -A CLI_VERSION_FLAGS=(
  [claude]="--version"
  [gemini]="--version"
  [codex]="--version"
  [aider]="--version"
)

declare -A CLI_LAUNCH_TEMPLATES=(
  [claude]='claude -p "{PROMPT}" --allowedTools "Bash(git*),Bash(npm*),Bash(node*),Read,Write,Edit" {OPTIONS}'
  [gemini]='echo "{PROMPT}" | gemini'
  [codex]='codex --full-auto "{PROMPT}"'
  [aider]='aider --yes-always --message "{PROMPT}" {FILES}'
)

declare -A CLI_CAPABILITIES=(
  [claude]="refactor,multi-file,complex-logic,testing,security,architecture"
  [gemini]="research,large-context,documentation,analysis,exploration"
  [codex]="refactor,quick-fix,sandboxed,testing"
  [aider]="refactor,quick-fix,multi-model,git-aware"
)

declare -A CLI_CONTEXT_WINDOW=(
  [claude]="200000"
  [gemini]="1000000"
  [codex]="200000"
  [aider]="varies"
)

declare -A CLI_COST_TIER=(
  [claude]="high"
  [gemini]="free"
  [codex]="medium"
  [aider]="varies"
)

# Task type -> preferred tool -> fallback
declare -A CLI_ROUTING=(
  [complex-refactor]="claude:aider:codex"
  [large-analysis]="gemini:claude"
  [quick-fix]="aider:codex:claude"
  [documentation]="gemini:claude"
  [security-audit]="claude:gemini"
  [test-generation]="claude:aider"
  [research]="gemini:claude"
  [new-feature]="claude:aider"
  [default]="claude:gemini:codex:aider"
)

# ─── Discovery ────────────────────────────────────────────────

cli_discover() {
  local tools=("claude" "gemini" "codex" "aider")
  local available=0
  local total=${#tools[@]}

  echo ""
  printf "  %-12s %-12s %-20s %s\n" "TOOL" "STATUS" "VERSION" "CAPABILITIES"
  printf "  %-12s %-12s %-20s %s\n" "────" "──────" "───────" "────────────"

  for tool in "${tools[@]}"; do
    local binary="${CLI_BINARIES[$tool]}"
    local bin_path
    bin_path=$(which "$binary" 2>/dev/null)

    if [ -n "$bin_path" ]; then
      local version
      version=$("$binary" ${CLI_VERSION_FLAGS[$tool]} 2>/dev/null | head -1 | tr -d '\n')
      printf "  %-12s \033[32m%-12s\033[0m %-20s %s\n" "$tool" "installed" "$version" "${CLI_CAPABILITIES[$tool]}"
      ((available++))
    else
      printf "  %-12s \033[31m%-12s\033[0m %-20s %s\n" "$tool" "not found" "-" "${CLI_CAPABILITIES[$tool]}"
    fi
  done

  echo ""
  echo "  $available/$total tools disponibles"
  echo ""
}

# ─── Health Check ─────────────────────────────────────────────

cli_health_check() {
  local tool="${1:-all}"

  if [ "$tool" = "all" ]; then
    local tools=("claude" "gemini" "codex" "aider")
  else
    local tools=("$tool")
  fi

  for t in "${tools[@]}"; do
    local binary="${CLI_BINARIES[$t]}"
    local bin_path
    bin_path=$(which "$binary" 2>/dev/null)

    if [ -z "$bin_path" ]; then
      echo "  [$t] ❌ No instalado"
      continue
    fi

    local version
    version=$("$binary" ${CLI_VERSION_FLAGS[$t]} 2>/dev/null | head -1)
    if [ $? -eq 0 ] && [ -n "$version" ]; then
      echo "  [$t] ✅ OK ($version)"
    else
      echo "  [$t] ⚠️  Instalado pero no responde"
    fi
  done
}

# ─── Tool Selection ───────────────────────────────────────────

cli_select() {
  local task_type="${1:-default}"
  local routing="${CLI_ROUTING[$task_type]:-${CLI_ROUTING[default]}}"

  IFS=':' read -ra candidates <<< "$routing"

  for candidate in "${candidates[@]}"; do
    local binary="${CLI_BINARIES[$candidate]}"
    if which "$binary" &>/dev/null; then
      echo "$candidate"
      return 0
    fi
  done

  # Last resort: return whatever is available
  for tool in claude gemini codex aider; do
    if which "${CLI_BINARIES[$tool]}" &>/dev/null; then
      echo "$tool"
      return 0
    fi
  done

  echo ""
  return 1
}

# ─── Build Command ────────────────────────────────────────────

cli_build_cmd() {
  local tool="$1"
  local prompt="$2"
  local options="${3:-}"
  local files="${4:-}"

  local template="${CLI_LAUNCH_TEMPLATES[$tool]}"
  if [ -z "$template" ]; then
    echo "ERROR: Tool '$tool' no tiene template definido" >&2
    return 1
  fi

  # Escape prompt for shell safety
  local escaped_prompt
  escaped_prompt=$(printf '%s' "$prompt" | sed "s/'/'\\\\''/g")

  local cmd="$template"
  cmd="${cmd//\{PROMPT\}/$escaped_prompt}"
  cmd="${cmd//\{OPTIONS\}/$options}"
  cmd="${cmd//\{FILES\}/$files}"

  echo "$cmd"
}

# ─── Install Tool ─────────────────────────────────────────────

cli_install() {
  local tool="$1"

  case "$tool" in
    claude)
      echo "  Claude Code se instala desde: https://docs.anthropic.com/en/docs/claude-code"
      echo "  Comando: curl -fsSL https://claude.ai/install.sh | sh"
      ;;
    gemini)
      echo "  Instalando Gemini CLI..."
      npm install -g @google/gemini-cli
      ;;
    codex)
      echo "  Instalando OpenAI Codex CLI..."
      npm install -g @openai/codex
      ;;
    aider)
      echo "  Instalando Aider..."
      if command -v pip3 &>/dev/null; then
        pip3 install --user aider-chat
      elif command -v python3 &>/dev/null; then
        python3 -m pip install --user aider-chat
      else
        echo "  ❌ Se requiere pip3 o python3 con pip. Instala con: sudo apt install python3-pip"
        return 1
      fi
      ;;
    *)
      echo "  ❌ Tool desconocido: $tool"
      echo "  Tools disponibles: claude, gemini, codex, aider"
      return 1
      ;;
  esac
}

# ─── Save Registry ────────────────────────────────────────────

cli_save_registry() {
  local config_dir
  config_dir=$(dirname "$CLI_TOOLS_CONFIG")
  mkdir -p "$config_dir"

  local tools_json='{"tools":['
  local first=true

  for tool in claude gemini codex aider; do
    local binary="${CLI_BINARIES[$tool]}"
    local bin_path
    bin_path=$(which "$binary" 2>/dev/null)
    local available="false"
    local version="null"

    if [ -n "$bin_path" ]; then
      available="true"
      local ver
      ver=$("$binary" ${CLI_VERSION_FLAGS[$tool]} 2>/dev/null | head -1 | tr -d '\n')
      if [ -n "$ver" ]; then
        version="\"$ver\""
      fi
    fi

    if [ "$first" = true ]; then
      first=false
    else
      tools_json+=","
    fi

    tools_json+=$(cat <<ENTRY
{
  "name":"$tool",
  "binary":"$binary",
  "available":$available,
  "version":$version,
  "capabilities":"${CLI_CAPABILITIES[$tool]}",
  "context_window":"${CLI_CONTEXT_WINDOW[$tool]}",
  "cost_tier":"${CLI_COST_TIER[$tool]}"
}
ENTRY
)
  done

  tools_json+=']}'

  echo "$tools_json" | python3 -m json.tool > "$CLI_TOOLS_CONFIG" 2>/dev/null || echo "$tools_json" > "$CLI_TOOLS_CONFIG"
  echo "  Registry guardado en: $CLI_TOOLS_CONFIG"
}

# ─── Swarm Tool Command Handler ───────────────────────────────

swarm_tool_handler() {
  local subcommand="${1:-list}"
  shift 2>/dev/null

  case "$subcommand" in
    list|ls)
      echo ""
      echo "  🔧 AI CLI Tools Registry"
      echo "  ========================"
      cli_discover
      ;;
    install)
      local tool_name="$1"
      if [ -z "$tool_name" ]; then
        echo "  Uso: coder swarm tool install <tool>"
        echo "  Tools: claude, gemini, codex, aider"
        return 1
      fi
      cli_install "$tool_name"
      ;;
    test|check)
      local tool_name="${1:-all}"
      echo ""
      echo "  🧪 Health Check: $tool_name"
      echo "  ─────────────────────────"
      cli_health_check "$tool_name"
      echo ""
      ;;
    select)
      local task_type="${1:-default}"
      local selected
      selected=$(cli_select "$task_type")
      if [ -n "$selected" ]; then
        echo "  Para '$task_type' → $selected"
      else
        echo "  ❌ No hay tool disponible para '$task_type'"
      fi
      ;;
    set)
      local project="$1"
      local agent="$2"
      local tool="$3"
      if [ -z "$project" ] || [ -z "$agent" ] || [ -z "$tool" ]; then
        echo "  Uso: coder swarm tool set <project> <agent> <tool>"
        return 1
      fi
      # Update agent config with tool field
      local project_file="${SWARM_DIR:-$HOME/.config/coder-cli/swarm}/projects/${project}.json"
      if [ ! -f "$project_file" ]; then
        echo "  ❌ Proyecto no encontrado: $project"
        return 1
      fi
      if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg agent "$agent" --arg tool "$tool" \
          '(.agents[] | select(.name == $agent)).tool = $tool' \
          "$project_file" > "$tmp" && mv "$tmp" "$project_file"
        echo "  ✅ $agent → $tool (proyecto: $project)"
      else
        echo "  ⚠️  Se requiere jq para actualizar el config"
        return 1
      fi
      ;;
    registry|save)
      echo "  📝 Actualizando registry..."
      cli_save_registry
      ;;
    *)
      echo ""
      echo "  🔧 coder swarm tool - Gestión de AI CLI Tools"
      echo "  ─────────────────────────────────────────────"
      echo ""
      echo "  Comandos:"
      echo "    list                          Ver tools disponibles"
      echo "    install <tool>                Instalar un tool"
      echo "    test [tool|all]               Verificar salud de tools"
      echo "    select <task-type>            Ver qué tool se usaría"
      echo "    set <project> <agent> <tool>  Asignar tool a un agente"
      echo "    registry                      Guardar registry a disco"
      echo ""
      echo "  Task types: complex-refactor, large-analysis, quick-fix,"
      echo "              documentation, security-audit, test-generation,"
      echo "              research, new-feature"
      echo ""
      ;;
  esac
}
