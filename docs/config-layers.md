# Configuration Layers

Dotfiles have three states. They are discovered in this order and merged into
the generated user environment:

| State | Path | Use it for |
| --- | --- | --- |
| Global | `.config/<program>/<file>` | Defaults shared by every host and user |
| Host | `host/<host>/.config/<program>/<file>` | Machine-specific hardware, monitor, input, and service differences |
| User | `user/<user>/.config/<program>/<file>` | Personal preferences and account-specific configuration |

When the same relative file exists in more than one state, the final generated
file is built from the least specific state to the most specific state:

```text
Global -> Host -> User
```

Plain text configuration files are concatenated. Structured or asset-like files
default to last-wins replacement because concatenating them would usually make
invalid output. The built-in replacement suffixes are:

```text
.json .qml .qmldir .svg .toml .yaml .yml
```

If a specific file needs different behavior, pass a `fileModes` override to
`mkHjemDotfiles`:

```nix
dotfilesLib.mkHjemDotfiles {
  hostName = config.networking.hostName;
  userName = "lex";
  fileModes = {
    "some/program.conf" = "override";
    "some/structured-file.json" = "merge";
  };
}
```

Theme and package placeholders are applied after the selected layers are read,
so every state can use the same substitutions.
