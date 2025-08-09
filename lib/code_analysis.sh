#!/bin/bash

# ==========================================
# MÓDULO DE ANÁLISIS AVANZADO DE CÓDIGO - code_analysis.sh
# ==========================================
# Implementa funcionalidades avanzadas de análisis de código
# inspiradas en Claude Code y Gemini CLI

# Función para análisis completo del código
ejecutar_analisis_completo() {
    local archivo_contexto="$1"
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local PURPLE='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    if [[ -z "$archivo_contexto" || ! -f "$archivo_contexto" ]]; then
        echo -e "${YELLOW}⚠️ No se encontró contexto del proyecto. Generando...${NC}"
        generar_contexto
        archivo_contexto=$(encontrar_archivo_contexto)
    fi
    
    echo -e "${PURPLE}🧠 Pensamiento profundo activado para análisis...${NC}"
    echo -e "${DIM}   - Analizando arquitectura del proyecto...${NC}"
    echo -e "${DIM}   - Identificando patrones de diseño...${NC}"
    echo -e "${DIM}   - Evaluando calidad del código...${NC}"
    echo -e "${DIM}   - Buscando problemas potenciales...${NC}"
    echo ""
    
    local prompt_analisis="ANÁLISIS PROFUNDO DE CÓDIGO - Piensa paso a paso

Actúa como un arquitecto de software senior y analiza profundamente este proyecto.

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

INSTRUCCIONES:
1. ARQUITECTURA: Analiza la estructura general y patrones arquitectónicos
2. CALIDAD: Evalúa la calidad del código (legibilidad, mantenibilidad)  
3. PROBLEMAS: Identifica code smells, antipatrones y problemas potenciales
4. SEGURIDAD: Busca vulnerabilidades y problemas de seguridad
5. RENDIMIENTO: Identifica cuellos de botella y optimizaciones
6. MEJORAS: Sugiere mejoras específicas y priorizadas

FORMATO DE RESPUESTA:
📊 RESUMEN EJECUTIVO
🏗️ ANÁLISIS ARQUITECTÓNICO  
📈 MÉTRICAS DE CALIDAD
⚠️ PROBLEMAS IDENTIFICADOS
🛡️ CONSIDERACIONES DE SEGURIDAD
⚡ OPORTUNIDADES DE OPTIMIZACIÓN
🎯 RECOMENDACIONES PRIORIZADAS

Piensa profundamente sobre cada aspecto antes de responder."

    consultar_llm "$prompt_analisis"
}

# Función para refactorización
ejecutar_refactorizacion() {
    local archivo="$1"
    local archivo_contexto="$2"
    
    if [[ -n "$archivo" && -f "$archivo" ]]; then
        local contenido_archivo=$(cat "$archivo")
        local prompt_refactor="REFACTORIZACIÓN ESPECÍFICA

Archivo a refactorizar: $archivo

CONTENIDO ACTUAL:
$contenido_archivo

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto" 2>/dev/null || echo "No disponible")

Analiza este archivo y sugiere refactorizaciones específicas:
1. Eliminar código duplicado
2. Mejorar nombres de variables/funciones
3. Simplificar lógica compleja
4. Aplicar principios SOLID
5. Optimizar rendimiento

Proporciona código refactorizado con explicaciones."
    else
        local prompt_refactor="ANÁLISIS DE REFACTORIZACIÓN GENERAL

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Identifica oportunidades de refactorización en todo el proyecto:
1. Código duplicado entre archivos
2. Funciones/clases demasiado grandes
3. Responsabilidades mal distribuidas
4. Patrones que se pueden extraer
5. Mejoras en la estructura general

Prioriza las refactorizaciones por impacto y esfuerzo."
    fi
    
    consultar_llm "$prompt_refactor"
}

# Función para revisión de código
ejecutar_revision_codigo() {
    local archivo_contexto="$1"
    
    local prompt_review="REVISIÓN DE CÓDIGO PROFESIONAL

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Actúa como un senior developer haciendo code review. Analiza:

🔍 LEGIBILIDAD:
- Nombres descriptivos
- Comentarios útiles
- Estructura clara

🏗️ ARQUITECTURA:
- Separación de responsabilidades
- Principios SOLID
- Patrones de diseño

🐛 PROBLEMAS:
- Bugs potenciales
- Edge cases no manejados
- Lógica incorrecta

📊 MANTENIBILIDAD:
- Complejidad ciclomática
- Acoplamiento
- Cohesión

Proporciona feedback constructivo con ejemplos específicos."

    consultar_llm "$prompt_review"
}

# Función para análisis de seguridad
ejecutar_analisis_seguridad() {
    local archivo_contexto="$1"
    
    local prompt_security="ANÁLISIS DE SEGURIDAD DEL CÓDIGO

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Realiza un análisis de seguridad exhaustivo:

🛡️ VULNERABILIDADES COMUNES:
- Inyección SQL/NoSQL
- XSS (Cross-Site Scripting)
- CSRF (Cross-Site Request Forgery)
- Autenticación/Autorización débil

🔐 MANEJO DE DATOS:
- Validación de entrada
- Sanitización de datos
- Cifrado de información sensible
- Gestión de secretos

🌐 CONFIGURACIÓN:
- Configuraciones inseguras
- Exposición de información
- Permisos excesivos
- Headers de seguridad

⚠️ PRIORIZACIÓN:
Clasifica los problemas por severidad (Crítico/Alto/Medio/Bajo)."

    consultar_llm "$prompt_security"
}

