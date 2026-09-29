# heimdall — OVH bootstrap

The disk and network configuration now reflects the supplied Debian inspection:
40 GB `/dev/sda`, BIOS boot, and NIC `fa:16:3e:4c:71:75` (`ens3`). IPv4 is
DHCP-assigned (`40.160.91.53/32`, gateway `40.160.91.1`); the static IPv6
address is `2604:2dc0:101:200::4588/128` with gateway
`2604:2dc0:101:200::1`. Disko will replace the Debian partitions with a BIOS
boot partition and ext4 root. The old EFI partition is not required for the
observed BIOS boot mode.

The hardware placeholder/build guard has been removed. This is still unvalidated:
the new Disko input needs locking, followed by Nix evaluation, a build, and a VM
test. No installation has been performed. kexec is not administratively disabled
and `debian` has passwordless sudo; successful kexec remains to be tested.

Initial scope: NixOS, key-only SSH, Tailscale, and local Monit checks. Asterisk,
Kuma, Healthchecks, and any M/Monit migration follow after boot and networking
have been verified. Local Monit currently logs events only; it has no external
notification destination. Inspect with `sudo monit status` and
`journalctl -u monit`.

## Inspect the temporary Debian installation

Record these over SSH before writing the installation layout:

```sh
uname -m
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS
findmnt /
test -d /sys/firmware/efi && echo UEFI || echo BIOS
ip -br address
ip route
ip -6 route
cat /etc/resolv.conf
cat /proc/sys/kernel/kexec_load_disabled
sudo -n true
```

Also inspect Debian's active network configuration and the OVH console/rescue
access. A zero kexec_load_disabled value is only a preliminary check, not proof
that kexec will succeed. Confirm the administrator has the private key matching
one of the existing pinned `myLib.nordyunKeys` public keys; otherwise add the
correct public key before installation.

## Complete the configuration

1. Confirm the pinned SSH administrator keys include a key you can use.
2. On a Nix-enabled workstation, include the new files in Git and run
   `nix flake lock` to lock the added Disko input without updating existing inputs.
   Review the lockfile diff.
3. Build `.#nixosConfigurations.heimdall.config.system.build.toplevel` locally
   and run nixos-anywhere's `--vm-test`. The VM test does not establish whether
   the real VPS's network or boot environment works.
4. Check `resolvectl status` and the active Debian network configuration to
   confirm DHCP/DNS behavior before installation. The existing stub resolver
   address `127.0.0.53` is not an upstream DNS server.
5. Install with a pinned nixos-anywhere revision using
   `--target-host debian@40.160.91.53`. Installation erases `/dev/sda`.
   Debian's passwordless-sudo access is for the installer; the finished system
   permits only `wash` on port 31225. Confirm the installer supports the final
   SSH port/user transition, or reconnect manually after reboot.

Keep TCP 31225 allowed in any OVH firewall before installation. Preserve whatever
SSH port the temporary installer requires during installation as well. Public
key-only SSH stays available as a recovery path independent of Tailscale.

## After first boot

```sh
ssh -p 31225 wash@PUBLIC_IP
sudo tailscale up
sudo monit status
```

Enroll in the existing tailnet interactively. No auth key or agenix ciphertext
is embedded in this bootstrap. Check Tailscale device expiry policy for the
server, access rules, and a direct connection from neptune. Subnet routing and
phone access are a later step.

Verify a reboot, SSH access, Tailscale reconnection, local monitoring, disk space,
and memory before adding services. Example subsequent deployment from a NixOS
machine, with the repo as the current directory:

```sh
NIX_SSHOPTS='-p 31225' nixos-rebuild switch \
  --flake .#heimdall --target-host wash@PUBLIC_IP --sudo
```

Build locally and copy the result to the VPS. The configured one-job limit also
reduces pressure if a build is ever performed there. The `wash` account has
passwordless sudo because password login is disabled.

Before introducing agenix secrets, collect the final host public key and add
heimdall only to the recipient lists it needs. Back up service state outside OVH;
the flake alone will not restore voicemail or monitoring history.
