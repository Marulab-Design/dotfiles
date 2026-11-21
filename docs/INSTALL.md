# Installation and laptop setup

This guide targets an **HP ZBook Firefly 15 G8 with 32 GB RAM and NVIDIA T500**, running up-to-date CachyOS, Hyprland **0.55 or later (Lua config support)** and **Noctalia v5** (`noctalia`, TOML configuration). Noctalia v4 (`noctalia-shell`, Quickshell/JSON) is different and does not automatically migrate its settings. Package names and functionality may change: read pacman's output and the linked upstream documentation. These files were not tested on your laptop; hardware-specific settings must be verified locally.

This model family has Intel 11th-generation processors and was sold with different displays, including 1080p and 4K panels. It typically has Intel integrated graphics alongside the T500, but check your exact configuration and display wiring. The 32 GB of RAM does not require a special Hyprland setting; avoid changing swap, zram or hibernation settings solely based on RAM size.

All terminal commands in this guide are written for **Fish**. Run them in a Fish terminal; the Lua and Zsh examples are configuration-file contents, not Fish commands. You do not need to remove Fish.

## 1. Prepare and back up

1. Update the whole system, not individual packages:

   ```fish
   sudo pacman -Syu
   reboot
   ```

2. Log back in. Keep a working desktop session or TTY available (normally Ctrl+Alt+F3). You can restore your old configs from the backup below. Don't use `sudo` to install files into your home directory.
3. Clone the repository or use your existing checkout:

   ```fish
   sudo pacman -S --needed git
   git clone https://github.com/Luxirai/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

   If you already cloned it elsewhere, `cd` to that directory instead. The commands below assume your current directory is the checkout.
4. Back up existing configurations **before** replacing them. This copies rather than deletes your originals:

   ```fish
   set -g backup "$HOME/dotfiles-backup-"(date +%Y%m%d-%H%M%S)
   mkdir -p "$backup" "$HOME/.config"
   for name in hypr noctalia kitty waybar
     if test -e "$HOME/.config/$name"; or test -L "$HOME/.config/$name"
       cp -a "$HOME/.config/$name" "$backup/"
       or echo "Backup failed for $name; stop and investigate before continuing"
     end
   end
   echo "Backup: $backup"
   ```

   This does not back up Noctalia's state; see section 5. Copy any files from your old configuration that you want to keep into the new one deliberately.

## 2. Drivers and GPU (NVIDIA T500 laptop)

CachyOS normally installs NVIDIA drivers during setup. **Do not install a second conflicting driver or blindly switch drivers.** T500 laptops can have an Intel or AMD iGPU as well as the NVIDIA GPU; panel wiring and the active render GPU vary by laptop.

```fish
lspci -k | grep -A3 -E 'VGA|3D|Display'
nvidia-smi
uname -r
cat /sys/module/nvidia_drm/parameters/modeset
cat /sys/module/nvidia_drm/parameters/fbdev 2>/dev/null
```

`nvidia-smi` should see the T500; `modeset` should show `Y`. If not, use the [CachyOS NVIDIA guide](https://wiki.cachyos.org/configuration/graphic_drivers/) and [Hyprland NVIDIA guide](https://wiki.hypr.land/Nvidia/) for your kernel and installed driver. When changing a driver, install the correct matching kernel headers for **every installed kernel** if using DKMS, regenerate the initramfs as directed by CachyOS, and reboot. `fbdev` may be needed on current systems; verify against the current guide and kernel rather than applying random boot parameters. Don't run bootloader-specific commands until you know whether the system uses GRUB, systemd-boot or another loader.

The T500 is a Turing-generation GPU; driver module and firmware support depends on the installed driver release. Let CachyOS choose a supported proprietary/open kernel-module package, rather than assuming an RTX-only recommendation fits. On hybrid systems prefer the Intel iGPU for normal desktop battery life and use the distribution's supported PRIME offload method for a particular application. No `AQ_DRM_DEVICES`, `LIBVA_DRIVER_NAME`, explicit-sync workaround or global NVIDIA rendering override is set here. Only configure one after identifying both GPUs and diagnosing a real problem; forcing the wrong device can cause a black screen or break external displays. For Intel hardware-accelerated video, the `intel-media-driver` and `libva-utils` packages are useful if not already installed; run `vainfo` inside the graphical session to check the available decode/encode profiles. Do not force `LIBVA_DRIVER_NAME` globally: the appropriate driver depends on the active GPU and application.

## 3. Install desktop tools

On CachyOS/Arch, install the following from your enabled repositories:

```fish
sudo pacman -S --needed hyprland noctalia kitty thunar hyprshot waybar \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  pipewire pipewire-pulse wireplumber pavucontrol \
  networkmanager bluez bluez-utils upower brightnessctl \
  ttf-jetbrains-mono-nerd wl-clipboard iproute2 jq
