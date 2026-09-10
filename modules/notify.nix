# Shared Slack notification path for the homelab.
#
# Installs a single `notify` command used by monit `exec` actions, NUT
# `upssched`, and systemd `OnFailure=` units:
#
#   notify <alert|warn|info> <title> <message...>
#
#   alert        -> #alerts   webhook  (hard down / failed / needs a human now)
#   warn | info  -> #warnings webhook  (recoverable / thresholds / recovered)
#
# The two incoming-webhook URLs are agenix secrets (declared in
# secrets/secrets.nix). `notify` degrades gracefully: if a webhook secret is
# missing/empty or the POST fails it logs to stderr and exits 0, so it never
# takes down the caller.
{
  config,
  pkgs,
  ...
}:
let
  notify = pkgs.writeShellApplication {
    name = "notify";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      sev="''${1:-info}"
      title="''${2:-notification}"
      shift 2 2>/dev/null || shift $#
      msg="$*"
      host="$(uname -n)"

      alerts_hook=${config.age.secrets.slack_alerts_webhook.path}
      warnings_hook=${config.age.secrets.slack_warnings_webhook.path}

      case "$sev" in
        alert|crit|critical) hook="$alerts_hook";   icon=":rotating_light:" ;;
        warn|warning)        hook="$warnings_hook"; icon=":warning:" ;;
        *)                   hook="$warnings_hook"; icon=":information_source:" ;;
      esac

      if [ ! -s "$hook" ]; then
        echo "notify: webhook secret '$hook' missing or empty -- would have sent [$sev] $title ($host): $msg" >&2
        exit 0
      fi

      text="$(printf '%s *%s*  ·  `%s`\n%s' "$icon" "$title" "$host" "$msg")"
      payload="$(jq -nc --arg t "$text" '{text: $t}')"

      if ! curl -fsS -m 10 --retry 2 -X POST \
            -H 'Content-type: application/json' \
            --data "$payload" "$(cat "$hook")" >/dev/null; then
        echo "notify: POST to Slack failed for [$sev] $title" >&2
      fi
    '';
  };
in
{
  environment.systemPackages = [ notify ];

  age.secrets.slack_alerts_webhook = {
    file = ../secrets/slack_alerts_webhook.age;
    mode = "0400";
  };
  age.secrets.slack_warnings_webhook = {
    file = ../secrets/slack_warnings_webhook.age;
    mode = "0400";
  };
}
