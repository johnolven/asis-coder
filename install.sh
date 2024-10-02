#!/bin/bash

set -e

# Configuración de directorios
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALL_DIR="$HOME/coder-cli"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/coder-cli"
BIN_DIR="$HOME/.local/bin"

# Crear directorios necesarios
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$BIN_DIR"

# Copiar el script principal
echo "Copiando Coder CLI..."
if [ -f "$SCRIPT_DIR/coder.sh" ]; then
    cp "$SCRIPT_DIR/coder.sh" "$INSTALL_DIR/coder.sh"
    echo "Copia exitosa."
else
    echo "Error: No se encuentra el archivo coder.sh en el directorio actual."
    exit 1
fi

# Verificar el contenido del archivo
if [ ! -s "$INSTALL_DIR/coder.sh" ]; then
    echo "El archivo copiado está vacío."
    exit 1
fi

# Mostrar las primeras líneas del archivo
echo "Primeras líneas del archivo copiado:"
head -n 5 "$INSTALL_DIR/coder.sh"

# Hacer el script ejecutable
chmod +x "$INSTALL_DIR/coder.sh"

# Crear un enlace simbólico en $BIN_DIR
ln -sf "$INSTALL_DIR/coder.sh" "$BIN_DIR/coder"

# Función para agregar línea a un archivo si no existe
add_line_to_file() {
    grep -qxF "$1" "$2" || echo "$1" >> "$2"
}

# Agregar $BIN_DIR al PATH en .bashrc y .zshrc si no está
PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
add_line_to_file "$PATH_EXPORT" "$HOME/.bashrc"
add_line_to_file "$PATH_EXPORT" "$HOME/.zshrc"

# Verificar si los shells están instalados y actualizar la configuración
if [ -f "$HOME/.bashrc" ]; then
    echo "Actualizando .bashrc..."
    source "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
    echo "Actualizando .zshrc..."
    # Usar una subshell para evitar problemas con configuraciones personalizadas
    (zsh -c "source $HOME/.zshrc" &>/dev/null) || true
fi

# Informar al usuario
echo "Coder CLI se ha instalado correctamente en $INSTALL_DIR"
echo "Se ha creado un enlace 'coder' en $BIN_DIR para ejecutar Coder CLI."
echo "Configuración se guardará en: $CONFIG_DIR"
echo "Se ha agregado $BIN_DIR a tu PATH en .bashrc y .zshrc (si existen)."
echo "Por favor, reinicia tu terminal o ejecuta 'source ~/.bashrc' (o ~/.zshrc) para aplicar los cambios."

# Preguntar si el usuario quiere configurar el LLM ahora
read -p "¿Quieres configurar tu LLM predeterminado ahora? (s/n) " configure_now
if [[ $configure_now == "s" || $configure_now == "S" ]]; then
    "$BIN_DIR/coder" -llm
else
    echo "Puedes configurar tu LLM más tarde ejecutando 'coder -llm'"
fi

echo "Instalación completa. ¡Disfruta usando Coder CLI!"