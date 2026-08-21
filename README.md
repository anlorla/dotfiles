# dotfiles

macOS 上的个人配置。整体风格统一为 **Catppuccin Mocha + 黄色强调色**，等宽字体 **Maple Mono NF CN**。

## 用法

大部分包用 [GNU stow](https://www.gnu.org/software/stow/) 软链到 `~`：

```sh
brew install stow
cd ~/dotfiles && stow -t ~ zsh tmux wezterm btop vscode bin
```

移除某个包：`stow -D -t ~ <包名>`

## 包一览

| 包 | 链接到 | 说明 |
|---|---|---|
| `zsh` | `~/.zshrc` | oh-my-zsh；`tizi`/`notizi` 代理开关；`codex` 自动走本地代理 |
| `tmux` | `~/.tmux.conf` | 手写 Catppuccin Mocha 状态栏，未用 TPM |
| `wezterm` | `~/.config/wezterm/wezterm.lua` | 终端 |
| `btop` | `~/.config/btop/` | 含 catppuccin_mocha 主题 |
| `vscode` | `~/Library/Application Support/Code/User/settings.json` | 配色 + LaTeX 工具链 |
| `bin` | `~/.local/bin/` | 自用小工具：`vpn`（管 colima + 校园 VPN 容器） |
| `thunderbird` | 见下 | **不走 stow**，用 `install.sh` |

## Thunderbird

profile 目录名带随机前缀（如 `ua8mevxz.default-release`），stow 无法处理，所以单独装：

```sh
# 先完全退出 Thunderbird
./thunderbird/install.sh
```

内容：

- `chrome/userChrome.css`、`chrome/userContent.css` — 界面配色与字体
- `extensions/initial-avatars/` — 自写插件，邮件列表显示彩色首字母头像。
  纯本地生成、零网络请求（不像 Auto Profile Picture 那样逐个发件人去查
  Gravatar/favicon，既慢又泄露通信对象）。配色取 Catppuccin 十色，
  按发件人邮箱哈希取色，同一个人恒定同色。
- `prefs-applied.js` — 已应用的 prefs 备查。**不直接导入**：`prefs.js` 由
  Thunderbird 自己重写，且含账户状态，不适合版本管理。需要时对照手动设置。

## LaTeX（vscode 包内）

本机是 BasicTeX，**没有 latexmk**，所以不用 LaTeX Workshop 的默认 recipe，
直接调引擎。命令写绝对路径 `/Library/TeX/texbin/*`——GUI 启动的 VSCode
不读 shell profile，PATH 里没有 TeX。

四个 recipe：`pdflatex ×2`、`xelatex ×2`（中文/自定义字体）、
以及两个带 `bibtex` 的（有参考文献时用）。`recipe.default` 设成 `lastUsed`。

自动清理故意**不删** `*.synctex.gz`（双击 PDF 跳回源码要用）和 `*.bbl`（参考文献要用）。
