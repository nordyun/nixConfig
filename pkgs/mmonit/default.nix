# M/Monit — central collector + web UI that aggregates every `monit` agent.
#
# Distributed only as a prebuilt vendor tarball (commercial software; a 30-day
# trial license is fetched from mmonit.com:443 on first start and written to
# conf/license.xml). Not in nixpkgs. The tarball ships its own libzdb in lib/
# and statically links OpenSSL + libsodium, so autoPatchelf only has to resolve
# glibc and point the loader at the bundled libzdb.
#
# The binary chdir()s to its install root and resolves conf/ db/ logs/ relative
# to it, so it cannot run from the read-only store: hosts/<host>/mmonit.nix
# copies $out/libexec/mmonit into a StateDirectory and runs it from there.
#
# Upgrades: bump `version`, refresh `hash` (nix-prefetch-url), re-test on a
# linux builder.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mmonit";
  version = "4.3.4";

  src = fetchurl {
    url = "https://mmonit.com/dist/mmonit-${finalAttrs.version}-linux-x64.tar.gz";
    hash = "sha256-8UBWPd2nznQMJqD4gU1MR8w3mBeli91rbrMCWUB3TG8=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ]; # glibc (libm/libdl/libpthread/libc); libzdb is bundled

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/mmonit $out/bin
    cp -a bin conf db doc docroot lib logs upgrade README $out/libexec/mmonit/

    ln -s $out/libexec/mmonit/bin/mmonit       $out/bin/mmonit
    ln -s $out/libexec/mmonit/bin/mmonit-admin $out/bin/mmonit-admin

    runHook postInstall
  '';

  # bin/mmonit's RUNPATH is "$ORIGIN/../lib"; make autoPatchelf bake an absolute
  # reference to the bundled libzdb so it still resolves after the tree is copied
  # into a StateDirectory.
  preFixup = ''
    addAutoPatchelfSearchPath $out/libexec/mmonit/lib
  '';

  meta = {
    description = "Central collector and web dashboard for Monit agents";
    homepage = "https://mmonit.com/";
    license = lib.licenses.unfree; # commercial; trial license fetched on first run
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "mmonit";
  };
})
