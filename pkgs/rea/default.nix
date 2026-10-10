# rea — reverse-engineering CLI + MCP server (https://github.com/morluto/rea).
#
# Built from the published npm tarball rather than GitHub source: the tarball
# already contains the compiled dist/, bridges and skills, while a source build
# needs turbo, TypeScript 7 and git submodules. npm tarballs ship without a
# lockfile, so package-lock.json here is generated from the tarball's
# package.json with devDependencies/overrides/scripts stripped (postPatch does
# the same strip so the two match).
#
# Backends (Hopper, Ghidra, jadx, mitmproxy, pwndbg, ...) are not packaged;
# rea installs/locates them itself at runtime.
#
# Upgrades: bump `version`, refresh `hash`, then in the unpacked tarball run
#   jq 'del(.devDependencies, .overrides, .scripts)' package.json > p && mv p package.json
#   npm install --package-lock-only --ignore-scripts
# copy package-lock.json here and refresh `npmDepsHash`.
{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  nodejs_22,
}:

buildNpmPackage rec {
  pname = "rea-agents";
  version = "6.3.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${version}.tgz";
    hash = "sha256-sWn8Y8BxDUTFxExZwvhx8iR530RHfN+qny5cN8RWOoQ=";
  };

  postPatch = ''
    ${lib.getExe jq} 'del(.devDependencies, .overrides, .scripts)' package.json > package.json.new
    mv package.json.new package.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-TnX9bs0O9MBOaB20kTarYzCdJq0FpW0/4Kp2rxlJjQg=";
  nodejs = nodejs_22;

  # dist/ is prebuilt; prepare/prepack scripts are dev-only.
  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  meta = {
    description = "Reverse engineer anything with agents, from app behavior down to native binaries";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
  };
}
