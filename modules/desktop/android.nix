{ lib, config, pkgs, myLib, ... }:
let
  cfg = config.modules.android;
  primaryUser = config.hostVars.primaryUser;
  unstable = myLib.mkUnstable pkgs;
in
{
  options.modules.android = {
    enable = lib.mkEnableOption "Android development environment";
  };

  config = lib.mkIf cfg.enable {

    # User groups for USB debugging and KVM emulator acceleration
    users.users.${primaryUser}.extraGroups = [ "kvm" ];

    environment.systemPackages = with pkgs; [
      (unstable.android-studio.override { forceWayland = true; })
      jdk17
      android-tools
    ];

    # Point ANDROID_HOME to Studio's default SDK download location
    environment.variables = {
      ANDROID_HOME = "/home/${primaryUser}/Android/Sdk";
      ANDROID_SDK_ROOT = "/home/${primaryUser}/Android/Sdk";
      JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    # nix-ld provides the dynamic linker and shared libraries that
    # pre-compiled Android SDK binaries (aapt2, build-tools, emulator, etc.)
    # expect on a standard Linux system. Without it these binaries fail with
    # "No such file or directory" because NixOS lacks /lib/ld-linux-*.
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      zlib
      libgcc
      ncurses5
      stdenv.cc.cc
      libX11
      libXrender
      freetype
      fontconfig
    ];

    hardware.graphics.enable = lib.mkDefault true;
  };
}
