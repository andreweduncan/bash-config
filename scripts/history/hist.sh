#!/bin/bash
# Timestamped history with per-command exit-code logging.
# Sourced (not executed) — sets up the recorder hook and the hist() query function.
#
# Log format (tab-separated):
#   command <TAB> exit_code <TAB> timestamp
#
# Depends on: set_prompt (from .bash_profile) via PROMPT_COMMAND chain.

export HISTTIMEFORMAT='%F %T  '

HIST_FILE="${HIST_FILE:-${HOME}/.bash_command_log}"

__hist_last_histnum=""

hist_record() {
	local exit_code=$?
	local histnum cmd
	histnum=$(HISTTIMEFORMAT='' builtin history 1 | awk '{print $1}')
	if [[ -n "${histnum}" && "${histnum}" != "${__hist_last_histnum}" ]]; then
		__hist_last_histnum="${histnum}"
		cmd=$(HISTTIMEFORMAT='' builtin history 1 | sed 's/^ *[0-9]* *//')
		printf '%s\t%d\t%s\n' "${cmd}" "${exit_code}" "$(date '+%F %T')" >> "${HIST_FILE}"
	fi
	return "${exit_code}"
}

PROMPT_COMMAND="hist_record;${PROMPT_COMMAND:+ ${PROMPT_COMMAND}}"

hist() {
	if [[ "$1" == "-h" || "$1" == "--help" ]]; then
		cat <<-'EOF'
		Usage: hist [-f] [n | string]

		Query the command log (command <TAB> exit_code <TAB> timestamp).

		  hist             last 20 log lines
		  hist <n>         last n log lines
		  hist <string>    lines whose command contains string
		  -f, --fails      only nonzero exits; with n, shows the
		                   last n failures (e.g. `hist -f 10`)
		  -h, --help       show this help

		Fields are tab-separated, so e.g.:
		  hist | cut -f1      commands
		  hist | cut -f2      exit codes
		  hist | cut -f3      timestamps
		EOF
		return 0
	fi

	# Accept -f/--fails in any position: `hist -f 5` or `hist 5 -f`
	local fails_only=false
	local -a args=()
	for arg in "$@"; do
		if [[ "${arg}" == "-f" || "${arg}" == "--fails" ]]; then
			fails_only=true
		else
			args+=("${arg}")
		fi
	done
	set -- "${args[@]}"

	local result
	if ${fails_only}; then
		local all_fails
		all_fails=$(awk -F'\t' '$2 + 0 != 0' "${HIST_FILE}")

		if [[ "$1" =~ ^[0-9]+$ ]]; then
			result=$(printf '%s\n' "${all_fails}" | tail -n "$1")
		elif [[ -n "$1" ]]; then
			result=$(printf '%s\n' "${all_fails}" | grep -F -- "$1")
		else
			result="${all_fails}"
		fi
	else
		if [[ "$1" =~ ^[0-9]+$ ]]; then
			result=$(tail -n "$1" "${HIST_FILE}")
		elif [[ -n "$1" ]]; then
			result=$(grep -F -- "$1" "${HIST_FILE}")
		else
			result=$(tail -n 20 "${HIST_FILE}")
		fi
	fi

	if [[ -t 1 ]]; then
		printf '%s\n' "${result}" | awk -F'\t' '
			{
				gray  = "\033[90m"
				red   = "\033[31m"
				green = "\033[32m"
				white = "\033[37m"
				reset = "\033[0m"
				code_color = ($2 + 0 != 0) ? red : green
				printf "%s%s  %s%4d  %s%s%s\n", \
					gray, $3, code_color, $2, white, $1, reset
			}'
	else
		printf '%s\n' "${result}"
	fi
}
