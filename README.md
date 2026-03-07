# MTerm Mac Plugin

Shell plugin for Mac that connects [MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074) with your Mac over SSH.

**Features:**
- Tab name & git branch shown in real-time in MTerm
- Completion notifications for long-running commands (foreground only)
- Session persistence via `abduco` — keep processes alive when iPad disconnects

[日本語](README.ja.md) | [한국어](README.ko.md) | [简体中文](README.zh-Hans.md) | [繁體中文](README.zh-Hant.md) | [हिन्दी](README.hi.md) | [ภาษาไทย](README.th.md) | [Tiếng Việt](README.vi.md)

---

## Install

```bash
git clone https://github.com/mtermapp/mterm-mac ~/.mterm/plugin
```

Add to `~/.zshrc` or `~/.bashrc`:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

Reload your shell:

```bash
source ~/.zshrc
```

---

## Session Persistence (optional)

Install `abduco` to keep processes running after iPad disconnects:

```bash
brew install abduco
```

Create a persistent session:

```bash
mterm-session            # uses current directory name
mterm-session "claude"   # custom name
```

Reconnect from MTerm → the session list shows your running sessions → tap to reattach.

---

## Configuration

```bash
# Notification threshold (default: 5 seconds)
export MTERM_NOTIFY_THRESHOLD=10

# Notify on failure too (1 = yes, 0 = no)
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## Compatibility

- macOS 13 Ventura+
- zsh / bash
- Works alongside [mterm-tmux](https://github.com/mtermapp/mterm-tmux) plugin
