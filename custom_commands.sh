#!/bin/bash
# Sourced from ~/.bash_profile && ~/.bashrc

dotfiles_dir="${BASH_CONFIG_DIR}"

# Command history with exit-code logging (see `hist -h`)
# shellcheck source=scripts/history/hist.sh
source "${dotfiles_dir}/scripts/history/hist.sh"

alias python='python3'

alias sudo='sudo ' # Enable aliases to be sudo'd
alias d='custom_command "Desktop"; command cd "${HOME}/Desktop"'
alias p='custom_command "projects"; command cd "${HOME}/projects" && ls'
alias dl='custom_command "Downloads"; command cd "${HOME}/Downloads"'
alias ..='custom_command ".."; command cd ..'
alias ...='custom_command "..."; command cd ../..'
alias ....='custom_command "...."; command cd ../../..'
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

    # Generate random name if none provided, retrying on collision
    if [ -z "${filename}" ]; then
        while true; do
            local word1 word2
            word1=$(pseudorandom_word)
            word2=$(pseudorandom_word)
            filename="${word1}-${word2}"
            [ ! -d "${dirpath}/${filename}" ] && break
        done
    fi

    echo "Creating sandbox directory: ${filename}..."
    local temp_dir="${dirpath}/${filename}"
    mkdir -p "${temp_dir}"
    cd "${temp_dir}" || return 1

    # Write .sbconfig metadata
    {
        echo "# Sandbox Configuration"
        echo "original_name=${filename}"
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

    # Source the config, then come back: src may move into a worktree
    local rerun_dir="${PWD}"
    # rr's search string isn't meant for src
    # shellcheck disable=SC2119
    src
    builtin cd "${rerun_dir}" || return

    echo -e "re-running...\n\$\033[32m${last_cmd}\033[0m"
    eval "${last_cmd}"
}


function _src_candidates() {
    # For src: print a line for each checkout or branch holding work that <base>
    # doesn't have (commits ahead of it, or uncommitted changes), tab-separated:
    #   <time> <worktree|branch> <path or branch> <label>
    # <time> is the newest commit's, or the newest changed file's if that's later.
    local base="$1"
    local line path="" head="" label="" checked_out="" ahead time newest

    # Worktrees, including the main checkout. Each is a block of lines ending in a
    # blank line; the extra echo makes sure the last block ends too.
    while IFS= read -r line; do
        case "${line}" in
            "worktree "*) path="${line#worktree }" ;;
            "HEAD "*) head="${line#HEAD }"; label="detached at ${head:0:7}" ;;
            "branch "*)
                label="${line#branch refs/heads/}"
                checked_out="${checked_out}${label}"$'\n'
                ;;
            "")
                if [[ -n "${head}" && -d "${path}" ]]; then
                    time=0
                    ahead=$(git rev-list --count "${base}..${head}")
                    if [[ "${ahead}" -gt 0 ]]; then
                        time=$(git log -1 --format=%ct "${head}")
                    fi
                    # Changed and new files (deleted ones have no time to read)
                    newest=$(builtin cd "${path}" && \
                        { git diff --name-only HEAD; git ls-files --others --exclude-standard; } | \
                        while IFS= read -r file; do
                            [[ -e "${file}" ]] && stat -f %m "${file}"
                        done | sort -n | tail -n 1)
                    if [[ -n "${newest}" && "${newest}" -gt "${time}" ]]; then
                        time="${newest}"
                    fi
                    if [[ "${time}" -gt 0 ]]; then
                        printf '%s\t%s\t%s\t%s\n' "${time}" worktree "${path}" "${label}"
                    fi
                fi
                path=""
                head=""
                label=""
                ;;
        esac
    done < <(git worktree list --porcelain; echo)

    # Branches not checked out anywhere (those were counted above, with their changes)
    local branch
    while IFS=$'\t' read -r branch time; do
        [[ "${branch}" = "${base}" ]] && continue
        printf '%s' "${checked_out}" | grep -qxF -e "${branch}" && continue
        ahead=$(git rev-list --count "${base}..${branch}")
        if [[ "${ahead}" -gt 0 ]]; then
            printf '%s\t%s\t%s\t%s\n' "${time}" branch "${branch}" "${branch}"
        fi
    done < <(git for-each-ref --format='%(refname:short)%09%(committerdate:unix)' refs/heads)
}


