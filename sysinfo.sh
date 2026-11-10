#!/usr/bin/env bash
#
# sysinfo.sh - print a short summary of this Linux machine.
#
# Everything is read locally, mostly from /proc and /sys. Nothing is sent
# over the network unless --net is given.

set -u

usage() {
    cat <<'USAGE'
Usage: sysinfo.sh [options]

  -n, --net        also look up the public IP address and local weather
                   (contacts ifconfig.me and wttr.in)
      --no-color   plain output (also the default when piped, or if NO_COLOR is set)
  -h, --help       show this help
USAGE
}

show_net=0
use_color=1
[ -t 1 ] || use_color=0
[ -n "${NO_COLOR:-}" ] && use_color=0

while [ $# -gt 0 ]; do
    case "$1" in
        -n | --net) show_net=1 ;;
        --no-color) use_color=0 ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "sysinfo.sh: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [ "$use_color" -eq 1 ]; then
    BOLD=$'\033[1m' DIM=$'\033[2m' CYAN=$'\033[36m' RESET=$'\033[0m'
else
    BOLD='' DIM='' CYAN='' RESET=''
fi

section() {
    printf '\n%s%s%s\n' "$BOLD$CYAN" "$1" "$RESET"
}

row() {
    printf '  %s%-10s%s %s\n' "$DIM" "$1" "$RESET" "${2:-unavailable}"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

# Convert a size in kB to a human-readable string.
human_kb() {
    awk -v kb="$1" 'BEGIN {
        split("K M G T", unit, " ")
        i = 1
        while (kb >= 1024 && i < 4) { kb /= 1024; i++ }
        printf "%.1f%s", kb, unit[i]
    }'
}

os_name() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        (. /etc/os-release && printf '%s' "${PRETTY_NAME:-${NAME:-Linux}}")
    else
        uname -s
    fi
}

uptime_text() {
    [ -r /proc/uptime ] || return
    awk '{
        s = int($1); d = int(s / 86400); h = int(s % 86400 / 3600); m = int(s % 3600 / 60)
        out = ""
        if (d) out = out d "d "
        if (d || h) out = out h "h "
        printf "%s%dm", out, m
    }' /proc/uptime
}

cpu_model() {
    awk -F': *' '/^model name/ { print $2; exit }' /proc/cpuinfo 2>/dev/null
}

cpu_count() {
    if have nproc; then
        nproc
    else
        grep -c '^processor' /proc/cpuinfo 2>/dev/null
    fi
}

# Busy share of the CPU over a short interval, from two /proc/stat samples.
cpu_usage() {
    [ -r /proc/stat ] || return
    local a b
    a=$(head -n 1 /proc/stat)
    sleep 0.3
    b=$(head -n 1 /proc/stat)
    printf '%s\n%s\n' "$a" "$b" | awk '
        {
            total = 0
            for (i = 2; i <= NF; i++) total += $i
            idle = $5 + $6      # idle + iowait
            if (NR == 1) { t1 = total; i1 = idle } else { t2 = total; i2 = idle }
        }
        END {
            dt = t2 - t1
            if (dt > 0) printf "%.0f%%", (1 - (i2 - i1) / dt) * 100
        }'
}

mem_field() {
    awk -v key="$1:" '$1 == key { print $2; exit }' /proc/meminfo 2>/dev/null
}

local_ip() {
    local ip=''
    if have ip; then
        # The source address the kernel would use for an outside destination.
        # This only consults the routing table; no packet is sent.
        ip=$(ip -4 route get 1.1.1.1 2>/dev/null |
            awk '{ for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit } }')
    fi
    if [ -z "$ip" ] && have hostname; then
        ip=$(hostname -I 2>/dev/null | awk '{ print $1 }')
    fi
    printf '%s' "$ip"
}

fetch() {
    curl --silent --fail --max-time 4 "$1" 2>/dev/null
}

# --- System -----------------------------------------------------------------

section "System"
row "OS" "$(os_name)"
row "Kernel" "$(uname -r)"
row "Hostname" "$(uname -n)"
row "Uptime" "$(uptime_text)"

# --- CPU --------------------------------------------------------------------

section "CPU"
row "Model" "$(cpu_model)"
row "Cores" "$(cpu_count)"
row "Usage" "$(cpu_usage)"
if [ -r /proc/loadavg ]; then
    row "Load" "$(cut -d ' ' -f 1-3 /proc/loadavg)"
fi

# --- Memory -----------------------------------------------------------------

section "Memory"
mem_total=$(mem_field MemTotal)
mem_available=$(mem_field MemAvailable)
if [ -n "$mem_total" ] && [ -n "$mem_available" ]; then
    mem_used=$((mem_total - mem_available))
    row "Total" "$(human_kb "$mem_total")"
    row "Used" "$(human_kb "$mem_used") ($((mem_used * 100 / mem_total))%)"
else
    row "Total" ""
fi

# --- Disk -------------------------------------------------------------------

section "Disk (/)"
disk=$(df -hP / 2>/dev/null | awk 'NR == 2 { print $2, $3, $5 }')
if [ -n "$disk" ]; then
    read -r disk_total disk_used disk_percent <<<"$disk"
    row "Total" "$disk_total"
    row "Used" "$disk_used ($disk_percent)"
else
    row "Total" ""
fi

# --- Battery ----------------------------------------------------------------

for battery in /sys/class/power_supply/BAT*; do
    [ -r "$battery/capacity" ] || continue
    section "Battery (${battery##*/})"
    status=$(cat "$battery/status" 2>/dev/null)
    row "Charge" "$(cat "$battery/capacity")%${status:+, $status}"
done

# --- Network ----------------------------------------------------------------

section "Network"
row "Local IP" "$(local_ip)"
if [ "$show_net" -eq 1 ]; then
    if have curl; then
        row "Public IP" "$(fetch https://ifconfig.me/ip)"
        row "Weather" "$(fetch 'https://wttr.in/?format=%l:+%C+%t')"
    else
        row "Public IP" "curl is not installed"
    fi
fi

printf '\n%sGenerated %s%s\n' "$DIM" "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$RESET"
