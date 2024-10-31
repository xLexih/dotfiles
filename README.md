# Description

This is a repository where I store all my dot files

## Requirements

- Git (To clone the repo)
- Stow (To symlink the dot files)

## How it works

It works by symlinking every file in It's directory to the appropriate path.
For example .zshrc from the repository will be symlinked to $HOME/.zshrc

## Setup

(this is a fine grained token for the repo so its fine)
`git clone https://oath2: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@github.com/xLexih/dotfiles.git $HOME/dotfiles`

`chmod +x ./install/setup.sh`

`./install/setup.sh`


`cd $HOME/dotfiles/`

`stow .`

