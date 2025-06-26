# 📚 Estructura Modular de Asis-coder

Esta carpeta contiene todos los módulos que componen el sistema Asis-coder, organizados de manera modular para facilitar el mantenimiento y desarrollo.

## 🏗️ Arquitectura Modular

### Beneficios de la Modularización:
- ✅ **Mantenimiento más fácil**: Cada módulo tiene una responsabilidad específica
- ✅ **Desarrollo colaborativo**: Múltiples desarrolladores pueden trabajar en diferentes módulos
- ✅ **Reutilización de código**: Los módulos pueden ser reutilizados en otros proyectos
- ✅ **Debugging simplificado**: Es más fácil encontrar y corregir errores
- ✅ **Testing individual**: Cada módulo puede ser probado por separado

## 📁 Módulos Disponibles

### 1. `config.sh` - Módulo de Configuración
**Responsabilidad**: Gestión de configuración del sistema, variables de entorno y archivos de configuración.

**Funciones principales**:
- `init_config_directories()` - Inicializar directorios necesarios
- `log()` - Sistema de logging
- `update_config_value()` - Actualizar valores de configuración
- `get_config_value()` - Obtener valores de configuración
- `get_api_config()` - Cargar configuración de APIs
- `mostrar_estado_configuracion()` - Mostrar estado completo
- `check_dependencies()` - Verificar dependencias del sistema
- `setup_environment()` - Configurar entorno
- `cleanup()` - Limpieza de archivos temporales

**Variables globales**:
```bash
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config/coder-cli"
BIN_DIR="$USER_HOME/.local/bin"
LOG_FILE="$CONFIG_DIR/coder.log"
CONFIG_FILE="$CONFIG_DIR/config.json"
DEBUG=false
VERSION="1.0.1"
```

### 2. `api_validation.sh` - Módulo de Validación de APIs
**Responsabilidad**: Validación de APIs de ChatGPT, Claude y Gemini, manejo de errores y diagnósticos.

**Funciones principales**:
- `validar_chatgpt_api()` - Validar API de ChatGPT
- `validar_claude_api()` - Validar API de Claude
- `validar_gemini_api()` - Validar API de Gemini
- `mostrar_estado_validacion()` - Mostrar estado de validación
- `mostrar_error_configuracion()` - Mostrar errores de configuración
- `probar_configuracion_api()` - Probar configuración completa

**Características**:
- Detección específica de errores (créditos, API keys inválidas)
- Mensajes informativos con enlaces de solución
- Validación previa antes de hacer consultas

### 3. `llm_models.sh` - Módulo de Gestión de LLMs
**Responsabilidad**: Selección de LLMs, gestión de modelos disponibles y configuración de API keys.

**Funciones principales**:
- `update_llm_choice()` - Actualizar selección de LLM
- `update_api_token()` - Configurar API keys
- `update_model()` - Seleccionar modelo específico
- `list_chatgpt_models()` - Listar modelos de ChatGPT (14 modelos)
- `list_claude_models()` - Listar modelos de Claude (8 modelos)
- `list_gemini_models()` - Listar modelos de Gemini (8 modelos)

**Modelos soportados**:
- **ChatGPT**: gpt-3.5-turbo → gpt-4.5 (14 modelos)
- **Claude**: claude-3-haiku → claude-opus-4 (8 modelos)
- **Gemini**: gemini-1.5-flash → gemini-2.5-pro (8 modelos)

### 4. `project_manager.sh` - Módulo de Gestión de Proyectos
**Responsabilidad**: Detección de tipos de proyecto, generación de contexto y gestión de archivos.

**Funciones principales**:
- `detectar_tipo_proyecto()` - Detección automática de tipo de proyecto
- `preguntar_tipo_proyecto_manual()` - Selección manual de tipo
- `definir_directorios_y_ignorar()` - Configurar directorios según tipo
- `es_archivo_texto()` - Verificar si un archivo es de texto
- `leer_archivos()` - Lectura recursiva de archivos
- `generar_contexto()` - Generar archivo de contexto
- `encontrar_archivo_contexto()` - Buscar archivo de contexto
- `detectar_proyecto_actual()` - Detectar proyecto para UI
- `inicializar_proyecto()` - Inicializar proyecto con Asis-coder
- `crear_guia_proyecto()` - Crear archivo CODER.md

