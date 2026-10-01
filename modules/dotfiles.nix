# Layered home files.
#
# Every file under global/home, hosts/<host>/home and users/<user>/home is
# copied into that user's $HOME at the same relative path. Generated files from
# `dotfiles.files` (from modules) sit below those layers. Layers are combined
# from the least to the most specific: text is concatenated, `.json` objects are
# merged recursively (lists are replaced), and formats that can't be combined
# take the most specific layer only. The copies are writable and get reset on
# the next rebuild.
{
  config,
  host,
  inputs,
  lib,
  pkgs,
  users,
  ...
}: let
  cfg = config.dotfiles;

  # Merged recursively; a more specific layer overrides individual keys.
  mergeSuffixes = [".json"];
  # The most specific layer replaces the others.
  replaceSuffixes = [".jsonc" ".qml" ".qmldir" ".svg" ".toml" ".yaml" ".yml"];
  # Copied as-is: no placeholders, no header.
  binarySuffixes = [".png" ".jpg" ".jpeg" ".webp" ".gif" ".ico" ".ttf" ".otf" ".woff2"];

  commentStyles = [
    {
      open = "# ";
      close = "";
      suffixes = [".conf" ".ini" ".toml" ".yaml" ".yml" ".sh" ".bash" ".py" ".nix" "bashrc" "direnvrc" "git/config"];
    }
    {
      open = "// ";
      close = "";
      suffixes = [".jsonc" ".js" ".ts" ".qml"];
    }
    {
      open = "/* ";
      close = " */";
      suffixes = [".css" ".scss" ".qss"];
    }
    {
      open = "-- ";
      close = "";
      suffixes = [".lua"];
    }
  ];

  hasSuffixIn = suffixes: path: lib.any (suffix: lib.hasSuffix suffix path) suffixes;

  header = path: let
    style = lib.findFirst (style: hasSuffixIn style.suffixes path) null commentStyles;
  in
    lib.optionalString (style != null)
    "${style.open}Changes to this file are temporary, they get lost upon a NixOS rebuild${style.close}\n";

  # {{name}} reads `dotfiles.vars`; {{pkgs.attr.path}} is a package store path.
  resolve = path: name:
    if lib.hasPrefix "pkgs." name
    then toString (lib.getAttrFromPath (lib.splitString "." (lib.removePrefix "pkgs." name)) pkgs)
    else cfg.vars.${name} or (throw "dotfiles: unknown placeholder {{${name}}} in ${path}");

  render = path: text:
    lib.concatMapStrings (part:
      if lib.isList part
      then resolve path (lib.head part)
      else part)
    (builtins.split "[{][{]([A-Za-z_][A-Za-z0-9_.-]*)[}][}]" text);

  withNewline = text:
    if text == "" || lib.hasSuffix "\n" text
    then text
    else text + "\n";

  layerDirs = user: [
    ../global/home
    ../hosts/${host}/home
    ../users/${user}/home
  ];

  filesIn = dir:
    lib.optionals (builtins.pathExists dir)
    (map (file: lib.removePrefix "${toString dir}/" (toString file)) (lib.filesystem.listFilesRecursive dir));

  mkFile = user: path: let
    layers = lib.filter builtins.pathExists (map (dir: dir + "/${path}") (layerDirs user));
    texts = lib.optional (cfg.files ? ${path}) cfg.files.${path} ++ map (file: render path (builtins.readFile file)) layers;
    # Key order is lost when layers are merged, so a single layer is kept verbatim.
    mergeJSON = hasSuffixIn mergeSuffixes path && lib.length texts > 1;
    # fromJSON rejects store-path context, so it is dropped for parsing and
    # re-attached to the result to keep referenced packages in the closure.
    mergedJSON =
      builtins.appendContext
      (builtins.toJSON (lib.foldl' lib.recursiveUpdate {} (map (text: builtins.fromJSON (builtins.unsafeDiscardStringContext text)) texts)))
      (builtins.getContext (lib.concatStrings texts));
  in
    {type = "copy";}
    // (
      if hasSuffixIn binarySuffixes path
      then {source = lib.last layers;}
      else if mergeJSON
      then {
        permissions = "644";
        source = pkgs.runCommand (baseNameOf path) {
          nativeBuildInputs = [pkgs.jq];
          json = mergedJSON;
          passAsFile = ["json"];
        } ''jq . "$jsonPath" > $out'';
      }
      else {
        permissions = "644";
        text =
          lib.optionalString (layers != []) (header path)
          + (
            if hasSuffixIn replaceSuffixes path
            then lib.last texts
            else lib.concatMapStrings withNewline texts
          );
      }
    );

  paths = user: lib.unique (lib.attrNames cfg.files ++ lib.concatMap filesIn (layerDirs user));
in {
  options.dotfiles = {
    vars = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
      description = "Values for `{{name}}` placeholders in layered files. `{{pkgs.<attr>}}` always resolves to a package path.";
    };
    files = lib.mkOption {
      type = with lib.types; attrsOf lines;
      default = {};
      description = "Generated files, relative to $HOME, layered below the files of every user.";
    };
  };

  config = {
    dotfiles.vars = {
      inherit host;
      flake = "${inputs.self}";
    };

    hjem.users = lib.genAttrs users (user: {
      files = lib.genAttrs (paths user) (mkFile user);
    });
  };
}
