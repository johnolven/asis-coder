#!/bin/bash

# ==========================================
# PROJECT WIZARD - swarm_project_wizard.sh
# ==========================================
# Asistente interactivo para crear proyectos con contexto completo

swarm_project_wizard() {
    echo -e "${SWARM_C_BOLD}${SWARM_C_CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   ASIS-CODER: PROJECT CREATION WIZARD                    ║"
    echo "║   Distributed AI Development Setup                       ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${SWARM_C_RESET}"
    echo
    echo "Este asistente te ayudará a configurar un proyecto para desarrollo distribuido"
    echo "con agentes autónomos trabajando en paralelo."
    echo

    # ============================================================
    # PASO 1: Información básica del proyecto
    # ============================================================
    echo -e "${SWARM_C_BOLD}PASO 1/6: Información del Proyecto${SWARM_C_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo

    local project_name=""
    while [ -z "$project_name" ]; do
        echo -n "Nombre del proyecto (ej: mi-sitio-web, auth-service): "
        read -r project_name
        project_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        if [ -z "$project_name" ]; then
            swarm_error "El nombre no puede estar vacío"
        fi
    done

    echo -n "Descripción breve (opcional): "
    read -r project_description
    [ -z "$project_description" ] && project_description="Proyecto desarrollado con Asis-Coder Swarm"

    echo

    # ============================================================
    # PASO 2: Tipo de proyecto (lenguaje/framework)
    # ============================================================
    echo -e "${SWARM_C_BOLD}PASO 2/6: Tipo de Proyecto${SWARM_C_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "Selecciona el tipo de proyecto:"
    echo "  1) React / Next.js (Node.js)"
    echo "  2) Python (Django / Flask / FastAPI)"
    echo "  3) Go (web service / API)"
    echo "  4) Rust (backend / CLI tool)"
    echo "  5) Java (Spring Boot / Micronaut)"
    echo "  6) PHP (Laravel / Symfony)"
    echo "  7) Otro (especificar)"
    echo

    local project_type=""
    local project_lang=""
    while [ -z "$project_type" ]; do
        echo -n "Opción (1-7): "
        read -r opt
        case "$opt" in
            1) project_type="nodejs"; project_lang="JavaScript/TypeScript (React)" ;;
            2) project_type="python"; project_lang="Python" ;;
            3) project_type="go"; project_lang="Go" ;;
            4) project_type="rust"; project_lang="Rust" ;;
            5) project_type="java"; project_lang="Java" ;;
            6) project_type="php"; project_lang="PHP" ;;
            7) echo -n "Especifica el lenguaje: "; read -r project_lang; project_type="custom" ;;
            *) swarm_error "Opción inválida" ;;
        esac
    done

    swarm_ok "Tipo: $project_lang"
    echo

    # ============================================================
    # PASO 3: Ubicación del proyecto (local + GitHub)
    # ============================================================
    echo -e "${SWARM_C_BOLD}PASO 3/6: Ubicación del Proyecto${SWARM_C_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "¿Dónde quieres crear el proyecto?"
    echo
    echo "  a) Crear nueva carpeta local + repo GitHub (recomendado)"
    echo "  b) Usar carpeta existente (especificar ruta)"
    echo "  c) Solo usar repo GitHub existente (clonar)"
    echo

    local local_path=""
    local github_repo=""
    local create_mode=""

    while [ -z "$create_mode" ]; do
        echo -n "Opción (a/b/c): "
        read -r opt
        case "$opt" in
            a|A)
                create_mode="new"
                echo -n "Ruta donde crear carpeta (default: ~/projects): "
                read -r base_path
                [ -z "$base_path" ] && base_path="$HOME/projects"
                local_path="$base_path/$project_name"

                echo -n "Crear repo en GitHub? (s/n, default: s): "
                read -r create_gh
                if [[ "$create_gh" != "n" ]]; then
                    echo -n "Usuario GitHub (default: johnolven): "
                    read -r gh_user
                    [ -z "$gh_user" ] && gh_user="johnolven"
                    github_repo="https://github.com/$gh_user/$project_name.git"
                fi
                ;;
            b|B)
                create_mode="existing"
                while [ -z "$local_path" ] || [ ! -d "$local_path" ]; do
                    echo -n "Ruta completa a la carpeta: "
                    read -r local_path
                    if [ ! -d "$local_path" ]; then
                        swarm_error "La carpeta no existe: $local_path"
                        local_path=""
                    fi
                done

                echo -n "URL del repo GitHub (opcional): "
                read -r github_repo
                ;;
            c|C)
                create_mode="clone"
                while [ -z "$github_repo" ]; do
                    echo -n "URL del repo GitHub: "
                    read -r github_repo
                done
                echo -n "Clonar en (default: ~/projects): "
                read -r base_path
                [ -z "$base_path" ] && base_path="$HOME/projects"
                local_path="$base_path/$project_name"
                ;;
            *) swarm_error "Opción inválida" ;;
        esac
    done

    swarm_ok "Local: $local_path"
    [ -n "$github_repo" ] && swarm_ok "GitHub: $github_repo"
    echo

    # ============================================================
    # PASO 4: Features del proyecto
    # ============================================================
    echo -e "${SWARM_C_BOLD}PASO 4/6: Features a Desarrollar${SWARM_C_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "¿Qué features quieres que los agentes desarrollen?"
    echo "Describe cada feature en una línea (vacío para terminar)."
    echo
    echo "Ejemplos:"
    echo "  - Hero component with gradient background"
    echo "  - User authentication with JWT"
    echo "  - REST API for blog posts"
    echo

    local -a features=()
    local feat_num=1
    while true; do
        echo -n "Feature #$feat_num: "
        read -r feature_desc
        [ -z "$feature_desc" ] && break
        features+=("$feature_desc")
        ((feat_num++))
    done

    if [ ${#features[@]} -eq 0 ]; then
        swarm_warn "No se especificaron features. Crearemos solo el bootstrap."
    else
        swarm_ok "${#features[@]} features definidas"
    fi
    echo

    # ============================================================
    # PASO 5: Distribución de agentes
    # ============================================================
    echo -e "${SWARM_C_BOLD}PASO 5/6: Distribución en Devices${SWARM_C_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "Devices disponibles:"
    coder swarm device list 2>/dev/null || swarm_error "No hay devices registrados. Ejecuta: coder swarm wizard"
    echo

    echo -n "¿Distribuir automáticamente? (s/n, default: s): "
    read -r auto_dist
    local distribute_auto=true
    [[ "$auto_dist" == "n" ]] && distribute_auto=false

    echo

    # ============================================================
    # PASO 6: Confirmar y generar
    # ============================================================
    echo -e "${SWARM_C_BOLD}PASO 6/6: Resumen y Confirmación${SWARM_C_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo -e "${SWARM_C_BOLD}Proyecto:${SWARM_C_RESET} $project_name"
    echo -e "${SWARM_C_BOLD}Descripción:${SWARM_C_RESET} $project_description"
    echo -e "${SWARM_C_BOLD}Tipo:${SWARM_C_RESET} $project_lang ($project_type)"
    echo -e "${SWARM_C_BOLD}Ubicación:${SWARM_C_RESET} $local_path"
    [ -n "$github_repo" ] && echo -e "${SWARM_C_BOLD}GitHub:${SWARM_C_RESET} $github_repo"
    echo -e "${SWARM_C_BOLD}Features:${SWARM_C_RESET} ${#features[@]}"
    for i in "${!features[@]}"; do
        echo "  $((i+1)). ${features[$i]}"
    done
    echo -e "${SWARM_C_BOLD}Distribución:${SWARM_C_RESET} $([ "$distribute_auto" = true ] && echo "Automática" || echo "Manual")"
    echo

    echo -n "¿Proceder con la creación? (s/n): "
    read -r confirm
    if [[ "$confirm" != "s" ]]; then
        swarm_warn "Cancelado por el usuario"
        return 1
    fi

    echo
    echo -e "${SWARM_C_BOLD}${SWARM_C_GREEN}Generando configuración del proyecto...${SWARM_C_RESET}"
    echo

    # ============================================================
    # GENERACIÓN: Crear estructura
    # ============================================================

    # 1. Crear carpeta local si es necesario
    if [ "$create_mode" = "new" ]; then
        mkdir -p "$local_path"
        cd "$local_path" || return 1
        git init
        swarm_ok "Carpeta creada: $local_path"
    elif [ "$create_mode" = "clone" ]; then
        git clone "$github_repo" "$local_path"
        cd "$local_path" || return 1
        swarm_ok "Repo clonado: $local_path"
    else
        cd "$local_path" || return 1
        swarm_ok "Usando carpeta existente: $local_path"
    fi

    # 2. Crear repo GitHub si es necesario
    if [ "$create_mode" = "new" ] && [ -n "$github_repo" ]; then
        if command -v gh >/dev/null 2>&1; then
            gh repo create "$project_name" --public --source=. --remote=origin --push || swarm_warn "No se pudo crear repo en GitHub (continuar manualmente)"
            swarm_ok "Repo GitHub creado: $github_repo"
        else
            swarm_warn "gh CLI no instalado. Crea el repo manualmente: https://github.com/new"
        fi
    fi

    # 3. Crear proyecto en swarm
    local repo_url="${github_repo:-$local_path}"
    coder swarm project create "$project_name" --repo "$repo_url"
    swarm_ok "Proyecto '$project_name' registrado en swarm"

    # 4. Generar PRD bootstrap
    local prd_dir="$local_path/.asis-coder"
    mkdir -p "$prd_dir"
    coder swarm prd bootstrap "$project_name" --type "$project_type" > "$prd_dir/prd-bootstrap.json"
    swarm_ok "PRD bootstrap generado: $prd_dir/prd-bootstrap.json"

    # 5. Generar PRDs de features
    if [ ${#features[@]} -gt 0 ]; then
        for i in "${!features[@]}"; do
            local feat_name="feature-$((i+1))"
            local feat_desc="${features[$i]}"
            coder swarm prd feature "$project_name" "$feat_name" --description "$feat_desc" > "$prd_dir/prd-$feat_name.json"
        done
        swarm_ok "${#features[@]} PRDs de features generados"
    fi

    # 6. Generar PRD merger
    local branches_list=""
    for i in "${!features[@]}"; do
        [ $i -gt 0 ] && branches_list+=","
        branches_list+="feat/feature-$((i+1))"
    done
    if [ -n "$branches_list" ]; then
        coder swarm prd merger "$project_name" --branches "$branches_list" > "$prd_dir/prd-merger.json"
        swarm_ok "PRD merger generado: $prd_dir/prd-merger.json"
    fi

    # 7. Generar script de ejecución
    local exec_script="$local_path/run-swarm.sh"
    cat > "$exec_script" <<EOF
#!/bin/bash
# Auto-generated by Asis-Coder Project Wizard
# Project: $project_name
# Generated: $(date)

set -e

PROJECT="$project_name"
PRD_DIR=".asis-coder"

echo "=========================================="
echo "Asis-Coder Swarm: $project_name"
echo "=========================================="
echo

# FASE 0: Bootstrap
echo "FASE 0: Bootstrap (inicializando proyecto)"
coder swarm agent add \$PROJECT bootstrap --device RB001 --branch main
coder swarm ralph start \$PROJECT bootstrap --prd \$PRD_DIR/prd-bootstrap.json --iterations 5

echo "Esperando bootstrap... Monitorea con: coder swarm dashboard"
echo "Presiona ENTER cuando bootstrap termine (verifica con: coder swarm ralph progress \$PROJECT bootstrap)"
read

# Validar bootstrap
coder swarm ralph validate \$PROJECT bootstrap || { echo "Bootstrap falló!"; exit 1; }

# FASE 1: Features
echo
echo "FASE 1: Features (desarrollo paralelo)"
EOF

    if [ ${#features[@]} -gt 0 ]; then
        for i in "${!features[@]}"; do
            local feat_name="feature-$((i+1))"
            cat >> "$exec_script" <<EOF
coder swarm agent add \$PROJECT $feat_name --device RB001 --branch feat/$feat_name
EOF
        done

        cat >> "$exec_script" <<EOF

# Ejecutar en paralelo
EOF

        for i in "${!features[@]}"; do
            local feat_name="feature-$((i+1))"
            cat >> "$exec_script" <<EOF
coder swarm ralph start \$PROJECT $feat_name --prd \$PRD_DIR/prd-$feat_name.json --iterations 20 &
EOF
        done

        cat >> "$exec_script" <<EOF
wait

echo "Features completadas. Validando..."
EOF

        for i in "${!features[@]}"; do
            local feat_name="feature-$((i+1))"
            cat >> "$exec_script" <<EOF
coder swarm ralph validate \$PROJECT $feat_name
EOF
        done
    fi

    if [ -n "$branches_list" ]; then
        cat >> "$exec_script" <<EOF

# FASE 2: Merger
echo
echo "FASE 2: Merger (integración)"
coder swarm agent add \$PROJECT merger --device RB001 --branch main
coder swarm ralph start \$PROJECT merger --prd \$PRD_DIR/prd-merger.json --iterations 10

echo "Esperando merger... Monitorea con: coder swarm dashboard --mode logs"
read

# Validar merger
coder swarm ralph validate \$PROJECT merger || { echo "Merger falló!"; exit 1; }

echo
echo "=========================================="
echo "✓ Proyecto completado!"
echo "=========================================="
echo "Ubicación: $local_path"
echo "Repo: $repo_url"
EOF
    fi

    chmod +x "$exec_script"
    swarm_ok "Script de ejecución: $exec_script"

    # 8. Resumen final
    echo
    echo -e "${SWARM_C_BOLD}${SWARM_C_GREEN}✓ Proyecto configurado exitosamente!${SWARM_C_RESET}"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${SWARM_C_BOLD}Próximos pasos:${SWARM_C_RESET}"
    echo
    echo "1. Revisar PRDs generados:"
    echo "   cd $local_path/.asis-coder"
    echo "   ls -la prd-*.json"
    echo
    echo "2. Ejecutar el proyecto completo:"
    echo "   cd $local_path"
    echo "   ./run-swarm.sh"
    echo
    echo "3. O ejecutar fase por fase:"
    echo "   # Bootstrap"
    echo "   coder swarm agent add $project_name bootstrap --device RB001 --branch main"
    echo "   coder swarm ralph start $project_name bootstrap --prd .asis-coder/prd-bootstrap.json"
    echo
    echo "4. Monitorear en tiempo real:"
    echo "   coder swarm dashboard"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
