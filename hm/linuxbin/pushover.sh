#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash

# Read credentials from agenix secrets
_token="$(cat "$HOME/.agenix/agenix/pushover_token")"
_user="$(cat "$HOME/.agenix/agenix/pushover_user")"

if [[ -z "${2:-}" ]]; then
  echo "Useage: pushover.sh TITLE MESSAGE" >&2
  exit 1
fi

curl -fsS --max-time 30 \
    -F "token=${_token}" \
    -F "user=${_user}" \
    -F "title=$1" \
    -F "message=$2" \
    https://api.pushover.net/1/messages.json
