# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export EDITOR=nvim

source <(fzf --zsh)

# open vs code

function code {
    if [[ $# = 0 ]]
    then
        open -a "Visual Studio Code"
    else
        local argPath="$1"
        [[ $1 = /* ]] && argPath="$1" || argPath="$PWD/${1#./}"
        open -a "Visual Studio Code" "$argPath"
    fi
}





function ya() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
# python path


alias py="python3"

alias g++="g++ -std=c++17"

alias ls="lsd -l"


alias dsig='touch .gitignore && echo -e ".DS_Store\n**/.DS_Store\n.DS_Store?" > .gitignore' 

alias ta='tmux attach'

eval $(thefuck --alias)

PROMPT='${ret_status} %{$fg[cyan]%}[%~]%{$reset_color%} $(git_prompt_info)'


# echo -e "( '-')ノ(._. )"


alias cat="bat"

# === Xray proxy shortcut (tizi) — added 2026-06-02 ===
# `tizi`  : start xray (~/.config/xray/config.json) and route this shell through local HTTP proxy :8080
# `notizi`: unset proxy env in this shell and stop xray
tizi() {
    local cfg="$HOME/.config/xray/config.json"
    local proxy_url="http://127.0.0.1:8080"
    if ! pgrep -f "xray run" >/dev/null 2>&1; then
        nohup xray run -c "$cfg" >/tmp/tizi-xray.log 2>&1 &
        sleep 2
    fi
    export all_proxy="$proxy_url" http_proxy="$proxy_url" https_proxy="$proxy_url"
    echo "Proxy enabled: $proxy_url"
    echo -n "Current IP: "; curl -s -m 8 https://ipinfo.io; echo
}
notizi() {
    unset all_proxy http_proxy https_proxy
    pkill -f "xray run" 2>/dev/null
    echo "Proxy disabled"
}

# Claude Code & user binaries on PATH (added 2026-06-02)
export PATH="$HOME/.local/bin:$PATH"

# === newproj: 快速新建科研课题骨架 (added 2026-06-02) ===
# 用法: newproj <课题名>   →  在 ~/research/projects/<课题名> 下建 code/data/results/writing + README 并进入
newproj() {
    if [[ -z "$1" ]]; then
        echo "用法: newproj <课题名>   (全小写、用连字符,如 vla-tactile)"
        return 1
    fi
    local base="$HOME/research/projects/$1"
    if [[ -e "$base" ]]; then
        echo "已存在: $base"
        return 1
    fi
    mkdir -p "$base"/{code,data,results,writing}
    {
        echo "# $1"
        echo
        echo "## 简介"
        echo
        echo "## 怎么跑"
        echo
        echo "## 进度"
        echo "- $(date +%Y-%m-%d) 创建"
    } > "$base/README.md"
    echo "已创建课题: $base  (code/ data/ results/ writing/ + README.md)"
    cd "$base"
}

# === codex 自动走本地代理（xray 已由 launchd 常驻：com.sanquine.xray）— added 2026-08-18 ===
codex() {
    local p="http://127.0.0.1:8080"
    all_proxy="$p" http_proxy="$p" https_proxy="$p" command codex "$@"
}
