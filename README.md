# Description

This is a repository where I store all my dot files

## Requirements

- Git (To clone the repo)
- Stow (To symlink the dot files)

## How it works

It works by symlinking every file in It's directory to the appropriate path.
For example .zshrc from the repository will be symlinked to $HOME/.zshrc

## Setup

`git clone git@github.com:xLexih/dotfiles.git $HOME/dotfiles`
`cd $HOME/dotfiles/`
`stow .`

