#!/bin/bash

# ==========================================
# VERIFICADOR DE CONFIGURACIÓN - JOHNOLVEN
# ==========================================
# Verifica que toda la configuración esté correcta

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}🔍 VERIFICACIÓN DE CONFIGURACIÓN PERSONALIZADA${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

# Verificar referencias de usuario
echo -e "${CYAN}📋 Verificando referencias de usuario...${NC}"

REFERENCIAS_CORRECTAS=0
REFERENCIAS_TOTALES=0

# Función para verificar archivo
verificar_archivo() {
    local archivo="$1"
    local descripcion="$2"
    
    if [ -f "$archivo" ]; then
        echo -e "   ${YELLOW}• Verificando: $descripcion${NC}"
        
        # Buscar referencias correctas a johnolven
        if grep -q "johnolven" "$archivo" 2>/dev/null; then
            echo -e "     ${GREEN}✅ Referencias a 'johnolven' encontradas${NC}"
            ((REFERENCIAS_CORRECTAS++))
        else
            echo -e "     ${YELLOW}⚠️  No se encontraron referencias a 'johnolven'${NC}"
        fi
        
        # Buscar referencias genéricas restantes
        if grep -q -E "(TU-USUARIO|USER|tu-repo)" "$archivo" 2>/dev/null; then
            echo -e "     ${RED}❌ Aún hay referencias genéricas${NC}"
            grep -n -E "(TU-USUARIO|USER|tu-repo)" "$archivo" | head -3 | while read line; do
                echo -e "        ${RED}→ $line${NC}"
            done
        else
            echo -e "     ${GREEN}✅ Sin referencias genéricas${NC}"
        fi
        
        ((REFERENCIAS_TOTALES++))
    else
        echo -e "   ${RED}❌ Archivo no encontrado: $archivo${NC}"
    fi
    echo ""
}

# Verificar archivos principales
verificar_archivo "build.sh" "Script de build público"
verificar_archivo "Makefile" "Script de make"
verificar_archivo "DISTRIBUTION.md" "Documentación de distribución"
verificar_archivo "install-remote.sh" "Instalador remoto"
verificar_archivo "dist-macos/DISTRIBUTION.md" "Documentación dist-macos"

echo -e "${CYAN}📊 Resumen de verificación:${NC}"
echo -e "   ${GREEN}• Referencias correctas: $REFERENCIAS_CORRECTAS/$REFERENCIAS_TOTALES${NC}"

# Verificar URLs funcionales
echo -e "${CYAN}🌐 Verificando URLs de GitHub...${NC}"

GITHUB_URL="https://github.com/johnolven/asis-coder"
RAW_URL="https://raw.githubusercontent.com/johnolven/asis-coder/main/install-remote.sh"

echo -e "   ${YELLOW}• URL principal: $GITHUB_URL${NC}"
echo -e "   ${YELLOW}• URL instalador: $RAW_URL${NC}"

# Verificar binarios
echo -e "${CYAN}📦 Verificando binarios...${NC}"

if [ -d "binaries" ]; then
    echo -e "   ${GREEN}✅ Directorio binaries existe${NC}"
    
    for binary in binaries/*; do
        if [ -f "$binary" ]; then
            SIZE=$(ls -lah "$binary" | awk '{print $5}')
            NAME=$(basename "$binary")
            echo -e "   ${GREEN}• $NAME ($SIZE)${NC}"
            
            # Verificar permisos
            if [ -x "$binary" ]; then
                echo -e "     ${GREEN}✅ Permisos de ejecución${NC}"
            else
                echo -e "     ${RED}❌ Sin permisos de ejecución${NC}"
            fi
        fi
    done
else
    echo -e "   ${RED}❌ Directorio binaries no encontrado${NC}"
fi

# Probar funcionalidad
echo -e "${CYAN}🧪 Probando funcionalidad...${NC}"

if ./coder.sh status >/dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Asis-coder funcional${NC}"
else
    echo -e "   ${RED}❌ Error en Asis-coder${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}🎉 VERIFICACIÓN COMPLETADA${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📋 Próximos pasos sugeridos:${NC}"
echo -e "   ${GREEN}1.${NC} Crear repositorio en GitHub: ${BOLD}https://github.com/new${NC}"
echo -e "   ${GREEN}2.${NC} Nombre del repo: ${BOLD}asis-coder${NC}"
echo -e "   ${GREEN}3.${NC} Descripción: ${BOLD}🚀 AI Code Assistant - More advanced than Claude Code${NC}"
echo -e "   ${GREEN}4.${NC} Push inicial: ${BOLD}git remote add origin https://github.com/johnolven/asis-coder.git${NC}"
echo -e "   ${GREEN}5.${NC} Crear release con binario para distribución${NC}"
echo ""
