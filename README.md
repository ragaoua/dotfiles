# dotfiles

## Global prerequisites

```bash
brew install make stow

sudo mkdir -p /etc/profile.d
# Source scripts in /etc/profile.d, for instance:
cat >>/etc/profile <<EOF
if [ -d /etc/profile.d ] ; then
	for script in /etc/profile.d/*.sh ; do
		if [ -r "$script" ] ; then
			. "$script"
		fi
	done
fi
EOF

sudo mkdir -p /usr/local/bin # Make sure it's in the PATH
```

## AeroSpace

```bash
brew install --cask nikitabobko/tap/aerospace
brew install FelixKratz/formulae/borders FelixKratz/formulae/sketchybar jq
make aerospace
```

## Bash

```bash
make bash
```

Then:

- Add the content of `bash/PS1.sh` somewhere in the `/etc/bashrc` file.
- Add `stty werase undef` to "`/etc/bashrc`."

## Command Palette

```bash
brew install fzf jq
make command_palette
```

## Fzf

```bash
brew install fzf
make fzf
```

## Ghostty

```bash
brew install --cask ghostty
brew install tmux
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
brew install --cask karabiner-elements
make karabiner
```

## Kubernetes

```bash
brew install kubectl
make kubernetes
```

## macOS

The macOS configuration contains:

- `NSWindowShouldDragOnGesture`, stored in `macos/config/GlobalPreferences.plist`.
- The Caps Lock delay override, stored in a LaunchAgent plist that reapplies it
  whenever you log in.

Install and apply the configuration with:

```bash
make macos
```

The LaunchAgent will also run automatically at future logins. The current
global preference may require affected applications to be restarted.

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

```bash
# ripgrep for telescope, npm for installing mason packages
brew install ripgrep npm
```

(Eventually) backup the current config :

```bash
mv "${HOME}/.config/nvim" "${HOME}/.config/nvim.bak"
mv "${HOME}/.local/share/nvim" "${HOME}/.local/share/nvim.bak"
mv "${HOME}/.local/state/nvim" "${HOME}/.local/state/nvim.bak"
mv "${HOME}/.cache/nvim" "${HOME}/.cache/nvim.bak"
```

Then:

```bash
brew install neovim
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
brew install opencode
make opencode
```

## Podman

```bash
brew install podman
make podman
```

## Tig

```bash
brew install tig
make tig
```

## Tmux

```bash
brew install tmux fzf fd
make tmux
```
