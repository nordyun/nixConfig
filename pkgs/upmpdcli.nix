{ lib
, stdenv
, fetchurl
, pkg-config
, meson
, ninja
, curl
, jsoncpp
, libmicrohttpd
, libmpdclient
, libupnpp
, python3
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    requests
  ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "upmpdcli";
  version = "1.9.12";

  src = fetchurl {
    url = "https://www.lesbonscomptes.com/upmpdcli/downloads/upmpdcli-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-cNl8TBG1J+1/67oO4zkSzFfktc5OlqGQefg39NXYBMw=";
  };

  nativeBuildInputs = [ pkg-config meson ninja ];
  buildInputs = [ curl jsoncpp libmicrohttpd libmpdclient libupnpp pythonEnv ];

  postPatch = ''
    # Fix hardcoded /etc install path
    substituteInPlace meson.build \
      --replace "install_data('src/upmpdcli.conf-dist', install_dir: '/etc')" \
                "install_data('src/upmpdcli.conf-dist', install_dir: get_option('sysconfdir'))"

    # Also fix the install script if it has hardcoded paths
    if [ -f tools/installconfig.sh ]; then
      substituteInPlace tools/installconfig.sh \
        --replace "/etc" "$out/etc" || true
    fi

    # Fix Python shebangs to use our Python environment with requests
    find src/mediaserver/cdplugins -name "*.py" -exec sed -i \
      's|#!/usr/bin/env python3|#!${pythonEnv}/bin/python3|g' {} \;
    find src/mediaserver/cdplugins -name "*.py" -exec sed -i \
      's|#!/usr/bin/python3|#!${pythonEnv}/bin/python3|g' {} \;
  '';

  passthru = { inherit pythonEnv; };

  meta = with lib; {
    description = "UPnP Media Renderer front-end for MPD";
    homepage = "https://www.lesbonscomptes.com/upmpdcli/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
})
