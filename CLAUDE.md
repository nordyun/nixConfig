# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS/nix-darwin flake configuration managing multiple hosts across Linux (NixOS) and macOS (nix-darwin) systems. The configuration uses a modular architecture with shared components for both platforms.

## Build and Deployment Commands

### Building Configurations

**For macOS (darwin) hosts:**
```bash
darwin-rebuild switch --flake .#<hostname>
```
Available darwin hosts: `anu`

**For NixOS hosts:**
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```
Available NixOS hosts: `anubis`, `thoth`, `neptune`, `horus`, `heimdall`

### Testing Without Activation
```bash
# macOS
darwin-rebuild build --flake .#<hostname>

# NixOS
sudo nixos-rebuild build --flake .#<hostname>
```

Flakes only see git-tracked files: new files must be `git add`ed (or `git add -N`) before a build will pick them up.

### Updating Dependencies
```bash
nix flake update
```

### Working with Secrets (agenix)
```bash
# Edit secrets (requires appropriate SSH key)
agenix -e secrets/<secret-name>.age

# Rekey secrets after adding new hosts/users
agenix -r
```

## Architecture

### Directory Structure

- **`flake.nix`**: Main flake definition with inputs and output configurations
- **`hosts/`**: Per-host configurations (both NixOS and darwin)
  - Each host has its own directory with `default.nix` and host-specific modules
- **`modules/`**: Reusable configuration modules
  - `common/`: Shared configuration (`sys-default.nix` for NixOS, `darwin-common.nix` for macOS)
  - `darwin/`: macOS workstation config (`workstation.nix`: window manager, sketchybar)
  - `desktop/`: Desktop environment configurations (bspwm, hyprwm, wayland)
  - `gnome/`: GNOME-specific configurations
  - `server/`: Server-specific configurations
  - Top-level shared service modules: `monit.nix`, `nut.nix`, `snmpd.nix`, `notify.nix`, `tailscale-serve.nix`
- **`hm/`**: Home Manager configurations
  - `common/`: Shared home-manager configs (CLI tools, nvim, fish)
  - `darwin.nix`: macOS-specific home-manager config
  - Desktop environment configs (hypr, waybar, etc.)
- **`users/`**: User-specific configurations
  - Separate directories for each user and platform combination
  - Format: `<username>` (Linux) or `darwin-<username>` (macOS)
- **`pkgs/`**: Local package derivations not in nixpkgs (see "Custom Packages")
- **`lib/`**: Shared helpers exposed as `myLib` (`mkUnstable`, `fetchGithubKeys`, `nordyunKeys`)
- **`secrets/`**: Encrypted secrets managed by agenix
  - `secrets.nix`: Public key mappings for secret encryption

### Key Architecture Patterns

**Platform Separation:**
- NixOS systems use `nixosConfigurations` in flake outputs
- macOS systems use `darwinConfigurations` in flake outputs
- Both share home-manager configurations from `hm/`

**Module Import Chain:**
1. Host imports platform-specific common module (`modules/common/darwin-common.nix` or `modules/common/sys-default.nix`)
2. Host imports user configuration from `users/`
3. User configuration imports home-manager modules from `hm/`
4. Additional feature modules (desktop, server, etc.) imported as needed

**Special Args Pattern:**
All configurations receive `{ inherit inputs outputs myLib; }` as `specialArgs`, making flake inputs and the helpers in `lib/` available throughout the configuration tree.

**Unstable Packages:**
Use the `myLib.mkUnstable` helper to access nixpkgs-unstable:
```nix
{ pkgs, myLib, ... }:
let
  unstable = myLib.mkUnstable pkgs;
in
```

**Custom Packages:**
Derivations for software not in nixpkgs live in `pkgs/` (a single `<name>.nix`, or `<name>/default.nix` when extra files like a lockfile are needed). They are not exported as flake outputs or via an overlay; the consuming module instantiates them directly:
```nix
mmonit = pkgs.callPackage ../../pkgs/mmonit { };
# or inline in a package list:
home.packages = [ (pkgs.callPackage ../pkgs/rea { }) ];
```

**Secret Management:**
- Uses agenix for encrypted secrets
- Secrets are encrypted for specific users and hosts defined in `secrets/secrets.nix`
- NixOS: secrets loaded via `inputs.agenix.nixosModules.age`
- Darwin: secrets loaded via `inputs.agenix.darwinModules.default`
- Home-manager: uses `inputs.agenix.homeManagerModules.default`

**SSH Key Fetching:**
Use the helpers in `lib/`: `myLib.nordyunKeys` for the standard user keys, or `myLib.fetchGithubKeys "<username>" "<sha256>"` for others.

### Host-Specific Notes

**anu (macOS):**
- Primary macOS workstation (aarch64-darwin, Determinate Nix so `nix.enable = false`)
- Window manager and sketchybar configured in `modules/darwin/workstation.nix` (aerospace currently installed via homebrew, configured in `~/.aerospace.toml`)
- Uses homebrew for casks (fonts, GUI apps)

**anubis (NixOS):**
- Desktop/audio machine: CamillaDSP, upmpdcli, Resilio, n8n
- Impermanence setup for stateless configuration
- Shedding non-desktop jobs to thoth

**thoth (NixOS):**
- Storage/media server: ZFS pool "mercury", Jellyfin (with hardware acceleration), Immich, NFS, Samba
- Sanoid/Syncoid for ZFS snapshot management; receives backups pulled from heimdall
- Impermanence setup

**neptune (NixOS):**
- Router/network appliance (`router.nix`, unbound DNS)

**horus (NixOS):**
- Homelab observability box (2012 Mac mini, headless): M/Monit, NUT, LibreNMS

**heimdall (NixOS):**
- OVH VPS (disko-provisioned): Uptime Kuma, healthchecks, external monitoring. See `hosts/heimdall/README.md`

### Configuration Files to Check

When modifying configurations:
1. Check if changes should be in `modules/common/` (affects all hosts)
2. Check if changes should be in `hm/common/` (affects all users)
3. Platform-specific changes go in `modules/common/darwin-common.nix` or `modules/common/sys-default.nix`
4. Host-specific overrides go in `hosts/<hostname>/`

### Common Development Patterns

**Adding a New Package System-Wide:**
- NixOS: Add to `environment.systemPackages` in relevant module
- Darwin: Add to `environment.systemPackages` in host config or darwin-common

**Adding a New Package to User Environment:**
Add to `hm/common/cli.nix` in `home.packages` (all platforms), or `hm/darwin.nix` for macOS only

**Modifying Window Manager on macOS:**
Edit `modules/darwin/workstation.nix`

**ZFS Management:**
- Check `hosts/thoth/sanoid.nix` and `hosts/thoth/syncoid.nix` for backup configurations
- ZFS pools are defined in host-specific configs with `boot.zfs.extraPools`
