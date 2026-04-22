{ pkgs, lib, config, ... }:

let
  ticktickMcpDir = "${config.home.homeDirectory}/.local/share/ticktick-mcp";

  mcpServers = {
    context7 = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };
    ticktick = {
      type = "stdio";
      command = "${lib.getExe pkgs.uv}";
      args = [ "run" "--directory" ticktickMcpDir "-m" "ticktick_mcp.cli" "run" ];
    };
    letta = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "letta-mcp-server" ];
      env = {
        LETTA_BASE_URL = "http://anubis:8283";
      };
    };
  };

  mcpJson = builtins.toJSON { inherit mcpServers; };
in
{
  home.packages = [ pkgs.uv ];

  age.secrets.letta-mcp-password.file = ../../secrets/letta-mcp-password.age;

  home.sessionVariables.UV_PYTHON_PREFERENCE = "only-system";

  home.activation.ticktickMcpRepo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export UV_PYTHON_PREFERENCE=only-system
    if [ ! -d "${ticktickMcpDir}" ]; then
      ${lib.getExe pkgs.git} clone https://github.com/jacepark12/ticktick-mcp.git "${ticktickMcpDir}"
      ${lib.getExe pkgs.uv} venv "${ticktickMcpDir}/.venv"
      ${lib.getExe pkgs.uv} pip install --python "${ticktickMcpDir}/.venv/bin/python" -e "${ticktickMcpDir}"
    fi
  '';

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" "ticktickMcpRepo" ] ''
    claude_json="$HOME/.claude.json"

    if [ ! -f "$claude_json" ]; then
      echo '{}' > "$claude_json"
    fi

    letta_pw_path="${config.age.secrets.letta-mcp-password.path}"
    if [ -r "$letta_pw_path" ]; then
      letta_pw="$(cat "$letta_pw_path")"
      ${lib.getExe pkgs.jq} -s --arg pw "$letta_pw" \
        '.[0] * (.[1] | .mcpServers.letta.env.LETTA_PASSWORD = $pw)' \
        "$claude_json" \
        <(echo '${mcpJson}') \
        > "$claude_json.tmp" \
      && mv "$claude_json.tmp" "$claude_json"
    else
      echo "[claudeMcpServers] $letta_pw_path not yet decrypted; writing mcp config without LETTA_PASSWORD" >&2
      ${lib.getExe pkgs.jq} -s '.[0] * .[1]' \
        "$claude_json" \
        <(echo '${mcpJson}') \
        > "$claude_json.tmp" \
      && mv "$claude_json.tmp" "$claude_json"
    fi
  '';
}
