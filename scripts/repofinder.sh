#!/bin/bash

set -e

# depends on: fd, fzf

ROOT_DIR="$HOME"

# match all .git dirs without a . in parent path e.g. .local/../../.git is ignored
# dirs=$(fd '\.git$' "$ROOT_DIR" -u --prune -t d -x dirname {} | grep -v '/\..*')
dirs=$(find "$ROOT_DIR" -maxdepth 2 -type d -name '.git' -prune -exec dirname {} \; | grep -v '/\..*')

# fuzzy select repo
selected_repo=$(printf "%s\n%s\n" "$dirs" \
  | sort \
  | uniq \
  | fzf --height 40% --border --ansi --prompt "Select a repository: ")

if [ ! -d "$selected_repo" ]; then
  echo "[repo-finder]: repo not found... clone it."
  exit 1
fi

WINDOW_NAME="$(basename "$selected_repo")"

SESSION_NAME="dev"

if ! tmux has-session -t "$SESSION_NAME"; then
  tmux new-session -d -s "$SESSION_NAME"
fi

if tmux list-windows -t "$SESSION_NAME" | grep -q "$WINDOW_NAME"; then
  echo "[repo-finder]: $WINDOW_NAME already exists in session $SESSION_NAME."
else
  tmux new-window -a -t "$SESSION_NAME" -n "$WINDOW_NAME"
  echo "[repo-finder]: new window $WINDOW_NAME created in session $SESSION_NAME."
fi

if [[ -z "$TMUX" ]]; then
  tmux attach-session -t "$SESSION_NAME"
else
  CURRENT_SESSION=$(tmux display-message -p '#S')
  if [[ "$CURRENT_SESSION" != "$SESSION_NAME" ]]; then
    tmux switch-client -t "$SESSION_NAME"
  else
    tmux select-window -t "$WINDOW_NAME"
  fi
fi

if tmux list-windows -t "$SESSION_NAME" | grep -q "$WINDOW_NAME"; then
  : "$WINDOW_NAME" already exists
else
  tmux new-window -a -t "$SESSION_NAME" -n "$WINDOW_NAME"
fi

if [[ -z "$TMUX" ]]; then
    : Not attached to tmux
else
    CURRENT_SESSION=$(tmux display-message -p '#S')
    if [[ "$CURRENT_SESSION" != "$SESSION_NAME" ]]; then
        : Already attached to a different session
        tmux switch-client -t "$SESSION_NAME"
    fi
fi

tmux select-window -t "$SESSION_NAME:$WINDOW_NAME"
sleep 0.1 # wait for tmux selection post-steps to finish e.g. bash_profile sourcing

if [[ "$(tmux list-panes -t "$SESSION_NAME:$WINDOW_NAME" -F '#{pane_current_command}')" =~ bash|tmux ]]; then
  tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME" "cd $selected_repo && cd $selected_repo && git pull && nvim ." Enter
fi