# Options come from the command line; rr calls src without any
# shellcheck disable=SC2120
function src() {
    # Source shell config files to pick up any changes
    local usage="Usage: src [-n] [-q]
  Reloads the shell config to pick up changes.

  Run inside the config's own repo, it loads the newest work there instead: the
  checkout (the main one or a worktree) or branch with the most recent change that
  main doesn't have, committed or not. It moves the terminal there first: into that
  worktree, or onto that branch with git switch. With nothing newer than main, or
  outside the repo, it reloads the usual config.

Options:
  -n, --no-switch   Reload the usual config, without looking for newer work
  -q, --quiet       Print nothing, except errors
  -h, --help        Show this help"

    local look=true
    local quiet=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--no-switch) look=false ;;
            -q|--quiet) quiet=true ;;
            -h|--help)
                echo "${usage}"
                return 0
                ;;
            *)
                echo "Error: Unknown option '$1'" >&2
                echo "${usage}" >&2
                return 2
                ;;
        esac
        shift
    done

    # Quiet hides everything src and the config files print; errors still show
    if [[ "${quiet}" = true ]]; then
        _src_load "${look}" >/dev/null
    else
        custom_command "src"
        _src_load "${look}"
    fi
}


function _src_load() {
    # For src: reload the config, loading the newest work instead when <look> is
    # true and this is the config's own repo
    local look="$1"

    # Only look for newer work inside the repo this config was loaded from
    local base=""
    if [[ "${look}" = true ]]; then
        local here_repo config_repo
        here_repo=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
        config_repo=$(git -C "${dotfiles_dir}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
        if [[ -n "${here_repo}" && "${here_repo}" = "${config_repo}" ]]; then
            if git show-ref --verify --quiet refs/heads/main; then
                base="main"
            elif git show-ref --verify --quiet refs/heads/master; then
                base="master"
            fi
        fi
    fi

    local newest=""
    if [[ -n "${base}" ]]; then
        newest=$(_src_candidates "${base}" | sort -t $'\t' -k1,1nr | head -n 1)
        if [[ -z "${newest}" ]]; then
            echo "Nothing newer than ${base}; reloading the usual config"
        fi
    fi
    if [[ -z "${newest}" ]]; then
        source "${HOME}/.bashrc"
        source "${HOME}/.bash_profile"
        return
    fi

    local kind target label checkout here
    IFS=$'\t' read -r _ kind target label <<< "${newest}"
    here=$(git rev-parse --show-toplevel) || return 1
    if [[ "${kind}" = branch ]]; then
        # Not checked out anywhere, so switch this checkout over to it
        if [[ -n "$(git status --porcelain)" ]]; then
            echo "Error: The newest work is on branch ${label}, but this checkout has" >&2
            echo "uncommitted changes, so it can't switch to it. Commit them first, or" >&2
            echo "reload the usual config with: src -n" >&2
            return 1
        fi
        git switch --quiet "${target}" || return 1
        checkout="${here}"
        echo "Switched ${checkout} to ${label}: it has the newest changes not on ${base}"
    else
        checkout="${target}"
        if [[ "${checkout}" != "${here}" ]]; then
            builtin cd "${checkout}" || return 1
        fi
        echo "Loading the config from ${checkout} (${label}): it has the newest changes not on ${base}"
    fi
    # shellcheck source=/dev/null
    source "${checkout}/.bash_profile"
}


function g() {
    # cd to ~/git if called in a terminal; print the path if used in a pipe/subshell
    custom_command "Git Projects"
    local dir="${HOME}/git"
    if [ -t 1 ]; then
        cd "${dir}" || return
    else
        echo "${dir}"
    fi
}


function cdl() {
    custom_command "cdl"
    if [[ $# -eq 1 ]]; then
        builtin cd -P "$1" && ls
    else
        ls .
    fi
}



function gif() {
    custom_command "gif - an ffmpeg wrapper for quickly creating gifs from videos"
    # Thin wrapper: delegates to the standalone, portable script in
    # programs/gif/gif (the same file shared with others). All argument
    # parsing and ffmpeg work lives there. Run `gif -h` for usage.
    "${dotfiles_dir}/programs/gif/gif" "$@"
}


function imgdiff() {
    custom_command "imgdiff - highlight the pixels that differ between two images"
    local usage="Usage: imgdiff [options] <image1> <image2>
       imgdiff [options] <image>   (one image holding both pictures)
  Compares two images with ImageMagick's \`compare\`, prints how many pixels differ, and
  opens a copy of image1 with every differing pixel painted red.
  Exits 0 if the images match, 1 if they differ, 2 on an error (like \`diff\`).

  Images of different sizes are lined up first (as with --align): image2 is moved
  (and scaled, if needed) to sit on image1, and only the area they share is compared.

  Given one image, like a spot-the-difference puzzle, it finds the two copies of the
  picture inside it, splits them apart and compares them. If the copies aren't clear,
  it stops and asks whether you meant to add a second image, or to use --split.

Options:
  -a, --align           Line the images up before comparing, even if they're the same
                        size: for screenshots scrolled or cropped differently, or a
                        spot-the-difference pair. Uses OpenCV via uv (programs/imgdiff)
  -s, --split           With one image: search harder for the two pictures in it,
                        and split down or across the middle if they still aren't clear
  -f, --fuzz [amount]   Count colours this close as the same, as a percentage, e.g. 5%
                        (default: exact; -f alone: 10%)
  -o, --output <file>   Where to save the highlighted image
                        (default: \$TMPDIR/imgdiff/<image1>-vs-<image2>.png)
  -n, --no-open         Save the highlighted image without opening it
  -h, --help            Show this help

Examples:
  imgdiff before.png after.png          highlight every changed pixel
  imgdiff -f 5% before.png after.png    ignore tiny colour shifts (anti-aliasing)
  imgdiff -f cam1.png cam2.png          ignore camera noise (the default 10%)
  imgdiff -a shot1.png shot2.png        line up two screenshots, then compare
  imgdiff -a -f 10% left.jpg right.jpg  spot the difference in two photos
  imgdiff -f 10% puzzle.png             spot the difference in a one-image puzzle
  imgdiff -s -f 10% puzzle.png          the same, searching harder for the two pictures
  imgdiff -n -o diff.png a.png b.png    save to diff.png, don't open it

Requires ImageMagick: brew install imagemagick
Lining up and splitting also need uv (brew install uv); the first run downloads OpenCV once."

    local fuzz="0"
    local default_fuzz="10%"
    # A fuzz amount is a percentage, like 10% or 2.5%. The % is required: it's how
    # a bare -f is told apart from -f followed by an image, and ImageMagick reads a
    # plain number as a raw colour value out of 65535, so -fuzz 10 is nearly exact.
    # (The pattern lives in a variable so bash 3.2 and later parse =~ the same way.)
    local fuzz_pattern='^[0-9]+([.][0-9]+)?%$'
    local plain_number_pattern='^[0-9]+([.][0-9]+)?$'
    local output=""
    local open_output=true
    local align=false
    local split_harder=false
    local images=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--fuzz)
                # The amount is optional: take the next word only if it's a
                # percentage, so "-f 01.png 02.png" keeps both images
                if [[ "${2-}" =~ ${fuzz_pattern} ]]; then
                    fuzz="$2"
                    shift 2
                elif [[ "${2-}" =~ ${plain_number_pattern} ]]; then
                    echo "Error: $1 takes a percentage: did you mean $1 $2%?" >&2
                    return 2
                else
                    fuzz="${default_fuzz}"
                    shift
                fi
                ;;
            --fuzz=*)
                fuzz="${1#*=}"
                if [[ ! "${fuzz}" =~ ${fuzz_pattern} ]]; then
                    echo "Error: --fuzz needs a percentage like 10%, got '${fuzz}'" >&2
                    return 2
                fi
                shift
                ;;
            -o|--output)
                if [[ -z "$2" ]]; then
                    echo "Error: No value provided after $1" >&2
                    echo "${usage}" >&2
                    return 2
                fi
                output="$2"
                shift 2
                ;;
            -n|--no-open)
                open_output=false
                shift
                ;;
            -a|--align)
                align=true
                shift
                ;;
            -s|--split)
                split_harder=true
                shift
                ;;
            -h|--help|help)
                echo "${usage}"
                return 0
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                echo "${usage}" >&2
                return 2
                ;;
            *)
                images+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#images[@]} -lt 1 ]] || [[ ${#images[@]} -gt 2 ]]; then
        echo "Error: Expected two images (or one holding both pictures), got ${#images[@]}." >&2
        echo "${usage}" >&2
        return 2
    fi
    if [[ "${split_harder}" = true ]] && [[ ${#images[@]} -ne 1 ]]; then
        echo "Error: --split is for one image holding both pictures; got ${#images[@]} images." >&2
        return 2
    fi

    if ! command -v magick >/dev/null 2>&1; then
        echo "Error: ImageMagick isn't installed. Install it with: brew install imagemagick" >&2
        return 2
    fi
    local image
    for image in "${images[@]}"; do
        if [[ ! -f "${image}" ]]; then
            echo "Error: File not found: ${image}" >&2
            return 2
        fi
    done

    # One image: split it into its two pictures, then compare those
    if [[ ${#images[@]} -eq 1 ]]; then
        local source="${images[0]}"
        if ! command -v uv >/dev/null 2>&1; then
            echo "Error: Splitting an image needs uv. Install it with: brew install uv" >&2
            return 2
        fi
        local base
        base=$(basename "${source%.*}")
        mkdir -p "${TMPDIR:-/tmp/}imgdiff"
        images=("${TMPDIR:-/tmp/}imgdiff/${base}-first.png" "${TMPDIR:-/tmp/}imgdiff/${base}-second.png")
        if [[ -z "${output}" ]]; then
            output="${TMPDIR:-/tmp/}imgdiff/${base}-diff.png"
        fi
        local mode="--split"
        [[ "${split_harder}" = true ]] && mode="--split-harder"
        "${dotfiles_dir}/programs/imgdiff/imgalign" "${mode}" "${source}" "${images[0]}" "${images[1]}"
        local split_status=$?
        if [[ ${split_status} -eq 3 ]]; then
            # Most often one image means the second was left off by mistake
            echo "" >&2
            echo "Did you mean to compare it with another image? Add the second one:" >&2
            echo "  imgdiff ${source} <image2>" >&2
            echo "Or, if it really holds two pictures, search harder:" >&2
            echo "  imgdiff --split ${source}" >&2
            return 2
        elif [[ ${split_status} -ne 0 ]]; then
            return 2
        fi
    fi
    local image1="${images[0]}"
    local image2="${images[1]}"

    local size1 size2
    size1=$(magick identify -format "%wx%h" "${image1}[0]") || return 2
    size2=$(magick identify -format "%wx%h" "${image2}[0]") || return 2

    local name1 name2 workdir
    name1=$(basename "${image1%.*}")
    name2=$(basename "${image2%.*}")
    workdir="${TMPDIR:-/tmp/}imgdiff"
    mkdir -p "${workdir}"
    if [[ -z "${output}" ]]; then
        output="${workdir}/${name1}-vs-${name2}.png"
    fi

    # compare works pixel by pixel, so images of different sizes are lined up first:
    # imgalign crops both to the area they share and writes them as two
    # same-size images, which are compared instead of the originals
    local compare1="${image1}"
    local compare2="${image2}"
    if [[ "${align}" = true ]] || [[ "${size1}" != "${size2}" ]]; then
        if ! command -v uv >/dev/null 2>&1; then
            echo "Error: Lining up images needs uv. Install it with: brew install uv" >&2
            [[ "${size1}" != "${size2}" ]] && echo "(The images are different sizes: ${size1} vs ${size2}.)" >&2
            return 2
        fi
        if [[ "${align}" != true ]]; then
            echo "The images are different sizes (${size1} vs ${size2}), so lining them up first"
        fi
        compare1="${workdir}/${name1}-aligned.png"
        compare2="${workdir}/${name2}-aligned.png"
        "${dotfiles_dir}/programs/imgdiff/imgalign" "${image1}" "${image2}" "${compare1}" "${compare2}" || return 2
        size1=$(magick identify -format "%wx%h" "${compare1}") || return 2
    fi

    # -metric AE counts the differing pixels and prints the count to stderr.
    # compare exits 0 when the images match, 1 when they differ, 2 on an error.
    local result status
    result=$(magick compare -metric AE -fuzz "${fuzz}" "${compare1}" "${compare2}" "${output}" 2>&1)
    status=$?
    if [[ ${status} -gt 1 ]]; then
        echo "Error: ImageMagick couldn't compare the images: ${result}" >&2
        return 2
    fi

    # The count comes first, followed by a normalised value in brackets. It can be
    # fractional (partly different pixels), so round it for display.
    local count
    count=$(printf "%.0f" "${result%% *}")
    local total=$(( ${size1%x*} * ${size1#*x} ))
    local percent
    percent=$(awk -v c="${count}" -v t="${total}" 'BEGIN { printf "%.3f", 100 * c / t }')

    if [[ ${status} -eq 0 ]]; then
        echo "Identical: no pixels differ (${size1})"
        return 0
    fi
    echo "Different: ${count} of ${total} pixels differ (${percent}%)"
    echo "Highlighted in red: ${output}"
    if [[ "${open_output}" = true ]]; then
        open "${output}"
    fi
    return 1
}


# Function to record daily commit with date and message
function dc() {
    custom_command "daily commit"
    local open_file=false
    local daily_commit_file="${HOME}/Desktop/daily-commit.txt"
    local message=""

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--open)
                open_file=true
                shift
                ;;
            -h|--help)
                echo "dc - Daily Commit - record a timestamped note in daily-commit.txt"
                echo "Usage: dc [options] [message]"
                echo ""
                echo "With no message, dc prompts you to type one. Entering the"
                echo "message at the prompt avoids shell quoting, globbing, and"
                echo "escaping, so you can type any characters freely."
                echo ""
                echo "Options:"
                echo "  -h, --help    Display this help message"
                echo "  -o, --open    Open the daily commit file after adding the message"
                echo ""
                echo "Examples:"
                echo "  dc                               Prompt for an entry, then record it"
                echo "  dc Working on new feature        Record the given message"
                echo "  dc -o Fixed bug in login         Record the message and open the file"
                return 0
                ;;
            *)
                # Collect all remaining arguments as the message
                message="$*"
                break
                ;;
        esac
    done

    # No message on the command line.
    if [ -z "${message}" ]; then
        # `dc -o` with no message stays a shortcut to just open the file.
        if [ "${open_file}" = true ]; then
            open "${daily_commit_file}"
            return 0
        fi
        # Otherwise prompt for the entry. Reading it interactively means the
        # shell never parses it, so quotes, globs, and backslashes are taken
        # literally and need no escaping. -r keeps backslashes verbatim and
        # IFS= preserves leading/trailing whitespace.
        if [ -t 0 ]; then
            IFS= read -r -e -p "Daily commit entry: " message
        else
            IFS= read -r message
        fi
    fi

    # Still nothing to record (empty prompt or empty piped input).
    if [ -z "${message}" ]; then
        echo "No entry provided; nothing recorded."
        return 1
    fi

    # Get current date in YYYY-MM-DD format
    current_date=$(date +"%Y-%m-%d")

    # Append date and message to daily-commit.txt
    echo "${current_date}: ${message}" >> "${daily_commit_file}"

    echo "Commit recorded: ${current_date}: ${message}"

    # Open the file if flag is set
    if [ "${open_file}" = true ]; then
        open "${daily_commit_file}"
    fi
}


function gen() {
    custom_command "gen - pseudorandom word series generator"
    local words_file="${dotfiles_dir}/alias_support/wordlists/wordlist.txt"
    local count=5
    local result=""

    local OPTIND=1
    while getopts "n:h" opt; do
        case "${opt}" in
            n) count="${OPTARG}" ;;
            h)
                echo "Usage: gen [-n <count>]"
                echo "  Generate a dash-separated series of random words"
                echo "  -n  Number of words (default: 5)"
                return 0
                ;;
            \?) return 1 ;;
        esac
    done

    for ((i=0; i<count; i++)); do
        local word
        word=$(awk -v seed=${RANDOM} 'BEGIN {srand(seed);} {lines[NR] = $0} END {print lines[int(NR * rand()) + 1]}' "${words_file}")
        if [ -z "${result}" ]; then
            result="${word}"
        else
            result="${result}-${word}"
        fi
    done

    echo "${result}"
}



function ts() {
    custom_command "ts - date wrapper for the current time"
    local usage="Usage: ts [--format <format>] [date|hour|minute|second] [-h|--help|help]
  A wrapper for \`date\`, used to conveniently generate the current time in common formats.
  Defaults to ISO 8601 with your local UTC offset.

Formats (--format):
  iso     2026-09-25T11:24:24-05:00  (default)
          ISO 8601 / RFC 3339. The general-purpose interchange format: JSON APIs, logs,
          config files. Most languages, databases, and CLI tools parse it directly.
  utc     2026-09-25T16:24:24Z
          ISO 8601 in UTC (Z = UTC). Standard for servers, cloud logs, APIs, and anything
          shared across timezones.
  epoch   1790353464
          Seconds since 1970-01-01 UTC. Used for time math in scripts, token/cookie
          expirations, cache keys, and system internals. Not human-readable.
  local   2026-09-25 11:24:24
          Local time, no timezone. Easy to read; matches how Postgres displays a
          timestamp (without time zone). Ambiguous once it leaves your machine.

Precision (optional positional argument):
  Truncates the current time and zeroes everything smaller. Truncation happens in the
  format's timezone: local for iso/local, UTC for utc/epoch.
  date    2026-09-25T00:00:00-05:00
  hour    2026-09-25T11:00:00-05:00
  minute  2026-09-25T11:24:00-05:00
  second  2026-09-25T11:24:24-05:00  (default)

Examples:
  ts                  2026-09-25T11:24:24-05:00
  ts date             2026-09-25T00:00:00-05:00
  ts --format utc hour      2026-09-25T16:00:00Z
  ts --format epoch minute  1790353440"

    local format="iso"
    local precision="second"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                if [[ -z "$2" ]]; then
                    echo "Error: No format provided after --format flag" >&2
                    echo "${usage}" >&2
                    return 1
                fi
                format="$2"
                shift 2
                ;;
            -h|--help|help)
                echo "${usage}"
                return 0
                ;;
            date|hour|minute|second)
                precision="$1"
                shift
                ;;
            *)
                echo "Error: Unknown argument '$1'" >&2
                echo "${usage}" >&2
                return 1
                ;;
        esac
    done

    local keep_chars epoch_unit
    case "${precision}" in
        date)   keep_chars=11; epoch_unit=86400 ;;
        hour)   keep_chars=13; epoch_unit=3600 ;;
        minute) keep_chars=16; epoch_unit=60 ;;
        second) keep_chars=19; epoch_unit=1 ;;
    esac

    local stamp
    case "${format}" in
        iso)   stamp=$(date -Iseconds) ;;
        utc)   stamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ") ;;
        local) stamp=$(date +"%Y-%m-%d %H:%M:%S") ;;
        epoch)
            local now
            now=$(date +%s)
            echo $(( now - now % epoch_unit ))
            return 0
            ;;
        *)
            echo "Error: Unknown format '${format}' (expected iso, utc, epoch, or local)" >&2
            return 1
            ;;
    esac

    # All non-epoch stamps share the layout YYYY-MM-DD?HH:MM:SS<suffix>, so zero the
    # time fields past the kept prefix and reattach any suffix (offset or Z)
    local zeros="00:00:00"
    echo "${stamp:0:${keep_chars}}${zeros:$(( keep_chars - 11 ))}${stamp:19}"
}
