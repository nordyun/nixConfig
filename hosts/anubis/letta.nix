{ pkgs, lib, config, ... }:

{
  virtualisation.oci-containers.backend = "podman";

  age.secrets.letta-env.file = ../../secrets/letta-env.age;

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8283 6333 ];

  systemd.tmpfiles.rules = [
    "d /mercury/letta 0755 root root - -"
    "d /mercury/letta/app 0700 root root - -"
    "d /mercury/letta/qdrant 0700 root root - -"
  ];

  virtualisation.oci-containers.containers."letta" = {
    image = "letta/letta:latest";
    environmentFiles = [ config.age.secrets.letta-env.path ];
    volumes = [
      "/mercury/letta/app:/root/.letta:rw"
    ];
    ports = [
      "8283:8283/tcp"
    ];
    log-driver = "journald";
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  virtualisation.oci-containers.containers."qdrant" = {
    image = "qdrant/qdrant:latest";
    volumes = [
      "/mercury/letta/qdrant:/qdrant/storage:rw"
    ];
    ports = [
      "6333:6333/tcp"
    ];
    log-driver = "journald";
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  systemd.services."podman-letta".serviceConfig.Restart = lib.mkOverride 90 "always";
  systemd.services."podman-qdrant".serviceConfig.Restart = lib.mkOverride 90 "always";

  systemd.services.podman-auto-update = {
    description = "Podman auto-update service";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman auto-update";
    };
  };

  systemd.timers.podman-auto-update = {
    description = "Daily podman auto-update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };
}
