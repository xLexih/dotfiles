{
  lib,
  self ? ../.,
}: let
  repoRoot = self;
  warningText = "Changes to this file are temporary, they get lost upon a nixos rebuild";

  commentStyleFor = relPath:
    if lib.any (suffix: lib.hasSuffix suffix relPath) [
      ".json"
      ".jsonc"
      ".js"
      ".ts"
      ".css"
      ".scss"
      ".qss"
    ]
    then "slashes"
    else if
      relPath == "bashrc"
      || relPath == "git/config"
      || lib.any (suffix: lib.hasSuffix suffix relPath) [
        ".conf"
        ".ini"
        ".toml"
        ".yaml"
        ".yml"
        ".sh"
        ".bash"
        ".zsh"
        ".nix"
      ]
    then "hash"
    else null;

  warningLineFor = relPath: let
    style = commentStyleFor relPath;
  in
    if style == "hash"
    then "# ${warningText}\n"
    else if style == "slashes"
    then "// ${warningText}\n"
    else "";

  last = list: builtins.elemAt list (builtins.length list - 1);

  pathExists = path: builtins.pathExists path;

  listRelativeFiles = dir:
    if !pathExists dir
    then []
    else
      lib.flatten (
        lib.mapAttrsToList (
          name: type: let
            path = dir + "/${name}";
          in
            if type == "directory"
            then map (child: "${name}/${child}") (listRelativeFiles path)
            else if type == "regular" || type == "symlink"
            then [name]
            else []
        ) (builtins.readDir dir)
      );

  layerRoots = {
    hostName,
    userName,
  }: [
    (repoRoot + "/.config")
    (repoRoot + "/host/${hostName}/.config")
    (repoRoot + "/user/${userName}/.config")
  ];

  discoverPaths = {
    hostName,
    userName,
  }:
    lib.unique (
      lib.sort builtins.lessThan (
        lib.flatten (map listRelativeFiles (layerRoots {inherit hostName userName;}))
      )
    );

  modeFor = relPath:
    if
      lib.any (suffix: lib.hasSuffix suffix relPath) [
        ".json"
        ".qml"
        ".qmldir"
        ".svg"
        ".toml"
        ".yaml"
        ".yml"
      ]
    then "override"
    else "merge";

  supportsComment = relPath: (commentStyleFor relPath) != null;

  ensureTrailingNewline = text:
    if lib.hasSuffix "\n" text
    then text
    else text + "\n";

  renderText = {
    layers,
    relPath,
    substitutions,
  }: let
    applySubstitutions = text:
      if substitutions == {}
      then text
      else
        builtins.replaceStrings
        (builtins.attrNames substitutions)
        (builtins.attrValues substitutions)
        text;
    renderedLayers = map (layer: applySubstitutions (builtins.readFile layer)) layers;
    prefix = warningLineFor relPath;
  in
    if modeFor relPath == "override"
    then prefix + (last renderedLayers)
    else prefix + lib.concatMapStrings ensureTrailingNewline renderedLayers;

  makeEntry = {
    commonSubstitutions ? {},
    hostName,
    perFileSubstitutions ? {},
    relPath,
    userName,
  }: let
    roots = layerRoots {inherit hostName userName;};
    layers = builtins.filter pathExists (map (root: root + "/${relPath}") roots);
    substitutions = commonSubstitutions // (perFileSubstitutions.${relPath} or {});
  in
    if layers == []
    then throw "No layered dotfile layers found for ${relPath}"
    else if modeFor relPath == "override" && substitutions == {} && !supportsComment relPath
    then {source = last layers;}
    else {
      type = "copy";
      permissions = "644";
      text = renderText {
        inherit layers relPath substitutions;
      };
    };

  classify = relPath:
    if relPath == "bashrc"
    then {
      kind = "home";
      key = ".bashrc";
    }
    else {
      kind = "xdg";
      key = relPath;
    };
in {
  mkHjemDotfiles = {
    commonSubstitutions ? {},
    hostName,
    perFileSubstitutions ? {},
    userName,
  }: let
    paths = discoverPaths {
      inherit hostName userName;
    };

    entries =
      map (
        relPath: let
          destination = classify relPath;
        in {
          inherit destination relPath;
          entry = makeEntry {
            inherit commonSubstitutions hostName perFileSubstitutions relPath userName;
          };
        }
      )
      paths;
  in {
    files = lib.listToAttrs (
      map
      (item: lib.nameValuePair item.destination.key item.entry)
      (builtins.filter (item: item.destination.kind == "home") entries)
    );

    xdgConfigFiles = lib.listToAttrs (
      map
      (item: lib.nameValuePair item.destination.key item.entry)
      (builtins.filter (item: item.destination.kind == "xdg") entries)
    );
  };
}
