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
    sha256 = "07m39l23wv0ifxwcr0gsf1iv6sfz1msl6k96brxr253hfp71h18c";
  };
}