```

Noctalia provides the bar, notification daemon, launcher, lock, wallpaper, volume and brightness controls. Waybar is installed for the optional alternative in section 7; its audio click uses `pavucontrol`, network script uses `iproute2` and `jq`, and icons use the Nerd Font. `hyprshot` powers the window screenshot shortcut. Portals support screen sharing and file dialogs; PipeWire and WirePlumber provide audio. UPower provides battery information. Bluetooth is optional. Avoid starting another notification daemon, lock manager, wallpaper manager or panel alongside the equivalent Noctalia service unless configured intentionally.

If pacman reports an unavailable package, check `pacman -Ss <name>` and the current distro documentation before proceeding; do not use partial upgrades. Optional tools for personal shortcuts: `zen-browser` (Super+B), Obsidian (Super+O), and Linux Flow / T3Code global shortcuts. Install those separately from their trusted publishers or change the bindings in `hypr/config/keybindings.lua` and `hypr/hyprland.lua`. They are not required for the desktop. For Waybar's power profile widget, install `power-profiles-daemon` only if you want it and do not already use a conflicting power manager such as TLP.

Enable system services as needed (NetworkManager may already be active):

```fish
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service  # optional
```

Do not enable multiple competing network managers. PipeWire/WirePlumber and portals normally start automatically through user services/socket activation. Verify with `systemctl --user status pipewire wireplumber` after login. Login via a graphical session or an existing properly configured Hyprland launcher; select Hyprland in your display manager. Do not start a second compositor inside your existing desktop.

## 4. Install the configuration

These are **copies**, so later changes to the checkout do not automatically propagate. This deliberately replaces the four existing config directories after the backup; inspect `$backup` first.

```fish
for name in hypr noctalia kitty waybar
  rm -rf "$HOME/.config/$name"
  cp -a "$PWD/$name" "$HOME/.config/$name"
