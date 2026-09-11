# Monit credential separation — audit finding 4

The repository migration preserves remote service control. Agents use
`monit_submission.age` solely to submit reports to Horus. Each agent has a unique
`monit_control_<host>.age`, decryptable only by that host and wash. These contain
the HTTP listener configuration, allowing connections from localhost and Horus's
Tailscale IPv4 address (`100.86.167.115`) and requiring a password as well.

The collector submission password remains unchanged to avoid a coordinated
M/Monit account change. It no longer authenticates to migrated agents. M/Monit
automatically receives each agent's new control credentials during registration.
Horus remains a trusted control point: compromise of the collector can still
expose credentials registered there.

## Deploy and verify

1. Include the new encrypted files in the deployment checkout; Git-based flakes
   must track them before rebuilding. Deploy Horus first, verify it, then deploy
   Anubis and Neptune one at a time using the normal host rebuild procedure.
2. On each host, run `sudo monit -t` and `sudo monit status`. Verify fresh reports
   arrive in M/Monit after a few polling cycles and that the host's registered
   username changes to `mmonit_<host>`.
3. From Horus, verify authenticated access to each agent on port 2812. Use a
   protected curl configuration file or an interactive password prompt; do not
   put credentials in command arguments. An unauthenticated request from Horus
   must fail authentication.
4. From another tailnet peer, verify port 2812 rejects HTTP access even with the
   correct credentials. The Monit source allowlist is independent of the current
   broad Tailscale firewall trust. Localhost remains allowed for the local CLI.
5. Verify the old shared credential fails against migrated agents. If validating
   a remote control action, use a deliberately harmless test service rather than
   restarting a production daemon merely to test the buttons.

## Ubuntu and later Thoth migration

The unmanaged Ubuntu agent still uses the old combined configuration. Give it a
unique agent-control password, retain the submission directive, and add the same
localhost/Horus source allowlist to its `set httpd` block. Check with `monit -t`,
reload, and verify registration and access as above. Store its credential through
the host's existing protected configuration workflow.

Keep `monit_collector.age` and its declaration until Ubuntu is migrated and no
deployment depends on it. Then remove the obsolete combined secret. Git history
will still contain it, so its password must never again be used for agent control.

Thoth does not currently enable collector mode. Before enabling it, add its host
key, give it access to the submission secret, and create a distinct
`monit_control_thoth.age` encrypted only to wash and Thoth. Do not share another
host's control secret.

## Reference

The [Monit manual](https://mmonit.com/monit/documentation/monit.html) documents
combined host/password authentication and automatic credential registration in
the HTTPD and M/Monit sections. HTTP traffic between tailnet addresses is carried
over Tailscale's encrypted transport.
