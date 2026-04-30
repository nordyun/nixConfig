{ pkgs, ...}:
{
  home.packages = with pkgs.llm-agents; [
    claude-code
    codex
    codex-acp
    gemini-cli
  ];
}
