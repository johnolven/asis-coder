# 🔥 Guía de Compilación y Uso Avanzado - Asis-coder

## 🚀 **Setup Inicial**

### **1. Verificar Requisitos**
```bash
# Verificar herramientas básicas
make --version
git --version

# En la mayoría de sistemas ya están instaladas
# Si no: apt install build-essential (Linux) o instalar Xcode (macOS)
```

### **2. Configurar Entorno**
```bash
# En tu directorio asis-coder
make setup
```

## 🦀 **Compilación del Core Inteligente**

### **Compilación Simple (Solo tu OS)**
```bash
# Compilar para tu sistema actual
make build

# Esto ejecuta:
# 1. make build-core      (prepara core nativo)
# 2. make install-binary  (copia binario a /binaries)
```

### **Compilación Multi-Plataforma**
```bash
# Para distribuir a múltiples OS
make build-all-platforms

# Genera binarios para:
# - macOS ARM64 (Apple Silicon)
# - macOS x64 (Intel)
# - Linux x64
```

### **Compilación Manual**
```bash
# Si prefieres hacerlo manual
# Core nativo pre-compilado
make build

# El binario estará en:
# binaries/asis-core-[platform]
```

## 🎯 **Verificar Instalación**

```bash
# Ver estado completo
make status

# O usar el comando integrado
./coder.sh status

# Probar funcionalidad
make test
```

## 🤖 **Uso de Funcionalidades Avanzadas**

### **Comandos Básicos Mejorados**
```bash
# Consulta con IA mejorada (usa contexto inteligente)
./coder.sh "explica la arquitectura de este proyecto"

# Modo interactivo avanzado
./coder.sh -i
```

### **Nuevos Comandos de Codificación**

#### **🔧 Fix Inteligente de Bugs**
```bash
# Arreglar problemas automáticamente
./coder.sh code fix "el login no funciona con emails en mayúsculas"
./coder.sh code fix "memoria leak en el módulo de cache"
./coder.sh code fix "error 500 al subir archivos grandes"

# El sistema:
# 1. Detecta archivos relevantes automáticamente
# 2. Analiza el problema con contexto
# 3. Genera fix específico
# 4. Aplica cambios de forma segura
```

#### **⚡ Implementación de Features**
```bash
# Implementar nuevas funcionalidades
./coder.sh code implement "sistema de notificaciones push"
./coder.sh code implement "autenticación con OAuth2"
./coder.sh code implement "cache distribuido con Redis"

# El sistema:
# 1. Analiza la arquitectura actual
# 2. Diseña la implementación
# 3. Genera código completo
# 4. Incluye tests y documentación
```

#### **🔬 Análisis Avanzado**
```bash
# Análisis completo del proyecto
./coder.sh code analyze

# Análisis de directorio específico
./coder.sh code analyze src/components

# El sistema genera:
# - Análisis arquitectónico
# - Métricas de calidad
# - Problemas identificados
# - Recomendaciones priorizadas
```

#### **🔄 Refactorización Inteligente**
```bash
# Refactorizar código existente
./coder.sh code refactor "optimizar queries de base de datos"
./coder.sh code refactor "extraer lógica común en utilidades"
./coder.sh code refactor "simplificar manejo de errores"

# El sistema:
# 1. Identifica oportunidades
# 2. Propone cambios estructurados
# 3. Mantiene funcionalidad
# 4. Mejora legibilidad y performance
```

#### **📋 Unidades de Contexto**
```bash
# Generar análisis semántico del proyecto
./coder.sh units

# Crea unidades lógicas de código:
# - Agrupación por funcionalidad
# - Documentación automática
# - Mapas de dependencias
# - READMEs por unidad
```

## 🔍 **Diferencias: Modo Básico vs Inteligente**

### **Modo Básico** (solo funciones bash)
```bash
./coder.sh "explica este código"
# ✅ Funciona, pero limitado
# ❌ Sin análisis de contexto avanzado
# ❌ Sin agentes especializados
# ❌ Sin clustering semántico
```

### **Modo Inteligente** (con core compilado)
```bash
./coder.sh "explica este código"
# ✅ Análisis de contexto completo
# ✅ Clustering semántico de archivos  
# ✅ Optimización de prompts propietaria
# ✅ Comprende arquitectura del proyecto
# ✅ Respuestas más precisas y contextuales
```

