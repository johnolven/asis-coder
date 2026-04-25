#!/bin/bash

# ==========================================
# PRD GENERATOR - prd_generator.sh
# ==========================================
# Genera PRDs desde templates para bootstrap, features y merger

prd_generate_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm prd${SWARM_C_RESET}  -  generador de PRDs desde templates

Genera PRDs pre-configurados para el workflow de 3 fases:
  Phase 0: Bootstrap (inicializa proyecto)
  Phase 1: Features (desarrollo paralelo)
  Phase 2: Merger (integración)

${SWARM_C_BOLD}COMANDOS${SWARM_C_RESET}
  coder swarm prd bootstrap <project> --type <nodejs|python|go|rust>
  coder swarm prd feature <project> <feature-name> --description "<desc>"
  coder swarm prd merger <project> --branches <branch1,branch2,...>

${SWARM_C_BOLD}EJEMPLOS${SWARM_C_RESET}
  # Bootstrap para proyecto React
  coder swarm prd bootstrap mysite --type nodejs > prd-bootstrap.json

  # Feature para componente Hero
  coder swarm prd feature mysite hero --description "Hero section with gradient" > prd-hero.json

  # Merger para integrar 3 features
  coder swarm prd merger mysite --branches feat/hero,feat/nav,feat/footer > prd-merger.json

${SWARM_C_BOLD}TIPOS DE PROYECTO${SWARM_C_RESET}
  nodejs  → npx create-react-app / npm install / npm run build / npm test
  python  → pip install / pytest / python -m compileall
  go      → go mod init / go build / go test
  rust    → cargo init / cargo build / cargo test
  java    → mvn / gradle
  php     → composer install / phpunit
EOF
}

