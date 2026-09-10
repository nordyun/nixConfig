{ pkgs, lib, config, ... }:

let
  mcpServers = {
    context7 = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
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
  age.secrets.letta-mcp-password.file = ../../secrets/letta-mcp-password.age;

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
