# server/

The headless arch profile. Use this on any box you want to run services on
instead of sit in front of.

## Setup

```sh
git clone https://github.com/TriTacLe/dotfiles.git ~/dotfiles
cd ~/dotfiles && git submodule update --init --recursive
echo server > ~/.dotfiles-role

sudo bash server/scripts/bootstrap.sh   # root setup, strip GUI if present
bash server/install-server.sh           # packages, stow, xdg
```

`install.sh` at the repo root picks this profile when `~/.dotfiles-role` is
`server`.

## What's in here

- `install-server.sh` — packages from `packages.txt`, CLI-only stow, drops a
  user-dirs.dirs that kills the Desktop/Music/Videos dance.
- `scripts/bootstrap.sh` — one-shot, idempotent. sshd hardening, lid policy,
  /srv, UFW (ssh + tailnet), then strips Hyprland/GUI/audio if found.
- `scripts/svc-new.sh` — `sudo bash svc-new.sh <name>` makes a new service
  slot under `/srv/<name>/` with its own `svc_<name>` user.
- `packages/{packages,aur}.txt` — what we install.
- `etc/` — root-owned configs that `bootstrap.sh` copies into `/etc/`.

## Service layout

```
/srv/<name>/
├── compose.yml   # you own it, you edit it
├── .env          # PUID/PGID = svc_<name>
└── data/         # svc_<name>:svc_<name>, mode 750
```

A container escape gets you `svc_<name>`, not `tri` and not root.

## Networking

UFW denies inbound, allows ssh from anywhere, trusts everything on
`tailscale0`. Public web traffic is supposed to come through cloudflared
(outbound-only, no port forwarding). No 80/443 open by default.

Reach this box from anywhere with `ssh tri@arch-thinkpad` over the tailnet.
