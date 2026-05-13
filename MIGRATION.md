# Migration Guide — Dotfiles on a New or Existing Machine

Single repo: `github.com/TriTacLe/dotfiles`
Works on: macOS, Arch Linux, Ubuntu/Debian
Entry point: `bash install.sh` — detects OS, handles everything.

---

## How it works

```
~/dotfiles/
├── install.sh              # OS-detect router
├── shared/stow/            # git, nvim, starship, lazygit, backgrounds, zsh/shared.zsh
├── macos/stow/             # .zshrc, tmux, alacritty, ghostty, kitty, neofetch
├── arch/stow/              # .zshrc, hypr, waybar, swaync, wofi, avizo, ...
├── ubuntu/stow/            # .zshrc, tmux, alacritty, rofi, swaylock, ...
└── claude-config/          # git submodule → stowed to ~/.claude/
```

Stow creates symlinks: `~/.zshrc → dotfiles/macos/stow/zsh/.zshrc`
Each OS `.zshrc` sources `~/.config/zsh/shared.zsh` at the end (shared aliases, functions, keybindings).
Always use `--no-folding` — prevents `~/.config` becoming a symlink when multiple packages share it.

---

## macOS — new machine

```bash
git clone git@github.com:TriTacLe/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

`install-macos.sh` installs Homebrew + Brewfile packages, then stows everything.

**Verify:**
```bash
readlink ~/.zshrc        # → dotfiles/macos/stow/zsh/.zshrc
readlink ~/.gitconfig    # → dotfiles/shared/stow/git/.gitconfig
readlink ~/.config/nvim/init.lua
readlink ~/.claude/settings.json
```

---

## Arch Linux — migrating from old repo

The old arch dotfiles used `stow --dotfiles -t ~` (flat repo root, no `stow/` subdir).
**Must unstow with the same flag** before switching repos.

### Step 1 — Pre-flight check

```bash
# See what is currently symlinked and where from
find ~ -maxdepth 1 -type l 2>/dev/null | while read f; do
    echo "$f -> $(readlink $f)"
done
find ~/.config -maxdepth 2 -type l 2>/dev/null | while read f; do
    echo "$f -> $(readlink $f)"
done
```

Symlinks should point into the old arch repo (e.g. `dotfiles/.zshrc` or `dotfiles/zsh/.zshrc`).

### Step 2 — Archive old repo

```bash
# Do NOT delete yet — needed for unstow
mv ~/dotfiles ~/dotfiles-arch-archive
# or wherever your arch dotfiles live — check $DOTFILES_DIR in your .zshrc
```

### Step 3 — Clone unified repo

```bash
git clone git@github.com:TriTacLe/dotfiles.git ~/dotfiles
```

### Step 4 — Unstow old arch packages

**Must use `--dotfiles` flag** (matches how they were originally stowed):

```bash
cd ~/dotfiles-arch-archive

stow --dotfiles -D -t ~ \
    alacritty avizo fastfetch ghostty git hypr kitty lazygit nvim \
    nwg-dock nwg-look pacseek starship swaync tmux waybar \
    wlogout wob wofi zathura zsh

# claude-config (if it was stowed there)
stow --dotfiles -d ~/dotfiles-arch-archive -t ~/.claude -D claude-config 2>/dev/null || true
```

Check nothing is broken after unstow:
```bash
# Should print nothing (no broken symlinks remaining from old repo)
find ~ -maxdepth 3 -type l ! -exec test -e {} \; -print 2>/dev/null \
    | grep -v ".Trash\|Caches\|Library\|.docker\|debug/latest"
```

### Step 5 — Clear any remaining real-file conflicts

Stow refuses to overwrite real files. If any of these exist as real files (not symlinks), move them out:

```bash
# Check which conflict
for f in ~/.zshrc ~/.gitconfig ~/.tmux.conf; do
    [[ -f "$f" && ! -L "$f" ]] && echo "CONFLICT (real file): $f"
done
for d in ~/.config/nvim ~/.config/alacritty ~/.config/ghostty ~/.config/kitty \
          ~/.config/fastfetch ~/.config/lazygit ~/.config/starship \
          ~/.config/hypr ~/.config/waybar ~/.config/swaync; do
    [[ -d "$d" && ! -L "$d" ]] && echo "CONFLICT (real dir): $d"
