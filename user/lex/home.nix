{ pkgs, ... }: {
  imports = [
    ../../home/core.nix # Enables home-manager managment and sets the path.
  ];
  home.packages = with pkgs; [
    git # just setup git, in case its not elsewhere. (ik it is tho hehe)
  ];
  programs.git = {
    userName = "lex";
    userEmail = "lex@lexih.dev";
  };

}
