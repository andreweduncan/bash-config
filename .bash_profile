#!/bin/bash

BASH_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Homebrew Python first for unversioned python/pip symlinks, then Homebrew, then system paths
export PATH=\
/opt/homebrew/opt/python@3.14/libexec/bin:\
/opt/homebrew/bin:\
/usr/local/bin:\
/System/Cryptexes/App/usr/bin:\
/usr/bin:\
/bin:\
/usr/sbin:\
/sbin

# Silence macOS deprecation warning recommending zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

# Case-insensitive globbing
shopt -s nocaseglob

# Append to history file rather than overwriting
shopt -s histappend

# History settings
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth:erasedups

# Save history immediately after each command
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"

# Bash completion (Homebrew)
[ -f /opt/homebrew/etc/bash_completion ] && source /opt/homebrew/etc/bash_completion

# Prompt
if [ -f "${BASH_CONFIG_DIR}/prompt.sh" ]; then
    source "${BASH_CONFIG_DIR}/prompt.sh"
fi

# Custom commands and aliases
if [ -f "${BASH_CONFIG_DIR}/custom_commands.sh" ]; then
    source "${BASH_CONFIG_DIR}/custom_commands.sh"
fi
