# Profiles

One local profile per person. Everything in `profiles/` except `example/` and
this file is gitignored, so names, emails, project paths, and Claude notes never
reach the repository.

The installer creates `profiles/<login>/` from `profiles/example/` on first run
and asks for the git name and email. The active profile is stored in
`~/.dotfiles-profile`; override it for one command with
`DOTFILES_PROFILE=<name>`.

## What gets linked

| Profile file | Target |
| --- | --- |
| `profile.env` | `<repo>/.env`, sourced by zsh |
| `gitconfig.local` | `~/.gitconfig.local` |
| `zshrc.local` | `~/.zshrc.local` |
| `nvim.lua` | `~/.config/nvim/lua/config/local.lua` |
| `ghostty.conf` | `~/.config/ghostty/local` |
| `CLAUDE.local.md` | `~/.claude/CLAUDE.local.md` |
| `settings.local.json` | `~/.claude/settings.local.json` |

Refresh the links after editing a profile with `just profile`.

## Selecting another profile

```bash
echo work > ~/.dotfiles-profile
just profile
```