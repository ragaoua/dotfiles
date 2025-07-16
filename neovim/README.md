# Installation

(Eventually) backup the current config

~~~bash
mv ${HOME}/.config/nvim ${HOME}/.config/nvim.bak
mv ${HOME}/.local/share/nvim ${HOME}/.local/share/nvim.bak
mv ${HOME}/.local/state/nvim ${HOME}/.local/state/nvim.bak
mv ${HOME}/.cache/nvim ${HOME}/.cache/nvim.bak
~~~

Install this config

~~~bash
ln -s <repo_directory> ${HOME}/.config/nvim
~~~

# Alias vi to nvim

cat >/etc/profile.d/vi.sh <<EOF
alias vi=nvim
EOF