**Tipos de proyecto soportados**:
- React, Node.js, Vue.js, Angular
- Ruby on Rails, Laravel
- Python (Flask/Django), Spring Boot
- Express.js, Flutter

### 5. `ui_interface.sh` - Módulo de Interfaz de Usuario
**Responsabilidad**: Todas las interfaces de usuario, pantallas de bienvenida y presentación visual.

**Funciones principales**:
- `mostrar_ui_interactivo()` - UI del modo interactivo
- `validar_y_mostrar_ui()` - Validar y mostrar UI principal
- `mostrar_ui_principal()` - UI principal con banner ASCII
- `mostrar_ui_bienvenida()` - UI de bienvenida para setup
- `dar_formato_codigo()` - Formatear código con colores
- `configuracion_inicial_completa()` - Proceso de configuración guiado

**Características visuales**:
- Banners ASCII art profesionales
- Colores y emojis para mejor UX
- Información de estado en tiempo real
- Guías paso a paso para configuración

### 6. `llm_communication.sh` - Módulo de Comunicación con LLMs
**Responsabilidad**: Comunicación con APIs de LLMs, modo interactivo y manejo de respuestas.

**Funciones principales**:
- `json_escape()` - Escapar JSON para APIs
- `consultar_llm()` - Función principal de consulta
- `modo_interactivo()` - Modo chat interactivo
- `limpiar_historial()` - Limpiar historial de conversaciones
- `nuevo_hito()` - Crear nuevo hito de conversación
- `mostrar_historiales()` - Mostrar historiales guardados

**Características avanzadas**:
- Streaming de respuestas en tiempo real
- Formateo automático de código
- Gestión de historial por sesión
- Manejo de errores específicos por API

## 🔧 Script Principal: `coder_modular.sh`

El script principal se encarga de:
1. **Verificar estructura**: Confirma que el directorio `lib/` existe
2. **Cargar módulos**: Importa todos los módulos en orden correcto
3. **Inicializar sistema**: Configura directorios y variables
4. **Ejecutar función main**: Maneja todos los comandos disponibles

### Orden de carga de módulos:
1. `config.sh` (primero - define variables globales)
2. `api_validation.sh`
3. `llm_models.sh`
4. `project_manager.sh`
5. `ui_interface.sh`
6. `llm_communication.sh` (último - depende de todos los demás)

## 🚀 Cómo Usar la Estructura Modular

### Para Desarrolladores:

1. **Agregar nueva funcionalidad**:
   - Identifica el módulo apropiado
   - Agrega la función al módulo correspondiente
   - No olvides documentar la función

2. **Crear nuevo módulo**:
   ```bash
   # Crear nuevo módulo
   touch lib/nuevo_modulo.sh
   
   # Agregar al script principal
   # Editar coder_modular.sh y agregar:
   if [ -f "$LIB_DIR/nuevo_modulo.sh" ]; then
       source "$LIB_DIR/nuevo_modulo.sh"
       echo "✅ Nuevo módulo cargado"
   fi
   ```

3. **Debugging por módulo**:
   ```bash
   # Probar función específica
   source lib/config.sh
   log "Test message"
   
   # Probar módulo completo
   bash -x lib/api_validation.sh
   ```

### Para Usuarios:

La estructura modular es transparente para los usuarios. Todos los comandos funcionan igual:

```bash
./coder_modular.sh setup    # Configuración inicial
./coder_modular.sh -i       # Modo interactivo
./coder_modular.sh "pregunta" # Consulta directa
```

## 📈 Beneficios de Rendimiento

- **Carga selectiva**: Solo se cargan las funciones necesarias
- **Memoria optimizada**: Cada módulo gestiona su propia memoria
- **Ejecución más rápida**: Funciones organizadas y optimizadas
- **Debugging eficiente**: Errores localizados por módulo

## 🔮 Futuras Mejoras

- **Carga dinámica**: Cargar módulos solo cuando se necesiten
- **Módulos opcionales**: Permitir funcionalidad opcional
- **API de módulos**: Interfaz estándar para nuevos módulos
- **Testing automatizado**: Tests unitarios por módulo
- **Documentación automática**: Generar docs desde comentarios

---

**¡La estructura modular hace que Asis-coder sea más potente, mantenible y fácil de expandir!** 🚀 