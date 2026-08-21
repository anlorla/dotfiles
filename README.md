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
| `bin` | `~/.local/bin/` | `vpn` 管校园 VPN；`codex` 锁定走 xray；`netcheck` 查各路径出口 |
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

## 两套代理的分工（别串）

| 用途 | 工具 | 端口 | 出口 |
|---|---|---|---|
| codex / claude | xray（launchd 常驻 `com.sanquine.xray`） | 1080 / 8080 | 美国，固定 |
| 学校 VPN 容器、日常浏览 | Clash Verge | 7897 | 可切，当前香港 |

codex 和 claude 的出口必须**始终是同一个美国 IP**（账号绑定），所以钉了两层：

- `~/.local/bin/codex` 包装脚本显式注入 `http_proxy` 指向 xray。写成脚本而非
  `.zshrc` 函数，是因为函数只在交互式 zsh 里存在，从 VSCode 启动就失效；
  `~/.local/bin` 在 PATH 最前，脚本能盖住 brew 的 codex。
- `~/.claude/settings.json` 的 `env` 段设 `HTTPS_PROXY`，Claude Code 无论
  怎么启动都读得到。

两处都是**显式指定代理**，所以 xray 挂了就直接失败，而不会悄悄改走 Clash 的
香港出口——出口 IP 突变比连不上更麻烦。

随时用 `netcheck` 核对：codex/claude 那一行不是 US 就说明串了。
⚠️ 如果 Clash Verge 打开 TUN 模式，它会在网卡层接管所有流量（xray 自己的连接
也会被套进去），`netcheck` 会对此告警。

## 校园 VPN（colima + EasyConnect 容器）

```sh
vpn start     # 起 colima，容器会跟着起（restart=unless-stopped）
vpn login     # 打开 VNC，在里面登录 EasyConnect
vpn status    # 看 colima / 容器 / 隧道三层
vpn stop      # 全停，省电
```

隧道状态看的是容器里有没有 `tun` 网卡，而不是容器是否 Up——EasyConnect
没登录时容器照样 Up，只看容器会误判成正常。

**两个踩过的坑**（都写进 `create_container` 了，别手写 docker run）：

1. EasyConnect 直连学校网关不稳定（colima 用户态网络的问题，选线路 15 秒
   超时就报 Path selection failed），所以让它借道 Clash Verge：
   `http_proxy=http://192.168.5.2:7897`，`192.168.5.2` 是容器眼里的宿主机。
2. 必须同时设 `no_proxy=127.0.0.1,localhost`。EasyConnect 界面要访问容器内
   `127.0.0.1:54530` 找本地 agent，漏了这条就会连本地请求也走代理然后全部
   失败，界面报 **local env error**。

改了参数用 `vpn recreate`，登录配置在 `~/.ecdata`，重建不丢。
