#!/bin/bash

# ==========================================
# SWARM DASHBOARD V2 - swarm_dashboard_v2.sh
# ==========================================
# Dashboard con gráficas sparklines y renderizado fijo (sin scroll)

# Terminal control con posicionamiento absoluto
tput_clear() { echo -ne "\033[2J\033[H"; }
tput_cup() { echo -ne "\033[${1};${2}H"; }
tput_bold() { echo -ne "\033[1m"; }
tput_reset() { echo -ne "\033[0m"; }
tput_hide_cursor() { echo -ne "\033[?25l"; }
tput_show_cursor() { echo -ne "\033[?25h"; }
tput_save_cursor() { echo -ne "\033[s"; }
tput_restore_cursor() { echo -ne "\033[u"; }
tput_alt_screen() { echo -ne "\033[?1049h"; }  # Enter alternate screen
tput_main_screen() { echo -ne "\033[?1049l"; }  # Exit alternate screen

# Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_WHITE="\033[37m"
C_BG_BLACK="\033[40m"
C_BG_BLUE="\033[44m"

# Sparkline characters
SPARK_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Terminal size
TERM_ROWS=40
TERM_COLS=120

# Get terminal size
get_term_size() {
    TERM_ROWS=$(tput lines 2>/dev/null || echo 40)
    TERM_COLS=$(tput cols 2>/dev/null || echo 120)
}

# Generate sparkline from values
generate_sparkline() {
    local -a values=("$@")
    local max=0
    local min=999999

    for v in "${values[@]}"; do
        [ "$v" -gt "$max" ] && max=$v
        [ "$v" -lt "$min" ] && min=$v
    done

    [ "$max" -eq 0 ] && max=1  # Avoid division by zero

    local sparkline=""
    for v in "${values[@]}"; do
        local normalized=$((v * 7 / max))
        [ "$normalized" -gt 7 ] && normalized=7
        sparkline+="${SPARK_CHARS[$normalized]}"
    done

    echo "$sparkline"
}

# CPU/RAM history (circular buffers)
declare -A CPU_HISTORY
declare -A RAM_HISTORY
HISTORY_SIZE=20

# Store metric
store_metric() {
    local device="$1"
    local type="$2"
    local value="$3"

    local var_name="${type}_HISTORY[$device]"
    local history="${!var_name}"

    # Add new value
    history="$history $value"

    # Keep only last N values
    history=$(echo "$history" | awk '{for(i=NF-'$((HISTORY_SIZE-1))'; i<=NF; i++) printf "%s ", $i}')

    eval "${type}_HISTORY[$device]=\"$history\""
}

# Get sparkline for metric
get_sparkline() {
    local device="$1"
    local type="$2"

    local var_name="${type}_HISTORY[$device]"
    local history="${!var_name}"

    [ -z "$history" ] && echo "▁▁▁▁▁▁▁▁▁▁" && return

    generate_sparkline $history
}

# Draw fixed header (no scroll)
draw_header_fixed() {
    local row=1

    tput_cup $row 1
    echo -ne "${C_BG_BLUE}${C_WHITE}${C_BOLD}"
    printf "%-${TERM_COLS}s" " ASIS-CODER SWARM │ Mode: $DASHBOARD_MODE │ Refresh: ${DASHBOARD_REFRESH}s │ [q]Quit [d/a/l/v] "
    echo -ne "${C_RESET}"
}

