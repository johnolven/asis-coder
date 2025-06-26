# 🤖 Asis-coder: Tu Asistente de Desarrollo IA

Un potente CLI modular que conecta tu código con modelos de IA como ChatGPT, Claude y Gemini para acelerar tu desarrollo.

## ⚡ Instalación Rápida

### Un solo comando:
```bash
curl -fsSL https://raw.githubusercontent.com/tu-usuario/asis-coder/main/install.sh | bash
```

### O clona y ejecuta:
```bash
git clone https://github.com/tu-usuario/asis-coder.git
cd asis-coder
./install.sh
```

## 🚀 Inicio Rápido

1. **Configuración inicial:**
   ```bash
   coder setup
   ```

2. **Inicializa tu proyecto:**
   ```bash
   cd tu-proyecto
   coder /init
   ```

3. **¡Comienza a preguntar!**
   ```bash
   coder "explica este proyecto"
   coder -i  # modo interactivo
   ```

## ✨ Características

### 🏗️ **Arquitectura Modular**
- Código organizado en módulos especializados
- Fácil mantenimiento y extensión
- Desarrollo colaborativo optimizado
- Testing individual por módulo

### 🔍 **Detección Automática de Proyectos**
- React, Vue, Angular, Node.js
- Python (Flask, Django), Ruby on Rails
- Java (Spring Boot), PHP (Laravel)
- Flutter, y más...

### 🤖 **Múltiples Modelos IA (30 modelos)**
- **ChatGPT**: gpt-4o, gpt-4-turbo, gpt-3.5-turbo, y más
- **Claude**: claude-3.5-sonnet, claude-3-opus, claude-3-haiku
- **Gemini**: gemini-1.5-pro, gemini-1.5-flash, gemini-pro

### 💬 **Modo Interactivo Avanzado**
- Chat continuo con contexto
- Historial de conversaciones
- Formateo de código con colores
- Respuestas en tiempo real

### 🛠️ **Comandos Útiles**

| Comando | Descripción |
|---------|-------------|
| `coder setup` | Configuración inicial completa |
| `coder /init` | Inicializar proyecto (genera CODER.md) |
| `coder -contexto` | Generar/actualizar contexto |
| `coder -i` | Modo chat interactivo |
| `coder -llm` | Cambiar modelo IA |
| `coder "pregunta"` | Consulta directa |

## 🎯 Ejemplos de Uso

### Análisis de Código
```bash
coder "¿qué hace esta función y cómo puedo optimizarla?"
coder "encuentra bugs potenciales en mi código"
coder "explica la arquitectura de este proyecto"
```

### Generación de Código
```bash
coder "crea tests unitarios para el módulo de autenticación"
coder "genera documentación API para mis endpoints"
coder "refactoriza este código para usar async/await"
```

### Debugging
```bash
coder "por qué falla este test?"
coder "cómo puedo mejorar el rendimiento de esta consulta?"
coder "sugiere mejores prácticas para este componente"
```

## 🔧 Configuración Avanzada

### Variables de Entorno
```bash
export CODER_DEFAULT_LLM="chatgpt"
export CODER_DEFAULT_MODEL="gpt-4o-mini"
export CODER_DEBUG="true"
```

### Archivos de Configuración
- **Config**: `~/.config/coder-cli/config.json`
- **Logs**: `~/.config/coder-cli/coder.log`
- **Historial**: `~/.config/coder-cli/historial_chat*.txt`

## 🚨 Importante: API Keys

Necesitarás obtener tokens de API:

### ChatGPT (OpenAI)
1. Ve a [platform.openai.com](https://platform.openai.com/)
2. Crea una cuenta y ve a "API Keys"
3. Genera un nuevo token

### Claude (Anthropic)
1. Ve a [console.anthropic.com](https://console.anthropic.com/)
2. Regístrate y obtén acceso a la API
3. Genera tu token en el dashboard

### Gemini (Google)
1. Ve a [makersuite.google.com](https://makersuite.google.com/)
2. Obtén tu API key gratuita
3. Configúrala en el setup inicial

## 🛡️ Seguridad

- ✅ Tokens encriptados localmente
- ✅ Conexión directa a APIs (sin servidores intermedios)
- ✅ Tu código permanece en tu máquina
- ✅ Logs locales para debugging

## 🤝 Comparación con Otras Herramientas

| Característica | Asis-coder | Claude Code | GitHub Copilot |
|----------------|------------|-------------|----------------|
| CLI nativo | ✅ | ✅ | ❌ |
| Múltiples LLMs | ✅ | ❌ | ❌ |
| Detección automática | ✅ | ✅ | ❌ |
| Modo interactivo | ✅ | ✅ | ❌ |
| Gratuito | ✅ | ❌ | ❌ |
| Historial local | ✅ | ✅ | ❌ |

## 📊 Casos de Uso

### Para Desarrolladores Individuales
- Debugging rápido
- Generación de documentación
- Aprendizaje de nuevas tecnologías

### Para Equipos
- Code reviews automatizados
- Estándares de código consistentes
- Onboarding de nuevos desarrolladores

### Para Proyectos Open Source
- Documentación automática
- Análisis de contribuciones
- Mejoras de código sugeridas

## 🐛 Troubleshooting

### Problemas Comunes

**Error de permisos:**
```bash
chmod +x ~/.local/bin/coder
```

**PATH no actualizado:**
```bash
source ~/.bashrc  # o ~/.zshrc
```

**Dependencias faltantes:**
```bash
# Ubuntu/Debian
sudo apt install curl jq

# macOS
brew install curl jq
```

## 🔄 Actualizaciones

```bash
cd asis-coder
git pull
./install.sh
```

## 📝 Changelog

### v1.1.0
- ✨ Detección automática de proyectos
- ✨ Comando `/init` para inicialización
- ✨ Soporte para más modelos GPT-4
- 🐛 Mejoras en estabilidad

### v1.0.1
- 🎨 Interfaz mejorada
- 📊 Sistema de logs
- 🔧 Configuración simplificada

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama: `git checkout -b feature/nueva-caracteristica`
3. Commit: `git commit -m 'Agregar nueva característica'`
4. Push: `git push origin feature/nueva-caracteristica`
5. Abre un Pull Request

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE) para más detalles.

## ⭐ Si te gusta el proyecto

¡Dale una estrella en GitHub! Ayuda a otros desarrolladores a encontrar esta herramienta.

---

**¿Necesitas ayuda?** Abre un [issue](https://github.com/tu-usuario/asis-coder/issues) o únete a nuestras [discusiones](https://github.com/tu-usuario/asis-coder/discussions).
