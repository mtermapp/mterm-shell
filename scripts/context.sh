#!/usr/bin/env bash
# context.sh — OSC 1212;context を emit する
# zsh: precmd_functions += mterm_update_context
# bash: PROMPT_COMMAND="mterm_update_context;${PROMPT_COMMAND}"
#
# MTerm がアクティブウィンドウのタブ名とステータスバーを更新する。

# tmux inside SSH でも動作するよう DCS passthrough を自動検出
_mterm_osc() {
    if [ -n "$TMUX" ]; then
        printf '\033Ptmux;\033\033]%s\007\033\\' "$1"
    else
        printf '\033]%s\007' "$1"
    fi
}

mterm_update_context() {
    local branch dir json

    branch=$(git branch --show-current 2>/dev/null || echo "")
    dir=$(echo "$PWD" | sed "s|$HOME|~|")

    if [ -n "$branch" ]; then
        json="{\"branch\":\"$branch\",\"dir\":\"$dir\"}"
    else
        json="{\"branch\":null,\"dir\":\"$dir\"}"
    fi

    _mterm_osc "1212;context;$json"

    # abduco セッション内の場合はセッションメタ情報を更新
    if [ -n "$MTERM_SESSION" ]; then
        _mterm_update_session_meta "$dir" "$branch"
    fi
}

# セッションメタ情報を ~/.mterm/sessions.json に書き込む
_mterm_update_session_meta() {
    local dir="$1"
    local branch="$2"
    local meta_file="$HOME/.mterm/sessions.json"
    local cmd
    cmd=$(ps -o comm= -p "$$" 2>/dev/null | tail -1 || echo "")

    mkdir -p "$HOME/.mterm"

    local ts
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ')

    if command -v jq >/dev/null 2>&1; then
        local existing="{}"
        [ -f "$meta_file" ] && existing=$(cat "$meta_file")
        local entry
        entry=$(jq -n \
            --arg dir "$dir" \
            --arg branch "$branch" \
            --arg cmd "$cmd" \
            --arg ts "$ts" \
            '{"dir":$dir,"branch":$branch,"cmd":$cmd,"last_active":$ts}')
        echo "$existing" | jq --arg name "$MTERM_SESSION" --argjson entry "$entry" \
            '.[$name] = $entry' > "$meta_file.tmp" && mv -f "$meta_file.tmp" "$meta_file"
    else
        # jq なし: シンプルな上書き
        local entry="{\"dir\":\"$dir\",\"branch\":\"$branch\",\"cmd\":\"$cmd\",\"last_active\":\"$ts\"}"
        echo "{\"$MTERM_SESSION\":$entry}" > "$meta_file"
    fi
}

# zsh 自動登録
if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd mterm_update_context
fi

# bash 自動登録
if [ -n "$BASH_VERSION" ]; then
    if [[ "$PROMPT_COMMAND" != *mterm_update_context* ]]; then
        PROMPT_COMMAND="mterm_update_context;${PROMPT_COMMAND:-}"
    fi
fi
