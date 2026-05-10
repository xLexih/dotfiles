{
  inputs,
  settings,
  ...
}: {
  imports =
    [
      inputs.hjem.nixosModules.default
    ]
    ++ map (username: ./${username}.nix) settings.users;
}
