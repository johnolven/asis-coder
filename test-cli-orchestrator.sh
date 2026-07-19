#!/usr/bin/env bash
# Prueba end-to-end del cli_orchestrator: pide codigo real a cada CLI instalado.
set -uo pipefail

source /home/johnolven/asis-coder/lib/cli_orchestrator.sh

WORK="$(mktemp -d)"; cd "$WORK"
PROMPT='Escribe SOLO el codigo de una funcion fizzbuzz(n) en Python. Sin explicacion.'

echo "workdir: $WORK"
echo

for tool in claude codex gemini; do
  command -v "$tool" >/dev/null 2>&1 || { echo "SKIP $tool (no instalado)"; continue; }

  cmd="$(cli_build_cmd "$tool" "$PROMPT" "${CLI_AUTO_FLAGS[$tool]}")"
  echo "======================================================"
  echo ">> $tool"
  echo ">> $cmd"
  echo "------------------------------------------------------"
  timeout 180 bash -c "$cmd" 2>&1 | head -25
  echo "[exit ${PIPESTATUS[0]}]"
  echo
done

echo "======================================================"
echo ">> Prompt hostil (regresion de quoting)"
echo "   Debe tratarse como TEXTO, no ejecutar nada:"
cli_build_cmd claude 'bug en "auth" con $HOME; echo PWNED' "${CLI_AUTO_FLAGS[claude]}"