# Draw devices panel with sparklines
draw_devices_panel() {
    local start_row=3
    local row=$start_row

    # Header
    tput_cup $row 2
    echo -ne "${C_CYAN}${C_BOLD}DEVICES${C_RESET}"
    ((row++))

    tput_cup $row 2
    printf "%-12s %-15s %-8s %-8s %-12s %-10s %s" "NAME" "IP" "STATUS" "CPU" "RAM" "AGENTS" "CPU TREND"
    ((row++))

    tput_cup $row 2
    printf "%-100s" "$(printf '─%.0s' {1..100})"
    ((row++))

    # Get devices
    local devices_json
    devices_json="$(cat "$SWARM_DEVICES_FILE" 2>/dev/null)"

    if [ -z "$devices_json" ] || [ "$devices_json" = "null" ]; then
        tput_cup $row 2
        echo -ne "${C_YELLOW}No devices registered${C_RESET}"
        return $((row + 2))
    fi

    echo "$devices_json" | jq -r '.[] | "\(.name)|\(.ip)|\(.user)"' 2>/dev/null | \
    while IFS='|' read -r name ip user; do
        # Quick status check
        local status="●" color="$C_RED" status_text="OFFLINE"
        if timeout 0.5 ping -c 1 "$ip" >/dev/null 2>&1; then
            status="●"
            color="$C_GREEN"
            status_text="ONLINE"
        fi

        # Get stats
        local cpu="?" ram="?" agents="0"
        if [ "$status_text" = "ONLINE" ]; then
            local stats
            stats="$(timeout 1 ssh -o ConnectTimeout=0.5 -o StrictHostKeyChecking=no "$user@$ip" \
                "top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2)}'; \
                 free | awk '/^Mem:/ {print int(\$3*100/\$2)}'; \
                 tmux ls 2>/dev/null | grep -c ralph || echo 0" 2>/dev/null)"
            if [ $? -eq 0 ]; then
                cpu=$(echo "$stats" | sed -n '1p')
                ram=$(echo "$stats" | sed -n '2p')
                agents=$(echo "$stats" | sed -n '3p')

                # Store for sparkline
                store_metric "$name" "CPU" "$cpu"
                store_metric "$name" "RAM" "$ram"
            fi
        fi

        # Get sparkline
        local cpu_spark=$(get_sparkline "$name" "CPU")

        # Draw row
        tput_cup $row 2
        printf "%-12s %-15s" "$name" "$ip"
        echo -ne "${color}${status}${C_RESET} "
        printf "%-6s  " "$status_text"

        # CPU bar
        local cpu_bars=$((cpu / 10))
        [ "$cpu" != "?" ] && {
            echo -ne "${C_GREEN}"
            printf "█%.0s" $(seq 1 $cpu_bars)
            echo -ne "${C_WHITE}"
            printf "░%.0s" $(seq 1 $((10 - cpu_bars)))
            echo -ne "${C_RESET} "
        } || echo -n "          "

        # RAM bar
        local ram_bars=$((ram / 10))
        [ "$ram" != "?" ] && {
            echo -ne "${C_BLUE}"
            printf "█%.0s" $(seq 1 $ram_bars)
            echo -ne "${C_WHITE}"
            printf "░%.0s" $(seq 1 $((10 - ram_bars)))
            echo -ne "${C_RESET} "
        } || echo -n "          "

        # Agents count
        printf "%-8s" "$agents"

        # Sparkline
        echo -ne "${C_CYAN}$cpu_spark${C_RESET}"

        ((row++))
    done

    return $row
}

# Draw agents panel with progress
draw_agents_panel() {
    local start_row=$1
    local row=$start_row

    # Header
    tput_cup $row 2
    echo -ne "${C_CYAN}${C_BOLD}ACTIVE AGENTS${C_RESET}"
    ((row++))

    tput_cup $row 2
    printf "%-25s %-8s %-20s %-10s %s" "AGENT" "DEVICE" "BRANCH" "STATUS" "PROGRESS"
    ((row++))

    tput_cup $row 2
    printf "%-100s" "$(printf '─%.0s' {1..100})"
    ((row++))

    # Get agents
    local agents
    agents="$(get_agents_status)"

    if [ -z "$agents" ]; then
        tput_cup $row 2
        echo -ne "${C_YELLOW}No agents running${C_RESET}"
        return $((row + 2))
    fi

    echo "$agents" | head -8 | while IFS='|' read -r agent device branch status progress; do
        tput_cup $row 2

        # Agent name
        echo -ne "${C_WHITE}${C_BOLD}"
        printf "%-25s" "$agent"
        echo -ne "${C_RESET}"

        # Device
        printf "%-8s " "$device"

        # Branch
        printf "%-20s " "$branch"

        # Status
        case "$status" in
            ralph-running)
                echo -ne "${C_GREEN}⚙ RUNNING${C_RESET}  "
                ;;
            idle)
                echo -ne "${C_WHITE}⏸ IDLE   ${C_RESET}  "
                ;;
            *)
                echo -ne "${C_YELLOW}? $status${C_RESET}  "
                ;;
        esac

        # Progress bar
        if [ -n "$progress" ]; then
            local completed total
            completed="$(echo "$progress" | awk '{print $1}')"
            total="$(echo "$progress" | awk '{print $3}')"

            if [ -n "$completed" ] && [ -n "$total" ] && [ "$total" -gt 0 ]; then
                local pct=$((completed * 100 / total))
                local bars=$((pct * 20 / 100))

                echo -ne "${C_MAGENTA}["
                echo -ne "${C_GREEN}"
                printf "█%.0s" $(seq 1 $bars)
                echo -ne "${C_WHITE}"
                printf "░%.0s" $(seq 1 $((20 - bars)))
                echo -ne "${C_MAGENTA}]${C_RESET} "
                printf "%3d%%" "$pct"
            fi
        fi

        ((row++))
    done

    return $row
}

