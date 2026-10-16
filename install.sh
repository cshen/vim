#!/usr/bin/env bash
#
# shellcheck disable=SC2088
# Messages keep a literal "~" on purpose, so paths read the way you type them
# on the command line. The directive sits at the top of the file so it applies
# to all of them.
#
# install.sh - install the cshen/vim configuration
#
# Usage:
#   bash install.sh [options]
#   curl -fL https://raw.githubusercontent.com/cshen/vim/main/install.sh | bash
#   curl -fL https://raw.githubusercontent.com/cshen/vim/main/install.sh | bash -s -- --skip-plugins
#
# Options:
#   --repo URL       clone from URL instead of the default repository
#   --skip-plugins   do not run vim-plug's :PlugInstall
#   --skip-fonts     do not install the bundled fonts
#   -h, --help       show this help
#
# What it does:
#   1. refuses to touch a non-empty ~/.config/vim (that is your call to make)
#   2. clones the repository into ~/.config/vim
#   3. makes sure Vim finds the config (XDG lookup on Vim >= 9.1, ~/.vimrc shim
#      on older builds)
#   4. installs the vim-plug bundles into ~/.local/share/vim/plugged
#   5. copies the bundled fonts into the user font directory
set -eu

DEFAULT_REPO="https://github.com/cshen/vim.git"
CONFIG_DIR="$HOME/.config/vim"
DATA_DIR="$HOME/.local/share/vim"
PLUGGED_DIR="$DATA_DIR/plugged"

REPO_URL="$DEFAULT_REPO"
SKIP_PLUGINS=0
SKIP_FONTS=0

# $CONFIG_DIR as a Vim string literal, for the -c arguments below: those run
# with the config directory on 'runtimepath' no matter which vim build this is.
config_dir_vim=$(printf '%s' "$CONFIG_DIR" | sed "s/'/''/g")

# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
    c_reset=$(printf '\033[0m')
    c_bold=$(printf '\033[1m')
    c_red=$(printf '\033[31m')
    c_green=$(printf '\033[32m')
    c_yellow=$(printf '\033[33m')
    c_blue=$(printf '\033[34m')
else
    c_reset=''; c_bold=''; c_red=''; c_green=''; c_yellow=''; c_blue=''
fi

step()  { printf '%s==>%s %s%s%s\n' "$c_blue" "$c_reset" "$c_bold" "$1" "$c_reset"; }
info()  { printf '    %s\n' "$1"; }
ok()    { printf '    %s%s%s %s\n' "$c_green" "ok" "$c_reset" "$1"; }
warn()  { printf '    %s%s%s %s\n' "$c_yellow" "warn" "$c_reset" "$1" >&2; }
die()   { printf '\n%s%s%s\n' "$c_red" "$1" "$c_reset" >&2; shift || true; for l in "$@"; do printf '       %s\n' "$l" >&2; done; exit 1; }

usage() {
    cat <<'USAGE'
install.sh - install the cshen/vim configuration

Usage:
  bash install.sh [options]
  curl -fL https://raw.githubusercontent.com/cshen/vim/main/install.sh | bash

Options:
  --repo URL       clone from URL instead of the default repository
  --skip-plugins   do not run vim-plug's :PlugInstall
  --skip-fonts     do not install the bundled fonts
  -h, --help       show this help

The installer stops if ~/.config/vim already exists and is not empty.
USAGE
}

# ---------------------------------------------------------------------------
# arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --repo)         [ $# -ge 2 ] || die "--repo needs a URL"; REPO_URL="$2"; shift 2 ;;
        --repo=*)       REPO_URL="${1#--repo=}"; shift ;;
        --skip-plugins) SKIP_PLUGINS=1; shift ;;
        --skip-fonts)   SKIP_FONTS=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *) die "unknown option: $1" "run 'bash install.sh --help' for the list of options" ;;
    esac
done

: "${HOME:?HOME is not set, cannot install}"

# ---------------------------------------------------------------------------
# where are we coming from: a checkout on disk, or a `curl | bash` pipe?
# ---------------------------------------------------------------------------
SOURCE_DIR=""
if [ -n "${BASH_SOURCE:-}" ] && [ -f "${BASH_SOURCE}" ]; then
    SOURCE_DIR=$(cd "$(dirname "${BASH_SOURCE}")" && pwd)
    if [ ! -f "$SOURCE_DIR/vimrc" ] || [ ! -f "$SOURCE_DIR/autoload/plug.vim" ]; then
        SOURCE_DIR=""       # some other script that happens to be on disk
    fi
fi

if [ -n "$SOURCE_DIR" ] && [ "$SOURCE_DIR" = "$CONFIG_DIR" ]; then
    MODE=checkout-in-place
elif [ -n "$SOURCE_DIR" ]; then
    MODE=checkout-elsewhere
else
    MODE=remote
fi

printf '%s\n' "${c_bold}cshen/vim installer${c_reset}"
info "config directory: $CONFIG_DIR"
info "source: $( [ "$MODE" = remote ] && printf '%s' "$REPO_URL" || printf '%s' "$SOURCE_DIR" )"
printf '\n'

