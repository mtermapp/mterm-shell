# MTerm Mac Plugin

Shell plugin สำหรับเชื่อมต่อ [MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074) กับ Mac ผ่าน SSH

**ฟีเจอร์:**
- แสดงชื่อแท็บและ git branch แบบเรียลไทม์ใน MTerm
- แจ้งเตือนเมื่อคำสั่งที่ใช้เวลานานเสร็จสิ้น (เฉพาะ foreground)
- คงเซสชันด้วย `abduco` — กระบวนการยังทำงานต่อแม้ iPad ตัดการเชื่อมต่อ

---

## ติดตั้ง

```bash
git clone https://github.com/mtermapp/mterm-mac ~/.mterm/plugin
```

เพิ่มใน `~/.zshrc` หรือ `~/.bashrc`:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

โหลด Shell ใหม่:

```bash
source ~/.zshrc
```

---

## การคงเซสชัน (ไม่บังคับ)

ติดตั้ง `abduco` เพื่อให้กระบวนการทำงานต่อหลัง iPad ตัดการเชื่อมต่อ:

```bash
brew install abduco
```

สร้างเซสชัน:

```bash
mterm-session            # ใช้ชื่อไดเรกทอรีปัจจุบัน
mterm-session "claude"   # ระบุชื่อเอง
```

แตะเซสชันที่กำลังทำงานในรายการ MTerm เพื่อเชื่อมต่ออีกครั้ง

---

## การตั้งค่า

```bash
# เกณฑ์การแจ้งเตือน (ค่าเริ่มต้น: 5 วินาที)
export MTERM_NOTIFY_THRESHOLD=10

# แจ้งเตือนเมื่อล้มเหลวด้วย (1=ใช่, 0=ไม่)
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## ความเข้ากันได้

- macOS 13 Ventura ขึ้นไป
- รองรับ zsh / bash
- ใช้งานร่วมกับ [mterm-tmux](https://github.com/mtermapp/mterm-tmux) plugin ได้