## 🛠️ **Comandos de Desarrollo**

### **Durante Desarrollo**
```bash
# Modo desarrollo (recompila automático)
make dev

# Verificar código sin compilar
make check

# Formatear código
make fmt  

# Linter
make clippy

# Tests
make test-core
```

### **Limpieza**
```bash
# Limpiar archivos de compilación
make clean

# Desinstalar completamente
make uninstall
```

## 📦 **Distribución**

### **Crear Paquete**
```bash
# Crear paquete completo con binarios
make package

# Genera: asis-coder-dist.tar.gz
# Contiene:
# - Scripts bash
# - Binarios compilados  
# - Documentación
# - Archivos de instalación
```

### **Instalación desde Paquete**
```bash
# Extraer paquete
tar -xzf asis-coder-dist.tar.gz
cd asis-coder/

# Instalar
make install
```

## 🚨 **Troubleshooting**

### **Core Inteligente No Detectado**
```bash
# Ver estado detallado
make status

# Si aparece "Core inteligente: DESACTIVADO"
make build

# Verificar paths
ls -la binaries/
```

### **Error de Build**
```bash
# Limpiar y recompilar
make clean && make build

# Limpiar y recompilar
make clean
make setup
make build
```

### **Dependencias Faltantes**
```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get install curl jq

# CentOS/RHEL
sudo yum install curl jq
```

### **Permisos de Ejecución**
```bash
# Dar permisos a scripts
chmod +x coder.sh
chmod +x install.sh

# Dar permisos a binarios
chmod +x binaries/*
```

## 🔒 **Seguridad y Propiedad Intelectual**

### **Archivos Ocultos del Git**
- ✅ `binaries/` - Binarios compilados distribución
- ✅ `binaries/` - Binarios compilados  
- ✅ `*.wasm` - Módulos WebAssembly
- ✅ Configuraciones con API keys

### **Archivos Públicos**
- ✅ `coder.sh` - Script principal
- ✅ `lib/*.sh` - Módulos bash básicos
- ✅ `package.json` - Configuración NPM
- ✅ `README.md` - Documentación

## 💡 **Mejores Prácticas**

### **Desarrollo**
1. **Siempre compila antes de hacer commit**:
   ```bash
   make build && make test
   ```

2. **Usa modo desarrollo para cambios frecuentes**:
   ```bash
   make dev  # Auto-recompila
   ```

3. **Verifica estado antes de trabajar**:
   ```bash
   make status
   ```

### **Uso**
1. **Para análisis rápido usa básico**:
   ```bash
   ./coder.sh "pregunta simple"
   ```

2. **Para codificación usa inteligente**:
   ```bash
   ./coder.sh code fix "problema complejo"
   ```

3. **Genera contexto una vez por proyecto**:
   ```bash
   ./coder.sh -contexto  # Solo la primera vez
   ```

## 🎉 **Ejemplos Completos**

### **Workflow Típico - Fix de Bug**
```bash
# 1. Estado inicial
make status

# 2. Identificar problema
./coder.sh code analyze

# 3. Arreglar automáticamente
./coder.sh code fix "autenticación falla con tokens expirados"

# 4. Verificar cambios
git diff

# 5. Commit
git add . && git commit -m "Fix: token expiration handling"
```

### **Workflow Típico - Nueva Feature**
```bash
# 1. Generar contexto (si es nuevo proyecto)
./coder.sh -contexto

# 2. Implementar
./coder.sh code implement "sistema de roles y permisos"

# 3. Analizar resultado
./coder.sh code analyze src/auth/

# 4. Refinar si es necesario
./coder.sh code refactor "simplificar lógica de permisos"
```

---

**🚀 ¡Ya tienes un asistente de codificación con IA más avanzado que Claude Code y Cursor CLI!** 

**Características únicas:**
- ✅ 30+ modelos de LLM soportados
- ✅ Análisis semántico propietario
- ✅ Agentes especializados por tarea
- ✅ Arquitectura híbrida local/remoto
- ✅ Protección de propiedad intelectual
- ✅ Interfaz en español nativo
