#!/usr/bin/env bash
# init.sh — MTerm Mac プラグイン シェルフック初期化
#
# ~/.zshrc または ~/.bashrc に以下を追加:
#   [ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
#
# これだけで context (タブ名+ブランチ) と notify (コマンド完了通知) が有効になる。
# abduco がインストールされている場合はセッション一覧も表示される。

# スクリプトディレクトリを自動検出
if [ -n "$ZSH_VERSION" ]; then
    _MTERM_SCRIPTS_DIR="${0:A:h}/scripts"
elif [ -n "$BASH_VERSION" ]; then
    _MTERM_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"
else
    _MTERM_SCRIPTS_DIR="${MTERM_MAC_PLUGIN_DIR:+$MTERM_MAC_PLUGIN_DIR/scripts}"
fi

if [ -z "$_MTERM_SCRIPTS_DIR" ] || [ ! -d "$_MTERM_SCRIPTS_DIR" ]; then
    return 0 2>/dev/null || exit 0
fi

# context: プロンプトごとにタブ名 + ブランチ情報を送信
# shellcheck disable=SC1091
source "$_MTERM_SCRIPTS_DIR/context.sh"

# notify: コマンド完了通知 (閾値超えで iOS 通知)
# shellcheck disable=SC1091
source "$_MTERM_SCRIPTS_DIR/notify.sh"

# sessions: バックグラウンドで abduco セッション一覧を定期送信
_MTERM_TTY=$(tty 2>/dev/null || true)
if [ -n "$_MTERM_TTY" ]; then
    # 既に起動済みの sessions デーモンがあればスキップ
    if [ -z "$_MTERM_SESSIONS_PID" ] || ! kill -0 "$_MTERM_SESSIONS_PID" 2>/dev/null; then
        # nohup + リダイレクトでジョブ通知（[N] Done等）を完全に抑制
        { bash "$_MTERM_SCRIPTS_DIR/sessions.sh" "$_MTERM_TTY" >/dev/null 2>&1 & } 2>/dev/null
        _MTERM_SESSIONS_PID=$!
        disown "$_MTERM_SESSIONS_PID" 2>/dev/null || true
    fi
fi

# mterm-session コマンド: セッション名を指定して abduco セッションを作成/リネーム
mterm-session() {
    # shellcheck disable=SC1091
    source "$_MTERM_SCRIPTS_DIR/session-cmd.sh"
    _mterm_session_cmd "$@"
}
