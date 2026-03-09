#!/usr/bin/env bash
# session-cmd.sh — mterm コマンドの実装
#
# 使い方:
#   mterm              # 現在のディレクトリ名でセッション作成/アタッチ
#   mterm "claude"     # 指定名でセッション作成/アタッチ
#   mterm list         # セッション一覧表示
#   mterm detach       # 現在のセッションからデタッチ
#   mterm version      # バージョン表示
#   mterm help         # ヘルプ表示

_MTERM_VERSION="0.1"

_mterm_session_cmd() {
    local name="${1:-}"
    local meta_file="$HOME/.mterm/sessions.json"

    # help サブコマンド
    if [ "$name" = "help" ] || [ "$name" = "--help" ] || [ "$name" = "-h" ]; then
        _mterm_help
        return 0
    fi

    # version サブコマンド
    if [ "$name" = "version" ] || [ "$name" = "--version" ] || [ "$name" = "-v" ]; then
        echo "mterm $_MTERM_VERSION"
        return 0
    fi

    # list サブコマンド
    if [ "$name" = "list" ]; then
        _mterm_session_list
        return $?
    fi

    # detach サブコマンド
    if [ "$name" = "detach" ]; then
        _mterm_detach
        return $?
    fi

    # 名前未指定の場合はカレントディレクトリ名を使用
    if [ -z "$name" ]; then
        name=$(basename "$PWD")
    fi

    # abduco チェック
    if ! command -v abduco >/dev/null 2>&1; then
        echo "mterm: abduco がインストールされていません"
        echo "  brew install abduco"
        return 1
    fi

    # MTERM_SESSION 環境変数を設定してから abduco にアタッチ
    # 既存セッションへのアタッチ、または新規作成
    export MTERM_SESSION="$name"

    # sessions.json に事前登録（アタッチ前にメタ情報を書き込む）
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

    # セッション一覧を即時 MTerm に送信（シートに表示されるよう）
    _mterm_send_sessions_now

    # abduco に入る前に外側の sessions.sh を停止
    # （停止しないと sessions.sh の OSC が abduco にキーボード入力として誤認される）
    _mterm_sessions_daemon_stop

    # アタッチを試み（-f: 既存クライアントを切断して強制アタッチ）、なければ新規作成
    if abduco -f -a "$name" 2>/dev/null; then
        :
    else
        # 新規セッション: MTERM_SESSION を引き継いだシェルで起動
        abduco -c "$name" env MTERM_SESSION="$name" "${SHELL:-zsh}"
    fi

    # abduco から戻ったら sessions.sh を再起動
    _mterm_sessions_daemon_start
}

# sessions デーモンを停止（PID ファイルを使用）
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

# sessions デーモンを起動
_mterm_sessions_daemon_start() {
    [ -z "$_MTERM_SCRIPTS_DIR" ] && return 0
    local tty pid_file
    tty=$(tty 2>/dev/null || true)
    [ -z "$tty" ] && return 0
    local tty_name
    tty_name=$(basename "$tty")
    pid_file="$HOME/.mterm/sessions-${tty_name}.pid"
    # 既に起動済みならスキップ
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

# abduco セッション一覧を OSC 1212;sessions で即時送信
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

# セッション一覧表示 + MTerm に OSC 送信
_mterm_session_list() {
    if ! command -v abduco >/dev/null 2>&1; then
        echo "mterm: abduco がインストールされていません"
        echo "  brew install abduco"
        return 1
    fi

    echo "=== abduco sessions ==="
    abduco 2>/dev/null || echo "(なし)"
    echo ""
    echo "=== sessions.json ==="
    local meta_file="$HOME/.mterm/sessions.json"
    if [ -f "$meta_file" ]; then
        cat "$meta_file"
    else
        echo "(なし)"
    fi
    echo ""

    # MTerm のセッションシートを更新
    echo "MTerm セッションシートを更新中..."
    _mterm_send_sessions_now
    echo "送信完了"
}

# 現在の abduco セッションからデタッチ
_mterm_detach() {
    if [ -z "$MTERM_SESSION" ]; then
        echo "mterm: abduco セッション内ではありません"
        return 1
    fi
    # abduco の親プロセス（abduco デーモン）に SIGQUIT を送ってデタッチ
    local abduco_pid
    abduco_pid=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
    if [ -n "$abduco_pid" ] && kill -0 "$abduco_pid" 2>/dev/null; then
        kill -QUIT "$abduco_pid"
    else
        echo "mterm: デタッチに失敗しました（abduco プロセスが見つかりません）"
        return 1
    fi
}

# ヘルプ表示
_mterm_help() {
    echo "mterm $_MTERM_VERSION - MTerm セッションマネージャー"
    echo ""
    echo "使い方:"
    echo "  mterm [名前]    セッションを作成/アタッチ（省略時はディレクトリ名）"
    echo "  mterm list      セッション一覧を表示"
    echo "  mterm detach    現在のセッションからデタッチ"
    echo "  mterm version   バージョンを表示"
    echo "  mterm help      このヘルプを表示"
    echo ""
    echo "デタッチ: Ctrl+\\ でも可"
}
