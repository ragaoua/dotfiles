# AstroNvim Template

**NOTE:** This is for AstroNvim v4+

A template for getting started with [AstroNvim](https://github.com/AstroNvim/AstroNvim)

# 🛠️ Installation

## Backup the current config

~~~shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
~~~

## Install this config

~~~shell
git clone <this_repo> <repo_directory>
ln -s <repo_directory>/neovim ~/.config/nvim
~~~

## Alias vi to nvim

~~~shell
cat >/etc/profile.d/vi.sh <<EOF
alias vi=nvim
EOF
~~~