# ---------------------------------------------------------------------------
# 1. never stomp on an existing installation
# ---------------------------------------------------------------------------
if [ -d "$CONFIG_DIR" ] && [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
    if [ "$MODE" = checkout-in-place ]; then
        ok "~/.config/vim already holds this checkout, installing in place"
    else
        die "~/.config/vim exists, remove it before u install" \
            "(found: $CONFIG_DIR)" \
            "move it aside:  mv ~/.config/vim ~/.config/vim.bak" \
            "or delete it:   rm -rf ~/.config/vim"
    fi
else
    ok "~/.config/vim is free"
fi

# ---------------------------------------------------------------------------
# 2. get the files into place
# ---------------------------------------------------------------------------
step "Fetching the configuration"
case "$MODE" in
    remote)
        command -v git >/dev/null 2>&1 || die "git is required" "install git (xcode-select --install, or brew install git) and re-run"
        mkdir -p "$(dirname "$CONFIG_DIR")"
        git clone --depth 1 "$REPO_URL" "$CONFIG_DIR" >/dev/null 2>&1 \
            || die "git clone failed: $REPO_URL" "check your network connection and that the URL is reachable"
        ok "cloned $REPO_URL"
        ;;
    checkout-elsewhere)
        mkdir -p "$CONFIG_DIR"
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --exclude '.git/' --exclude '.DS_Store' "$SOURCE_DIR/" "$CONFIG_DIR/"
        else
            cp -R "$SOURCE_DIR/." "$CONFIG_DIR/"
            rm -rf "$CONFIG_DIR/.git"
            rm -f "$CONFIG_DIR/.DS_Store"
        fi
        ok "copied $SOURCE_DIR"
        ;;
    checkout-in-place)
        ok "using $CONFIG_DIR as is"
        ;;
esac

[ -f "$CONFIG_DIR/vimrc" ] || die "$CONFIG_DIR/vimrc is missing" "the installation looks incomplete"
[ -f "$CONFIG_DIR/autoload/plug.vim" ] || die "$CONFIG_DIR/autoload/plug.vim is missing" "the installation looks incomplete"

# ---------------------------------------------------------------------------
# 3. make Vim find the config
# ---------------------------------------------------------------------------
step "Wiring Vim to $CONFIG_DIR"

vim_bin=$(command -v vim || true)

# Feature probe: modern Vim sources $XDG_CONFIG_HOME/vim/vimrc by itself, but
# only when no ~/.vimrc or ~/.vim/vimrc is in the way.
vim_reads_xdg_config() {
    [ -n "$vim_bin" ] || return 1
    probe=$(mktemp -d 2>/dev/null) || return 1
    mkdir -p "$probe/.config/vim"
    printf 'call writefile(["probed"], "%s/marker")\n' "$probe" >"$probe/.config/vim/vimrc"
    HOME="$probe" "$vim_bin" -N -c 'qa!' </dev/null >/dev/null 2>&1 || true
    if [ -f "$probe/marker" ]; then
        rm -rf "$probe"
        return 0
    fi
    rm -rf "$probe"
    return 1
}

if [ -z "$vim_bin" ]; then
    warn "vim is not installed yet, skipping the version check"
    XDG_AWARE=0
elif vim_reads_xdg_config; then
    XDG_AWARE=1
else
    XDG_AWARE=0
fi

if [ "$XDG_AWARE" = 1 ]; then
    if [ -e "$HOME/.vimrc" ] || [ -e "$HOME/.vim/vimrc" ]; then
        warn "~/.vimrc (or ~/.vim/vimrc) exists and wins over $CONFIG_DIR/vimrc"
        warn "remove it, or make it source $CONFIG_DIR/vimrc, otherwise this config stays unused"
    else
        ok "this vim reads \$XDG_CONFIG_HOME/vim/vimrc directly, nothing to link"
    fi
else
    shim_marker="Managed by ~/.config/vim/install.sh"
    if [ -L "$HOME/.vimrc" ] && [ "$(readlink "$HOME/.vimrc")" = "$CONFIG_DIR/vimrc" ]; then
        ok "~/.vimrc already points at $CONFIG_DIR/vimrc"
    elif [ -f "$HOME/.vimrc" ] && grep -qF "$shim_marker" "$HOME/.vimrc" 2>/dev/null; then
        ok "~/.vimrc shim already in place"
    elif [ -e "$HOME/.vimrc" ]; then
        warn "~/.vimrc already exists and was left untouched"
        warn "add these two lines to it so this vim build picks up the config:"
        warn "  set runtimepath^=\$HOME/.config/vim"
        warn "  source \$HOME/.config/vim/vimrc"
    else
        cat >"$HOME/.vimrc" <<EOF
