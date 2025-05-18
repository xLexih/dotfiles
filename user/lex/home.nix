{pkgs, ...}: {
  imports = [
    ../../home/core.nix # Enables home-manager managment and sets the path.
  ];
  programs.git = {
    userName = "lex";
    userEmail = "lex@lexih.dev";
  };
  
}
