# dotfiles

## Global prerequisites

Install make, stow

## Scripts set up

Prerequiite: install fzf and fd (fd-find)

```bash
brew install fzf fd
make scripts
```

## Tmux configuration

Prerequisite: install tmux and the tmux-related scripts installed in `/usr/local/bin`.

```bash
make tmux
```

When running `tmux` for the first time after that, the config will try
and bootstrap `tpm` by cloning it then installing all plugins configured. So,
the first execution of tmux might take a while.

## Ghostty configuration

Prerequisite: install ghostty, tmux

Install the theme used. e.g, for the catppuccin-macchiato theme:

```bash
mkdir -p $HOME/.config/ghostty/themes
curl https://raw.githubusercontent.com/catppuccin/ghostty/refs/heads/main/themes/catppuccin-macchiato.conf -o "$HOME/.config/ghostty/themes/catppuccin-macchiato"
```

Install the ghostty config:

```bash
make ghostty
```

Then reload the Ghostty config (cmd+shift+,)

## Neovim configuration

This config has been heavily inspired by the [kickstart project](https://github.com/nvim-lua/kickstart.nvim), but it
isn't a fork per say. I wanted to write the config myself and make sure I understand (almost) every piece of code / config
my neovim setup uses. Plus, I did want to make sure the config isn't bloated with stuff and keymaps and settings I'm not
gonna be using.

The kickstart config commit : 3338d39. If anything breaks in the future (maybe due to a neovim update or a plugin update),
take a look at the kickstart github and see if maybe they addressed it.

### Installation

Prerequisite: install ripgrep (telescope dependency).

(Eventually) backup the current config :

```bash
mv ${HOME}/.config/nvim ${HOME}/.config/nvim.bak
mv ${HOME}/.local/share/nvim ${HOME}/.local/share/nvim.bak
mv ${HOME}/.local/state/nvim ${HOME}/.local/state/nvim.bak
mv ${HOME}/.cache/nvim ${HOME}/.cache/nvim.bak
```

Install the config :

```bash
make nvim
```

## profile.d configuration

```bash
make profile
```

## Keyboard configuration

```bash
make keyboard
```

## PS1

Just add the content of `bash/PS1.sh` somewhere in the `/etc/bashrc` file.

## .inputrc

```bash
make inputrc
```

Then add `stty werase undef` to `/etc/bashrc`.

## Opencode

(Eventually) backup the current config :

```bash
mv ${HOME}/.config/opencode ${HOME}/.config/opencode.bak
mv ${HOME}/.local/share/opencode ${HOME}/.local/share/opencode.bak
mv ${HOME}/.local/state/opencode ${HOME}/.local/state/opencode.bak
mv ${HOME}/.cache/opencode ${HOME}/.cache/opencode.bak
```

Install this config :

```bash
make opencode
```
