#!/bin/bash

# Dashboard responsivo con positioning fijo

# Control terminal
hide_cursor() { echo -ne "\033[?25l"; }
show_cursor() { echo -ne "\033[?25h"; }
alt_screen() { echo -ne "\033[?1049h"; }
main_screen() { echo -ne "\033[?1049l"; }
clear_screen() { echo -ne "\033[2J\033[H"; }
move_to() { echo -ne "\033[${1};${2}H"; }

# Colors
R="\033[0m" B="\033[1m" 
RED="\033[31m" GRN="\033[32m" YEL="\033[33m" BLU="\033[34m"
MAG="\033[35m" CYN="\033[36m" WHT="\033[37m"
BG_BLK="\033[40m" BG_BLU="\033[44m"

# State
ROWS=24 COLS=80 MODE="all" REFRESH=2 RUNNING=true

get_size() {
    ROWS=$(tput lines 2>/dev/null || echo 24)
    COLS=$(tput cols 2>/dev/null || echo 80)
    [ $ROWS -lt 10 ] && ROWS=10
    [ $COLS -lt 40 ] && COLS=40
}

# Helpers
is_narrow() { [ $COLS -lt 80 ]; }
is_wide() { [ $COLS -ge 100 ]; }
trunc() { local t="$1" w=$2; [ ${#t} -le $w ] && echo "$t" || echo "${t:0:$((w-2))}.."; }

# Draw functions
draw_header() {
    move_to 1 1
    echo -ne "${BG_BLU}${WHT}${B}"
    if is_narrow; then
        printf "%-${COLS}s" " SWARM │ $MODE │ ${REFRESH}s"
    else
        printf "%-${COLS}s" " ASIS-CODER SWARM │ Mode: $MODE │ Refresh: ${REFRESH}s │ [q]uit"
    fi
    echo -ne "$R"
}

draw_devices() {
    local r=3
    move_to $r 2
    echo -ne "${CYN}${B}DEVICES${R}"
    ((r++))

    local djson=$(cat "$SWARM_DEVICES_FILE" 2>/dev/null)
    [ -z "$djson" ] && { move_to $r 2; echo -ne "${YEL}No devices${R}"; return $((r+1)); }

    echo "$djson" | jq -r '.[] | "\(.name)|\(.ip)|\(.user)"' 2>/dev/null | while IFS='|' read -r n i u; do
        move_to $r 2

        local st="○" clr="$RED"
        timeout 0.2 ping -c 1 "$i" >/dev/null 2>&1 && { st="●"; clr="$GRN"; }

        if is_narrow; then
            echo -ne "$(trunc "$n" 10) ${clr}${st}${R}"
        else
            printf "%-12s %-15s " "$n" "$i"
            echo -ne "${clr}${st}${R}"
        fi

        ((r++))
        [ $r -ge $((ROWS-8)) ] && break
    done

    echo $r
}

draw_agents() {
    local r=$1
    move_to $r 2
    echo -ne "${CYN}${B}AGENTS${R}"
    ((r++))

    local ags=""
    for pf in "$SWARM_PROJECTS_DIR"/*.json; do
        [ ! -f "$pf" ] && continue
        local pj=$(jq -r '.name' "$pf" 2>/dev/null)
        jq -r '.agents[] | "\(.name)|\(.device)|\(.status)"' "$pf" 2>/dev/null | while IFS='|' read -r a d s; do
            echo "$pj/$a|$d|$s"
        done
    done | head -6 | while IFS='|' read -r a d s; do
        move_to $r 2

        local ic="⏸" clr="$WHT"
        [ "$s" = "ralph-running" ] && { ic="⚙"; clr="$GRN"; }

        if is_narrow; then
            echo -ne "$(trunc "$a" 18) ${clr}${ic}${R}"
        else
            printf "%-25s %-8s ${clr}${ic}${R}" "$(trunc "$a" 25)" "$d"
        fi

        ((r++))
    done

    echo $r
}

draw_logs() {
    local r=$1
    move_to $r 2
    echo -ne "${CYN}${B}LOGS${R}"
    ((r++))

    local max=$((ROWS - r - 2))
    [ $max -lt 1 ] && return

    move_to $r 2
    echo -ne "${WHT}(live logs...)${R}"

    echo $r
}

draw_footer() {
    move_to $ROWS 1
    echo -ne "${BG_BLK}${YEL}"
    if is_narrow; then
        printf "%-${COLS}s" " [q]uit [d]ev [a]gt [l]og [v]all +/-"
    else
        printf "%-${COLS}s" " [q]Quit [d]Devices [a]Agents [l]Logs [v]All [+]Faster [-]Slower"
    fi
    echo -ne "$R"
}

render() {
    get_size
    clear_screen
    draw_header

    case "$MODE" in
        devices)
            draw_devices
            ;;
        agents)
            draw_agents 3
            ;;
        logs)
            draw_logs 3
            ;;
        all|*)
            local r=$(draw_devices)
            ((r++))
            r=$(draw_agents $r)
            ((r++))
            draw_logs $r
            ;;
    esac

    draw_footer
}

swarm_dashboard_run() {
    MODE="all" REFRESH=2

    while [ $# -gt 0 ]; do
        case "$1" in
            --mode) MODE="$2"; shift 2 ;;
            --refresh) REFRESH="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    alt_screen
    hide_cursor

    trap 'main_screen; show_cursor' EXIT INT TERM

    while $RUNNING; do
        render

        if read -t "$REFRESH" -n 1 k 2>/dev/null; then
            case "$k" in
                q|Q) RUNNING=false ;;
                d|D) MODE="devices" ;;
                a|A) MODE="agents" ;;
                l|L) MODE="logs" ;;
                v|V) MODE="all" ;;
                +) REFRESH=$((REFRESH > 1 ? REFRESH - 1 : 1)) ;;
                -) REFRESH=$((REFRESH + 1)) ;;
            esac
        fi
    done
}

swarm_dashboard_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm dashboard${SWARM_C_RESET}  -  monitor responsivo

Dashboard adaptativo al tamaño del terminal.

${SWARM_C_BOLD}USO${SWARM_C_RESET}
  coder swarm dashboard [--mode all|devices|agents|logs] [--refresh N]

${SWARM_C_BOLD}CONTROLES${SWARM_C_RESET}
  q → Quit    d → Devices    a → Agents    l → Logs    v → All
  + → Faster  - → Slower
EOF
}

swarm_dashboard_cmd() {
    if [[ "$1" == --* ]] || [ -z "$1" ]; then
        swarm_dashboard_run "$@"
    else
        case "$1" in
            run) shift; swarm_dashboard_run "$@" ;;
            help|-h) swarm_dashboard_help ;;
            *) swarm_error "Unknown: $1"; return 1 ;;
        esac
    fi
}
