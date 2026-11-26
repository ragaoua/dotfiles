alias gc="git commit"
alias gs="git status"
alias gb="git branch"
alias gba="git branch --all"
alias gdc="git diff --color"
alias gdch="git diff --color HEAD"
alias gdcc="git diff --word-diff=color"

if [ -n "$BASH_VERSION" ] && [ -r /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash ]; then
  . /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
  __git_complete gc _git_commit
  __git_complete gs _git_status
  __git_complete gb _git_branch
  __git_complete gba _git_branch
  __git_complete gdc _git_diff
  __git_complete gdch _git_diff
  __git_complete gdcc _git_diff
fi
