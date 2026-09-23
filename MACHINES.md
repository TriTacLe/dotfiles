# Machines

Per-host dotfiles reference. Add a row when a new machine joins.

---

## Lenovo ThinkPad T14s Gen 2i (Ubuntu)

| Field | Value |
|---|---|
| Hostname | tri-thinkpad |
| OS | Ubuntu 24.04.4 LTS |
| Kernel | 6.17.0-23-generic |
| CPU | Intel Core i5-1135G7 (4c/8t, TigerLake) |
| GPU | Intel Iris Xe Graphics (iHD driver) |
| RAM | 16 GB |
| Storage | 256 GB NVMe |
| Display | AU Optronics 0x573D, 14", 1920x1080, eDP-1 |
| DPI | 157 (scale 1.0) |
| Touchpad | Synaptics precision |
| WM | Hyprland 0.55 (cppiber PPA) + Sway fallback |
| Display server | Wayland (GDM) |
| Installer | `ubuntu/install-ubuntu.sh` |
| Hypr host overlay | `ubuntu/stow/hypr-host/.config/hypr/host.lua` |

### Notes

- `hl.env("WLR_NO_HARDWARE_CURSORS", "1")` kept from the wlroots era; no effect on aquamarine
- `hl.env("LIBVA_DRIVER_NAME", "iHD")` + `hl.env("VDPAU_DRIVER", "va_gl")` for VA-API
- Monitor by connector name `eDP-1` (Intel panels don't reliably expose EDID description)
- scale 1.0

---

## HP ZBook Studio G7 (Arch, daily driver)

| Field | Value |
|---|---|
| Hostname | archlinux |
| OS | Arch Linux |
| Model | HP ZBook Studio G7 Mobile Workstation |
| BIOS | S91 Ver. 01.22.00 (2025-07-08) |
| Kernel | 7.2.6-arch2-1 |
| CPU | Intel Core i7-10750H (6c/12t, 2.60 GHz base, 5.0 GHz turbo), `intel_pstate` active + HWP |
| GPU | Intel UHD CometLake-H GT2 `8086:9bc4` (i915) + NVIDIA Quadro T1000 Mobile TU117GLM `10de:1fb9` (nouveau) |
| RAM | 16 GB DDR4-3200 (runs at 2933, the 10750H controller ceiling), dual channel, **soldered, not upgradeable** |
| Storage | 512 GB Samsung 970 EVO/PRO NVMe `144d:a808` (46 GB root, 422 GB /home) |
| Display | AU Optronics 0x1092, 1920x1080@60.164, eDP-1, driven by the iGPU |
| WiFi | Intel AX201 CNVi `8086:06f0` (iwlwifi) |
| Touchpad | elan1201:00-04f3:3098 |
| WM | Hyprland 0.56.2 (pacman) |
| Installer | `arch/install-arch.sh` |
| Hypr host overlay | `arch/stow/hypr-host/.config/hypr/host.lua` |

### Notes

- Monitor by EDID description `desc:AU Optronics 0x1092`, scale 1.0
- Hybrid GPU: Intel iGPU drives the display (`card1`), Quadro T1000 is `card0`
- The Quadro runs on nouveau, so there is no CUDA. Ollama embeds on CPU only, which is why a full RAG reindex takes hours
- Root 46 GB (small), home 422 GB - keep root lean
- Pacman cache at `/home/pacman-cache` and journal capped at 200 MB, both set by `install_system_configs`, so upgrades stop failing the download-space check on root

### Power and thermal

- Battery is 7.17 Ah design, so about 80 Wh new and 65 Wh at current health. Measured 2026-09-23: 5.95 Ah full charge = 83.0% health, 320 cycles. That reads higher than the 81.6% measured on 2026-09-18 at 313 cycles. Health does not recover, so the difference is the gauge recalibrating, and single readings on this EC are worth about a point either way
- **RAM is soldered.** `dmidecode` reports `Form Factor: SODIMM` but that field lies here; the `Bottom-OnBoard 1/2` locators and HP QuickSpecs c06710184 ("Memory is soldered down and not upgradeable") agree it is not socketed. 32 GB was a factory option only, so 16 GB is permanent and every memory fix has to live within it
- **This EC exposes no `power_now` and no `current_now`.** `power_now` does not exist, `current_now` returns "No such device". Any guide that starts by reading `power_now` is unusable here
- The only way to measure draw is integrating `charge_now` over time, and the gauge moves in ~6 mAh steps. **Windows under 3 minutes return noise**: two short samples once read 8.0 W and 15.9 W for the same workload while a 240 s sample read 6.8 W

  ```bash
  c1=$(cat /sys/class/power_supply/BAT0/charge_now); t1=$(date +%s)
  sleep 240
  c2=$(cat /sys/class/power_supply/BAT0/charge_now); t2=$(date +%s)
  v=$(cat /sys/class/power_supply/BAT0/voltage_now)
  awk -v a=$c1 -v b=$c2 -v v=$v -v dt=$((t2-t1)) \
    'BEGIN{printf "%.1f W\n", (a-b)/1e6*(3600/dt)*v/1e6}'
  ```

- dGPU power management already works: `runtime_status` suspended 99.45% of runtime-managed time, `d3cold_allowed=1`, 5 s autosuspend. Nothing to gain by "turning the NVIDIA card off"
- `cpu-tune.service` is now nothing but the RAPL write, capping the long-term limit (`constraint_0_power_limit_uw`) to 45 W, the chip's rated TDP, at every boot. It checks `constraint_0_name` first, because the constraint index is not guaranteed to be `long_term`. PL2 (`constraint_1`, 125 W) is deliberately left alone so short bursts stay fast. This unit exists only because TLP has no RAPL setting. `max_perf_pct` and EPP started here in `746b5de` and now live in `tlp.d/01-power.conf`, where they differ between AC and battery. A deliberate fan-noise tradeoff, not stock. Transition verified 2026-09-23: on AC `max_perf_pct` 80, EPP `balance_power`, turbo on; on battery 60, `power`, turbo off. PL1 stays 45 W across the transition because TLP has no RAPL setting and never touches it
- **99 C under all-core load is the power limit, not throttling.** Stock firmware sets PL1 to 70 W on a 45 W-class CPU, so `stress-ng --cpu 0` pins the package at 99 C against a Tjmax of 100 C and holds there. Check `core_throttle_count` before believing any thermal diagnosis: it read 0 over a 21 h uptime that included such a run, with `package_throttle_count` at 2 totalling 7 ms. Idle clocks of 800-900 MHz are `powersave` plus EPP `balance_power` behaving normally and are routinely misread as throttling. Measured 2026-09-23 with PL1 at 45 W, `stress-ng --cpu 0` on AC settles at **73 C and 2300 MHz all-core**, against 99 C at the stock 70 W, and scores 9419 bogo ops/s over a clean 5 min run with nothing failed. No 70 W throughput baseline was ever captured, so the cost of the cap in ops/s is unmeasured. **Read the two throttle counters as different things.** `core_throttle_count` is the thermal one and stayed at 0 throughout. `package_throttle_count` also counts power and PROCHOT events, so capping PL1 makes it climb by design: it went from 2 to 1011 (5709 ms total, 148 ms worst single event) during the first two minutes of the run, then stayed frozen at 1011 for the remaining three minutes at 73 C. A rising package counter with a flat core counter is the cap working, not a fault
- `/proc/pressure/io` runs high on this machine without any disk problem. It sat at `some avg10=72` / `full avg10=57` while NVMe `io_ticks` moved 184 ms per 10 s, about 1.8% busy. The only D-state task was `kworker/u49:0+i915_flip`, and the stall attributes to `user.slice`. The i915 page-flip worker waiting on vblank is billed to PSI as IO. Cross-check `io_ticks` in `/proc/diskstats` before treating PSI IO as storage
- `vpnagentd.service` (Cisco Secure Client) is disabled. Running, it produced 279 of 332 priority-3 journal errors in one boot, looping on `getCertDBPath` returning `CERTSTORE_ERROR_BAD_PARAMETER` and on `DeterminePublicInterface`. The cert error is because the daemon runs as root and the NSS database exists at `~/.pki/nssdb` but not `/root/.pki/nssdb`. `openconnect` and `vpnc` are installed and both speak AnyConnect, so use those. **`systemctl mask` does not work on it**: the Cisco installer drops a real file at `/etc/systemd/system/vpnagentd.service` rather than shipping it under `/usr/lib`, and mask needs to put its own symlink at that path, so it fails with "File ... already exists". Disabled is enough here, nothing pulls the unit in and no package owns the file, so upgrades cannot re-enable it. Bring it back with `sudo systemctl enable --now vpnagentd.service`, and seed `/root/.pki/nssdb` to silence the cert loop
- **Sleep must stay on `s2idle`. Do not switch to `deep`.** `/sys/power/mem_sleep` offers both, but S3 was tested on 2026-09-18 and it suspends, resumes, then leaves the embedded controller wedged: `ACPI Error: Timeout from EC hardware or EC device driver`, and the machine powers itself off a few minutes later with everything unsaved lost. `s2idle` has clean multi-hour cycles including a five hour overnight. The usual advice that Comet Lake-H s0ix is leaky so deep wins does not survive this firmware
- The EC flakiness is the same root cause as the missing `power_now`: `BAT0._BST` is one of the ACPI methods that times out
- Kernel cmdline carries no `i915.*`, `pcie_aspm` or `nvme_core.*` parameters
- Installed: `thermald`, `tlp` and `powertop`. No power-profiles-daemon, no auto-cpufreq. TLP owns everything that differs between AC and battery; do not add a second power daemon alongside it

---

## Mac (secondary)

| Field | Value |
|---|---|
| OS | macOS |
| WM | N/A (Aqua) |
| Installer | `macos/install-macos.sh` |
| Hypr host overlay | N/A |

### Portability notes

- No Hyprland, no waybar. Shares: git, nvim, lazygit, backgrounds, zsh, scripts, claude-config.
- Homebrew + Brewfile handles packages.

---

## Lenovo ThinkPad L390 Yoga (Arch, server)

| Field | Value |
|---|---|
| Hostname | arch-thinkpad |
| OS | Arch Linux |
| Kernel | 6.19.11-arch1-1 |
| CPU | Intel Core i3-8145U (2c/4t, 2.10 GHz, WhiskeyLake-U) |
| GPU | Intel UHD Graphics 620 (integrated) |
| RAM | 8 GB |
| Storage | 256 GB NVMe (Toshiba KXG6AZNV256G) |
| Role pin | `~/.dotfiles-role` = `server` |
| Installer | `server/install-server.sh` |
| Dotfiles path | `~/dotfiles/` (server convention, not `~/Desktop/dotfiles/`) |
| Hypr host overlay | N/A (headless) |

### Role

Headless server pivot from a former Hyprland desktop install. Hosts Dockerized
apps fronted by Cloudflare Tunnel, with Tailscale for admin access, fail2ban
for any open ports, and restic/borg for backups.

### Portability notes

- No Hyprland, no waybar, no GUI stow packages.
- Shares with desktop hosts: git, nvim, lazygit, zsh, tmux, scripts, ipython. Prompt is
  powerlevel10k via the Arch `.zshrc`; starship is macOS-only.
- Selection is by the `server` role pin (`~/.dotfiles-role`), not by hostname,
  so any Arch host can opt in.

### Service hosting

- Docker stacks live under `/srv/<name>/`, one per service.
- Each service has a dedicated system user `svc_<name>` (uid <1000, no shell);
  container processes run as that user via `PUID/PGID`.
- `tri` owns the compose file and `.env`; the data dir is owned by the
  service user so a container escape stays scoped to that service.
- Provision with `sudo bash server/scripts/svc-new.sh <name>`.

### Hardening

- SSH: key-only, no root login, `AllowUsers tri`, 10 min idle timeout
  (`server/etc/ssh/sshd_config.d/99-hardening.conf`).
- UFW: deny incoming, allow ssh from anywhere, allow all on `tailscale0`.
  No public 80/443 — cloudflared dials out.
- fail2ban watches sshd.

---

## Waybar DPI guide

`style.css` uses fixed pixel values. Adjust `scale` in the host's `host.lua` if bar looks wrong:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.25 })  -- HiDPI 14" panels
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })     -- standard 27"+ at 1440p or lower
```

Reference DPIs:
- 14" 1920x1080 = 157 DPI
- 15" 1920x1080 = 141 DPI
- 27" 2560x1440 = 109 DPI
- 27" 1920x1080 = 81 DPI
