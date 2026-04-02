#!/bin/bash
# bash-config setup script
# Installs dependencies and wires up dotfiles.
# Safe to run multiple times (idempotent).

set -e

BASH_CONFIG_DIR="${HOME}/git/bash-config"
BASHRC_SOURCE_LINE="[ -f \"${BASH_CONFIG_DIR}/.bashrc\" ] && source \"${BASH_CONFIG_DIR}/.bashrc\""
BASH_PROFILE_SOURCE_LINE="[ -f \"${BASH_CONFIG_DIR}/.bash_profile\" ] && source \"${BASH_CONFIG_DIR}/.bash_profile\""

# ── Shell ──────────────────────────────────────────────────────────────────────

current_shell=$(echo "${SHELL}")
echo "Current shell: ${current_shell}"

if [ "${current_shell}" != "/bin/bash" ]; then
    echo "Changing default shell to bash..."
    chsh -s /bin/bash
    echo "✅ Default shell changed to bash (restart your terminal)"
else
    echo "✅ Already using bash"
fi

# ── Homebrew ───────────────────────────────────────────────────────────────────

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for the remainder of this script (Apple Silicon path)
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo "✅ Homebrew installed"
else
    echo "✅ Homebrew already installed"
fi

# ── Helper ─────────────────────────────────────────────────────────────────────

function install_brew_package() {
    local package="$1"
    local check_cmd="${2:-${package}}"  # command to check; defaults to package name
    if ! command -v "${check_cmd}" &>/dev/null; then
        echo "Installing ${package}..."
        brew install "${package}"
        echo "✅ ${package} installed"
    else
        echo "✅ ${package} already installed"
    fi
}

function install_brew_cask() {
    local cask="$1"
    local app_path="$2"
    if [ ! -d "${app_path}" ]; then
        echo "Installing ${cask}..."
        brew install --cask "${cask}"
        echo "✅ ${cask} installed"
    else
        echo "✅ ${cask} already installed"
    fi
}

# ── Tools ──────────────────────────────────────────────────────────────────────

install_brew_package "git"
install_brew_package "gh"
install_brew_package "python" "python3"
install_brew_package "duckdb"
install_brew_package "fzf"
install_brew_package "jq"
install_brew_package "ripgrep" "rg"

install_brew_cask "google-chrome" "/Applications/Google Chrome.app"
install_brew_cask "visual-studio-code" "/Applications/Visual Studio Code.app"

# ── Dotfiles ───────────────────────────────────────────────────────────────────

function add_source_line() {
    local file="$1"
    local source_line="$2"
    local backup_file="${file}.bak"

    # Touch the file if it doesn't exist yet
    touch "${file}"

    if [ -f "${file}" ] && [ ! -f "${backup_file}" ]; then
        cp "${file}" "${backup_file}"
        echo "Created backup: ${backup_file}"
    fi

    if grep -Fxq "${source_line}" "${file}" 2>/dev/null; then
        echo "Source line already present in ${file}"
        return 0
    fi

    echo -e "\n# Source bash-config\n${source_line}" >> "${file}"
    echo "Added source line to ${file}"
}

add_source_line "${HOME}/.bashrc" "${BASHRC_SOURCE_LINE}"
add_source_line "${HOME}/.bash_profile" "${BASH_PROFILE_SOURCE_LINE}"

# ──────────────────────────────────────────────────────────────────────────────

echo ""
echo "Setup complete! Restart your terminal or run: source ~/.bash_profile"
