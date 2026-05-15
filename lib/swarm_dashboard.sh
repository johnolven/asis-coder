#!/bin/bash

# ==========================================
# SWARM DASHBOARD - swarm_dashboard.sh
# ==========================================
# Dashboard interactivo tipo htop para monitorear el swarm en tiempo real

# Terminal control
tput_clear() { tput clear 2>/dev/null || clear; }
tput_cup() { tput cup "$1" "$2" 2>/dev/null || echo -ne "\033[${1};${2}H"; }
tput_bold() { tput bold 2>/dev/null || echo -ne "\033[1m"; }
tput_reset() { tput sgr0 2>/dev/null || echo -ne "\033[0m"; }
tput_el() { echo -ne "\033[K"; }  # Clear to end of line
tput_color() {
    local color="$1"
    case "$color" in
        green)  echo -ne "\033[32m" ;;
        yellow) echo -ne "\033[33m" ;;
        red)    echo -ne "\033[31m" ;;
        blue)   echo -ne "\033[34m" ;;
        cyan)   echo -ne "\033[36m" ;;
        white)  echo -ne "\033[37m" ;;
        *)      tput_reset ;;
    esac
}

# Clear line and print (prevents ghosting)
print_line() {
    tput_el
    echo "$@"
}

# Get terminal size
get_term_size() {
    TERM_ROWS=$(tput lines 2>/dev/null || echo 40)
    TERM_COLS=$(tput cols 2>/dev/null || echo 120)
}

# Draw box characters
draw_box_line() {
    local char="${1:-─}"
    local width=${2:-$TERM_COLS}
    [ $width -lt 1 ] && width=1
    printf "$char%.0s" $(seq 1 $width)
}

# Dashboard state
DASHBOARD_MODE="all"  # all, devices, agents, redis, logs
DASHBOARD_REFRESH=2
DASHBOARD_RUNNING=true
DASHBOARD_SCROLL=0

# Sparkline characters
SPARK_CHARS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# CPU/RAM history (circular buffers)
declare -A CPU_HISTORY
declare -A RAM_HISTORY
HISTORY_SIZE=12

# Store metric in history
store_metric() {
    local device="$1" type="$2" value="$3"
    local key="${type}_HISTORY[$device]"
    local hist="${!key}"

    # Add new value
    hist="$hist $value"

    # Keep only last N values
    local count=$(echo "$hist" | wc -w)
    if [ $count -gt $HISTORY_SIZE ]; then
        local start=$((count - HISTORY_SIZE + 1))
        hist=$(echo "$hist" | awk '{for(i='$start'; i<=NF; i++) printf "%s ", $i}')
    fi

    eval "${type}_HISTORY[$device]=\"$hist\""
}

# Generate sparkline from values
generate_sparkline() {
    local values="$1"
    [ -z "$values" ] && echo "▁▁▁▁▁▁▁▁" && return

    local max=1
    for v in $values; do
        [ "$v" -gt "$max" ] && max=$v
    done

    local sparkline=""
    for v in $values; do
        local idx=$((v * 7 / max))
        [ "$idx" -gt 7 ] && idx=7
        sparkline+="${SPARK_CHARS[$idx]}"
    done

    echo "$sparkline"
}

# Get sparkline for device
get_sparkline() {
    local device="$1" type="$2"
    local key="${type}_HISTORY[$device]"
    local hist="${!key}"
    generate_sparkline "$hist"
}

# Check terminal width
is_narrow() { [ $TERM_COLS -lt 100 ]; }
is_wide() { [ $TERM_COLS -ge 120 ]; }

swarm_dashboard_help() {
    cat <<EOF
${SWARM_C_BOLD}coder swarm dashboard${SWARM_C_RESET}  -  monitor swarm en tiempo real

Dashboard interactivo tipo htop para visualizar el estado del swarm.

${SWARM_C_BOLD}MODOS${SWARM_C_RESET}
  all     → Vista completa (default)
  devices → Solo estado de devices
  agents  → Solo agentes activos
  redis   → Solo tráfico Redis
  logs    → Solo logs en vivo

${SWARM_C_BOLD}USO${SWARM_C_RESET}
  coder swarm dashboard [--mode <mode>] [--refresh <seconds>]

${SWARM_C_BOLD}CONTROLES${SWARM_C_RESET}
  q       → Salir
  d       → Modo devices
  a       → Modo agents
  r       → Modo redis
  l       → Modo logs
  v       → Modo all (vista completa)
  +/-     → Aumentar/disminuir refresh rate
  ↑/↓     → Scroll logs
  ENTER   → Ver detalle de item seleccionado

${SWARM_C_BOLD}EJEMPLO${SWARM_C_RESET}
  coder swarm dashboard
  coder swarm dashboard --mode agents --refresh 1
EOF
}

