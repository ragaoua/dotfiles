# Installation

(Eventually) backup the current config :

~~~bash
mv ${HOME}/.config/nvim ${HOME}/.config/nvim.bak
mv ${HOME}/.local/share/nvim ${HOME}/.local/share/nvim.bak
mv ${HOME}/.local/state/nvim ${HOME}/.local/state/nvim.bak
mv ${HOME}/.cache/nvim ${HOME}/.cache/nvim.bak
~~~

Install this config :

~~~bash
ln -s <repo_directory> ${HOME}/.config/nvim
~~~

Install dependencies :

~~~bash
# ripgrep is required for telescopes's grepping features
brew install ripgrep
~~~

# Alias vi to nvim

cat >/etc/profile.d/vi.sh <<EOF
alias vi=nvim
EOF
