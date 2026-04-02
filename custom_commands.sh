#!/bin/bash
# Sourced from ~/.bash_profile && ~/.bashrc

dotfiles_dir="${HOME}/git/bash-config"

alias python='python3'

alias sudo='sudo ' # Enable aliases to be sudo'd
alias d='custom_command "Desktop"; command cd "${HOME}/Desktop"'
alias p='custom_command "projects"; command cd "${HOME}/projects" && ls'
alias dl='custom_command "Downloads"; command cd "${HOME}/Downloads"'
alias tc='custom_command "bash-config"; command code "${dotfiles_dir}"'
alias TC='tc'


function custom_command() {
    # Display a header for custom commands in terminal output, but not in redirects, pipes, or nesting
    if [ -t 1 ]; then
        if [ ${#FUNCNAME[@]} -lt 3 ]; then
            echo -e "\033[95m>\033[0m custom command \033[95m$1\033[0m"
        fi
    fi
}


function sb() {
    custom_command "[temporary] Sandbox"
    local usage="Usage: sb [-n <name>|-c|--clean|-d|--dir|-f|--file <filename>|-h|--help]\n  Creates a temporary sandbox directory and \`cd\`s into it.\n  Generates a random two-word directory name by default unless an overriding name is provided.\n\nOptions:\n  -n, --name     Enter your own sandbox name instead of a random one\n  -c, --clean    Clean up unused sandbox directories (interactive, no deletion without confirmation)\n  -d, --dir      Navigate to sandbox parent directory\n  -f, --file     Create and open a file in the sandbox\n  -h, --help     Show this help message"

    local filename=""
    local sandbox_file=""
    local dirpath="${TMPDIR:-/tmp}sandbox"
    local custom_name=false

    if [ ! -d "${dirpath}" ]; then
        mkdir "${dirpath}"
    fi

    function pseudorandom_word() {
        local words_file="${dotfiles_dir}/alias_support/wordlists/wordlist.txt"
        awk -v seed=${RANDOM} 'BEGIN {srand(seed);} {lines[NR] = $0} END {print lines[int(NR * rand()) + 1]}' "${words_file}"
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dir)
                if [ ! -d "${dirpath}" ]; then
                    echo "Sandbox directory does not exist. Creating ${dirpath}..."
                    mkdir -p "${dirpath}"
                fi
                cd "${dirpath}" || return 1
                return 0
                ;;
            -n|--name)
                if [ -z "$2" ]; then
                    echo "Error: No name provided after -n|--name flag"
                    echo -e "${usage}"
                    return 1
                fi
                filename="$2"
                custom_name=true
                shift 2
                ;;
            -f|--file)
                if [ -z "$2" ]; then
                    echo "Error: No filename provided after -f|--file flag"
                    echo -e "${usage}"
                    return 1
                fi
                sandbox_file="$2"
                shift 2
                ;;
            -h|--help)
                echo -e "${usage}"
                return 0
                ;;
            -c|--clean)
                local sandbox_dir="${TMPDIR:-/tmp}sandbox"

                if [ ! -d "${sandbox_dir}" ]; then
                    echo "Sandbox directory not found"
                    return 1
                fi

                declare -a unused_dirs=()
                local ignored_files=("wordlist.txt" "README.md" ".gitignore" "scratchpad.txt" ".sbconfig" ".cursorrules" ".cursorignore")

                echo "Scanning sandbox directories..."
                for dir in "${sandbox_dir}"/*; do
                    if [ -d "${dir}" ]; then
                        local dir_name
                        dir_name=$(basename "${dir}")

                        local find_cmd="find \"${dir}\" -type f"
                        for ignored in "${ignored_files[@]}"; do
                            find_cmd+=" -not -name \"${ignored}\""
                        done
                        find_cmd+=" -not -name \".*\""

                        local other_files
                        other_files=$(eval "${find_cmd}" | wc -l | tr -d ' ')

                        if [ "${other_files}" -gt 0 ]; then
                            echo -e "\033[32m${dir_name}\033[0m (in use)"
                        else
                            echo -e "\033[31m${dir_name}\033[0m (unused)"
                            unused_dirs+=("${dir}")
                        fi
                    fi
                done

                if [ ${#unused_dirs[@]} -gt 0 ]; then
                    echo -e "\nFound ${#unused_dirs[@]} unused sandbox directories."
                    read -r -p "Do you want to remove these directories? [y/N] " response

                    case "${response}" in
                        [yY][eE][sS]|[yY])
                            for dir in "${unused_dirs[@]}"; do
                                rm -rf "${dir}"
                                echo "Removed: $(basename "${dir}")"
                            done
                            echo "Cleanup complete."
                            ;;
                        *)
                            echo "Cleanup cancelled."
                            ;;
                    esac
                else
                    echo "No unused sandbox directories found."
                fi
                return 0
                ;;
            *)
                echo "Error: Unknown option $1"
                echo -e "${usage}"
                return 1
                ;;
        esac
    done

    # Generate random name if none provided
    if [ -z "${filename}" ]; then
        local word1 word2
        word1=$(pseudorandom_word)
        word2=$(pseudorandom_word)
        filename="${word1}-${word2}"
    fi

    echo "Creating sandbox directory: ${filename}..."
    local temp_dir
    temp_dir=$(mktemp -d "${dirpath}/${filename}.XXXXXX")
    cd "${temp_dir}" || return 1

    local actual_dir_name
    actual_dir_name=$(basename "${temp_dir}")

    # Write .sbconfig metadata
    {
        echo "# Sandbox Configuration"
        echo "original_name=${actual_dir_name}"
        echo "custom_name=${custom_name}"
        echo "project_identifier=${filename}-$(pseudorandom_word)"
        echo "sandbox_id=$(echo "${filename}-$(date +%s)-${RANDOM}" | shasum -a 256 | cut -d ' ' -f1)"
        echo "created_at=$(date +%Y-%m-%d\ %H:%M:%S)"
    } > ".sbconfig"

    cp "${dotfiles_dir}/templates/.cursorrules" .
    cp "${dotfiles_dir}/templates/.cursorignore" .

    echo "creating scratchpad..."
    touch "${temp_dir}/scratchpad.txt"
    echo "ready."
    code -n "${temp_dir}" && code -g "${temp_dir}/scratchpad.txt"

    if [ -n "${sandbox_file}" ]; then
        touch "${temp_dir}/${sandbox_file}"
        code "${temp_dir}/${sandbox_file}"
    fi
}

alias SB='sb'


function harden() {
    custom_command "harden - sandbox to project"
    local dir=""
    local new_name=""
    local open_in_cursor=false
    local projects_dir="${HOME}/projects"
    local usage="Usage: harden [-h] [-o] [directory]
    Move a sandbox directory to the projects folder.

    Options:
        -h    Show this help message
        -o    Open the hardened project in Cursor
        directory    Optional: specify directory to harden (defaults to current directory)"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "${usage}"
                return 0
                ;;
            -o|--open)
                open_in_cursor=true
                shift
                ;;
            *)
                if [ -z "${dir}" ]; then
                    dir="$1"
                else
                    echo "Error: Too many arguments"
                    echo "${usage}"
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "${dir}" ]; then
        dir=$(pwd)
    fi

    local sbconfig_file="${dir}/.sbconfig"

    if [ ! -f "${sbconfig_file}" ]; then
        echo "Warning: This is not a sandbox directory (no .sbconfig file found)"
        read -r -p "Do you want to move this directory to projects anyway? (y/n): " confirm
        if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled"
            return 1
        fi
    else
        local original_name was_custom_name current_dir_name
        original_name=$(grep "^original_name=" "${sbconfig_file}" | cut -d'=' -f2)
        was_custom_name=$(grep "^custom_name=" "${sbconfig_file}" | cut -d'=' -f2)
        current_dir_name=$(basename "${dir}")

        if [ "${was_custom_name}" = "true" ]; then
            new_name="${current_dir_name}"
        elif [ -n "${original_name}" ] && [ "${original_name}" != "${current_dir_name}" ]; then
            new_name="${current_dir_name}"
        else
            echo "This sandbox has a randomly-generated name: ${current_dir_name}"
            read -r -p "Enter a meaningful project name (or press Enter to keep current): " new_name
            if [ -z "${new_name}" ]; then
                new_name="${current_dir_name}"
            fi
        fi
    fi

    local dir_name dest_name
    dir_name=$(basename "${dir}")
    mkdir -p "${projects_dir}"

    if [ -n "${new_name}" ]; then
        dest_name="${new_name}"
    else
        dest_name="${dir_name}"
    fi

    mv "${dir}" "${projects_dir}/${dest_name}"
    echo "Moved sandbox to ${projects_dir}/${dest_name}"

    if [[ "${open_in_cursor}" == true ]]; then
        code "${projects_dir}/${dest_name}"
    fi
}


function gld() {
    custom_command "gld - Get Last Download"
    # Move the newest file/directory from Downloads to the current directory.
    # Optional first argument: new name for the destination (extension preserved for files).
    local downloads_dir="${HOME}/Downloads/"

    local newest_item
    newest_item=$(find "${downloads_dir}" -mindepth 1 -maxdepth 1 -print0 \
        | xargs -0 stat -f "%m:%N" \
        | sort -nr \
        | head -n1 \
        | cut -d: -f2-)

    if [ -z "${newest_item}" ]; then
        echo "Error: Could not find any items in the Downloads directory."
        return 1
    fi

    echo "Newest item in Downloads: ${newest_item}"

    local filename
    filename=$(basename "${newest_item}")

    if [ -d "${newest_item}" ]; then
        local destination_name
        if [ -z "$1" ]; then
            destination_name="${filename}"
        else
            destination_name="$1"
        fi
        mv "${newest_item}" "./${destination_name}" && \
            echo "Moved download directory '${filename}' to './${destination_name}'"
    else
        local extension destination_name
        extension="${filename##*.}"
        if [ -z "$1" ]; then
            destination_name="${filename}"
        else
            destination_name="$1.${extension}"
        fi
        mv "${newest_item}" "./${destination_name}" && \
            echo "Moved download file '${filename}' to './${destination_name}'"
    fi
}


function rr() {
    custom_command "rr - refresh/rerun"
    # Source bash files to get any changes, then rerun a command from history.

    local help_msg="Usage: rr [search_string]

Refresh bash config and rerun a command from history.

Options:
    (no args)       Rerun the last command (excluding rr/src)
    <search_string> Search history for a command containing the string,
                    then prompt for confirmation before running
    -h, --help      Show this help message

Examples:
    rr              # Rerun last command
    rr git          # Find and rerun most recent command containing 'git'"

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "${help_msg}"
        return 0
    fi

    if [[ $# -gt 1 ]]; then
        echo "Error: Too many arguments. Only one search string is allowed."
        echo ""
        echo "${help_msg}"
        return 1
    fi

    local last_cmd

    if [[ $# -eq 1 ]]; then
        local search_term="$1"

        local filtered_history
        filtered_history=$(history | awk '{$1=""; print $0}' | grep -vE '^ *(rr|src)($| )')

        last_cmd=$(echo "${filtered_history}" | grep -F "${search_term}" | tail -n 1)

        if [[ -z "${last_cmd}" ]]; then
            echo "No command found in history containing '${search_term}'"
            return 1
        fi

        local total_cmds match_line_num cmds_ago
        total_cmds=$(echo "${filtered_history}" | wc -l | tr -d ' ')
        match_line_num=$(echo "${filtered_history}" | grep -nF "${search_term}" | tail -n 1 | cut -d: -f1)
        cmds_ago=$((total_cmds - match_line_num))

        last_cmd=$(echo "${last_cmd}" | sed 's/^[[:space:]]*//')

        echo -e "Found command (${cmds_ago} commands ago):\n\$\033[32m${last_cmd}\033[0m"
        read -r -p "Run this command? (y/n): " confirm

        if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
            echo "Cancelled."
            return 0
        fi
    else
        last_cmd=$(history | awk '{$1=""; print $0}' | grep -vE '^ *(rr|src)($| )' | tail -n 1)
        last_cmd=$(echo "${last_cmd}" | sed 's/^[[:space:]]*//')
    fi

    src

    echo -e "re-running...\n\$\033[32m${last_cmd}\033[0m"
    eval "${last_cmd}"
}


function src() {
    custom_command "src"
    # Source shell config files to pick up any changes
    source "${HOME}/.bashrc"
    source "${HOME}/.bash_profile"
}
