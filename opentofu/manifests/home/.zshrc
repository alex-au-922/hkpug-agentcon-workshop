typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/.opencode/bin" $path)
export PATH
export SHELL=/usr/bin/zsh
export TZ="Asia/Hong_Kong"

HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt PROMPT_SUBST

autoload -Uz compinit && compinit
autoload -Uz colors vcs_info
colors

zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:*' enable git

precmd() {
  vcs_info
}

source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

PROMPT='%F{cyan}%n%f %F{blue}%~%f%F{magenta}${vcs_info_msg_0_}%f %# '
RPROMPT='%F{yellow}%*%f'

if [[ -o interactive ]] && [[ -t 0 ]] && command -v kubectl >/dev/null 2>&1; then
  autoload -Uz bashcompinit && bashcompinit
  source <(kubectl completion zsh)
  alias k=kubectl
  compdef __start_kubectl k
fi
