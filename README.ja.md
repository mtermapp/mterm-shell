# MTerm Mac プラグイン

[MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074) と Mac を SSH 経由で連携するシェルプラグイン。

**機能:**
- タブ名・git ブランチをリアルタイムで MTerm に表示
- 長時間コマンドの完了通知（フォアグラウンド時のみ）
- `abduco` によるセッション永続化 — iPad を閉じてもプロセスを維持

---

## インストール

```bash
git clone https://github.com/mtermapp/mterm-mac ~/.mterm/plugin
```

`~/.zshrc` または `~/.bashrc` に追加:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

シェルを再読み込み:

```bash
source ~/.zshrc
```

---

## セッション永続化（任意）

iPad を閉じてもプロセスを維持するには `abduco` をインストール:

```bash
brew install abduco
```

セッション作成:

```bash
mterm-session            # カレントディレクトリ名を使用
mterm-session "claude"   # 名前を指定
```

MTerm のセッション一覧から実行中のセッションをタップして再接続できます。

---

## 設定

```bash
# 通知しきい値（デフォルト: 5秒）
export MTERM_NOTIFY_THRESHOLD=10

# 失敗時も通知する（1=する、0=しない）
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## 互換性

- macOS 13 Ventura 以上
- zsh / bash 対応
- [mterm-tmux](https://github.com/mtermapp/mterm-tmux) プラグインと共存可能
