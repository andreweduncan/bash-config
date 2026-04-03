# AGENTS.md

Conventions for humans and AI agents working in this repo.

---

## Repo purpose

`bash-config` is a minimal, opinionated bash setup for macOS. It provides:
- A git-aware prompt (`prompt.sh`)
- Shell aliases and functions (`custom_commands.sh`)
- A one-shot, idempotent setup script (`setup/setup.sh`)

Keep it small and focused. If something is highly personal or work-specific, it does not belong here.

---

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short imperative summary>
```

Types:
- `feat:` — new command, alias, or capability
- `fix:` — bug fix in an existing command or script
- `chore:` — dependency updates, tooling, CI
- `docs:` — README, comments, AGENTS.md changes only
- `refactor:` — restructure without behavior change

Examples:
```
feat: add g function to cd to ~/git
fix: handle missing HISTFILE in top_cmds
docs: update README install instructions
```

No ticket numbers, no emoji, no period at end of subject line.

---

## Branch naming

```
feat/<short-slug>
fix/<short-slug>
chore/<short-slug>
docs/<short-slug>
```

Examples: `feat/dynamic-repo-path`, `fix/setup-idempotency`, `docs/readme-cleanup`

---

## Pull requests

- One logical change per PR — keep diffs small and reviewable
- PR title matches the commit style (`feat:`, `fix:`, etc.)
- Include a short **Summary** and **Test plan** in the PR body

---

## Shell script conventions

- Always use `${variable}` braces, even when not strictly required (prevents SC2250 warnings)
- All scripts must be idempotent — safe to run more than once
- Prefer `command -v` over `which` for checking if a binary exists
- Use `builtin cd` inside functions to avoid alias recursion
- Test with `shellcheck` before pushing (`brew install shellcheck`)

---

## For AI agents

- **Do not auto-commit.** Stage and diff first; let the human confirm.
- **Do not reorder the PATH** in `.bash_profile` without explicit instruction — ordering is intentional.
- **Do not change `setup.sh` idempotency guards** without confirming the change is safe to run on an already-configured machine.
- **Prefer editing existing files** over creating new ones.
- **No comments that narrate code** — comments should explain *why*, not *what*.
- When adding a new command to `custom_commands.sh`, also add a row to the commands table in `README.md`.
- Shell variable braces rule (`${var}`) applies to all shell files in this repo.
