{ pkgs, inputs, ... }:
let
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [
    agents.claude-code
    agents.codex
    agents.codex-acp
    agents.gemini-cli
  ];
}
