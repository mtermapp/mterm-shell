# MTerm Mac प्लगइन

SSH के माध्यम से [MTerm](https://apps.apple.com/us/app/mterm-ssh-terminal/id6758785074) को Mac से जोड़ने वाला Shell प्लगइन।

**विशेषताएं:**
- MTerm में टैब नाम और git ब्रांच रियल-टाइम में दिखाई देती है
- लंबे चलने वाले कमांड पूरे होने पर सूचना (केवल फोरग्राउंड में)
- `abduco` के जरिए सेशन बनाए रखें — iPad बंद करने पर भी प्रक्रिया चलती रहती है

---

## इंस्टॉल करें

```bash
git clone https://github.com/mtermapp/mterm-shell ~/.mterm/plugin
```

`~/.zshrc` या `~/.bashrc` में जोड़ें:

```bash
[ -f ~/.mterm/plugin/init.sh ] && source ~/.mterm/plugin/init.sh
```

Shell रिलोड करें:

```bash
source ~/.zshrc
```

---

## सेशन बनाए रखें (वैकल्पिक)

iPad डिसकनेक्ट होने पर प्रक्रिया चालू रखने के लिए `abduco` इंस्टॉल करें:

```bash
brew install abduco
```

सेशन बनाएं:

```bash
mterm-session            # मौजूदा डायरेक्टरी नाम का उपयोग करें
mterm-session "claude"   # कस्टम नाम दें
```

MTerm सेशन सूची से चल रहे सेशन पर टैप करके पुनः कनेक्ट करें।

---

## कॉन्फ़िगरेशन

```bash
# सूचना सीमा (डिफ़ॉल्ट: 5 सेकंड)
export MTERM_NOTIFY_THRESHOLD=10

# विफलता पर भी सूचना (1=हां, 0=नहीं)
export MTERM_NOTIFY_ALL_EXITS=1
```

---

## संगतता

- macOS 13 Ventura या उससे ऊपर
- zsh / bash समर्थित
- [mterm-tmux](https://github.com/mtermapp/mterm-tmux) प्लगइन के साथ काम करता है
