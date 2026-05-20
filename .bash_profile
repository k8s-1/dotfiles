# bash_profile will run on every new tmux window

# if tmux isn't running, start it
if [ -z "$TMUX" ]; then
    tmux
fi

# source bashrc
. ~/.bashrc

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
