# NIRUX fish integration. Sourced from the managed block in config.fish.
# History, autosuggestions and completion are fish's built-ins; this file adds
# the NIRU prompt, theme colours and a small distro-aware update helper.

set -g fish_greeting ""
set -g fish_term24bit 1

# NIRUX commands live in the session PATH; keep them available in a plain shell.
if not contains -- $HOME/.local/bin $PATH
    fish_add_path -g $HOME/.local/bin
end

function fish_prompt
    set -l last_status $status
    set -l niru_theme $__fish_config_dir/../nirux/theme/fish.fish
    if test -r $niru_theme
        source $niru_theme
    end

    set -l cwd (prompt_pwd)
    set -l git ''
    if command -sq git
        set git (fish_git_prompt 2>/dev/null)
        set git (string trim -- $git)
    end
    set -l duration ''
    if set -q CMD_DURATION; and test "$CMD_DURATION" -ge 2000
        set duration (printf '%ss' (math "round($CMD_DURATION / 1000)"))
    end

    set_color $NIRU_PROMPT_PRIMARY
    printf '%s' $cwd
    if test -n "$git"
        set_color $NIRU_PROMPT_ACCENT
        printf ' %s' $git
    end
    if test -n "$duration"
        set_color $NIRU_PROMPT_MUTED
        printf ' %s' $duration
    end
    set_color normal
    printf '\n'

    if test $last_status -eq 0
        set_color $NIRU_PROMPT_SUCCESS
    else
        set_color $NIRU_PROMPT_ERROR
    end
    if test (id -u) -eq 0
        printf '# '
    else
        printf '❯ '
    end
    set_color normal
end

# Ctrl+F accepts the current autosuggestion, as in the NIRU dotfiles.
if status is-interactive
    bind \cf accept-autosuggestion 2>/dev/null
end

# Distro-aware update helper; does not shadow the user's own `update`.
if command -sq paru
    function nirux-update --description 'Update system and AUR'
        paru -Syu --skipreview
    end
else if command -sq pacman
    function nirux-update --description 'Update system'
        sudo pacman -Syu
    end
else if command -sq apt
    function nirux-update --description 'Update system'
        sudo apt update; and sudo apt upgrade
    end
else if command -sq xbps-install
    function nirux-update --description 'Update system'
        sudo xbps-install -Su
    end
end
