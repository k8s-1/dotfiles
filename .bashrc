# shellcheck shell=bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=20000
HISTFILESIZE=20000
HISTTIMEFORMAT="%F %T"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    if test -r ~/.dircolors; then eval "$(dircolors -b ~/.dircolors)"; else eval "$(dircolors -b)"; fi
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias grep='grep --color=auto'
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    # shellcheck source=/dev/null
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    # shellcheck source=/dev/null
    . /etc/bash_completion
  fi
fi

# Prevent other users from r+w, allow read access with 022
umask 077

# PS1
function parse_git_info {
  local branch
  branch=$(git branch --no-color 2>/dev/null | sed -n 's/^\* //p')
  [ -z "$branch" ] && return
  [[ $(timeout 0.5 git status --porcelain 2>/dev/null) ]] && branch="${branch}*"
  echo " ($branch)"
}

kcontext() {
  local current_context
  current_context="${KUBE_CURRENT_CONTEXT:-$(grep '^current-context:' "${KUBECONFIG:-$HOME/.kube/config}" 2>/dev/null | awk '{print $2}')}"
  [[ -n "$current_context" ]]  && echo "(☸ $current_context)"
}

PS1="\[\033[32m\]\w\
\[\033[33m\]\$(parse_git_info)\[\033[00m\] \
\[\033[94m\]\$(kcontext)\[\033[00m\] \
$ "

# PATH
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:"$HOME"/go/bin
export PATH=$PATH:"$HOME"/.cargo/bin
export PATH="$HOME/.bun/bin:$PATH"

# ENV
[ -f "$HOME/.config/sops/age/keys.txt" ] && export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
if command -v sops &>/dev/null && [ -s "$HOME/.token/token.enc" ]; then
  eval "$(sops -d "$HOME/.token/token.enc")"
fi
# ~/.token/token.enc:
# export VAR=...

# Alias
alias up="sudo apt update && sudo apt upgrade -y && sudo apt clean"

alias v='nvim'

alias ac='git add . && git commit -m "chore: update file(s): $(git diff --cached --name-only | tr "\n" " ")"'
alias g='git status'
alias gl='git log --oneline --graph --format="%C(yellow)%h%C(reset) %C(cyan)%an%C(reset) %C(green)%ar%C(reset) %s"'
alias gps='git push'
alias gpl='git pull'

alias py='python3'

alias tf=terraform

alias f="bash ~/scripts/repofinder.sh"


if command -v just &>/dev/null; then
    alias j=just
    _just_complete() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local recipes
        recipes=$(just --list --unsorted --no-aliases 2>/dev/null | awk 'NR>1 {print $1}')
        mapfile -t COMPREPLY < <(compgen -W "$recipes" -- "$cur")
    }
    complete -F _just_complete j
    complete -F _just_complete just
fi

if command -v kubectl &>/dev/null; then
  # cache completion script — regenerate only when kubectl binary is newer than cache
  _kc="$HOME/.cache/kubectl_completion.bash"
  [ "$_kc" -ot "$(command -v kubectl)" ] && kubectl completion bash > "$_kc"
  # shellcheck source=/dev/null
  source "$_kc"
  alias k=kubectl
  complete -o default -F __start_kubectl k

  kx() {
    local ctx
    ctx=$(kubectl config get-contexts -o name | fzf)
    if [ -n "$ctx" ]; then
      kubectl config use-context "$ctx"
      export KUBE_CURRENT_CONTEXT="$ctx"
    fi
  }

  kn() {
    local namespace
    namespace=$(kubectl get namespace -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf --prompt="Select Kubernetes namespace: " --height=10)
    if [ -n "$namespace" ]; then
      kubectl config set-context --current --namespace="$namespace"
      echo "Switched to namespace: $namespace"
    else
      echo "No namespace selected."
    fi
  }
fi

kindcluster() {
  kind delete cluster && kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
EOF
  kubectl cluster-info --context kind-kind
}

export dry="--dry-run=client -o yaml"

# JIRA CLI
if command -v jira &>/dev/null; then
  _jc="$HOME/.cache/jira_completion.bash"
  [ "$_jc" -ot "$(command -v jira)" ] && jira completion bash > "$_jc"
  # shellcheck source=/dev/null
  source "$_jc"
  jil() {
    jira issue list --assignee "$(jira me)" -s"To Do" -s"In Progress" --columns key,summary,status,updated
  }
fi

export EDITOR=nvim

# fzf keybindings:
# Ctrl+R history
# Ctrl+T insert file path
# Alt+C cd
# **<Tab> fuzzy complete
command -v fzf &>/dev/null && eval "$(fzf --bash)"

if command -v terraform &>/dev/null; then
  complete -C terraform terraform tf
fi