# Función para análisis de rendimiento
ejecutar_analisis_rendimiento() {
    local archivo_contexto="$1"
    
    local prompt_performance="ANÁLISIS DE RENDIMIENTO

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Analiza el rendimiento del código:

⚡ CUELLOS DE BOTELLA:
- Consultas N+1
- Bucles ineficientes
- Operaciones costosas
- Memoria mal gestionada

📊 MÉTRICAS:
- Complejidad temporal (Big O)
- Uso de memoria
- I/O operations
- Llamadas a APIs

🚀 OPTIMIZACIONES:
- Caching strategies
- Lazy loading
- Batch operations
- Algoritmos más eficientes

📈 ESCALABILIDAD:
- Puntos de falla
- Límites de capacidad
- Estrategias de escalado

Proporciona mejoras concretas con impacto estimado."

    consultar_llm "$prompt_performance"
}

# Función para generación de tests
ejecutar_generacion_tests() {
    local archivo_contexto="$1"
    
    local prompt_tests="GENERACIÓN DE TESTS AUTOMÁTICOS

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Genera una estrategia completa de testing:

🧪 TIPOS DE TESTS:
- Unit tests para funciones críticas
- Integration tests para APIs
- End-to-end tests para flujos principales
- Performance tests para carga

📋 CASOS DE PRUEBA:
- Happy path scenarios
- Edge cases
- Error handling
- Boundary conditions

🛠️ HERRAMIENTAS:
- Framework de testing recomendado
- Mocking strategies
- Test data management
- CI/CD integration

💡 COBERTURA:
- Funciones críticas prioritarias
- Métricas de cobertura objetivo
- Tests de regresión

Genera código de tests específicos para las funciones más importantes."

    consultar_llm "$prompt_tests"
}

# Función para generación de documentación
ejecutar_generacion_docs() {
    local archivo_contexto="$1"
    
    local prompt_docs="GENERACIÓN DE DOCUMENTACIÓN

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Genera documentación completa:

📚 DOCUMENTACIÓN TÉCNICA:
- README mejorado
- Documentación de API
- Guías de instalación/configuración
- Arquitectura del sistema

👥 DOCUMENTACIÓN DE USUARIO:
- Guías de uso
- Ejemplos prácticos
- FAQ
- Troubleshooting

🔧 DOCUMENTACIÓN DE DESARROLLO:
- Guía de contribución
- Estándares de código
- Workflow de desarrollo
- Deployment guide

📝 COMENTARIOS EN CÓDIGO:
- Funciones complejas
- Lógica de negocio
- Algoritmos específicos
- Configuraciones críticas

Genera documentación en formato Markdown lista para usar."

    consultar_llm "$prompt_docs"
}

# Función para pensamiento profundo
ejecutar_pensamiento_profundo() {
    local tema="$1"
    local archivo_contexto="$2"
    
    local prompt_thinking="PENSAMIENTO PROFUNDO ACTIVADO

TEMA A ANALIZAR: $tema

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto" 2>/dev/null || echo "No disponible")

INSTRUCCIONES:
Piensa profundamente sobre este tema en el contexto del proyecto.

🧠 PROCESO DE PENSAMIENTO:
1. Analiza el problema desde múltiples ángulos
2. Considera implicaciones a corto y largo plazo
3. Evalúa diferentes alternativas
4. Identifica riesgos y beneficios
5. Proporciona recomendaciones fundamentadas

🎯 ASPECTOS A CONSIDERAR:
- Impacto técnico
- Complejidad de implementación
- Mantenibilidad futura
- Rendimiento
- Seguridad
- Experiencia del usuario
- Recursos necesarios

Muestra tu proceso de razonamiento paso a paso antes de llegar a conclusiones."

    consultar_llm "$prompt_thinking"
}

# Función para listar archivos del proyecto
listar_archivos_proyecto() {
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    echo -e "${CYAN}📁 Estructura del proyecto:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    
    # Usar tree si está disponible, sino usar find
    if command -v tree >/dev/null 2>&1; then
        tree -I 'node_modules|.git|dist|build|coverage' -L 3
    else
        find . -type f -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rb" -o -name "*.php" -o -name "*.java" -o -name "*.go" -o -name "*.rs" | grep -v node_modules | grep -v .git | head -20
    fi
    
    echo -e "${DIM}────────────────────────────────────────${NC}"
    echo -e "${YELLOW}💡 Usa ${CYAN}/focus <archivo>${YELLOW} para analizar un archivo específico${NC}"
}

