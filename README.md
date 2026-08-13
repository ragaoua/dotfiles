# dotfiles

## Global prerequisites

Install make and stow.

## Bash

```bash
make bash
```

Then:

- Add the content of `bash/PS1.sh` somewhere in the `/etc/bashrc` file.
- Add `stty werase undef` to "`/etc/bashrc`."

## Command Palette

Prerequisites: install `fzf` and `jq`

```bash
make command_palette
```

## Fzf

```bash
make fzf
```

## Ghostty

Prerequisite: install tmux.

```bash
make ghostty
```

### Theme

Install a theme. e.g:

```bash
mkdir -p "$HOME/.config/ghostty/themes"
curl \
    "https://raw.githubusercontent.com/catppuccin/ghostty/refs/heads/main/themes/catppuccin-macchiato.conf" \
    -o "$HOME/.config/ghostty/themes/catppuccin-macchiato"
```

### Background

Put a file named "background.png" in the "$HOME/.config/ghostty/" directory. It
will be picked up by the config to use as the background. If missing, keeps the
default background.

Then reload the Ghostty config (Cmd + Shift + ,).

## Git

```bash
make git
```

## Karabiner

```bash
make karabiner
```

## Kubernetes

```bash
make kubernetes
```

## Neovim

This config has been heavily inspired by the [kickstart
project](https://github.com/nvim-lua/kickstart.nvim), but it isn't a fork per
say. I wanted to write the config myself and make sure I understand (almost)
every piece of code / config my neovim setup uses. Plus, I did want to make
sure the config isn't bloated with stuff and keymaps and settings I'm not gonna
be using.

The kickstart config commit : 3338d39. If anything breaks in the future (maybe
due to a neovim update or a plugin update), take a look at the kickstart github
and see if maybe they addressed it.

### Installation

Prerequisite: install ripgrep (telescope dependency) and npm (to install Mason
packages).

(Eventually) backup the current config :

```bash
mv "${HOME}/.config/nvim" "${HOME}/.config/nvim.bak"
mv "${HOME}/.local/share/nvim" "${HOME}/.local/share/nvim.bak"
mv "${HOME}/.local/state/nvim" "${HOME}/.local/state/nvim.bak"
mv "${HOME}/.cache/nvim" "${HOME}/.cache/nvim.bak"
```

Then:

```bash
make nvim
```

## Opencode

(Eventually) backup the current config :

```bash
mv "${HOME}/.config/opencode" "${HOME}/.config/opencode.bak"
mv "${HOME}/.local/share/opencode" "${HOME}/.local/share/opencode.bak"
mv "${HOME}/.local/state/opencode" "${HOME}/.local/state/opencode.bak"
mv "${HOME}/.cache/opencode" "${HOME}/.cache/opencode.bak"
```

Then:

```bash
make opencode
```

## Podman

```bash
make podman
```

## Tig

```bash
make tig
```

## Tmux

Prerequisite: install fzf and fd (used by my custom tmux scripts).

```bash
make tmux
```

When running `tmux` for the first time after that, the config will try
and bootstrap `tpm` by cloning it then installing all plugins configured. So,
the first execution of tmux might take a while.
