# bash_profile will run on every new tmux window

# make sure docker daemon is always started
if ! sudo service docker status > /dev/null 2>&1; then
    sudo service docker start
fi

# if tmux isn't running, start it
if [ -z "$TMUX" ]; then
    tmux
fi

# source bashrc
. ~/.bashrc
