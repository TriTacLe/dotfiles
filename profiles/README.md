# Profiles

One local profile per person. Everything in `profiles/` except `example/` and
this file is gitignored, so names, emails, project paths, and Claude notes never
reach the repository.

The installer creates `profiles/<login>/` from `profiles/example/` on first run
and asks for the git name and email. The active profile is stored in
`~/.dotfiles-profile`; override it for one command with
`DOTFILES_PROFILE=<name>`.

## What gets linked

| Profile file | Target | Read by |
| --- | --- | --- |
| `profile.env` | `<repo>/.env` | `shared.zsh` at shell start, with `set -a` |
| `gitconfig.local` | `~/.gitconfig.local` | `[include]` at the end of the stowed `.gitconfig` |
| `zshrc.local` | `~/.zshrc.local` | sourced near the end of `shared.zsh` |
| `nvim.lua` | `~/.config/nvim/lua/config/local.lua` | `pcall(require, "config.local")` in `init.lua` |
| `ghostty.conf` | `~/.config/ghostty/local` | `config-file = ?local` |
| `CLAUDE.local.md` | `~/.claude/CLAUDE.local.md` | Claude Code |
| `settings.local.json` | `~/.claude/settings.local.json` | Claude Code |

Refresh the links after editing a profile with `just profile`.

`~/.claude` points at the bundled `claude-config` submodule by default. Set
`DOTFILES_CLAUDE_REPO` in `profile.env` to clone your own config instead, or
`DOTFILES_CLAUDE_DIR` to use a directory you already have.

## Selecting another profile

```bash
echo work > ~/.dotfiles-profile
just profile
```