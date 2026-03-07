# MTerm Mac 플러그인

[MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074)과 Mac을 SSH로 연동하는 셸 플러그인.

**기능:**
- 탭 이름 & git 브랜치를 MTerm에 실시간 표시
- 오래 걸리는 명령어 완료 알림 (포그라운드 전용)
- `abduco`를 통한 세션 유지 — iPad를 닫아도 프로세스 유지

---

## 설치

```bash
git clone https://github.com/mtermapp/mterm-shell ~/.mterm/plugin
```

`~/.zshrc` 또는 `~/.bashrc`에 추가:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

셸 재로드:

```bash
source ~/.zshrc
```

---

## 세션 유지 (선택사항)

iPad를 닫아도 프로세스를 유지하려면 `abduco` 설치:

```bash
brew install abduco
```

세션 생성:

```bash
mterm-session            # 현재 디렉토리 이름 사용
mterm-session "claude"   # 이름 지정
```

MTerm 세션 목록에서 실행 중인 세션을 탭하여 재접속.

---

## 설정

```bash
# 알림 기준 시간 (기본값: 5초)
export MTERM_NOTIFY_THRESHOLD=10

# 실패 시에도 알림 (1=예, 0=아니요)
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## 호환성

- macOS 13 Ventura 이상
- zsh / bash 지원
- [mterm-tmux](https://github.com/mtermapp/mterm-tmux) 플러그인과 함께 사용 가능