# Get device stats
get_device_stats() {
    local device_name="$1"
    local device_info
    device_info="$(swarm_device_get "$device_name" 2>/dev/null)"
    [ -z "$device_info" ] && return 1

    local ip user
    ip="$(echo "$device_info" | jq -r '.ip')"
    user="$(echo "$device_info" | jq -r '.user')"

    # Get CPU, RAM, agents count via SSH
    local stats
    stats="$(ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$user@$ip" \
        "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1; \
         free -m | awk '/^Mem:/ {printf \"%.1f/%.1fGB\", \$3/1024, \$2/1024}'; \
         find ~/swarm-projects -name 'ralph.log' 2>/dev/null | wc -l" 2>/dev/null)"

    if [ $? -eq 0 ]; then
        local cpu ram agents
        cpu="$(echo "$stats" | sed -n '1p')"
        ram="$(echo "$stats" | sed -n '2p')"
        agents="$(echo "$stats" | sed -n '3p')"
        echo "$device_name|$ip|online|${cpu}%|$ram|${agents}"
    else
        echo "$device_name|$ip|offline|0%|0/0GB|0"
    fi
}

# Get all agents status
get_agents_status() {
    local projects_dir="$SWARM_PROJECTS_DIR"
    [ ! -d "$projects_dir" ] && return

    for pfile in "$projects_dir"/*.json; do
        [ ! -f "$pfile" ] && continue
        local project_name
        project_name="$(jq -r '.name' "$pfile" 2>/dev/null)"

        jq -r '.agents[] | "\(.name)|\(.device)|\(.branch)|\(.status)"' "$pfile" 2>/dev/null | \
        while IFS='|' read -r agent device branch status; do
            # Get progress if Ralph is running
            local progress=""
            if [ "$status" = "ralph-running" ]; then
                local agent_info
                agent_info="$(swarm_agent_get "$project_name" "$agent" 2>/dev/null)"
                if [ -n "$agent_info" ]; then
                    local device_name
                    device_name="$(echo "$agent_info" | jq -r '.device')"
                    local prd_progress
                    prd_progress="$(swarm_ralph_progress "$project_name" "$agent" 2>/dev/null | grep -o '[0-9]* / [0-9]*' | head -1)"
                    progress="$prd_progress"
                fi
            fi
            echo "$project_name/$agent|$device|$branch|$status|$progress"
        done
    done
}

# Draw header
draw_header() {
    tput_cup 0 0
    tput_bold; tput_color cyan
    printf "┌"; draw_box_line "─"; printf "┐\n"
    printf "│ "
    tput_color green
    printf "ASIS-CODER SWARM DASHBOARD"
    tput_reset; tput_color cyan
    local role_text="[?] Unknown"
    if [ -f "$SWARM_ROLE_FILE" ]; then
        local role
        role="$(jq -r '.role' "$SWARM_ROLE_FILE" 2>/dev/null)"
        case "$role" in
            parent) role_text="[P] Parent Mode" ;;
            child)  role_text="[C] Child Mode" ;;
        esac
    fi
    local title_len=26
    local padding=$((TERM_COLS - title_len - ${#role_text} - 4))
    [ $padding -lt 0 ] && padding=0
    printf "%*s" $padding " "
    tput_color yellow
    printf "%s" "$role_text"
    tput_reset; tput_color cyan
    printf " │\n"

    local hostname_text="$(hostname) @ $(hostname -I | awk '{print $1}')"
    local refresh_text="Refresh: ${DASHBOARD_REFRESH}s"
    printf "│ %s" "$hostname_text"
    local padding2=$((TERM_COLS - ${#hostname_text} - ${#refresh_text} - 4))
    [ $padding2 -lt 0 ] && padding2=0
    printf "%*s" $padding2 " "
    tput_color white
    printf "%s" "$refresh_text"
    tput_reset; tput_color cyan
    printf " │\n"
    printf "├"; draw_box_line "─"; printf "┤\n"
    tput_reset
}

# Draw devices section
draw_devices() {
    tput_bold; tput_color blue
    echo "│ DEVICES"
    tput_reset; tput_color cyan
    printf "├"; draw_box_line "─"; printf "┤\n"
    tput_reset

    # Get all devices from swarm_common location
    local devices_file="${SWARM_DEVICES_FILE:-$HOME/.asis-coder/swarm/devices.json}"
    local devices_json
    devices_json="$(cat "$devices_file" 2>/dev/null)"

    if [ -z "$devices_json" ] || [ "$devices_json" = "null" ]; then
        tput_color yellow
        echo "│ No devices configured. Run: coder swarm device add <name> <ip>"
        tput_reset
        return
    fi

    # Extract devices array (format is {"devices": [...]})
    local devices_array
    devices_array="$(echo "$devices_json" | jq -r '.devices // []' 2>/dev/null)"

    local count
    count="$(echo "$devices_array" | jq 'length' 2>/dev/null || echo 0)"

    if [ "$count" -eq 0 ]; then
        tput_color yellow
        echo "│ No devices registered. Run: coder swarm device add <name> <ip>"
        tput_reset
        return
    fi

    # Process devices in parallel for speed
    local tmpdir="/tmp/dashboard-$$"
    mkdir -p "$tmpdir"

    # Launch SSH queries in parallel
    echo "$devices_array" | jq -r '.[] | "\(.name)|\(.ip)|\(.user)"' 2>/dev/null | \
    while IFS='|' read -r name ip user; do
        (
            local stats
            stats="$(timeout 2 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no "$user@$ip" \
                "top -bn1 | grep 'Cpu' | head -1 | awk '{print int(\$2)}'; \
                 free -m | awk '/^Mem:/ {printf \"%.1f/%.1fG\\n\", \$3/1024, \$2/1024}'; \
                 tmux ls 2>/dev/null | grep -c ralph || echo 0" 2>/dev/null)"
            echo "$stats" > "$tmpdir/$name.stats"
        ) &
    done

    # Wait for all SSH calls (max 2.5s)
    sleep 2.5

    # Display results with responsive layout
    echo "$devices_array" | jq -r '.[] | "\(.name)|\(.ip)|\(.user)"' 2>/dev/null | \
    while IFS='|' read -r name ip user; do
        local status="offline" cpu_val="?" ram="?/?GB" agents="0"

        if [ -f "$tmpdir/$name.stats" ]; then
            local stats=$(cat "$tmpdir/$name.stats")
            if [ -n "$stats" ]; then
                status="online"
                cpu_val="$(echo "$stats" | sed -n '1p')"
                ram="$(echo "$stats" | sed -n '2p')"
                agents="$(echo "$stats" | sed -n '3p')"

                # Store CPU for sparkline
                store_metric "$name" "CPU" "$cpu_val"
            fi
        fi

        printf "│ "
        tput_bold
        printf "%-10s" "$name"
        tput_reset

        if is_narrow; then
            # Narrow: compact view
            printf " "
            if [ "$status" = "online" ]; then
                tput_color green; printf "●"
            else
                tput_color red; printf "○"
            fi
            tput_reset
            printf " CPU:%s%%" "$cpu_val"

        elif is_wide; then
            # Wide: full view with sparkline
            printf " %-15s " "$ip"

            if [ "$status" = "online" ]; then
                tput_color green; printf "● ONLINE "
            else
                tput_color red; printf "○ OFFLINE"
            fi
            tput_reset

            printf "  CPU: %-3s%% RAM: %-10s %s AGT  " "$cpu_val" "$ram" "$agents"

            # Sparkline
            if [ "$status" = "online" ] && [ "$cpu_val" != "?" ]; then
                local spark=$(get_sparkline "$name" "CPU")
                tput_color cyan
                printf "%s" "$spark"
                tput_reset
            fi
        else
            # Medium: moderate detail
            printf " %-15s " "$ip"

            if [ "$status" = "online" ]; then
                tput_color green; printf "●"
            else
                tput_color red; printf "○"
            fi
            tput_reset

            printf " CPU: %-3s%% RAM: %-10s" "$cpu_val" "$ram"
        fi

        printf "\n"
    done

    # Cleanup
    rm -rf "$tmpdir"
}

# Draw agents section
draw_agents() {
    tput_bold; tput_color blue
    echo "│ ACTIVE AGENTS"
    tput_reset; tput_color cyan
    printf "├"; draw_box_line "─"; printf "┤\n"
    tput_reset

    local agents
    agents="$(get_agents_status)"

    if [ -z "$agents" ]; then
        tput_color yellow
        echo "│ No agents running"
        tput_reset
        return
    fi

    echo "$agents" | head -10 | while IFS='|' read -r agent device branch status progress; do
        printf "│ "
        tput_color cyan
        printf "%-20s" "$agent"
        tput_reset
        printf " %-6s %-20s " "$device" "$branch"

        case "$status" in
            ralph-running)
                tput_color green; printf "⚙ RUNNING "
                ;;
            idle)
                tput_color white; printf "⏸ IDLE    "
                ;;
            *)
                tput_color yellow; printf "? %-8s" "$status"
                ;;
        esac
        tput_reset

        if [ -n "$progress" ]; then
            printf " [%s]" "$progress"
            # Draw progress bar
            local completed total
            completed="$(echo "$progress" | awk '{print $1}')"
            total="$(echo "$progress" | awk '{print $3}')"
            if [ -n "$completed" ] && [ -n "$total" ] && [ "$total" -gt 0 ]; then
                local pct=$((completed * 100 / total))
                local bars=$((pct / 20))
                printf " "
                tput_color green
                printf "█%.0s" $(seq 1 $bars)
                tput_color white
                printf "░%.0s" $(seq 1 $((5 - bars)))
                tput_reset
            fi
        fi
        echo
    done
}

# Draw redis traffic section
draw_redis() {
    tput_bold; tput_color blue
    echo "│ REDIS TRAFFIC (last 10s)"
    tput_reset; tput_color cyan
    printf "├"; draw_box_line "─"; printf "┤\n"
    tput_reset

    # This would require redis-cli monitor in background
    # For now, show a placeholder
    tput_color yellow
    echo "│ (Redis monitoring requires: redis-cli monitor &)"
    tput_reset
}

# Draw logs section
draw_logs() {
    tput_bold; tput_color blue
    echo "│ LOGS (live tail)"
    tput_reset; tput_color cyan
    printf "├"; draw_box_line "─"; printf "┤\n"
    tput_reset

    # Get last N log lines from all Ralph logs
    local max_lines=$((TERM_ROWS - 20))
    [ $max_lines -lt 5 ] && max_lines=5

    local all_logs=""
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
            log_lines="$(ssh -o ConnectTimeout=2 "$user@$ip" \
                "tail -5 ~/swarm-projects/$project_name/ralph.log 2>/dev/null" 2>/dev/null)"

            if [ -n "$log_lines" ]; then
                echo "$log_lines" | while read -r line; do
                    printf "│ "
                    tput_color cyan
                    printf "[%-6s/%-8s]" "$device" "$agent"
                    tput_reset
                    printf " %s\n" "$line"
                done
            fi
        done
    done | tail -$max_lines
}

# Draw footer
draw_footer() {
    tput_color cyan
    printf "└"; draw_box_line "─"; printf "┘\n"
    tput_reset
    tput_color yellow
    printf " [q]Quit [d]Devices [a]Agents [r]Redis [l]Logs [v]All [+/-]Speed\n"
    tput_reset
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

    # Hide cursor
    tput civis 2>/dev/null || echo -ne "\033[?25l"

    # Trap to restore cursor on exit
    trap 'tput cnorm 2>/dev/null || echo -ne "\033[?25h"; tput_reset; clear' EXIT INT TERM

    # Clear screen once at start
    tput_clear

    while $DASHBOARD_RUNNING; do
        get_term_size

        # Move to home without clearing (prevents flicker)
        tput_cup 0 0

        draw_header

        case "$DASHBOARD_MODE" in
            devices)
                draw_devices
                ;;
            agents)
                draw_agents
                ;;
            redis)
                draw_redis
                ;;
            logs)
                draw_logs
                ;;
            all|*)
                draw_devices
                tput_color cyan
                printf "├"; draw_box_line "─"; printf "┤\n"
                tput_reset
                draw_agents
                tput_color cyan
                printf "├"; draw_box_line "─"; printf "┤\n"
                tput_reset
                draw_logs
                ;;
        esac

        draw_footer

        # Non-blocking read with timeout
        if read -t "$DASHBOARD_REFRESH" -n 1 key 2>/dev/null; then
            case "$key" in
                q|Q) DASHBOARD_RUNNING=false ;;
                d|D) DASHBOARD_MODE="devices" ;;
                a|A) DASHBOARD_MODE="agents" ;;
                r|R) DASHBOARD_MODE="redis" ;;
                l|L) DASHBOARD_MODE="logs" ;;
                v|V) DASHBOARD_MODE="all" ;;
                +) DASHBOARD_REFRESH=$((DASHBOARD_REFRESH > 1 ? DASHBOARD_REFRESH - 1 : 1)) ;;
                -) DASHBOARD_REFRESH=$((DASHBOARD_REFRESH + 1)) ;;
            esac
        fi
    done
}

swarm_dashboard_cmd() {
    # Check if first arg is a flag
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
