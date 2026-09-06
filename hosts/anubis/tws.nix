{ pkgs, ... }:
let
  # Interactive Brokers Trader Workstation.
  #
  # TWS is a prebuilt Java app that expects a normal FHS layout and self-updates
  # its jars at runtime, so we run it inside an FHS sandbox rather than patching
  # a fixed install. All persistent state lives in ~/Jts, ~/.tws and ~/.i4j_jres
  # (real btrfs subvol on anubis, survives the tmpfs root wipe) so nothing extra
  # is needed for impermanence.
  #
  # Usage:
  #   1. sudo nixos-rebuild switch --flake .#anubis
  #   2. Download the Linux installer from interactivebrokers.com, then:
  #        tws            # drops you into the FHS shell
  #        sh ./tws-latest-standalone-linux-x64.sh
  #   3. Thereafter launch with:  tws  ->  ~/Jts/tws.sh   (path may vary)
  #      or change runScript below to the launcher path directly.
  tws = pkgs.buildFHSEnv {
    name = "tws";
    runScript = "bash";
    targetPkgs =
      p: with p; [
        # toolchain / core libs
        gcc-unwrapped
        zlib
        expat
        curl
        dbus

        # fonts
        fontconfig
        freetype

        # X11
        libX11
        libXext
        libXrender
        libXtst
        libXi
        libXft
        libXcursor
        libXrandr
        libXfixes
        libxcb
        libXScrnSaver
        libXdamage
        libXcomposite
        libxshmfence
        libxkbcommon

        # bundled Chromium engine (JxBrowser) used by TWS news / account panels
        libgbm
        libdrm
        libglvnd

        # GTK / GDK stack (TWS uses both gtk2 and gtk3 depending on version)
        glib
        gtk2
        gtk3
        pango
        cairo
        atk
        gdk-pixbuf
        at-spi2-core
        at-spi2-atk

        # misc runtime
        nss
        nspr
        alsa-lib
        libGL
        cups
      ];
  };
in
{
  environment.systemPackages = [ tws ];
}
