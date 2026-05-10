{
  lib,
  config,
  pkgs,
  settings,
  ...
}:
let
  cfg = config.program.app.ollama;
in
{
  options.program.app.ollama = {
    enable = lib.mkEnableOption "Ollama LLM server";
    username = lib.mkOption {
      type = lib.types.enum settings.users;
      default = builtins.head settings.users;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ollama
      opencommit
    ];

    hjem.users.${cfg.username} = {
      files = {
        ".opencommit".text = ''
          OCO_API_URL=http://127.0.0.1:11434/api/chat
          OCO_MODEL=qwen2.5:3b
          OCO_API_KEY=undefined
          OCO_AI_PROVIDER=ollama
          OCO_TOKENS_MAX_INPUT=40960
          OCO_TOKENS_MAX_OUTPUT=4096
          OCO_DESCRIPTION=false
          OCO_EMOJI=false
          OCO_LANGUAGE=en
          OCO_MESSAGE_TEMPLATE_PLACEHOLDER="$msg"

          OCO_PROMPT_MODULE=conventional-commit
          OCO_ONE_LINE_COMMIT=true
          OCO_TEST_MOCK_TYPE=commit-message
          OCO_OMIT_SCOPE=false
          OCO_GITPUSH=true
          OCO_WHY=false
        '';
      };
    };

    systemd.services.ollama = {
      description = "Starts Ollama in the background for LLMs to run in the future";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Restart = "always";
        RestartSec = 3;
        User = cfg.username;
      };
      enable = false;
    };
  };
}
