# Manages $HOME configuration files
This project contains a dotfile baselayer.

## Install symlinks
`stow -R .`

## Uninstall symlinks
`stow -D .`

## Setup
1. Adjust .gitconfig and setup git signing

2. To generate jira cli config,
```
jira init
```
Add it from
~/.config/.jira/.config.yml

See https://github.com/ankitpokhrel/jira-cli

3. Copy wslconfig to Windows host if using WSL