done
```

For each conflict:
```bash
mv ~/.zshrc ~/.zshrc.pre-unified     # back up, do not delete
mv ~/.config/nvim ~/.config/nvim.pre-unified
# ... repeat for each flagged path
```

### Step 6 — Run installer

```bash
cd ~/dotfiles
bash install.sh
```

Installs stow if missing, inits submodule, stows everything.

### Step 7 — Verify

```bash
source ~/.zshrc                          # no errors
readlink ~/.zshrc                        # → dotfiles/arch/stow/zsh/.zshrc
readlink ~/.config/hypr/hyprland.conf    # → dotfiles/arch/stow/hypr/...
readlink ~/.gitconfig                    # → dotfiles/shared/stow/git/.gitconfig
readlink ~/.config/zsh/shared.zsh        # → dotfiles/shared/stow/zsh/...
git lg                                   # git alias works
nvim --version                           # nvim works
```

### Post-migration — NTNU repos

Shared `.gitconfig` uses `tritac.le@gmail.com`. For NTNU repos, set per-repo:
```bash
cd ~/dev/ntnu/some-repo
git config --local user.email trile@stud.ntnu.no
```

---

## Ubuntu — migrating from manual configs/

Ubuntu had no stow — configs were real files. Must back them up before stow can link.

### Step 1 — Identify conflicts

```bash
for f in ~/.zshrc ~/.gitconfig ~/.tmux.conf; do
    [[ -f "$f" ]] && echo "EXISTS: $f"
done
for d in ~/.config/alacritty ~/.config/fontconfig ~/.config/ghostty \
          ~/.config/rofi ~/.config/swaylock ~/.config/swaync \
          ~/.config/wlogout ~/.config/zathura ~/.config/nvim; do
    [[ -d "$d" ]] && echo "EXISTS: $d"
done
```

### Step 2 — Back up all conflicts

```bash
BACKUP=~/.dotfiles-backup-$(date +%Y%m%d)
mkdir -p "$BACKUP"

# Root dotfiles
for f in .zshrc .gitconfig .tmux.conf; do
    [[ -f ~/$f ]] && mv ~/$f "$BACKUP/$f"
done

# .config dirs
for d in alacritty fontconfig ghostty rofi swaylock swaync wlogout zathura nvim; do
    [[ -d ~/.config/$d ]] && mv ~/.config/$d "$BACKUP/$d"
done

echo "Backed up to $BACKUP"
```

### Step 3 — Clone and install

```bash
git clone git@github.com:TriTacLe/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

### Step 4 — Verify

```bash
source ~/.zshrc
readlink ~/.zshrc              # → dotfiles/ubuntu/stow/zsh/.zshrc
readlink ~/.gitconfig          # → dotfiles/shared/stow/git/.gitconfig
readlink ~/.config/rofi/config.rasi
git lg
nvim --version
```

### Recover from backup if needed

```bash
# If something is wrong, restore originals
cp -r ~/.dotfiles-backup-YYYYMMDD/.zshrc ~/.zshrc
# etc.
```

---

## What to do if stow fails mid-install

`install.sh` uses `set -e` — a conflict aborts the run. If it stops early:

```bash
# See what was already stowed
find ~ -maxdepth 1 -type l | while read f; do readlink "$f"; done | grep dotfiles
find ~/.config -maxdepth 2 -type l | while read f; do readlink "$f"; done | grep dotfiles

# Find what stow is complaining about
stow -d ~/dotfiles/shared/stow -t ~ --no-folding --simulate git nvim starship lazygit backgrounds zsh 2>&1
stow -d ~/dotfiles/arch/stow -t ~ --no-folding --simulate zsh tmux alacritty ghostty kitty fastfetch ... 2>&1

# Remove the specific conflict, then re-run
bash ~/dotfiles/install.sh
```

---

## Adding/restowing a single package

From any OS, use the stow command directly:

```bash
# Re-stow a shared package
stow -d ~/dotfiles/shared/stow -t ~ --no-folding -R nvim

# Re-stow a mac-specific package
stow -d ~/dotfiles/macos/stow -t ~ --no-folding -R ghostty

# Re-stow claude-config
stow -d ~/dotfiles -t ~/.claude -R claude-config
```

On Mac, you can also use the shell helpers:
```bash
stow-all              # restow everything
stow-pkg nvim         # restow one package (checks shared + macos)
unstow-pkg alacritty  # remove symlinks for one package
```

---

## Keeping in sync across machines

```bash
cd ~/dotfiles
git pull --rebase          # get latest changes
stow-all                   # on Mac (uses shell helper)
# or manually:
bash install.sh            # safe to re-run; stow -R restows cleanly
```

---

## Repo is clean — GitHub

Single source of truth: `github.com/TriTacLe/dotfiles` (private)
Old repos (dotfiles-macos, dotfiles-arch, dotfiles-ubuntu) archived.