end
```

If running this in a new shell, repeat `cd ~/dotfiles` (or your actual checkout) first. `hypr/hyprpaper.conf` is a legacy optional file and is not started: leave wallpaper management to Noctalia. `waybar/modules.json` is a legacy file and is not included by the active `config.jsonc`.

The `zsh/` files are optional personal shell snippets, **not** a complete `.zshrc`. They are not compatible with Fish; do not source them in Fish. If you separately use Zsh, review them before sourcing; they include personal tools, SDK paths and aliases that require additional programs. To use them, append the following to your existing `~/.zshrc` after changing the path to the actual checkout:

```zsh
source "$HOME/dotfiles/zsh/cachyos.zsh"
source "$HOME/dotfiles/zsh/exports.zsh"
source "$HOME/dotfiles/zsh/personal.zsh"
```

Do not install unrelated applications merely to satisfy optional aliases. The aliases and hardware-accelerated video helper functions may require extra tools and GPU codec support.

## 5. First login and appearance

1. Log out completely and select Hyprland, then log in. Noctalia starts automatically once per session. Give it time to initialize; open the launcher with **Super+Space** and settings with **Super+comma**.
2. Choose a wallpaper in Noctalia settings. The original referenced a file in another user's Downloads folder and is not included. Choose a local image or directory; Noctalia manages the wallpaper. The included `new-main` custom palette is in `~/.config/noctalia/palettes/`. Noctalia can generate Kitty and Hyprland theme files; the checked-in theme files provide initial defaults and generated colors may overwrite them.
3. Run `hyprctl monitors all`. The default rule enables connected displays at preferred mode and scale 1 without assuming an `eDP-1` connector. Edit `~/.config/hypr/config/monitors.lua` for your actual connector names, placement and scale; for example, **replace `eDP-1` with the observed name**:

   ```lua
   hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.25 })
   hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
   ```

   Adjust scale for the panel; check available modes in `hyprctl monitors all`. On this 15.6-inch model, scale 1 is a reasonable starting point for a 1080p panel; a 4K panel may be more comfortable around 1.5–2. These are starting points, not detected settings. Reload with `hyprctl reload`. Avoid copying the old DP-2 mode or position blindly. Configure workspace assignments only after verifying monitor names.
4. The keyboard is configured for a Japanese JIS layout (`jp`, model `jp106`) as the only/default layout; there is no US/Arabic layout toggle. Change `kb_layout`, `kb_model` and `kb_options` in `config/devices.lua` if needed. This sets the physical key mapping; typing Japanese kana/kanji also requires an input method such as Fcitx5 with Mozc, which this repo does not configure. Touchpad defaults come from Hyprland; configure natural scrolling and tap behavior there if desired.
5. Test locking and unlocking **while you have access to a TTY**, before relying on idle lock: `noctalia msg session lock`. Verify your password works on the laptop display and all connected monitors. If it fails, switch to a TTY, log in and inspect `journalctl --user -b`, Noctalia and PAM configuration; restore the backup if necessary. The inherited idle lock and screen-off timeout is two hours; change it in Noctalia settings for your security needs.

Noctalia merges all top-level `~/.config/noctalia/*.toml` alphabetically, then its GUI-managed `~/.local/state/noctalia/settings.toml` overrides them. An older state file can override this repository's settings, including bar and monitor settings. Back it up before resetting it, and don't delete it without checking:

```fish
mkdir -p "$HOME/noctalia-state-backup"
if test -d "$HOME/.local/state/noctalia"
  cp -a "$HOME/.local/state/noctalia/." "$HOME/noctalia-state-backup/"
end
noctalia config validate "$HOME/.config/noctalia/config.toml"
noctalia config export > "$HOME/noctalia-effective-user-config.toml"
```

Inspect the state overrides and use Settings to change them. If you deliberately want to reset GUI settings, log out of Hyprland first and move `~/.local/state/noctalia/settings.toml` to a backup, then log back in. Noctalia's settings are version-specific; verify validation with your installed version. Community templates/plugins may need network access and installation; disable unused ones in Settings if they generate errors. The old machine-specific Obsidian template was removed; add your own template with your actual vault path only if desired.

## 6. Shortcuts and validation

| Keys | Action |
| --- | --- |
| Super+Enter / E | Kitty / Thunar |
| Super+Space / S / comma | Launcher / control center / settings |
| Super+Q / Shift+Q | Close / force-kill window |
| Super+F / V | Fullscreen / toggle floating |
| Super+1…0; Super+Shift+1…0 | Switch / move window to workspace 1…10 |
| Super+H/J/K/L; Super+Shift+H/J/K/L | Focus / move window |
| Super+R, then H/J/K/L, Escape | Resize mode |
| Super+mouse buttons | Drag / resize; Super+wheel changes workspace |
| Super+Shift+Space | Region screenshot; add Ctrl for window screenshot |
| Super+M / Super+F4 | Session menu / lock and suspend |
| Volume, brightness and media keys | Noctalia controls |

Useful checks:

```fish
Hyprland --version
Hyprland --verify-config --config "$HOME/.config/hypr/hyprland.lua"
hyprctl reload
hyprctl monitors all
hyprctl binds
noctalia config validate "$HOME/.config/noctalia/config.toml"
noctalia msg status
systemctl --user status xdg-desktop-portal xdg-desktop-portal-hyprland
journalctl --user -b -p warning
```

Run `hyprctl` and `noctalia msg` inside the logged-in Hyprland session. If the installed Hyprland version uses different CLI options, check `Hyprland --help`. After editing startup commands, log out and back in; a config reload does not re-run startup. If using Hyprland's optional permission enforcement, consult [Noctalia's Hyprland integration](https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/) for permission rules and restart Hyprland: permissions don't take effect on reload. Resolve the actual Noctalia binary path instead of assuming it.

## 7. Optional: use Waybar instead of the Noctalia bar

Keep Noctalia running for its launcher, lock, wallpaper, notifications and IPC bindings. Disable the Noctalia bar in its Settings (or `noctalia msg bar-hide main`; GUI state can override TOML), then start `waybar` from a terminal. Confirm you have only one bar and all modules work. To start Waybar each login, add `hl.exec_cmd("waybar")` inside the existing `hyprland.start` callback in `~/.config/hypr/config/autostart.lua`. Do not start it twice.

Waybar's temperature module relies on an available sensor. If it shows the wrong reading or fails, inspect `ls /sys/class/thermal/thermal_zone*/type` and configure the correct `thermal-zone` or `hwmon-path` in `~/.config/waybar/config.jsonc` per the [Waybar temperature manual](https://github.com/Alexays/Waybar/wiki/Module:-Temperature). The power-profile module needs a running power-profiles-daemon. Menu hibernation needs a separately configured and tested swap/resume setup; don't assume it works. If the network counter says offline, check `ip route` and whether your VPN/default route is the intended interface. To return to the default, stop Waybar, remove its autostart and re-enable Noctalia's bar.

## 8. Troubleshooting and rollback

- **Black screen or broken config:** use a TTY. Inspect `~/.config/hypr/`, `journalctl --user -b`, `nvidia-smi` and Hyprland logs. Do not force a DRM device without identifying it. Undo your last GPU or monitor change and reboot if necessary.
- **Noctalia absent / duplicated bar:** check `command -v noctalia`, `noctalia msg status`, session logs and autostart. Check state overrides as described above. Ensure only one Waybar/Noctalia bar is enabled.
- **Screensharing fails:** check portal services and installed package versions; restart the session after environment changes. Close conflicting portal configurations before changing backends.
- **Icons/fonts missing:** install the Nerd Font above, log out/in and check `fc-list | grep -i 'JetBrainsMono Nerd'`. The configured bar and Kitty use Nerd Font glyphs.
- **No audio, network, Bluetooth or brightness:** inspect the services above, `wpctl status`, `nmcli`, `bluetoothctl`, `upower -e`, and `brightnessctl`; verify permissions and hardware support. External display brightness may require DDC/CI configuration.
- **Restore configs:** log out; from a TTY replace each affected `~/.config/<name>` with its copy in the timestamped backup. Restore Noctalia state separately if you changed it. Keep your current files in another directory first if you want to preserve later changes.

References: [Hyprland wiki](https://wiki.hypr.land/), [Noctalia installation](https://docs.noctalia.dev/noctalia/getting-started/installation/), [Noctalia Hyprland integration](https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/), [CachyOS docs](https://wiki.cachyos.org/).