# Draw mini logs panel
draw_logs_panel() {
    local start_row=$1
    local row=$start_row
    local max_rows=$((TERM_ROWS - row - 2))

    [ $max_rows -lt 3 ] && return $row

    # Header
    tput_cup $row 2
    echo -ne "${C_CYAN}${C_BOLD}LIVE LOGS${C_RESET} ${C_WHITE}(last $max_rows lines)${C_RESET}"
    ((row++))

    tput_cup $row 2
    printf "%-100s" "$(printf '─%.0s' {1..100})"
    ((row++))

    # Get logs from Ralph agents
    for pfile in "$SWARM_PROJECTS_DIR"/*.json; do
        [ ! -f "$pfile" ] && continue
        local project_name
        project_name="$(jq -r '.name' "$pfile" 2>/dev/null)"

        jq -r '.agents[] | select(.status=="ralph-running") | "\(.name)|\(.device)"' "$pfile" 2>/dev/null | \
        while IFS='|' read -r agent device; do
            local agent_info
            agent_info="$(swarm_agent_get "$project_name" "$agent" 2>/dev/null)"
            [ -z "$agent_info" ] && continue

            local device_name
            device_name="$(echo "$agent_info" | jq -r '.device')"
            local device_info
            device_info="$(swarm_device_get "$device_name" 2>/dev/null)"
            [ -z "$device_info" ] && continue

            local ip user
            ip="$(echo "$device_info" | jq -r '.ip')"
            user="$(echo "$device_info" | jq -r '.user')"

            local log_lines
            log_lines="$(timeout 1 ssh -o ConnectTimeout=0.5 "$user@$ip" \
                "tail -3 ~/swarm-projects/$project_name/ralph.log 2>/dev/null" 2>/dev/null)"

            if [ -n "$log_lines" ]; then
                echo "$log_lines" | while read -r line; do
                    [ $row -ge $((TERM_ROWS - 1)) ] && break
                    tput_cup $row 2
                    echo -ne "${C_CYAN}[$device/$agent]${C_RESET} "
                    echo -n "${line:0:$((TERM_COLS - 30))}"
                    ((row++))
                done
            fi
        done
    done | head -$max_rows

    return $row
}

# Main render loop with double buffering
dashboard_render() {
    get_term_size

    # Buffer output
    local buffer=""

    # Clear and home
    buffer+="\033[2J\033[H"

    # Build entire frame in buffer
    # Header
    buffer+="\033[1;1H"
    buffer+="${C_BG_BLUE}${C_WHITE}${C_BOLD}"
    buffer+=$(printf "%-${TERM_COLS}s" " ASIS-CODER SWARM │ Mode: $DASHBOARD_MODE │ Refresh: ${DASHBOARD_REFRESH}s │ [q]Quit [d/a/l/v] ")
    buffer+="${C_RESET}"

    # Body (capture output)
    local body_output
    case "$DASHBOARD_MODE" in
        devices)
            body_output=$(draw_devices_panel)
            ;;
        agents)
            body_output=$(draw_agents_panel 3)
            ;;
        logs)
            body_output=$(draw_logs_panel 3)
            ;;
        all|*)
            local row
            body_output=$(draw_devices_panel)
            row=$?
            ((row += 2))
            body_output+=$(draw_agents_panel $row)
            row=$?
            ((row += 2))
            body_output+=$(draw_logs_panel $row)
            ;;
    esac

    buffer+="$body_output"

    # Footer
    buffer+="\033[${TERM_ROWS};1H"
    buffer+="${C_BG_BLACK}${C_YELLOW}"
    buffer+=$(printf "%-${TERM_COLS}s" " [q]Quit [d]Devices [a]Agents [l]Logs [v]All [+]Faster [-]Slower")
    buffer+="${C_RESET}"

    # Write entire buffer at once
    echo -ne "$buffer"
}

# Get agents status (same as before)
get_agents_status() {
    local projects_dir="$SWARM_PROJECTS_DIR"
    [ ! -d "$projects_dir" ] && return

    for pfile in "$projects_dir"/*.json; do
        [ ! -f "$pfile" ] && continue
        local project_name
        project_name="$(jq -r '.name' "$pfile" 2>/dev/null)"

        jq -r '.agents[] | "\(.name)|\(.device)|\(.branch)|\(.status)"' "$pfile" 2>/dev/null | \
        while IFS='|' read -r agent device branch status; do
            local progress=""
            if [ "$status" = "ralph-running" ]; then
                local prd_progress
                prd_progress="$(swarm_ralph_progress "$project_name" "$agent" 2>/dev/null | grep -o '[0-9]* / [0-9]*' | head -1)"
                progress="$prd_progress"
            fi
            echo "$project_name/$agent|$device|$branch|$status|$progress"
        done
    done
}

# Main dashboard loop
swarm_dashboard_run() {
    local mode="all"
    local refresh=2

    while [ $# -gt 0 ]; do
        case "$1" in
            --mode) mode="$2"; shift 2 ;;
            --refresh) refresh="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    DASHBOARD_MODE="$mode"
    DASHBOARD_REFRESH="$refresh"
    DASHBOARD_RUNNING=true

    # Enter alternate screen and hide cursor
    tput_alt_screen
    tput_hide_cursor

    # Trap to restore on exit
    trap 'tput_main_screen; tput_show_cursor; tput_reset' EXIT INT TERM

    while $DASHBOARD_RUNNING; do
        get_term_size
        dashboard_render

        # Non-blocking read
        if read -t "$DASHBOARD_REFRESH" -n 1 key 2>/dev/null; then
            case "$key" in
                q|Q) DASHBOARD_RUNNING=false ;;
                d|D) DASHBOARD_MODE="devices" ;;
                a|A) DASHBOARD_MODE="agents" ;;
                l|L) DASHBOARD_MODE="logs" ;;
                v|V) DASHBOARD_MODE="all" ;;
                +) DASHBOARD_REFRESH=$((DASHBOARD_REFRESH > 1 ? DASHBOARD_REFRESH - 1 : 1)) ;;
                -) DASHBOARD_REFRESH=$((DASHBOARD_REFRESH + 1)) ;;
            esac
        fi
    done
}

swarm_dashboard_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm dashboard${SWARM_C_RESET}  -  monitor swarm en tiempo real

Dashboard interactivo con gráficas sparklines y renderizado fijo (sin scroll).

${SWARM_C_BOLD}USO${SWARM_C_RESET}
  coder swarm dashboard [--mode <mode>] [--refresh <seconds>]

${SWARM_C_BOLD}MODOS${SWARM_C_RESET}
  all     → Vista completa (default)
  devices → Solo dispositivos con sparklines CPU
  agents  → Solo agentes con progress bars
  logs    → Solo logs en vivo

${SWARM_C_BOLD}CONTROLES${SWARM_C_RESET}
  q       → Salir
  d       → Modo devices
  a       → Modo agents
  l       → Modo logs
  v       → Modo all
  +       → Refresh más rápido
  -       → Refresh más lento

${SWARM_C_BOLD}EJEMPLO${SWARM_C_RESET}
  coder swarm dashboard
  coder swarm dashboard --mode devices --refresh 1
EOF
}

swarm_dashboard_cmd() {
    if [[ "$1" == --* ]] || [ -z "$1" ]; then
        swarm_dashboard_run "$@"
    else
        local sub="$1"; shift || true
        case "$sub" in
            run) swarm_dashboard_run "$@" ;;
            help|-h) swarm_dashboard_help ;;
            *) swarm_error "Subcomando desconocido: $sub"; swarm_dashboard_help; return 1 ;;
        esac
    fi
}
