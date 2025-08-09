#!/bin/bash

# ==========================================
# ASIS-CODER PUBLIC BUILD SCRIPT
# ==========================================
# Builds Asis-coder with available binaries

set -e

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}🚀 ASIS-CODER BUILD SYSTEM${NC}"
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo ""

# Verificar si existen binarios pre-compilados
if [ -d "binaries" ] && [ "$(ls -A binaries)" ]; then
    echo -e "${GREEN}✅ Encontrados binarios pre-compilados${NC}"
    
    # Listar binarios disponibles
    echo -e "${CYAN}📦 Binarios disponibles:${NC}"
    for binary in binaries/*; do
        if [ -f "$binary" ]; then
            SIZE=$(ls -lah "$binary" | awk '{print $5}')
            NAME=$(basename "$binary")
            echo -e "   ${YELLOW}•${NC} $NAME (${SIZE})"
        fi
    done
    
    # Verificar funcionalidad
    OS_TYPE=$(uname -s)
    ARCH_TYPE=$(uname -m)
    
    case "$OS_TYPE" in
        "Darwin")
            if [ "$ARCH_TYPE" = "arm64" ]; then
                EXPECTED_BINARY="binaries/asis-core-macos-arm64"
            else
                EXPECTED_BINARY="binaries/asis-core-macos-x64"
            fi
            ;;
        "Linux")
            EXPECTED_BINARY="binaries/asis-core-linux"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Sistema $OS_TYPE no reconocido${NC}"
            EXPECTED_BINARY=""
            ;;
    esac
    
    if [ -n "$EXPECTED_BINARY" ] && [ -f "$EXPECTED_BINARY" ]; then
        echo ""
        echo -e "${GREEN}🎯 Binario para tu sistema: ${BOLD}$(basename "$EXPECTED_BINARY")${NC}"
        
        # Dar permisos de ejecución
        chmod +x "$EXPECTED_BINARY"
        
        # Verificar funcionalidad
        if "$EXPECTED_BINARY" --version >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Binario funcional y listo${NC}"
        else
            echo -e "${YELLOW}⚠️  Binario presente pero no verificado${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No hay binario específico para tu sistema${NC}"
        echo -e "${CYAN}💡 Sistema detectado: $OS_TYPE $ARCH_TYPE${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Build completado con binarios existentes${NC}"
    
else
    # No hay binarios - explicar como obtenerlos
    echo -e "${RED}❌ No se encontraron binarios pre-compilados${NC}"
    echo ""
    echo -e "${YELLOW}📦 Para obtener Asis-coder:${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Opción 1: Descarga automática${NC}"
    echo -e "   ${GREEN}curl -sSL https://raw.githubusercontent.com/johnolven/asis-coder/main/install-remote.sh | bash${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Opción 2: Release oficial${NC}"
    echo -e "   ${GREEN}1.${NC} Ve a: https://github.com/johnolven/asis-coder/releases"
    echo -e "   ${GREEN}2.${NC} Descarga el .tar.gz para tu sistema"
    echo -e "   ${GREEN}3.${NC} Extrae y ejecuta: ./install.sh"
    echo ""
    echo -e "${CYAN}${BOLD}Opción 3: NPM${NC}"
    echo -e "   ${GREEN}npm install -g asis-coder${NC}"
    echo ""
    echo -e "${RED}⚠️  Nota: ${NC}Los binarios contienen algoritmos propietarios"
    echo -e "    y no están incluidos en el código fuente público."
    
    exit 1
fi

echo -e "${YELLOW}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Asis-coder listo para usar${NC}"
echo -e "${CYAN}💡 Prueba: ${BOLD}./coder.sh status${NC}"
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
