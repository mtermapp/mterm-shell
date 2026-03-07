# MTerm Mac 外掛程式

透過 SSH 將 [MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074) 與 Mac 連接的 Shell 外掛程式。

**功能:**
- 即時在 MTerm 顯示分頁名稱和 git 分支
- 長時間指令完成通知（僅前景）
- 透過 `abduco` 保持工作階段 — iPad 中斷連線後行程繼續執行

---

## 安裝

```bash
git clone https://github.com/mtermapp/mterm-mac ~/.mterm/plugin
```

新增至 `~/.zshrc` 或 `~/.bashrc`:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

重新載入 Shell:

```bash
source ~/.zshrc
```

---

## 工作階段持久化（選用）

安裝 `abduco` 以在 iPad 中斷連線後保持行程執行:

```bash
brew install abduco
```

建立工作階段:

```bash
mterm-session            # 使用目前目錄名稱
mterm-session "claude"   # 自訂名稱
```

從 MTerm 工作階段清單點擊正在執行的工作階段以重新連線。

---

## 設定

```bash
# 通知閾值（預設: 5秒）
export MTERM_NOTIFY_THRESHOLD=10

# 失敗時也通知（1=是，0=否）
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## 相容性

- macOS 13 Ventura 以上
- 支援 zsh / bash
- 可與 [mterm-tmux](https://github.com/mtermapp/mterm-tmux) 外掛程式共存
