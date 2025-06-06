{
  inputs,
  settings,
  ...
}: {
  # refer ExtraSpecialArgs.users in flake.nix
  imports =
    [
      # ./Wrappers
      inputs.hjem.nixosModules.default
    ]
    ++ builtins.map (username: ./${username}.nix) settings.users;
}
