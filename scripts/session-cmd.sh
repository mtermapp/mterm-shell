#!/usr/bin/env bash
# session-cmd.sh — mterm-session コマンドの実装
#
# 使い方:
#   mterm-session              # 現在のディレクトリ名でセッション作成/アタッチ
#   mterm-session "claude"     # 指定名でセッション作成/アタッチ

_mterm_session_cmd() {
    local name="${1:-}"
    local meta_file="$HOME/.mterm/sessions.json"

    # 名前未指定の場合はカレントディレクトリ名を使用
    if [ -z "$name" ]; then
        name=$(basename "$PWD")
    fi

    # abduco チェック
    if ! command -v abduco >/dev/null 2>&1; then
        echo "mterm-session: abduco がインストールされていません"
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
            'if .[$n] then . else .[$n] = $e end' > "$meta_file.tmp" 2>/dev/null \
            && mv "$meta_file.tmp" "$meta_file"
    fi

    echo "MTerm session: $name"

    # アタッチを試み、なければ新規作成
    # -e detach-key をデフォルトの Ctrl-\ にする（abduco デフォルト）
    if abduco -a "$name" 2>/dev/null; then
        return 0
    else
        # 新規セッション: MTERM_SESSION を引き継いだシェルで起動
        abduco -c "$name" env MTERM_SESSION="$name" "${SHELL:-zsh}"
    fi
}
