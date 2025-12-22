# dotfiles

## Global prerequisites

Install make, stow

## Scripts set up

```bash
brew install fzf fd
make scripts
```

## Tmux configuration

Prerequisites : tmux-related scripts installed in `/usr/local/bin`.

```bash
brew install tmux
make tmux
```

When running `tmux` for the first time after that, the config will try
and bootstrap `tpm` by cloning it then installing all plugins configured. So,
the first execution of tmux might take a while.

## Ghostty configuration

Prerequisite : install tmux

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

(Eventually) backup the current config :

```bash
mv ${HOME}/.config/nvim ${HOME}/.config/nvim.bak
mv ${HOME}/.local/share/nvim ${HOME}/.local/share/nvim.bak
mv ${HOME}/.local/state/nvim ${HOME}/.local/state/nvim.bak
mv ${HOME}/.cache/nvim ${HOME}/.cache/nvim.bak
```

Install this config :

```bash
make nvim
```

Install dependencies :

```bash
# ripgrep is required for telescopes's grepping features
brew install ripgrep
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
