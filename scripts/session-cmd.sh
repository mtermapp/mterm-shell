#!/usr/bin/env bash
# session-cmd.sh — mterm command implementation
#
# Usage:
#   mterm              # Create or attach using current directory name
#   mterm "claude"     # Create or attach with specified name
#   mterm list         # List sessions
#   mterm kill <name>  # Kill a session
#   mterm detach       # Detach from current session
#   mterm version      # Show version
#   mterm help         # Show help

_MTERM_VERSION="0.1"

_mterm_session_cmd() {
    local name="${1:-}"
    local meta_file="$HOME/.mterm/sessions.json"

    # help
    if [ "$name" = "help" ] || [ "$name" = "--help" ] || [ "$name" = "-h" ]; then
        _mterm_help
        return 0
    fi

    # version
    if [ "$name" = "version" ] || [ "$name" = "--version" ] || [ "$name" = "-v" ]; then
        echo "mterm $_MTERM_VERSION"
        return 0
    fi

    # list
    if [ "$name" = "list" ] || [ "$name" = "-l" ]; then
        _mterm_session_list
        return $?
    fi

    # detach
    if [ "$name" = "detach" ] || [ "$name" = "-d" ]; then
        _mterm_detach
        return $?
    fi

    # kill
    if [ "$name" = "kill" ] || [ "$name" = "-k" ]; then
        _mterm_kill "${2:-}"
        return $?
    fi

    # attach (-a name)
    if [ "$name" = "-a" ]; then
        name="${2:-}"
        if [ -z "$name" ]; then
            echo "mterm: session name required"
            echo "  mterm -a <name>"
            return 1
        fi
    fi

    # default to current directory name
    if [ -z "$name" ]; then
        name=$(basename "$PWD")
    fi

    # abduco check
    if ! command -v abduco >/dev/null 2>&1; then
        echo "mterm: abduco is not installed"
        echo "  brew install abduco"
        return 1
    fi

    export MTERM_SESSION="$name"

    # register in sessions.json before attaching
    local dir
    dir=$(echo "$PWD" | sed "s|$HOME|~|")
    local ts
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ')

    mkdir -p "$HOME/.mterm"
    if command -v jq >/dev/null 2>&1; then
        local existing="{}"
        [ -f "$meta_file" ] && existing=$(cat "$meta_file" 2>/dev/null || echo "{}")
        local entry
        entry=$(jq -n --arg dir "$dir" --arg ts "$ts" \
            '{"dir":$dir,"branch":"","cmd":"","last_active":$ts}')
        echo "$existing" | jq --arg n "$name" --argjson e "$entry" \
            'if .[$n] then . else .[$n] = $e end' > "$meta_file" 2>/dev/null
    fi

    echo "MTerm session: $name"

    # send session list to MTerm immediately
    _mterm_send_sessions_now

    # stop sessions.sh daemon before entering abduco (prevents TTY corruption)
    _mterm_sessions_daemon_stop

    # attach to existing session or create new one
    if abduco -f -a "$name" 2>/dev/null; then
        :
    else
        abduco -c "$name" env MTERM_SESSION="$name" "${SHELL:-zsh}"
    fi

    # restart sessions.sh daemon after returning from abduco
    _mterm_sessions_daemon_start
}

# stop sessions daemon (using PID file)
_mterm_sessions_daemon_stop() {
    local tty_name pid_file pid
    tty_name=$(basename "$(tty 2>/dev/null || echo unknown)")
    pid_file="$HOME/.mterm/sessions-${tty_name}.pid"
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file" 2>/dev/null)
        [ -n "$pid" ] && kill "$pid" 2>/dev/null
        rm -f "$pid_file"
    fi
}

# start sessions daemon
_mterm_sessions_daemon_start() {
    [ -z "$_MTERM_SCRIPTS_DIR" ] && return 0
    local tty pid_file
    tty=$(tty 2>/dev/null || true)
    [ -z "$tty" ] && return 0
    local tty_name
    tty_name=$(basename "$tty")
    pid_file="$HOME/.mterm/sessions-${tty_name}.pid"
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file" 2>/dev/null)
        kill -0 "$pid" 2>/dev/null && return 0
    fi
    mkdir -p "$HOME/.mterm"
    { bash "$_MTERM_SCRIPTS_DIR/sessions.sh" "$tty" >/dev/null 2>&1 & } 2>/dev/null
    echo $! > "$pid_file"
    disown $! 2>/dev/null || true
}

