#!/bin/bash

# ==========================================
# ASIS-CODER INSTALADOR REMOTO
# ==========================================
# Descarga e instala Asis-coder desde internet

set -e

# Colores para output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Configuración
ASIS_CODER_VERSION="1.0.1"
GITHUB_REPO="johnolven/asis-coder"  # ← Tu repositorio GitHub
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${ASIS_CODER_VERSION}/asis-coder-macos-arm64.tar.gz"
INSTALL_DIR="$HOME/.local/asis-coder"
BIN_DIR="$HOME/.local/bin"

echo -e "${CYAN}${BOLD}🚀 INSTALADOR DE ASIS-CODER${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Instalando Asis-coder v${ASIS_CODER_VERSION}...${NC}"
echo ""

# Detectar OS
OS_TYPE=$(uname -s)
ARCH_TYPE=$(uname -m)

case "$OS_TYPE" in
    "Darwin")
        if [ "$ARCH_TYPE" = "arm64" ]; then
            PACKAGE_NAME="asis-coder-macos-arm64.tar.gz"
            DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${ASIS_CODER_VERSION}/${PACKAGE_NAME}"
        else
            PACKAGE_NAME="asis-coder-macos-x64.tar.gz"
            DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${ASIS_CODER_VERSION}/${PACKAGE_NAME}"
        fi
        ;;
    "Linux")
        PACKAGE_NAME="asis-coder-linux.tar.gz"
        DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${ASIS_CODER_VERSION}/${PACKAGE_NAME}"
        ;;
    "MINGW"*|"CYGWIN"*|"MSYS"*)
        PACKAGE_NAME="asis-coder-windows.tar.gz"
        DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${ASIS_CODER_VERSION}/${PACKAGE_NAME}"
        ;;
    *)
        echo -e "${RED}❌ Sistema operativo no soportado: $OS_TYPE${NC}"
        echo -e "${YELLOW}💡 Sistemas soportados: macOS, Linux, Windows${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}🔍 Sistema detectado: ${BOLD}$OS_TYPE $ARCH_TYPE${NC}"
echo -e "${YELLOW}📦 Paquete: ${BOLD}$PACKAGE_NAME${NC}"
echo ""

# Verificar dependencias
echo -e "${CYAN}🔧 Verificando dependencias...${NC}"

# Verificar curl
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}❌ curl no encontrado${NC}"
    echo -e "${YELLOW}💡 Instala curl primero:${NC}"
    case "$OS_TYPE" in
        "Darwin")
            echo -e "   ${BOLD}brew install curl${NC}"
            ;;
        "Linux")
            echo -e "   ${BOLD}sudo apt-get install curl${NC} (Ubuntu/Debian)"
            echo -e "   ${BOLD}sudo yum install curl${NC} (CentOS/RHEL)"
            ;;
    esac
    exit 1
fi

# Verificar tar
if ! command -v tar >/dev/null 2>&1; then
    echo -e "${RED}❌ tar no encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencias verificadas${NC}"
echo ""

# Crear directorios
echo -e "${CYAN}📁 Creando directorios...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Descargar paquete
echo -e "${CYAN}⬇️ Descargando Asis-coder...${NC}"
echo -e "${YELLOW}   URL: $DOWNLOAD_URL${NC}"

TEMP_FILE="/tmp/asis-coder.tar.gz"

if curl -L --progress-bar --fail "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
    echo -e "${GREEN}✅ Descarga completada${NC}"
else
    echo -e "${RED}❌ Error descargando Asis-coder${NC}"
    echo -e "${YELLOW}💡 Verifica que el release existe: https://github.com/${GITHUB_REPO}/releases${NC}"
    exit 1
fi

# Extraer paquete
echo -e "${CYAN}📦 Extrayendo archivos...${NC}"
if tar -xzf "$TEMP_FILE" -C "$INSTALL_DIR" --strip-components=0; then
    echo -e "${GREEN}✅ Archivos extraídos${NC}"
