# MTerm Mac Plugin

Shell plugin kết nối [MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074) với Mac qua SSH.

**Tính năng:**
- Hiển thị tên tab và git branch theo thời gian thực trong MTerm
- Thông báo khi lệnh chạy lâu hoàn thành (chỉ khi ở foreground)
- Duy trì phiên làm việc bằng `abduco` — tiến trình tiếp tục chạy khi iPad ngắt kết nối

---

## Cài đặt

```bash
git clone https://github.com/mtermapp/mterm-mac ~/.mterm/plugin
```

Thêm vào `~/.zshrc` hoặc `~/.bashrc`:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

Tải lại Shell:

```bash
source ~/.zshrc
```

---

## Duy trì phiên làm việc (tùy chọn)

Cài đặt `abduco` để tiến trình tiếp tục chạy sau khi iPad ngắt kết nối:

```bash
brew install abduco
```

Tạo phiên làm việc:

```bash
mterm-session            # dùng tên thư mục hiện tại
mterm-session "claude"   # đặt tên tùy chỉnh
```

Nhấn vào phiên đang chạy trong danh sách MTerm để kết nối lại.

---

## Cấu hình

```bash
# Ngưỡng thông báo (mặc định: 5 giây)
export MTERM_NOTIFY_THRESHOLD=10

# Thông báo cả khi thất bại (1=có, 0=không)
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## Tương thích

- macOS 13 Ventura trở lên
- Hỗ trợ zsh / bash
- Dùng được cùng với plugin [mterm-tmux](https://github.com/mtermapp/mterm-tmux)
