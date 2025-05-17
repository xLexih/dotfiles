{pkgs, ...}: {
  imports = [
    ../../home/core.nix
    ../../home/program
  ];

  # programs.git = {
  #   userName = "lex";
  #   userEmail = "lex@lexih.dev";
  # };
}
