#!/usr/bin/env bash
# Symlink the configs in this repo into $HOME. Safe to run any number of times.
#
#   ./link.sh            create/repair links (an existing real file is moved to <name>.bak-<date>)
#   ./link.sh --check    only report; exit 1 if any link is missing or wrong
#   ./link.sh -n         dry run: show what would change
#
# Add a line to LINKS when you add a config to the repo. --check also lists repo files
# that no link covers, so a forgotten one shows up.
# system/ scripts are not linked; run them with sudo (each has setup + rollback).
set -euo pipefail

REPO=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)

# repo path : path under $HOME
LINKS=(
    "zsh/zshrc:.zshrc"
    "aider/model.settings.yml:.aider.model.settings.yml"
    "niri:.config/niri"
    "noctalia:.config/noctalia"
    "ghostty/config:.config/ghostty/config"
    "tmux/tmux.conf:.config/tmux/tmux.conf"
    "starship/starship.toml:.config/starship.toml"
    "fastfetch/config.jsonc:.config/fastfetch/config.jsonc"
    "xdg/mimeapps.list:.config/mimeapps.list"
    "xdg/xdg-terminals.list:.config/xdg-terminals.list"
    "ollama/Modelfile.agent:.config/ollama/Modelfile.agent"
    "ollama/Modelfile.inline:.config/ollama/Modelfile.inline"
    "vectorcode/config.json:.config/vectorcode/config.json"
    "systemd/user/automount.service:.config/systemd/user/automount.service"
    "systemd/user/postgresql.service:.config/systemd/user/postgresql.service"
    "systemd/user/vectorcode-chroma.service:.config/systemd/user/vectorcode-chroma.service"
)

# repo files that are used in place, not linked (the nvim config itself, sudo scripts, ...)
NOT_LINKED=(lua/ init.lua nvim-pack-lock.json system/ ai/ .gitignore .editorconfig link.sh)

mode=install
case ${1:-} in
    --check) mode=check ;;
    -n|--dry-run) mode=dry ;;
    "") ;;
    *) sed -n '2,11p' "$0"; exit 2 ;;
esac

if [[ -t 1 ]]; then G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' D=$'\e[2m' N=$'\e[0m'; else G= Y= R= D= N=; fi
problems=0 changed=0 units=0

status_of() { # $1 source, $2 target
    if [[ -L $2 ]]; then
        if [[ $(readlink -f "$2") == "$(readlink -f "$1")" ]]; then echo ok
        elif [[ -e $2 ]]; then echo wrong
        else echo broken; fi
    elif [[ -e $2 ]]; then echo real
    else echo missing; fi
}

for entry in "${LINKS[@]}"; do
    src="$REPO/${entry%%:*}" rel="${entry#*:}" dst="$HOME/${entry#*:}"
    if [[ ! -e $src ]]; then
        echo "${R}✗ $rel${N}  source missing in repo: ${entry%%:*}"; problems=$((problems + 1)); continue
    fi
    st=$(status_of "$src" "$dst")
    case $st in
        ok)      echo "${G}✓${N} ${D}~/$rel${N}"; continue ;;
        missing) msg="missing" ;;
        broken)  msg="broken link → $(readlink "$dst")" ;;
        wrong)   msg="points elsewhere → $(readlink "$dst")" ;;
        real)    msg="is a real $( [[ -d $dst ]] && echo folder || echo file ), not a link" ;;
    esac
    problems=$((problems + 1))
    echo "${Y}! ~/$rel${N}  $msg"
    [[ $mode == check ]] && continue

    action="link"
    if [[ $st == real ]]; then
        if [[ -f $dst ]] && cmp -s "$src" "$dst"; then
            action="replace identical copy with link"
        else
            bak="$dst.bak-$(date +%Y%m%d-%H%M%S)"
            action="move to ${bak/#$HOME/~}, then link"
        fi
    fi
    echo "    → $action"
    [[ $mode == dry ]] && continue

    mkdir -p "$(dirname "$dst")"
    if [[ $st == real ]]; then
        if [[ ${bak:-} ]]; then mv "$dst" "$bak"; unset bak; else rm -f "$dst"; fi
    fi
    ln -sfn "$src" "$dst"
    changed=$((changed + 1))
    [[ $rel == .config/systemd/user/* ]] && units=1
done

# repo files no link covers
uncovered=()
while IFS= read -r f; do
    for skip in "${NOT_LINKED[@]}"; do [[ $f == "$skip" || $f == "$skip"* && $skip == */ ]] && continue 2; done
    for entry in "${LINKS[@]}"; do
        s=${entry%%:*}; [[ $f == "$s" || $f == "$s/"* ]] && continue 2
    done
    uncovered+=("$f")
done < <(git -C "$REPO" ls-files)
if (( ${#uncovered[@]} )); then
    echo; echo "${Y}Repo files not covered by any link${N} (add to LINKS or NOT_LINKED):"
    printf '    %s\n' "${uncovered[@]}"
fi

(( units )) && systemctl --user daemon-reload && echo "reloaded systemd user units"

echo
case $mode in
    check) (( problems )) && { echo "${R}$problems problem(s)${N} — run ./link.sh to fix"; exit 1; } \
                          || echo "${G}all ${#LINKS[@]} links ok${N}" ;;
    dry)   echo "dry run: $problems link(s) would change" ;;
    *)     echo "${G}done${N}: $changed link(s) created/repaired, $(( ${#LINKS[@]} - problems )) already ok" ;;
esac
