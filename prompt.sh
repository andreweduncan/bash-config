#!/bin/bash
# Terminal prompt configuration.
# Sourced by .bash_profile.

function prompt_git() {
    # Customized terminal prompt that shows git branch and status indicators.
    local s=''
    local branchName=''

    git rev-parse --is-inside-work-tree &>/dev/null || return

    branchName="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || \
        git describe --all --exact-match HEAD 2>/dev/null || \
        git rev-parse --short HEAD 2>/dev/null || \
        echo '(unknown)')"

    local repoUrl
    repoUrl="$(git config --get remote.origin.url)"
    if grep -q 'chromium/src.git' <<< "${repoUrl}"; then
        s+='*'
    else
        # +  uncommitted changes in index
        if ! git diff --quiet --ignore-submodules --cached; then
            s+='+'
        fi
        # !  unstaged changes
        if ! git diff-files --quiet --ignore-submodules --; then
            s+='!'
        fi
        # ?  untracked files
        if [ -n "$(git ls-files --others --exclude-standard)" ]; then
            s+='?'
        fi
        # $  stashed changes
        if git rev-parse --verify refs/stash &>/dev/null; then
            s+='$'
        fi
    fi

    [ -n "${s}" ] && s=" [${s}]"

    echo -e "${1}${branchName}${2}${s}"
}

if tput setaf 1 &>/dev/null; then
    tput sgr0
    bold=$(tput bold)
    reset=$(tput sgr0)
    blue=$(tput setaf 33)
    green=$(tput setaf 64)
    orange=$(tput setaf 166)
    red=$(tput setaf 124)
    violet=$(tput setaf 61)
    white=$(tput setaf 15)
    yellow=$(tput setaf 136)
else
    bold=''
    reset="\e[0m"
    blue="\e[1;34m"
    green="\e[1;32m"
    orange="\e[1;33m"
    red="\e[1;31m"
    violet="\e[1;35m"
    white="\e[1;37m"
    yellow="\e[1;33m"
fi

if [[ "${USER}" == "root" ]]; then
    userStyle="${red}"
else
    userStyle="${orange}"
fi

if [[ "${SSH_TTY}" ]]; then
    hostStyle="${bold}${red}"
else
    hostStyle="${yellow}"
fi

set_prompt() {
    local exit_code=$?
    history -a

    PS1="\[\033]0;\W\007\]"       # window title: working directory base name
    PS1+="\[${bold}\]\n"
    PS1+="\[${userStyle}\]\u"     # username
    PS1+="\[${white}\] at "
    PS1+="\[${hostStyle}\]\h"     # hostname
    PS1+="\[${white}\] in "
    PS1+="\[${green}\]\w"         # full working directory path
    PS1+="$(prompt_git "\[${white}\] on \[${violet}\]" "\[${blue}\]")"
    if [[ ${exit_code} -ne 0 ]]; then
        PS1+="\[${red}\] exit:${exit_code} "
    fi
    PS1+="\n"
    if [[ ${exit_code} -ne 0 ]]; then
        PS1+="\[${red}\]● "
    else
        PS1+="\[${blue}\]● "
    fi
    PS1+="\[${white}\]\$ \[${reset}\]"
}
PROMPT_COMMAND=set_prompt

PS2="\[${yellow}\]→ \[${reset}\]"
export PS2