" $shim_marker -- do not edit.
" This vim build does not read \$XDG_CONFIG_HOME/vim/vimrc, so point it at the
" config directory and source the real vimrc.
if !filereadable(expand('\$HOME/.config/vim/vimrc'))
  echoerr '~/.config/vim/vimrc is missing, re-run the installer'
  finish
endif
set runtimepath^=\$HOME/.config/vim
source \$HOME/.config/vim/vimrc
EOF
        ok "wrote ~/.vimrc shim for this older vim"
    fi
fi

mkdir -p "$PLUGGED_DIR" "$DATA_DIR/session"

# ---------------------------------------------------------------------------
# 4. vim-plug bundles
# ---------------------------------------------------------------------------
if [ "$SKIP_PLUGINS" = 1 ]; then
    step "Skipping vim-plug install (--skip-plugins)"
    info "run ':PlugInstall' inside vim when you are ready"
elif [ -z "$vim_bin" ]; then
    step "Skipping vim-plug install (no vim on PATH)"
    info "install vim, then run ':PlugInstall' inside vim"
else
    step "Installing vim-plug bundles"
    info "plugins go to $PLUGGED_DIR, this needs network access and may take a while"
    plug_log=$(mktemp -t vim-plug-install) || plug_log=/dev/null
    plug_missing=$(mktemp -t vim-plug-status) || plug_missing=/dev/null

    # vim exits non-zero in Ex mode even when every bundle landed, so ask
    # vim-plug afterwards which plugin directories are still absent.
    plug_install() {
        "$vim_bin" -N -es --cmd "let &runtimepath = '$config_dir_vim' . ',' . &runtimepath" \
            -u "$CONFIG_DIR/vimrc" -c 'PlugInstall --sync' -c 'qa!' \
            </dev/null >"$plug_log" 2>&1 || true
        "$vim_bin" -N -es --cmd "let &runtimepath = '$config_dir_vim' . ',' . &runtimepath" \
            -u "$CONFIG_DIR/vimrc" \
            -c "call writefile(filter(keys(g:plugs), {_, k -> !isdirectory(g:plugs[k].dir)}), '$plug_missing')" \
            -c 'qa!' </dev/null >/dev/null 2>&1 || true
    }
    plug_install
    if [ -s "$plug_missing" ]; then
        info "some bundles did not land on the first pass, retrying once"
        plug_install
    fi

    if [ ! -s "$plug_missing" ]; then
        ok "all bundles installed"
    else
        warn "$(wc -l <"$plug_missing" | tr -d ' ') bundle(s) are missing:"
        sed 's/^/      /' "$plug_missing" >&2
        warn "start vim and run ':PlugInstall' to retry, it needs network access"
        if [ -s "$plug_log" ]; then
            tail -n 10 "$plug_log" | sed 's/^/      /' >&2
        fi
    fi
    [ "$plug_log" = /dev/null ] || rm -f "$plug_log"
    [ "$plug_missing" = /dev/null ] || rm -f "$plug_missing"
fi

# ---------------------------------------------------------------------------
# 5. fonts
# ---------------------------------------------------------------------------
if [ "$SKIP_FONTS" = 1 ]; then
    step "Skipping fonts (--skip-fonts)"
else
    step "Installing fonts"
    case "$(uname -s)" in
        Darwin) FONT_DIR="$HOME/Library/Fonts" ;;
        Linux)  FONT_DIR="$HOME/.local/share/fonts" ;;
        *)      FONT_DIR="" ;;
    esac
    if [ -z "$FONT_DIR" ]; then
        warn "unknown platform $(uname -s), skipping fonts"
    elif ! ls "$CONFIG_DIR"/fonts/*.ttf >/dev/null 2>&1; then
        warn "no fonts found in $CONFIG_DIR/fonts"
    else
        mkdir -p "$FONT_DIR"
        font_count=0
        for font in "$CONFIG_DIR"/fonts/*.ttf; do
            name=$(basename "$font")
            if [ -f "$FONT_DIR/$name" ] && cmp -s "$font" "$FONT_DIR/$name"; then
                continue
            fi
            cp -f "$font" "$FONT_DIR/$name" || { warn "could not copy $name"; continue; }
            font_count=$((font_count + 1))
        done
        if command -v fc-cache >/dev/null 2>&1; then
            fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
        fi
        ok "$font_count font file(s) installed into $FONT_DIR"
        info "Cascadia Code for the GUI, Caskaydia Cove Nerd Font for the terminal"
    fi
fi

# ---------------------------------------------------------------------------
# done
# ---------------------------------------------------------------------------
printf '\n%s%s installed%s\n' "$c_green" "${c_bold}done:" "$c_reset"
info "config   $CONFIG_DIR"
info "plugins  $PLUGGED_DIR"
info "extras   fonts/, personal overrides go in vimrc.local"
printf '\n'
info "next steps:"
info "  vim                open vim, plugins and theme should be in place"
info "  :PlugUpdate        update the bundles later"
info "  :Copilot setup     sign in to GitHub Copilot (optional)"
info "  git -C ~/.config/vim pull   update the configuration itself"
printf '\n'
