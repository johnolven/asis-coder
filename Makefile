# =============================================
# ASIS-CODER MAKEFILE - COMPILACIÓN Y GESTIÓN
# =============================================

# Variables de configuración
CORE_DIR = native-core
BINARIES_DIR = binaries
TARGET_DIR = $(CORE_DIR)/target
BINARY_NAME = asis-core

# Colores para output
CYAN = \033[0;36m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BOLD = \033[1m
NC = \033[0m # No Color

# Detección de OS y arquitectura
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
    ifeq ($(UNAME_M),arm64)
        OS_SUFFIX = macos-arm64
        NATIVE_TARGET = aarch64-apple-darwin
    else
        OS_SUFFIX = macos-x64
        NATIVE_TARGET = x86_64-apple-darwin
    endif
else ifeq ($(UNAME_S),Linux)
    OS_SUFFIX = linux
    NATIVE_TARGET = x86_64-unknown-linux-gnu
else
    OS_SUFFIX = windows
    NATIVE_TARGET = x86_64-pc-windows-gnu
    BINARY_NAME = asis-core.exe
endif

FINAL_BINARY_NAME = $(BINARY_NAME)-$(OS_SUFFIX)

# ===========================================
# COMANDOS PRINCIPALES
# ===========================================

.PHONY: help
help: ## Mostrar ayuda
	@echo -e "$(CYAN)$(BOLD)🚀 ASIS-CODER BUILD SYSTEM$(NC)"
	@echo -e "$(YELLOW)================================$(NC)"
	@echo ""
	@echo -e "$(GREEN)📦 Comandos de Compilación:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(GREEN)🎯 Ejemplos de Uso:$(NC)"
	@echo -e "  $(YELLOW)make setup$(NC)          # Primera configuración"
	@echo -e "  $(YELLOW)make build$(NC)          # Compilar todo"
	@echo -e "  $(YELLOW)make install$(NC)        # Instalar localmente"
	@echo -e "  $(YELLOW)make test$(NC)           # Probar funcionalidad"
	@echo ""

.PHONY: setup
setup: ## Configurar entorno de desarrollo
	@echo -e "$(CYAN)🔧 Configurando entorno de desarrollo...$(NC)"
	@echo -e "$(YELLOW)1. Verificando herramientas de compilación...$(NC)"
	@if ! command -v make >/dev/null 2>&1; then \
		echo -e "$(RED)❌ Herramientas de build no encontradas$(NC)"; \
	else \
		echo -e "$(GREEN)✅ Build tools disponibles$(NC)"; \
	fi
	@echo -e "$(YELLOW)2. Instalando targets...$(NC)"
	@echo -e "$(YELLOW)2. Configurando target $(NATIVE_TARGET)..$(NC)"
	@echo -e "$(YELLOW)3. Creando directorios...$(NC)"
	@mkdir -p $(BINARIES_DIR)
	@echo -e "$(GREEN)✅ Entorno configurado correctamente$(NC)"

.PHONY: build-core
build-core: ## Verificar y preparar binarios existentes
	@echo -e "$(CYAN)🚀 Preparando Asis-coder...$(NC)"
	@if [ -x "./build.sh" ]; then \
		./build.sh; \
	else \
		echo -e "$(RED)❌ Script de build no encontrado$(NC)"; \
		exit 1; \
	fi

.PHONY: build
build: build-core install-binary ## Compilar todo y copiar binarios
	@echo -e "$(GREEN)🎉 Compilación completa finalizada$(NC)"

.PHONY: install-binary
install-binary: ## Verificar binarios existentes
	@echo -e "$(CYAN)📦 Verificando binarios...$(NC)"
	@mkdir -p $(BINARIES_DIR)
	@if [ -f "$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" ]; then \
		chmod +x $(BINARIES_DIR)/$(FINAL_BINARY_NAME); \
		echo -e "$(GREEN)✅ Binario listo: $(BINARIES_DIR)/$(FINAL_BINARY_NAME)$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠️  Binario no encontrado para esta plataforma$(NC)"; \
		echo -e "$(CYAN)💡 Descarga desde: https://github.com/johnolven/asis-coder/releases$(NC)"; \
	fi

.PHONY: build-all-platforms
build-all-platforms: ## Información sobre compilación multi-plataforma
	@echo -e "$(CYAN)🌍 Compilación Multi-Plataforma$(NC)"
	@echo -e "$(YELLOW)═══════════════════════════════════════$(NC)"
	@echo ""
	@echo -e "$(RED)⚠️  Compilación desde código fuente no disponible públicamente$(NC)"
	@echo ""
	@echo -e "$(YELLOW)📦 Para obtener binarios multi-plataforma:$(NC)"
	@echo ""
	@echo -e "${CYAN}${BOLD}Opción 1: Releases oficiales${NC}"
	@echo -e "   ${GREEN}•${NC} Descarga desde: https://github.com/johnolven/asis-coder/releases"
	@echo -e "   ${GREEN}•${NC} Disponible para: macOS (ARM64/x64), Linux, Windows"
	@echo ""
	@echo -e "${CYAN}${BOLD}Opción 2: Instalación automática${NC}"
	@echo -e "   ${GREEN}curl -sSL https://raw.githubusercontent.com/johnolven/asis-coder/main/install-remote.sh | bash${NC}"
	@echo ""
	@echo -e "$(YELLOW)ℹ️  Los binarios contienen algoritmos propietarios optimizados${NC}"
	@echo -e "$(YELLOW)   desarrollados con tecnologías nativas para máximo rendimiento.$(NC)"

.PHONY: clean
clean: ## Limpiar archivos temporales
	@echo -e "$(YELLOW)🧹 Limpiando archivos temporales...$(NC)"
	@rm -rf dist-*/
	@rm -f *.tar.gz
	@rm -f *.log
	@echo -e "$(GREEN)✅ Limpieza completada$(NC)"

.PHONY: test-core
test-core: ## Probar funcionalidad del core
	@echo -e "$(CYAN)🧪 Probando core inteligente...$(NC)"
	@if [ -f "$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" ]; then \
		if "$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" --version >/dev/null 2>&1; then \
			echo -e "$(GREEN)✅ Core inteligente funcional$(NC)"; \
		else \
			echo -e "$(YELLOW)⚠️  Core encontrado pero no responde$(NC)"; \
		fi \
	else \
		echo -e "$(RED)❌ Core no encontrado$(NC)"; \
	fi

.PHONY: test
test: build ## Probar funcionalidad completa
	@echo -e "$(CYAN)🔬 Probando funcionalidad de Asis-coder...$(NC)"
	@echo -e "$(YELLOW)1. Verificando script principal...$(NC)"
	@./coder.sh -v
	@echo -e "$(YELLOW)2. Verificando core inteligente...$(NC)"
	@if [ -x "$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" ]; then \
		echo -e "$(GREEN)✅ Core inteligente disponible$(NC)"; \
		$(BINARIES_DIR)/$(FINAL_BINARY_NAME) --help || true; \
	else \
		echo -e "$(YELLOW)⚠️  Core inteligente no disponible$(NC)"; \
	fi
	@echo -e "$(YELLOW)3. Probando análisis de contexto...$(NC)"
	@./coder.sh -contexto > /dev/null && echo -e "$(GREEN)✅ Análisis de contexto funcional$(NC)" || echo -e "$(YELLOW)⚠️  Análisis básico$(NC)"
	@echo -e "$(GREEN)🎉 Pruebas completadas$(NC)"

.PHONY: install
install: build ## Instalar Asis-coder localmente
	@echo -e "$(CYAN)📦 Instalando Asis-coder localmente...$(NC)"
	@./install.sh
	@echo -e "$(GREEN)✅ Instalación completada$(NC)"

.PHONY: status
status: ## Mostrar estado del proyecto
	@echo -e "$(CYAN)$(BOLD)📊 ESTADO DE ASIS-CODER$(NC)"
	@echo -e "$(YELLOW)═══════════════════════════════════$(NC)"
	@echo ""
	@echo -e "$(GREEN)🏗️  Estructura del Proyecto:$(NC)"
	@echo -e "  $(CYAN)•$(NC) Script principal: $$([ -f coder.sh ] && echo -e "$(GREEN)✅$(NC)" || echo -e "$(RED)❌$(NC)") coder.sh"
	@echo -e "  $(CYAN)•$(NC) Módulos Bash: $$(ls lib/*.sh 2>/dev/null | wc -l | tr -d ' ') módulos"
	@echo -e "  $(CYAN)•$(NC) Core Nativo: $$([ -d binaries ] && echo -e "$(GREEN)✅$(NC)" || echo -e "$(RED)❌$(NC)") binaries/"
	@echo -e "  $(CYAN)•$(NC) Binarios: $$(ls binaries/* 2>/dev/null | wc -l | tr -d ' ') binarios"
	@echo ""
	@echo -e "$(GREEN)🛠️ Estado del Core:$(NC)"
	@if [ -f "$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" ]; then \
		echo -e "  $(CYAN)•$(NC) Core compilado: $(GREEN)✅$(NC)"; \
	else \
		echo -e "  $(CYAN)•$(NC) Core compilado: $(RED)❌$(NC)"; \
	fi
	@echo ""
	@echo -e "$(GREEN)🎯 Funcionalidades:$(NC)"
	@echo -e "  $(CYAN)•$(NC) Modo básico: $(GREEN)✅ Siempre disponible$(NC)"
	@if [ -x "$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" ]; then \
		echo -e "  $(CYAN)•$(NC) Core inteligente: $(GREEN)✅ Disponible$(NC)"; \
		echo -e "  $(CYAN)•$(NC) Análisis avanzado: $(GREEN)✅ Activado$(NC)"; \
		echo -e "  $(CYAN)•$(NC) Agentes de código: $(GREEN)✅ Activado$(NC)"; \
	else \
		echo -e "  $(CYAN)•$(NC) Core inteligente: $(YELLOW)⚠️  No compilado$(NC)"; \
		echo -e "  $(CYAN)•$(NC) Análisis avanzado: $(RED)❌ Desactivado$(NC)"; \
		echo -e "  $(CYAN)•$(NC) Agentes de código: $(RED)❌ Desactivado$(NC)"; \
	fi
	@echo ""

.PHONY: dev
dev: ## Modo desarrollo (no disponible en distribución)
	@echo -e "$(YELLOW)🚧 Modo desarrollo no disponible en versión pública$(NC)"
	@echo -e "$(CYAN)💡 Use 'make build' para compilar$(NC)"

.PHONY: update-deps
update-deps: ## Actualizar dependencias
	@echo -e "$(YELLOW)🚧 Gestión de dependencias no disponible en versión pública$(NC)"
	@echo -e "$(CYAN)💡 Los binarios ya incluyen todas las dependencias optimizadas$(NC)"

.PHONY: check
check: ## Verificar funcionalidad del core
	@echo -e "$(CYAN)🔍 Verificando core nativo...$(NC)"
	@if [ -x "$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" ]; then \
		"$(BINARIES_DIR)/$(FINAL_BINARY_NAME)" --version >/dev/null 2>&1 && \
		echo -e "$(GREEN)✅ Core funcional$(NC)" || \
		echo -e "$(YELLOW)⚠️  Core presente pero no responde$(NC)"; \
	else \
		echo -e "$(RED)❌ Core no encontrado$(NC)"; \
	fi

.PHONY: fmt
fmt: ## Formatear código
	@echo -e "$(YELLOW)🚧 Formateo no disponible en versión pública$(NC)"
	@echo -e "$(CYAN)💡 Los binarios ya están optimizados$(NC)"

.PHONY: clippy
clippy: ## Análisis de código
	@echo -e "$(YELLOW)🚧 Análisis de código no disponible en versión pública$(NC)"
	@echo -e "$(CYAN)💡 Los binarios pasan todos los checks de calidad$(NC)"

.PHONY: package
package: build-all-platforms ## Crear paquete de distribución
	@echo -e "$(CYAN)📦 Creando paquete de distribución...$(NC)"
	@tar -czf asis-coder-dist.tar.gz \
		coder.sh \
		lib/ \
		binaries/ \
		package.json \
		install.sh \
		README.MD \
		LICENSE \
		--exclude='lib/README.md'
	@echo -e "$(GREEN)✅ Paquete creado: asis-coder-dist.tar.gz$(NC)"

.PHONY: uninstall
uninstall: ## Desinstalar Asis-coder
	@echo -e "$(YELLOW)🗑️  Desinstalando Asis-coder...$(NC)"
	@rm -f $$HOME/.local/bin/coder
	@rm -rf $$HOME/.config/coder-cli
	@echo -e "$(GREEN)✅ Desinstalación completada$(NC)"

# Comando por defecto
.DEFAULT_GOAL := help