else
    echo -e "${RED}❌ Error extrayendo archivos${NC}"
    exit 1
fi

# Limpiar archivo temporal
rm -f "$TEMP_FILE"

# Hacer ejecutable
chmod +x "$INSTALL_DIR/coder.sh"
chmod +x "$INSTALL_DIR/install.sh"

# Crear enlace simbólico
echo -e "${CYAN}🔗 Creando enlace simbólico...${NC}"
ln -sf "$INSTALL_DIR/coder.sh" "$BIN_DIR/coder"

# Agregar al PATH si no está
echo -e "${CYAN}🛣️ Configurando PATH...${NC}"

# Detectar shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

# Verificar si el PATH ya contiene el directorio
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo -e "${YELLOW}   Agregando $BIN_DIR al PATH en $SHELL_RC${NC}"
    
    # Crear backup del archivo de configuración si no existe
    [ ! -f "$SHELL_RC" ] && touch "$SHELL_RC"
    
    # Agregar al PATH
    echo "" >> "$SHELL_RC"
    echo "# Asis-coder PATH" >> "$SHELL_RC"
    echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_RC"
    
    echo -e "${GREEN}✅ PATH configurado${NC}"
else
    echo -e "${GREEN}✅ PATH ya configurado${NC}"
fi

# Verificar instalación
echo ""
echo -e "${CYAN}🧪 Verificando instalación...${NC}"

if [ -x "$BIN_DIR/coder" ]; then
    echo -e "${GREEN}✅ Instalación exitosa${NC}"
    
    # Mostrar versión
    VERSION_OUTPUT=$("$BIN_DIR/coder" -v 2>/dev/null || echo "Asis-coder v$ASIS_CODER_VERSION")
    echo -e "${GREEN}📦 $VERSION_OUTPUT${NC}"
    
else
    echo -e "${RED}❌ Error en la instalación${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}${BOLD}🎉 ¡INSTALACIÓN COMPLETADA!${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Asis-coder instalado en: ${BOLD}$INSTALL_DIR${NC}"
echo -e "${GREEN}✅ Comando disponible: ${BOLD}coder${NC}"
echo ""
echo -e "${YELLOW}📋 Para empezar:${NC}"
echo -e "   ${CYAN}1.${NC} Reinicia tu terminal o ejecuta: ${BOLD}source $SHELL_RC${NC}"
echo -e "   ${CYAN}2.${NC} Ve a tu proyecto: ${BOLD}cd /ruta/a/tu/proyecto${NC}"
echo -e "   ${CYAN}3.${NC} Configura API: ${BOLD}coder setup${NC}"
echo -e "   ${CYAN}4.${NC} Genera contexto: ${BOLD}coder -contexto${NC}"
echo -e "   ${CYAN}5.${NC} Primera consulta: ${BOLD}coder \"explica este proyecto\"${NC}"
echo ""
echo -e "${YELLOW}🤖 Comandos avanzados disponibles:${NC}"
echo -e "   ${CYAN}•${NC} ${BOLD}coder code fix \"problema\"${NC}    # Arreglar bugs"
echo -e "   ${CYAN}•${NC} ${BOLD}coder code analyze${NC}            # Análisis avanzado"
echo -e "   ${CYAN}•${NC} ${BOLD}coder units${NC}                   # Context units"
echo -e "   ${CYAN}•${NC} ${BOLD}coder status${NC}                  # Estado completo"
echo ""
echo -e "${GREEN}📖 Documentación: ${BOLD}https://github.com/${GITHUB_REPO}${NC}"
echo -e "${GREEN}🐛 Reportar bugs: ${BOLD}https://github.com/${GITHUB_REPO}/issues${NC}"
echo ""
echo -e "${YELLOW}⚠️  Nota: Necesitarás configurar tu API key (OpenAI, Claude, o Gemini) en el primer uso${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"