prd_generate_bootstrap() {
    local project="$1" proj_type=""
    shift

    while [ $# -gt 0 ]; do
        case "$1" in
            --type) proj_type="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$project" ] || [ -z "$proj_type" ]; then
        swarm_error "Uso: coder swarm prd bootstrap <project> --type <nodejs|python|go|rust>"
        return 1
    fi

    # Generate based on type
    case "$proj_type" in
        nodejs)
            cat <<EOF
{
  "project": "$project",
  "branchName": "main",
  "description": "Initialize Node.js/React project structure",
  "projectType": "nodejs",
  "userStories": [
    {
      "id": "BOOT-001",
      "title": "Initialize React project",
      "description": "As a developer, I need a React project initialized",
      "acceptanceCriteria": [
        "Run: npx create-react-app . (if directory empty)",
        "Verify package.json exists with scripts: start, build, test",
        "Verify src/ directory created",
        "Install react-router-dom: npm install react-router-dom"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "BOOT-002",
      "title": "Verify build works",
      "description": "As a developer, I need to verify the project builds",
      "acceptanceCriteria": [
        "Run: npm run build",
        "Build completes without errors",
        "build/ directory created"
      ],
      "priority": 2,
      "passes": false
    },
    {
      "id": "BOOT-003",
      "title": "Commit initial structure",
      "description": "As a developer, I need the bootstrap committed",
      "acceptanceCriteria": [
        "Git add all files",
        "Commit: 'chore: initialize $project with React'",
        "Push to origin/main"
      ],
      "priority": 3,
      "passes": false
    }
  ]
}
EOF
            ;;
        python)
            cat <<EOF
{
  "project": "$project",
  "branchName": "main",
  "description": "Initialize Python project structure",
  "projectType": "python",
  "userStories": [
    {
      "id": "BOOT-001",
      "title": "Initialize Python project",
      "description": "As a developer, I need a Python project initialized",
      "acceptanceCriteria": [
        "Create requirements.txt",
        "Create setup.py or pyproject.toml",
        "Create src/ directory structure",
        "Create tests/ directory"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "BOOT-002",
      "title": "Set up pytest",
      "description": "As a developer, I need pytest configured",
      "acceptanceCriteria": [
        "Add pytest to requirements.txt",
        "Create pytest.ini or pyproject.toml config",
        "Create example test in tests/",
        "Run: pytest (should pass)"
      ],
      "priority": 2,
      "passes": false
    },
    {
      "id": "BOOT-003",
      "title": "Commit initial structure",
      "description": "As a developer, I need the bootstrap committed",
      "acceptanceCriteria": [
        "Git add all files",
        "Commit: 'chore: initialize $project with Python'",
        "Push to origin/main"
      ],
      "priority": 3,
      "passes": false
    }
  ]
}
EOF
            ;;
        go)
            cat <<EOF
{
  "project": "$project",
  "branchName": "main",
  "description": "Initialize Go project structure",
  "projectType": "go",
  "userStories": [
    {
      "id": "BOOT-001",
      "title": "Initialize Go module",
      "description": "As a developer, I need a Go module initialized",
      "acceptanceCriteria": [
        "Run: go mod init $project",
        "Verify go.mod created",
        "Create main.go with package main",
        "Create cmd/ and pkg/ directories"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "BOOT-002",
      "title": "Verify build works",
      "description": "As a developer, I need to verify the project builds",
      "acceptanceCriteria": [
        "Run: go build ./...",
        "Build completes without errors",
        "Run: go test ./... (should pass)"
      ],
      "priority": 2,
      "passes": false
    },
    {
      "id": "BOOT-003",
      "title": "Commit initial structure",
      "description": "As a developer, I need the bootstrap committed",
      "acceptanceCriteria": [
        "Git add all files",
        "Commit: 'chore: initialize $project with Go'",
        "Push to origin/main"
      ],
      "priority": 3,
      "passes": false
    }
  ]
}
EOF
            ;;
        rust)
            cat <<EOF
{
  "project": "$project",
  "branchName": "main",
  "description": "Initialize Rust project structure",
  "projectType": "rust",
  "userStories": [
    {
      "id": "BOOT-001",
      "title": "Initialize Cargo project",
      "description": "As a developer, I need a Rust project initialized",
      "acceptanceCriteria": [
        "Run: cargo init .",
        "Verify Cargo.toml created",
        "Verify src/main.rs created",
        "Create src/lib.rs if library"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "BOOT-002",
      "title": "Verify build works",
      "description": "As a developer, I need to verify the project builds",
      "acceptanceCriteria": [
        "Run: cargo build",
        "Build completes without errors",
        "Run: cargo test (should pass)"
      ],
      "priority": 2,
      "passes": false
    },
    {
      "id": "BOOT-003",
      "title": "Commit initial structure",
      "description": "As a developer, I need the bootstrap committed",
      "acceptanceCriteria": [
        "Git add all files",
        "Commit: 'chore: initialize $project with Rust'",
        "Push to origin/main"
      ],
      "priority": 3,
      "passes": false
    }
  ]
}
EOF
            ;;
        *)
            swarm_error "Tipo no soportado: $proj_type"
            return 1
            ;;
    esac
}

prd_generate_feature() {
    local project="$1" feature="$2" description=""
    shift 2

    while [ $# -gt 0 ]; do
        case "$1" in
            --description) description="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$project" ] || [ -z "$feature" ]; then
        swarm_error "Uso: coder swarm prd feature <project> <feature-name> --description \"<desc>\""
        return 1
    fi

    [ -z "$description" ] && description="Implement $feature feature"

    cat <<EOF
{
  "project": "$project",
  "branchName": "feat/$feature",
  "description": "$description",
  "userStories": [
    {
      "id": "FEAT-001",
      "title": "Create $feature component/module",
      "description": "As a developer, I need the $feature functionality implemented",
      "acceptanceCriteria": [
        "Create appropriate source file(s)",
        "Implement core functionality",
        "Follow project conventions",
        "Add comments for complex logic"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "FEAT-002",
      "title": "Write tests for $feature",
      "description": "As a developer, I need tests covering $feature",
      "acceptanceCriteria": [
        "Create test file",
        "Test happy path",
        "Test edge cases",
        "All tests pass"
      ],
      "priority": 2,
      "passes": false
    },
    {
      "id": "FEAT-003",
      "title": "Integrate $feature into app",
      "description": "As a developer, I need $feature integrated",
      "acceptanceCriteria": [
        "Import/use $feature in appropriate files",
        "Update routing/navigation if needed",
        "No breaking changes to existing code"
      ],
      "priority": 3,
      "passes": false
    },
    {
      "id": "FEAT-004",
      "title": "Verify build and tests",
      "description": "As a developer, I need to verify everything works",
      "acceptanceCriteria": [
        "Build succeeds (npm run build or equivalent)",
        "Tests pass (npm test or equivalent)",
        "No console errors",
        "$feature works as expected"
      ],
      "priority": 4,
      "passes": false
    },
    {
      "id": "FEAT-005",
      "title": "Commit $feature to branch",
      "description": "As a developer, I need the feature committed",
      "acceptanceCriteria": [
        "Git status clean",
        "Commit message: 'feat($feature): $description'",
        "Push to origin/feat/$feature"
      ],
      "priority": 5,
      "passes": false
    }
  ]
}
EOF
}