# send abduco session list via OSC 1212;sessions immediately
_mterm_send_sessions_now() {
    command -v abduco >/dev/null 2>&1 || return 0

    local meta_file="$HOME/.mterm/sessions.json"
    local meta="{}"
    [ -f "$meta_file" ] && meta=$(cat "$meta_file" 2>/dev/null || echo "{}")

    local result="["
    local first=true

    while IFS= read -r line; do
        [[ "$line" =~ ^active ]] && continue
        [[ -z "${line// }" ]] && continue

        local attached first_char="${line:0:1}"
        if [[ "$first_char" == "*" ]] || [[ "$first_char" == "+" ]]; then
            attached=true
        elif [[ "$first_char" == " " ]] || [[ "$first_char" == "-" ]]; then
            attached=false
        else
            continue
        fi

        local sname
        sname=$(echo "$line" | cut -c3- \
            | sed 's/^[A-Za-z][a-z][a-z][[:space:]]*//' \
            | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[[:space:]]*//' \
            | sed 's/^[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}[[:space:]]*//' \
            | sed 's/[[:space:]]*\[.*\][[:space:]]*$//' \
            | sed 's/[[:space:]]*$//')
        [ -z "$sname" ] && continue

        local sdir sbranch scmd
        if command -v jq >/dev/null 2>&1; then
            sdir=$(echo "$meta" | jq -r --arg n "$sname" '.[$n].dir // "~"' 2>/dev/null || echo "~")
            sbranch=$(echo "$meta" | jq -r --arg n "$sname" '.[$n].branch // ""' 2>/dev/null || echo "")
            scmd=$(echo "$meta" | jq -r --arg n "$sname" '.[$n].cmd // ""' 2>/dev/null || echo "")
        else
            sdir="~"; sbranch=""; scmd=""
        fi

        local entry="{\"id\":\"$sname\",\"name\":\"$sname\",\"source\":\"mac\",\"dir\":\"$sdir\",\"attached\":$attached"
        [ -n "$sbranch" ] && entry="${entry},\"branch\":\"$sbranch\""
        [ -n "$scmd" ]    && entry="${entry},\"cmd\":\"$scmd\""
        entry="${entry}}"

        [ "$first" = true ] || result+=","
        result+="$entry"
        first=false
    done <<< "$(abduco 2>/dev/null)"

    result+="]"

    if [ "$result" != "[]" ]; then
        if [ -n "$TMUX" ]; then
            printf '\033Ptmux;\033\033]1212;sessions;%s\007\033\\' "$(echo "$result" | tr -d '\n\r')"
        else
            printf '\033]1212;sessions;%s\007' "$(echo "$result" | tr -d '\n\r')"
        fi
    fi
}

# list sessions
_mterm_session_list() {
    if ! command -v abduco >/dev/null 2>&1; then
        echo "mterm: abduco is not installed"
        echo "  brew install abduco"
        return 1
    fi

    echo "=== abduco sessions ==="
    abduco 2>/dev/null || echo "(none)"
    echo ""
    echo "=== sessions.json ==="
    local meta_file="$HOME/.mterm/sessions.json"
    if [ -f "$meta_file" ]; then
        cat "$meta_file"
    else
        echo "(none)"
    fi
    echo ""

    echo "Updating MTerm session sheet..."
    _mterm_send_sessions_now
    echo "Done"
}

# kill a session (terminate process + remove socket)
_mterm_kill() {
    local name="${1:-}"
    if [ -z "$name" ]; then
        echo "mterm: session name required"
        echo "  mterm kill <name>"
        return 1
    fi

    # find socket file (~/.abduco/name@hostname)
    local socket
    socket=$(ls "$HOME/.abduco/" 2>/dev/null | grep "^${name}@" | head -1)
    if [ -z "$socket" ]; then
        echo "mterm: session '$name' not found"
        return 1
    fi
    socket="$HOME/.abduco/$socket"

    # find abduco daemon PID via lsof
    local pid
    pid=$(lsof -t "$socket" 2>/dev/null | head -1)
    if [ -n "$pid" ]; then
        kill -TERM "$pid" 2>/dev/null
        sleep 0.3
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null
    fi

    # remove socket file and sessions.json entry
    rm -f "$socket"
    local meta_file="$HOME/.mterm/sessions.json"
    if [ -f "$meta_file" ] && command -v jq >/dev/null 2>&1; then
        jq --arg n "$name" 'del(.[$n])' "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"
    fi

    echo "mterm: session '$name' killed"
    _mterm_send_sessions_now
}

# detach from current abduco session
_mterm_detach() {
    if [ -z "$MTERM_SESSION" ]; then
        echo "mterm: not inside an abduco session"
        return 1
    fi
    local abduco_pid
    abduco_pid=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
    if [ -n "$abduco_pid" ] && kill -0 "$abduco_pid" 2>/dev/null; then
        kill -QUIT "$abduco_pid"
    else
        echo "mterm: detach failed (abduco process not found)"
        return 1
    fi
}

# show help
_mterm_help() {
    echo "mterm $_MTERM_VERSION - MTerm session manager"
    echo ""
    echo "Usage:"
    echo "  mterm [name]      Create or attach to a session (defaults to current directory name)"
    echo "  mterm -a <name>   Attach to a session"
    echo "  mterm -l          List sessions"
    echo "  mterm -k <name>   Kill a session"
    echo "  mterm -d          Detach from current session"
    echo "  mterm -v          Show version"
    echo "  mterm -h          Show this help"
    echo ""
    echo "Tip: Ctrl+\\ also detaches"
}
