{ inputs, ... }:
{
  # Centralized unstable package import function
  mkUnstable = pkgs: import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  # Centralized SSH key fetching
  fetchGithubKeys = username: sha256: builtins.fetchurl {
    url = "https://github.com/${username}.keys";
    inherit sha256;
  };

  # Standard user SSH keys (for nordyun)
  nordyunKeys = builtins.fetchurl {
    url = "https://github.com/nordyun.keys";
    sha256 = "0nc1lp77z9mkls5sqprayngafvjccci9y5mpmkszqps42qvcyl5l";
  };
}
