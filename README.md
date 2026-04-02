# bash-config

A minimal, opinionated bash configuration for macOS. Provides a clean prompt, useful shell functions, and a one-shot setup script.

## Install

```bash
git clone https://github.com/<your-username>/bash-config.git ~/git/bash-config
bash ~/git/bash-config/setup/setup.sh
# Restart your terminal (or: source ~/.bash_profile)
```

`setup.sh` is idempotent — safe to run again after pulling updates.

## What setup.sh does

1. Sets bash as the default shell (if not already)
2. Installs [Homebrew](https://brew.sh) (if not already)
3. Installs: `git`, `gh`, `python`, `duckdb`, `fzf`, `jq`, `ripgrep`, Google Chrome, VS Code (`code`)
4. Adds source lines to `~/.bashrc` and `~/.bash_profile` pointing to this repo

## File structure

```
bash-config/
├── .bash_profile         # PATH, history, shell options, sources prompt.sh + custom_commands.sh
├── .bashrc               # Sources ~/.bash_profile
├── prompt.sh             # Git-aware PS1/PS2 prompt
├── custom_commands.sh    # Functions and aliases
├── setup/
│   └── setup.sh          # One-shot installer
├── alias_support/
│   └── wordlists/
│       └── wordlist.txt  # Word list for random sandbox names
└── templates/
    ├── .cursorrules       # Default VS Code/editor rules copied into new sandboxes
    └── .cursorignore      # Default editor ignore rules copied into new sandboxes
```

## Commands

### `sb` — Sandbox

Instantly spins up a temporary scratch directory for low-friction prototyping. Sandboxes live in `$TMPDIR/sandbox/`, which macOS clears on restart — so you get a clean workspace with zero manual cleanup. If something turns out to be worth keeping, use `harden` to permanently move it to `~/projects/`.

Opens the new directory in VS Code and `cd`s into it. Uses a random two-word name by default.

```bash
sb                        # Create sandbox with random name
sb -n my-experiment       # Create sandbox with a specific name
sb -f notes.md            # Create sandbox and open a specific file
sb -d                     # Navigate to the sandbox parent directory
sb -c                     # Interactive cleanup of unused sandboxes
```

Each sandbox gets a `.sbconfig` metadata file and a `scratchpad.txt` to start from.

### `harden` — Promote sandbox to project

Moves a sandbox directory from `$TMPDIR/sandbox/` into `~/projects/`. Prompts for a meaningful name if the sandbox still has a random one.

```bash
harden                    # Harden current directory
harden /path/to/sandbox   # Harden a specific directory
harden -o                 # Harden and open in VS Code
```

### `gld` — Get Last Download

Moves the most recently modified item from `~/Downloads/` to the current directory.

```bash
gld                       # Move with original name
gld my-file               # Move and rename (extension preserved for files)
```

### `rr` — Refresh and Rerun

Sources your bash config to pick up any changes, then reruns a command from history.

```bash
rr                        # Rerun last command
rr git                    # Find most recent command containing 'git', confirm, then run
```

### `src` — Source config

Re-sources `~/.bashrc` and `~/.bash_profile` to pick up changes without restarting the terminal.

```bash
src
```

### `g` — Go to git projects

```bash
g                         # cd ~/git
echo "$(g)/my-repo"       # Print path (non-TTY mode, safe in subshells)
```

### `cdl` — cd + ls

`cd` into a directory (resolving symlinks via `-P`) and immediately list its contents.

```bash
cdl ~/projects/my-repo
cdl .                     # No args: ls current directory
```

### Finding alias candidates

To see the most frequent first words in your shell history (useful for deciding what to alias):

```bash
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -30
```

### `gif` — Create GIF from video

Converts a video file (or clip) to an optimised GIF. Requires `ffmpeg` (installed by `setup.sh`).

```bash
gif video.mp4 output                    # Entire video at normal speed
gif -s 5 video.mp4 output               # Start at 5 seconds
gif -s 5 -e 15 -l 3 video.mp4 output    # Clip 5s–15s, compress to 3 second gif
```

### `gen` — Pseudorandom word generator

Generates a dash-separated series of random words from the bundled wordlist. Useful for naming things.

```bash
gen                       # 5 words (default): cloud-river-maple-drift-stone
gen -n 3                  # 3 words: river-maple-drift
```

### Navigation aliases

| Alias | Action |
|-------|--------|
| `d`   | `cd ~/Desktop` |
| `p`   | `cd ~/projects && ls` |
| `dl`  | `cd ~/Downloads` |
| `tc`  | Open bash-config in VS Code |
