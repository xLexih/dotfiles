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

`cd $HOME/dotfiles/`

`stow .`

