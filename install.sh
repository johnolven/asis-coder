#!/bin/bash

set -e

# Obtener la ruta absoluta del directorio del proyecto
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/coder-cli"

# Crear directorios necesarios
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# Crear un enlace simbólico en $BIN_DIR
ln -sf "$PROJECT_DIR/coder.sh" "$BIN_DIR/coder"

# Hacer el script ejecutable
chmod +x "$PROJECT_DIR/coder.sh"

# Resto del script install.sh...

echo "Coder CLI se ha instalado correctamente."
echo "Se ha creado un enlace 'coder' en $BIN_DIR que apunta a $PROJECT_DIR/coder.sh"
echo "Ahora puedes hacer cambios en $PROJECT_DIR/coder.sh y se reflejarán inmediatamente sin necesidad de reinstalar."
