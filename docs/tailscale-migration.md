# Tailscale identity and access migration

Status: planning; no tailnet policy or device identity changes applied.
Existing active rules are recorded in `tailscale-policy-before.hujson`.
The restrictive draft is `tailscale-policy.hujson`. It has not been validated by
the Tailscale control plane. `tailscale-policy-transition.hujson` defines the same
identities while retaining allow-all for the identity transition.

## Intended identities

| Owner / identity | Devices | Intended role |
|---|---|---|
| grady@washatka.net | anu, gs25u, anubis | Personal devices; administrator access |
| mdwashatka@gmail.com | mollys-macbook-pro | Neptune exit only |
| mgwashatka@gmail.com | iphone-11-pro-max, iphone-xs | Shared parents' identity; Andromeda exit only |
| Son (not enrolled in new design) | zelda | Retirement planned; no migration or device deletion performed |
| tag:router | neptune | Router, approved subnet routes, home exit node, Monit/SNMP agent, NUT client |
| tag:backup | andromeda | Syncoid pulls from Anubis over TCP 31225; offsite exit node; Monit agent, no SNMP |
| tag:monitor | horus | Collector, dashboards, monitoring probes, NUT server |
| tag:storage | thoth (future) | Media/storage services, Monit/SNMP agent and NUT client after migration |

Servers use tag identities, not another human login. Grady owns tag assignment.
Personal devices remain user-owned: tagging them would replace their user identity.
Anubis remains Grady-owned as requested during its transition to a workstation.
This means it retains Grady's administrator network access while still serving apps.
Rules allowing monitoring into Anubis can initially use its stable Tailscale IP,
100.89.187.60, rather than granting access to every device owned by Grady.

Use separate exit tags (for example `tag:exit-home`, `tag:exit-offsite`) on Neptune
and Andromeda to constrain Internet grants with `via`. Tags are additive; review
all matching grants. A broad Internet grant without `via` would defeat a narrower
exit-node selection rule. Anubis's exit-node role is retired: Neptune is the only
home exit node. Anubis's Nix configuration now uses client routing features and
`extraSetFlags = [ "--advertise-exit-node=false" ]` to clear its persisted
advertisement on deployment. Deployment has not yet been confirmed.

## Access design

- `group:admins` initially contains only grady@washatka.net.
- Family members are ordinary tailnet members, not administrators or tag owners.
- `group:exit-home` contains mdwashatka@gmail.com; Neptune only.
- `group:exit-offsite` contains mgwashatka@gmail.com; Andromeda only.
- Both parents' phones intentionally share one identity and permissions. Device
  records remain separate so a lost phone can be removed individually.
- Approve only the intended users in this existing tailnet; Google organization
  membership and an invitation to the correct tailnet are separate concerns.
- User confirmed Grady-owned devices should access everything, including family
  devices. Grant all ports/protocols to all destinations and Internet exit access.
  Application authentication and destination service/firewall behavior still apply.
- Any device still enrolled as Grady (including stale family nodes and Zelda)
  inherits that unrestricted access. Excluding Zelda from a named device list does
  not revoke it: retire its node before considering the migration complete.
- Permit agents to Horus TCP 8080; Horus to agents TCP 2812 and UDP 161.
- Andromeda runs Monit only: permit Andromeda to Horus TCP 8080 and Horus to
  Andromeda TCP 2812. Exclude Andromeda from UDP 161/SNMP grants.
- Permit Neptune and, later, Thoth to Horus TCP 3493 for UPS monitoring.
- Permit Andromeda (`tag:backup`) to Anubis (100.89.187.60) TCP 31225:
  Andromeda initiates syncoid pulls over ordinary OpenSSH. Return traffic does not
  require a reverse initiation grant. Add the corresponding Thoth destination
  when the backup source moves; retain Anubis only while still needed.
- Neptune's advertised subnet is confirmed as 10.1.1.0/24. Grant access to
  Grady's administrator identity; family identities retain exit-only access.
  The previously supplied 10.1.1.5–10.1.1.250 range was the DHCP pool.
- Add Kuma probe destinations, backup flows, subnet access, dashboard access and
  any explicit administration of family devices before the restrictive cutover.
- Family exit-only rules target `autogroup:internet`, with `via` restricted to
  approved exit tags. They do not grant access to private subnet routes or host
  management ports. Verify both allowed and disallowed exit nodes on each client.
- Ordinary OpenSSH on TCP 31225 needs network grants. The separate `ssh` policy
  controls Tailscale SSH, which is not enabled by these NixOS configurations.
- Keep NixOS firewall/netfilter settings unchanged during policy migration;
  evaluate host-firewall defense in depth separately afterward.

## Staged migration

1. Family identities, exits, Neptune's subnet and Andromeda's backup flow are
   confirmed. Confirm other offsite monitoring requirements.
2. Prepare policy with groups, tag ownership, required grants and allow/deny tests.
   Validate in Tailscale's policy editor before publishing restrictive rules.
3. Introduce groups/tag definitions while retaining the current allow-all rule
   for the identity transition. This phase intentionally provides no isolation.
4. Tag existing server nodes through the admin console without logging out the
   router or remote backup server. Preserve routes/exit approvals and verify SSH.
5. Invite family users; re-enroll one personal device at a time under its actual
   owner. Confirm it joined the existing tailnet and check its new identity/IP.
   Retire stale device records only after replacement access is verified.
6. Update server enrollment in Nix to use suitably scoped tagged auth keys rather
   than the shared user-owned enrollment key. Existing node identity and future
   enrollment configuration must agree; avoid giving all hosts every server tag.
7. From Grady's verified personal device, with LAN/console fallback available,
   publish the complete tested policy removing the wildcard grant. Retain a copy
   of the previous policy for recovery. Narrow grants cannot override allow-all.
8. Verify new SSH connections, monitored agents, SNMP, NUT reads (no shutdown
   test), backups, dashboards, permitted exit use, denied exits and denied private
   services. Do not rely solely on connections established before the cutover.
9. Add Thoth with its server identity when installed; migrate service grants and
   remove obsolete Anubis server access after validating the move.

## Before restrictive cutover

- Confirm any Kuma tailnet probes beyond Monit/SNMP; these are GUI-managed and
  unknown. The draft grants only the confirmed service flows, not arbitrary
  collector access. Local LAN switch polling is outside tailnet policy.
- Assign Neptune `tag:router` and `tag:exit-home`; Andromeda `tag:backup` and
  `tag:exit-offsite`; Horus `tag:monitor`. Reserve `tag:storage` for Thoth.
- Invite both family identities before applying policies that refer to them.
- Re-enroll family clients, retire Zelda and stale Grady-owned family records,
  and verify Anubis no longer advertises an exit node.
- Validate the target policy and included tests in Tailscale's editor. Local JSON
  parsing is only a syntax check. Actual exit selection requires runtime testing.

## References

- [Server identities](https://tailscale.com/docs/how-to/set-up-servers)
- [Device tags](https://tailscale.com/docs/features/tags)
- [Grants and via syntax](https://tailscale.com/docs/reference/syntax/grants)
- [Current plan limits](https://tailscale.com/pricing)
