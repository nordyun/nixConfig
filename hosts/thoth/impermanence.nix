{
  inputs,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # always persist these
  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/etc/NetworkManager"
      "/var/log"
      "/var/lib"
      "/var/cache/jellyfin"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
