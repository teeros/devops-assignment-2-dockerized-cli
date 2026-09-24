#!/usr/bin/env bash
#
# diagnostic.sh - Dockerized Linux diagnostic CLI.
#
# Usage:
#   diagnostic system
#   diagnostic network <host>
#   diagnostic disk
#   diagnostic help
#
# Exit codes:
#   0 - success
#   1 - operational/runtime failure
#   2 - invalid command or input
#
set -u

print_help() {
    cat <<USAGE
Usage: diagnostic <command> [arguments]

Commands:
  system              Display Linux system information
  network <host>      Check connectivity to <host>
  disk                Display disk usage information
  help                Show this help message

Exit codes:
  0  success
  1  operational/runtime failure
  2  invalid command or input
USAGE
}

cmd_system() {
    echo "=========================================="
    echo "            SYSTEM INFORMATION"
    echo "=========================================="
    echo "Hostname        : $(hostname 2>/dev/null || echo unknown)"
    echo "Current User    : $(whoami 2>/dev/null || echo unknown)"
    echo "Date/Time       : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    if [[ -f /etc/os-release ]]; then
        echo "Operating System: $(. /etc/os-release && echo "$PRETTY_NAME")"
    else
        echo "Operating System: $(uname -s)"
    fi
    echo "Kernel Version  : $(uname -r)"
    echo "Uptime          : $(uptime -p 2>/dev/null || uptime)"
    echo "------------------------------------------"
    if [[ -f /proc/cpuinfo ]]; then
        echo "CPU Cores       : $(grep -c '^processor' /proc/cpuinfo)"
    fi
    if command -v free >/dev/null 2>&1; then
        free -h
    fi
    return 0
}

cmd_disk() {
    echo "=========================================="
    echo "            DISK USAGE"
    echo "=========================================="
    if command -v df >/dev/null 2>&1; then
        df -h -P
        return 0
    else
        echo "Error: 'df' command not available." >&2
        return 1
    fi
}

cmd_network() {
    local host="${1:-}"
    if [[ -z "$host" ]]; then
        echo "Error: 'network' requires a <host> argument." >&2
        print_help >&2
        return 2
    fi
    if ! [[ "$host" =~ ^[A-Za-z0-9.:_-]+$ ]]; then
        echo "Error: '$host' is not a valid hostname or IP address." >&2
        return 2
    fi

    echo "=========================================="
    echo "          NETWORK CHECK: $host"
    echo "=========================================="

    local resolved=""
    if command -v getent >/dev/null 2>&1; then
        resolved=$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -n1)
    fi
    if [[ -z "$resolved" ]] && [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        resolved="$host"
    fi

    local status=0
    if [[ -n "$resolved" ]]; then
        echo "Resolved Address: $resolved"
    else
        echo "Resolved Address: UNRESOLVED"
        status=1
    fi

    if command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            echo "Ping             : reachable"
        else
            echo "Ping             : unreachable"
            status=1
        fi
    fi

    return "$status"
}

main() {
    local command="${1:-}"

    case "$command" in
        system)
            cmd_system
            exit $?
            ;;
        network)
            shift
            cmd_network "${1:-}"
            exit $?
            ;;
        disk)
            cmd_disk
            exit $?
            ;;
        help|--help|-h)
            print_help
            exit 0
            ;;
        "")
            echo "Error: no command supplied." >&2
            print_help >&2
            exit 2
            ;;
        *)
            echo "Error: unknown command '$command'." >&2
            print_help >&2
            exit 2
            ;;
    esac
}

main "$@"
