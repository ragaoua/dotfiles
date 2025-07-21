# Git configuration

Execute :

~~~bash
mkdir -p ${HOME}/.config/git
ln "git/.gitignore" "${HOME}/.config/git/.gitignore"
git config --global core.excludesFile "${HOME}/.config/git/.gitignore"
~~~
