# MTerm Mac 插件

通过 SSH 将 [MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074) 与 Mac 连接的 Shell 插件。

**功能:**
- 实时在 MTerm 显示标签名称和 git 分支
- 长时间命令完成通知（仅前台）
- 通过 `abduco` 保持会话 — iPad 断开后进程继续运行

---

## 安装

```bash
git clone https://github.com/mtermapp/mterm-mac ~/.mterm/plugin
```

添加到 `~/.zshrc` 或 `~/.bashrc`:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

重新加载 Shell:

```bash
source ~/.zshrc
```

---

## 会话持久化（可选）

安装 `abduco` 以在 iPad 断开后保持进程运行:

```bash
brew install abduco
```

创建会话:

```bash
mterm-session            # 使用当前目录名
mterm-session "claude"   # 自定义名称
```

从 MTerm 会话列表中点击正在运行的会话重新连接。

---

## 配置

```bash
# 通知阈值（默认: 5秒）
export MTERM_NOTIFY_THRESHOLD=10

# 失败时也通知（1=是，0=否）
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## 兼容性

- macOS 13 Ventura 及以上
- 支持 zsh / bash
- 可与 [mterm-tmux](https://github.com/mtermapp/mterm-tmux) 插件共存
