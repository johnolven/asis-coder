# Coder: Asistente de Desarrollo con LLM

Coder es un script de bash que facilita la interacción con modelos de lenguaje largo (LLMs) como ChatGPT y Claude para asistir en tareas de desarrollo. Permite generar contexto de código de tu proyecto y hacer consultas basadas en ese contexto.

## Características

- Soporte para múltiples LLMs (actualmente ChatGPT y Claude)
- Generación de contexto de código para diferentes tipos de proyectos
- Consultas al LLM basadas en el contexto del proyecto
- Configuración flexible de modelos y tokens de API
- Capacidad de trabajar desde cualquier subdirectorio del proyecto
- Instalador automático para facilitar el uso global del script

## Requisitos

- Bash (versión 4 o superior)
- Python 3
- jq
- curl

## Instalación

1. Clona este repositorio o descarga el archivo `coder.sh`.
2. Da permisos de ejecución al script:

```bash
chmod +x coder.sh
```

3. Ejecuta el instalador:

```bash
./coder.sh -install
```

Esto instalará el script en `~/bin` y añadirá este directorio a tu PATH en tu archivo de configuración de shell (`.bashrc` o `.zshrc`).

4. Reinicia tu terminal o ejecuta `source ~/.bashrc` (o `~/.zshrc`) para aplicar los cambios.

Ahora puedes usar el comando `coder` desde cualquier ubicación.

## Uso

### Generar contexto de código

```bash
coder -contexto
```

Esto analizará tu proyecto y generará un archivo de contexto.

### Hacer una consulta

```bash
coder "Tu pregunta aquí"
```

Asegúrate de haber generado el contexto antes de hacer consultas.

### Cambiar el LLM

```bash
coder -llm
```

Te permitirá elegir entre ChatGPT y Claude.

### Actualizar el modelo

```bash
coder -model
```

Te mostrará los modelos disponibles para el LLM seleccionado.

### Actualizar el token de API

```bash
coder -token
```

Te permitirá actualizar el token de API para el LLM seleccionado.

## Configuración

El script guarda la configuración en un archivo llamado `coder_config.txt` en el mismo directorio que el script. Esto incluye:

- LLM seleccionado
- Tokens de API
- Modelo seleccionado

## Notas

- Asegúrate de tener tokens de API válidos para los LLMs que planeas usar.
- El contexto de código se guarda en un archivo llamado `contexto_codigo.txt` en la raíz de tu proyecto.
- Puedes ejecutar el script desde cualquier subdirectorio de tu proyecto una vez que hayas generado el contexto.

## Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue para discutir cambios mayores antes de enviar un pull request.

## Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.