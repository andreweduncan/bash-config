# bash-config

A minimal, opinionated bash configuration for macOS. Provides a clean prompt, useful shell functions, and a one-shot setup script.

## Install

Paste this into Terminal. It works even if you don't have git installed yet — the script detects what's available and does the right thing.

```bash
if command -v git &>/dev/null; then
  git clone https://github.com/andreweduncan/bash-config.git
else
  curl -fsSL https://github.com/andreweduncan/bash-config/archive/main.tar.gz | tar xz
  mv bash-config-main bash-config
fi
bash bash-config/setup/setup.sh
# Restart your terminal (or: source ~/.bash_profile)
```

Clone anywhere you like — `setup.sh` detects its own location automatically.

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
├── programs/
│   ├── gif/              # Standalone ffmpeg wrapper behind `gif`
│   └── imgdiff/          # imgalign, which lines images up for `imgdiff`
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

Run inside this repo, it loads the newest work instead, so you can try a change before committing it. It picks the checkout (the main one or a worktree) or branch with the most recent change that `main` doesn't have, committed or not, and moves the terminal there: into that worktree, or onto that branch with `git switch` (only if the current checkout has no uncommitted changes). With nothing newer than `main`, or outside the repo, it reloads as usual.

```bash
src                       # Reload, from the newest work when inside this repo
src -n                    # Reload the usual config, wherever you are
```

`rr` uses `src` too, then returns to the directory you ran it from before rerunning.

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

An ffmpeg wrapper for quickly creating optimised GIFs from videos. Requires `ffmpeg` (installed by `setup.sh`). Only the input is required; with no `-o` the GIF is written next to it (`clip.mov` → `clip.gif`). Every flag has a short and long form. See `gif -h` for all options.

```bash
gif video.mp4                              # Entire video, writes video.gif alongside it
gif -o out.gif video.mp4                   # Save to a specific path
gif -s 5 video.mp4                         # Start at 5 seconds
gif -s 5 -e 15 -l 3 -o clip.gif video.mp4  # Clip 5s–15s, compress to 3 second gif
gif -v video.mp4                           # Verbose: show ffmpeg's full output
```

Quiet by default — on success it prints only the output path (interactive terminals still show ffmpeg's live progress line). Pass `-v`/`--verbose` for full ffmpeg output.

### `imgdiff` — Highlight what changed between two images

Compares two images, prints how many pixels differ, and opens a copy of the first with every differing pixel painted red. Images of different sizes are lined up first, and one image holding both pictures (a spot-the-difference puzzle) is split and compared. Exits 0 if they match, 1 if they differ. Requires ImageMagick and uv (`brew install imagemagick uv`). See `imgdiff -h` for all options, and [programs/imgdiff](programs/imgdiff/README.md) for how lining up works.

```bash
imgdiff before.png after.png              # Highlight every changed pixel
imgdiff -f before.png after.png           # Ignore small colour shifts, like camera noise (10%)
imgdiff -f 5% before.png after.png        # Choose how much to ignore
imgdiff -a shot1.png shot2.png            # Line up two screenshots, then compare
imgdiff -f 10% puzzle.png                 # Spot the difference in a one-image puzzle
```

### `gen` — Pseudorandom word generator

Generates a dash-separated series of random words from the bundled wordlist. Useful for naming things.

```bash
gen                       # 5 words (default): cloud-river-maple-stone-drift
gen -n 3                  # 3 words: cloud-river-maple
```

### `hist` — Command history with exit codes

Logs every command (with its exit code and a timestamp) to `~/.bash_command_log`
via a `PROMPT_COMMAND` hook, and queries that log. Fields are tab-separated
(`command <TAB> exit_code <TAB> timestamp`), and terminal output is colorized
(green for zero exits, red for failures).

```bash
hist                      # Last 20 log lines
hist 50                   # Last 50 log lines
hist git                  # Lines whose command contains "git"
hist -f                   # Only failures (nonzero exit)
hist -f 10                # Last 10 failures
hist | cut -f1            # Just the commands (tab-separated fields)
hist -h                   # Help
```

### `ts` — Current timestamp

A wrapper for `date`, used to conveniently generate the current time in common formats without memorizing format strings. Defaults to ISO 8601 with your local UTC offset. An optional `date|hour|minute|second` argument truncates the time. See `ts help` for where each format is typically used.

```bash
ts                         # ISO 8601 (default): 2026-09-25T11:24:24-05:00
ts --format utc            # UTC: 2026-09-25T16:24:24Z
ts --format epoch          # Unix epoch seconds: 1790353464
ts --format local          # Local, no timezone: 2026-09-25 11:24:24
ts date                    # Truncate to the day: 2026-09-25T00:00:00-05:00
ts --format utc hour       # Truncate to the hour: 2026-09-25T16:00:00Z
```

### Navigation aliases

| Alias  | Action |
|--------|--------|
| `d`    | `cd ~/Desktop` |
| `p`    | `cd ~/projects && ls` |
| `dl`   | `cd ~/Downloads` |
| `tc`   | Open bash-config in VS Code |
| `..`   | `cd ..` |
| `...`  | `cd ../..` |
| `....` | `cd ../../..` |