# Función para enfocar en un archivo específico
enfocar_archivo() {
    local archivo="$1"
    
    if [[ -z "$archivo" ]]; then
        echo -e "${YELLOW}⚠️ Especifica un archivo: /focus src/components/Header.js${NC}"
        return
    fi
    
    if [[ ! -f "$archivo" ]]; then
        echo -e "${YELLOW}⚠️ Archivo no encontrado: $archivo${NC}"
        return
    fi
    
    local prompt_focus="ANÁLISIS ENFOCADO DE ARCHIVO

ARCHIVO: $archivo

CONTENIDO:
$(cat "$archivo")

Proporciona un análisis detallado de este archivo:

🔍 PROPÓSITO Y FUNCIONALIDAD
📊 CALIDAD DEL CÓDIGO
🐛 PROBLEMAS IDENTIFICADOS
🔧 SUGERENCIAS DE MEJORA
🧪 CASOS DE PRUEBA RECOMENDADOS

Sé específico y proporciona ejemplos de código mejorado donde sea necesario."

    consultar_llm "$prompt_focus"
}

# Función para generar resumen del proyecto
generar_resumen_proyecto() {
    local archivo_contexto="$1"
    
    local prompt_summary="RESUMEN EJECUTIVO DEL PROYECTO

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Genera un resumen ejecutivo completo:

🎯 DESCRIPCIÓN DEL PROYECTO
- Propósito y objetivos
- Funcionalidades principales
- Público objetivo

🛠️ STACK TECNOLÓGICO
- Lenguajes y frameworks
- Dependencias principales
- Herramientas de desarrollo

🏗️ ARQUITECTURA
- Patrones arquitectónicos
- Estructura de directorios
- Flujo de datos

📊 ESTADO ACTUAL
- Nivel de madurez
- Cobertura de tests
- Documentación disponible

🎯 PRÓXIMOS PASOS RECOMENDADOS
- Mejoras prioritarias
- Refactorizaciones necesarias
- Nuevas funcionalidades

Mantén el resumen conciso pero informativo."

    consultar_llm "$prompt_summary"
}

# Función para arreglar problemas específicos
ejecutar_fix_problema() {
    local problema="$1"
    local archivo_contexto="$2"
    
    local prompt_fix="SOLUCIÓN DE PROBLEMA ESPECÍFICO

PROBLEMA A RESOLVER: $problema

CONTEXTO DEL PROYECTO:
$(cat "$archivo_contexto")

Proporciona una solución completa:

🔍 ANÁLISIS DEL PROBLEMA
- Causa raíz
- Impacto actual
- Archivos afectados

🔧 SOLUCIÓN PROPUESTA
- Código específico para el fix
- Pasos de implementación
- Consideraciones adicionales

🧪 VALIDACIÓN
- Cómo probar la solución
- Casos de prueba
- Posibles efectos secundarios

📝 DOCUMENTACIÓN
- Cambios necesarios en docs
- Notas para el equipo

Proporciona código listo para implementar."

    consultar_llm "$prompt_fix"
}

# Función auxiliar para mostrar respuesta con streaming
mostrar_respuesta_streaming() {
    local pid="$1"
    local temp_file="$2"
    
    local last_size=0
    local pensando_mostrado=true
    local respuesta_acumulada=""
    
    while kill -0 $pid 2>/dev/null; do
        current_size=$(wc -c < "$temp_file")
        if [ "$current_size" -gt "$last_size" ]; then
            if $pensando_mostrado; then
                echo -ne "\r\033[K"  # Borrar la línea actual
                echo -n "$(get_text "assistant"): "
                pensando_mostrado=false
            fi
            nuevo_contenido=$(tail -c +$((last_size + 1)) "$temp_file")
            respuesta_acumulada+="$nuevo_contenido"
            
            # Detectar y formatear código
            if echo "$respuesta_acumulada" | grep -q '```'; then
                IFS='```' read -ra ADDR <<< "$respuesta_acumulada"
                for i in "${!ADDR[@]}"; do
                    if (( i % 2 == 1 )); then
                        echo -e "\n\033[36m```"  # Cyan
                        dar_formato_codigo "${ADDR[$i]}"
                        echo -e "```\033[0m"  # Reset color
                    else
                        echo -n "${ADDR[$i]}"
                    fi
                done
            else
                echo -n "$nuevo_contenido"
            fi
            
            last_size=$current_size
        fi
        sleep 0.1
    done
    
    # Asegurarse de que se muestre el contenido final
    if $pensando_mostrado; then
        echo -ne "\r\033[K"  # Borrar la línea actual
        echo -n "$(get_text "assistant"): "
    fi
    nuevo_contenido=$(tail -c +$((last_size + 1)) "$temp_file")
    respuesta_acumulada+="$nuevo_contenido"
    
    # Formatear el contenido final si es necesario
    if echo "$respuesta_acumulada" | grep -q '```'; then
        IFS='```' read -ra ADDR <<< "$respuesta_acumulada"
        for i in "${!ADDR[@]}"; do
            if (( i % 2 == 1 )); then
                echo -e "\n\033[36m```"  # Cyan
                dar_formato_codigo "${ADDR[$i]}"
                echo -e "```\033[0m"  # Reset color
            else
                echo -n "${ADDR[$i]}"
            fi
        done
    else
        echo -n "$nuevo_contenido"
    fi
    echo  # Nueva línea después de la respuesta completa
} 