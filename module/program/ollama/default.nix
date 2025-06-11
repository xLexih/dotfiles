{
  pkgs,
  lib,
  config,
  settings,
  ...
}: {
  options.ollama = {
    user = lib.mkOption {
      type = lib.types.enum settings.users;
    };
  };
  config.environment.systemPackages = with pkgs; [
    ollama
    opencommit
  ];

  config.hjem.users.${config.ollama.user} = {
    # https://github.com/di-sukharev/opencommit?tab=readme-ov-file#local-per-repo-configuration
    #tavernari/git-commit-message:cod
    files = {
      ".opencommit".text = ''
        OCO_API_URL=http://127.0.0.1:11434/api/chat
        OCO_MODEL=smallthinker:3b
        OCO_API_KEY=undefined
        OCO_AI_PROVIDER=ollama
        OCO_TOKENS_MAX_INPUT=40960
        OCO_TOKENS_MAX_OUTPUT=4096
        OCO_DESCRIPTION=false
        OCO_EMOJI=false
        OCO_LANGUAGE=en
        OCO_MESSAGE_TEMPLATE_PLACEHOLDER=$msg

        OCO_PROMPT_MODULE=conventional-commit
        OCO_ONE_LINE_COMMIT=true
        OCO_TEST_MOCK_TYPE=commit-message
        OCO_OMIT_SCOPE=false
        OCO_GITPUSH=true
        OCO_WHY=true
      '';
    };
  };
  # journalctl -u ollama.service -b --no-pager
  # https://ollama.com/library?sort=newest
  config.systemd.services.ollama = {
    description = "Starts Ollama in the background for LLMs to run in the future";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      # OCO_API_URL = 'http://127.0.0.1:11434/api/chat'
      # OCO_AI_PROVIDER='ollama'
      # OCO_MODEL='mistral'
      Type = "simple"; # or "notify" if Ollama supports systemd notifications
      ExecStart = ''
        ${pkgs.ollama}/bin/ollama serve
      ''; # Adjust path if needed
      Restart = "always";
      RestartSec = 3;
      User = config.ollama.user; # or another user if preferred
      # Add Environment if needed, e.g.:
      # Environment = "OLLAMA_HOST=0.0.0.0";
    };
    enable = true;
  };
}
