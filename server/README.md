# server/

Headless Arch profile. Use on any machine running services instead of a desktop.

## Setup

```sh
git clone https://github.com/TriTacLe/dotfiles.git ~/dotfiles
cd ~/dotfiles && git submodule update --init --recursive
echo server > ~/.dotfiles-role

sudo bash server/scripts/bootstrap.sh   # sshd hardening, UFW, /srv, strip GUI
bash server/install-server.sh           # packages, stow, xdg
```

`install.sh` at the root picks this profile when `~/.dotfiles-role` is `server`.

## Scripts

- `scripts/bootstrap.sh` - one-shot, idempotent. sshd hardening, lid policy, `/srv`, UFW (ssh + tailnet), strips Hyprland/GUI/audio if present.
- `scripts/svc-new.sh` - `sudo bash svc-new.sh <name>` creates `/srv/<name>/` with its own `svc_<name>` system user. A container escape gets `svc_<name>`, not `tri`, not root.

## Networking

UFW denies inbound by default. Allows SSH from anywhere, trusts `tailscale0` fully. Public traffic goes through cloudflared (outbound-only, no open 80/443).

Reach the box from anywhere via `ssh tri@arch-thinkpad` over the tailnet.
