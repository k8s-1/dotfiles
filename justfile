# list commands
default:
    just --list

# stow / restow dotfiles
install:
    stow -R .

# remove stow symlinks
uninstall:
    stow -D .
