local wezterm = require("wezterm")
local act = wezterm.action

local config = {
    font_size = 14,
    font = wezterm.font("Maple Mono NF CN"),
    color_scheme = "Catppuccin Mocha",
    -- 覆盖选中色:Claude Code 等终端程序里的选中高亮由 WezTerm 渲染,统一成暖黄底深字
    colors = {
        selection_bg = "#f9e2af",
        selection_fg = "#1e1e2e",
    },

    use_fancy_tab_bar = true,
    hide_tab_bar_if_only_one_tab = true,
    default_cursor_style = 'BlinkingBlock',
    animation_fps = 10,

    -- 键盘选 URL(tmux 里鼠标被占用也能用):Cmd+Shift+U 给屏幕上所有链接打字母标签,
    -- 敲标签即用默认浏览器打开;不影响 tmux 的鼠标点击/滚屏。
    keys = {
        {
            key = "u",
            mods = "CMD|SHIFT",
            action = act.QuickSelectArgs({
                label = "open url",
                patterns = { "https?://\\S+" },
                action = wezterm.action_callback(function(window, pane)
                    local url = window:get_selection_text_for_pane(pane)
                    if url and url ~= "" then
                        wezterm.open_with(url)
                    end
                end),
            }),
        },
    },
}

return config
