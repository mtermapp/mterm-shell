#!/usr/bin/env bash
# notify.sh — コマンド完了を OSC 1212;notify で iOS に通知する
#
# 使用方法:
#   mterm_notify_done "<cmd>" <exit_code> <duration_sec>
#
# zsh の場合は preexec/precmd フックで自動計測できる。
# bash の場合は PROMPT_COMMAND と trap DEBUG を組み合わせる。

MTERM_NOTIFY_THRESHOLD="${MTERM_NOTIFY_THRESHOLD:-5}"
MTERM_NOTIFY_ALL_EXITS="${MTERM_NOTIFY_ALL_EXITS:-1}"

# tmux inside SSH でも動作するよう DCS passthrough を自動検出
_mterm_osc() {
    if [ -n "$TMUX" ]; then
        printf '\033Ptmux;\033\033]%s\007\033\\' "$1"
    else
        printf '\033]%s\007' "$1"
    fi
}

mterm_notify_done() {
    local cmd="$1"
    local exit_code="${2:-0}"
    local duration="${3:-0}"

    # しきい値未満はスキップ
    [ "$duration" -lt "$MTERM_NOTIFY_THRESHOLD" ] && return

    # 成功のみ通知モード (MTERM_NOTIFY_ALL_EXITS=0) で失敗コードはスキップ
    if [ "$MTERM_NOTIFY_ALL_EXITS" = "0" ] && [ "$exit_code" -ne 0 ]; then
        return
    fi

    local title
    title=$(basename "$cmd" 2>/dev/null || echo "$cmd")

    local json
    json="{\"title\":\"$title\",\"exit_code\":$exit_code,\"duration_sec\":$duration,\"cmd\":\"$cmd\"}"

    _mterm_osc "1212;notify;$json"
}

# --- zsh 自動登録 ---
if [ -n "$ZSH_VERSION" ]; then
    _mterm_cmd_start_time=0
    _mterm_last_cmd=""

    _mterm_preexec() {
        _mterm_cmd_start_time=$(date +%s)
        _mterm_last_cmd="$1"
    }

    _mterm_precmd_notify() {
        local exit_code=$?
        local now
        now=$(date +%s)
        local duration=$(( now - _mterm_cmd_start_time ))
        if [ -n "$_mterm_last_cmd" ] && [ "$_mterm_cmd_start_time" -ne 0 ]; then
            mterm_notify_done "$_mterm_last_cmd" "$exit_code" "$duration"
        fi
        _mterm_cmd_start_time=0
        _mterm_last_cmd=""
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _mterm_preexec
    add-zsh-hook precmd  _mterm_precmd_notify
fi