prd_generate_merger() {
    local project="$1" branches=""
    shift

    while [ $# -gt 0 ]; do
        case "$1" in
            --branches) branches="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$project" ]; then
        swarm_error "Uso: coder swarm prd merger <project> [--branches feat/a,feat/b,...]"
        return 1
    fi

    local branches_json=""
    if [ -n "$branches" ]; then
        branches_json=$(echo "$branches" | sed 's/,/", "/g' | sed 's/^/["/' | sed 's/$/"]/')
    else
        branches_json='["feat/*"]'
    fi

    cat <<EOF
{
  "project": "$project",
  "branchName": "main",
  "description": "Merge all completed feature branches into main",
  "expectedBranches": $branches_json,
  "userStories": [
    {
      "id": "MERGE-001",
      "title": "Fetch all feature branches",
      "description": "As a merger, I need all remote branches fetched",
      "acceptanceCriteria": [
        "Run: git fetch --all",
        "List all feat/* branches",
        "Verify expected branches exist",
        "Log branch list to merge-report.txt"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "MERGE-002",
      "title": "Merge branches sequentially",
      "description": "As a merger, I need each branch merged",
      "acceptanceCriteria": [
        "Checkout main",
        "For each feat/* branch: git merge --no-ff origin/<branch>",
        "Resolve conflicts with: git checkout --theirs . && git add .",
        "Create merge commit with description",
        "Log status to merge-report.txt"
      ],
      "priority": 2,
      "passes": false
    },
    {
      "id": "MERGE-003",
      "title": "Reinstall dependencies",
      "description": "As a merger, I need dependencies updated",
      "acceptanceCriteria": [
        "Run install command (npm install / pip install / etc)",
        "No dependency conflicts",
        "Lock file updated"
      ],
      "priority": 3,
      "passes": false
    },
    {
      "id": "MERGE-004",
      "title": "Validate build",
      "description": "As a merger, I need build to succeed",
      "acceptanceCriteria": [
        "Run build command",
        "Build MUST succeed",
        "If fails: revert last merge, log error, continue"
      ],
      "priority": 4,
      "passes": false
    },
    {
      "id": "MERGE-005",
      "title": "Run tests",
      "description": "As a merger, I need tests to pass",
      "acceptanceCriteria": [
        "Run test command",
        "Log results (warn if fail, don't block)",
        "If critical failure: revert last merge"
      ],
      "priority": 5,
      "passes": false
    },
    {
      "id": "MERGE-006",
      "title": "Generate merge report",
      "description": "As a PM, I need a comprehensive report",
      "acceptanceCriteria": [
        "Create merge-report.md",
        "List all branches: status, conflicts, timestamp",
        "Show build/test results",
        "List reverted branches and why"
      ],
      "priority": 6,
      "passes": false
    },
    {
      "id": "MERGE-007",
      "title": "Push merged main",
      "description": "As a merger, I need integrated code pushed",
      "acceptanceCriteria": [
        "Git add merge-report.md",
        "Commit: 'chore: merge all feature branches'",
        "Push to origin/main"
      ],
      "priority": 7,
      "passes": false
    }
  ]
}
EOF
}

prd_generate_cmd() {
    local sub="$1"; shift || true
    case "$sub" in
        bootstrap) prd_generate_bootstrap "$@" ;;
        feature)   prd_generate_feature "$@" ;;
        merger)    prd_generate_merger "$@" ;;
        ""|help|-h|--help) prd_generate_help ;;
        *) swarm_error "Subcomando desconocido: $sub"; prd_generate_help; return 1 ;;
    esac
}
