#!/usr/bin/env bash
# 把本目录下的 Thunderbird 定制安装到当前 profile。
# Thunderbird 的 profile 目录名带随机前缀（如 ua8mevxz.default-release），
# 所以不能用 stow，这里现场解析出来再软链接。
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES="$HOME/Library/Thunderbird/Profiles"

profile="$(ls -d "$PROFILES"/*.default-release 2>/dev/null | head -1)"
if [[ -z "${profile:-}" ]]; then
    echo "找不到 Thunderbird profile（$PROFILES 下没有 *.default-release）" >&2
    exit 1
fi
echo "profile: $profile"

if pgrep -x thunderbird >/dev/null; then
    echo "Thunderbird 正在运行，请先退出再执行。" >&2
    exit 1
fi

# 1) 界面样式（userChrome/userContent）
mkdir -p "$profile/chrome"
for f in userChrome.css userContent.css; do
    ln -sfn "$SRC/chrome/$f" "$profile/chrome/$f"
    echo "  linked chrome/$f"
done

# 2) 自写插件：打包成 xpi 放进 extensions/
addon_id="initial-avatars@sanquine.local"
mkdir -p "$profile/extensions"
( cd "$SRC/extensions/initial-avatars" && zip -qr "$profile/extensions/$addon_id.xpi" \
    manifest.json background.js api/ )
echo "  installed $addon_id.xpi"

cat <<'EOF'

完成。启动 Thunderbird 后还需要两步（Thunderbird 不允许脚本代劳）：
  1. 设置 → 常规 → 配置编辑器，确认
     toolkit.legacyUserProfileCustomizations.stylesheets = true
  2. 附加组件管理器里启用 "Initial Avatars"
     （旁加载的插件首次需要手动启用一次）
EOF
