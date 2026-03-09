#!/usr/bin/env bash
# sessions.sh — abduco セッション情報を OSC 1212;sessions で定期送信する
#
# init.sh からバックグラウンドで起動される。
# 引数 $1 = 書き込み先の TTY パス（例: /dev/ttys001）
# 3 秒ごとに Mac セッション一覧を JSON で送信する。

TTY_PATH="${1:-}"
INTERVAL="${MTERM_SESSIONS_INTERVAL:-3}"
META_FILE="$HOME/.mterm/sessions.json"

# 書き込み先 TTY の確認
if [ -z "$TTY_PATH" ] || [ ! -w "$TTY_PATH" ]; then
    exit 0
fi

# abduco セッション一覧をパースして JSON を構築
build_sessions_json() {
    local result="["
    local first=true

    if ! command -v abduco >/dev/null 2>&1; then
        echo "[]"
        return
    fi

    # abduco 出力例:
    #   active sessions (users in []):
    #   + 2024-01-01 10:00:00    MTerm          [1]
    #   - 2024-01-01 09:00:00    server         []
    local meta="{}"
    [ -f "$META_FILE" ] && meta=$(cat "$META_FILE" 2>/dev/null || echo "{}")

    while IFS= read -r line; do
        # 空行をスキップ
        [[ -z "${line// }" ]] && continue

        # ステータス判定（新形式: */space、旧形式: +/-）
        local attached first_char="${line:0:1}"
        if [[ "$first_char" == "*" ]] || [[ "$first_char" == "+" ]]; then
            attached=true
        elif [[ "$first_char" == " " ]] || [[ "$first_char" == "-" ]]; then
            attached=false
        else
            continue  # ヘッダー行などをスキップ
        fi

        # セッション名を抽出（新旧フォーマット両対応）
        # 新形式: "* Mon    YYYY-MM-DD HH:MM:SS    name"
        # 旧形式: "+ YYYY-MM-DD HH:MM:SS    name    [N]"
        local name
        name=$(echo "$line" | cut -c3- \
            | sed 's/^[A-Za-z][a-z][a-z][[:space:]]*//' \
            | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[[:space:]]*//' \
            | sed 's/^[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}[[:space:]]*//' \
            | sed 's/[[:space:]]*\[.*\][[:space:]]*$//' \
            | sed 's/[[:space:]]*$//')
        [ -z "$name" ] && continue

        # セッションメタ情報を sessions.json から取得
        local dir branch cmd last_active
        if command -v jq >/dev/null 2>&1; then
            dir=$(echo "$meta" | jq -r --arg n "$name" '.[$n].dir // "~"' 2>/dev/null || echo "~")
            branch=$(echo "$meta" | jq -r --arg n "$name" '.[$n].branch // ""' 2>/dev/null || echo "")
            cmd=$(echo "$meta" | jq -r --arg n "$name" '.[$n].cmd // ""' 2>/dev/null || echo "")
            last_active=$(echo "$meta" | jq -r --arg n "$name" '.[$n].last_active // ""' 2>/dev/null || echo "")
        else
            dir="~"
            branch=""
            cmd=""
            last_active=""
        fi

        # JSON エントリ組み立て（改行禁止: OSC シーケンスが壊れるため）
        local entry
        entry="{\"id\":\"$name\",\"name\":\"$name\",\"source\":\"mac\",\"dir\":\"$dir\",\"attached\":$attached"
        [ -n "$branch" ] && entry="${entry},\"branch\":\"$branch\""
        [ -n "$cmd" ] && entry="${entry},\"cmd\":\"$cmd\""
        [ -n "$last_active" ] && entry="${entry},\"last_active\":\"$last_active\""
        entry="${entry}}"

        [ "$first" = true ] || result+=","
        result+="$entry"
        first=false
    done <<< "$(abduco 2>/dev/null)"

    result+="]"
    echo "$result"
}

# メインループ
while true; do
    # TTY が閉じられたら終了
    [ -w "$TTY_PATH" ] || exit 0

    sessions=$(build_sessions_json 2>/dev/null | tr -d '\n\r')
    if [ -n "$sessions" ] && [ "$sessions" != "[]" ]; then
        printf '\033]1212;sessions;%s\007' "$sessions" > "$TTY_PATH" 2>/dev/null
    fi

    sleep "$INTERVAL"
done
