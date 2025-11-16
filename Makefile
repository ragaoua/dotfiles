SHELL := /bin/bash

all:
	@echo "Please define the targets explicitly"

.PHONY: ghostty
ghostty:
	stow -t "$(HOME)" ghostty
	@echo "✅ Ghostty config installed. Reload Ghostty with Cmd+Shift+,"

.PHONY: nvim
nvim:
	stow -t "$(HOME)" nvim
	@echo "✅ Neovim config installed"

.PHONY: scripts
scripts:
	sudo stow -t "/usr/local/bin/" scripts
	@echo "✅ Scripts installed under /usr/local/bin"

.PHONY: tmux
tmux:
	stow -t "$(HOME)" tmux
	@echo "✅ Tmux config installed"

.PHONY: git
git:
	stow -t "$(HOME)" git
	git config --global core.excludesFile "$(HOME)/.config/git/.gitignore"
	@echo "✅ Git config installed"

.PHONY: profile
profile:
	sudo stow -t /etc/profile.d profile.d
	@echo "✅ profile.d scripts installed"

.PHONY: keyboard
keyboard:
	sudo stow -t "$(HOME)/.config/karabiner" keyboard
	@echo "✅ Keyboard config installed"

.PHONY: inputrc
inputrc:
	stow -t "$(HOME)" inputrc
	@echo "✅ .inputrc installed"
