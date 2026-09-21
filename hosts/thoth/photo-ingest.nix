{ pkgs, ... }:

let
  src = "/srv/photo-ingest/grady";
  photoDest = "/mercury/photos";
  videoDest = "/mercury/homevids";

  # ---------------------------------------------------------------------------
  # Main ingest
  # ---------------------------------------------------------------------------

  ingest = pkgs.writeShellScript "photo-ingest-grady" ''
    set -euo pipefail
    # Photos
    ${pkgs.rsync}/bin/rsync -av --chmod=D755,F644 \
    --remove-source-files \
    --exclude='.*' \
    --include='*/' \
    --include='*.[jJ][pP][gG]' \
    --include='*.[jJ][pP][eE][gG]' \
    --include='*.[hH][eE][iI][cC]' \
    --include='*.[pP][nN][gG]' \
    --include='*.[dD][nN][gG]' \
    --exclude='*' \
    ${src}/ ${photoDest}/
    # Videos
    ${pkgs.rsync}/bin/rsync -av --chmod=D755,F644 \
    --remove-source-files \
    --exclude='.*' \
    --include='*/' \
    --include='*.[mM][pP]4' \
    --include='*.[mM][oO][vV]' \
    --include='*.[mM][kK][vV]' \
    --include='*.[wW][eE][bB][mM]' \
    --exclude='*' \
    ${src}/ ${videoDest}/
  '';

  # ---------------------------------------------------------------------------
  # Post-run sanity check
  # Also installed as `photo-ingest-check`, so it can be run manually.
  # ---------------------------------------------------------------------------

  check = pkgs.writeShellApplication {
    name = "photo-ingest-check";
    runtimeInputs = [
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      src=${src}
      # Ignore anything recent enough that it could legitimately still
      # be uploading. Anything older should have been consumed above.
      leftovers="$(
        find "$src" \
          -type f \
          -mmin +60 \
          -printf '%P\n'
      )"
      if [[ -n "$leftovers" ]]; then
        count="$(printf '%s\n' "$leftovers" | wc -l)"
        echo "WARNING: $count old file(s) remain in $src:"

        while IFS= read -r file; do
          printf '  %s\n' "$file"
        done <<< "$leftovers"

        if command -v notify >/dev/null 2>&1; then
          notify warn \
          "Photo ingest leftovers" \
          "$count old file(s) remain in $src"
        fi
      else
        echo "Photo ingest staging area looks clean."
      fi
    '';
  };

in
{
  # Lets you run `photo-ingest-check` manually.
  environment.systemPackages = [
    check
  ];
  systemd.services.photo-ingest-grady = {
    description = "Grady photos and videos to mercury";
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
    unitConfig.ConditionPathIsMountPoint = [
      "/srv/photo-ingest"
      photoDest
      videoDest
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "wash";
      Group = "users";
      ExecStart = ingest;
      ExecStartPost = "${check}/bin/photo-ingest-check";
    };
  };
  systemd.timers.photo-ingest-grady = {
    description = "Nightly photo ingest";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
    };
  };
}
