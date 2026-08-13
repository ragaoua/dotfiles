SHELL := /bin/bash

.PHONY: all
all:
	@echo "Please define the targets explicitly"

.PHONY: bash
bash:
	stow --no-folding --dir bash --target "$(HOME)" home
	sudo stow --dir bash --target /etc/profile.d profile.d
	@echo "Bash config installed"

.PHONY: command_palette
command_palette:
	sudo stow --no-folding --dir command_palette --target "/usr/local/bin" bin
	stow --no-folding --dir command_palette --target "$(HOME)" home
	sudo stow --dir command_palette --target /etc/profile.d profile.d
	@echo "Command palette installed"

.PHONY: fzf
fzf:
	sudo stow --dir fzf --target /etc/profile.d profile.d
	@echo "Fzf config installed"

.PHONY: ghostty
ghostty:
	stow --no-folding --dir ghostty --target "$(HOME)" home
	sudo stow --dir ghostty --target /etc/profile.d profile.d
	@echo "Ghostty config installed. Reload Ghostty with [Cmd + Shift + ,]"

.PHONY: git
git:
	sudo stow --dir git --target /etc/profile.d profile.d
	@echo "Git config installed"

.PHONY: karabiner
karabiner:
	stow --no-folding --dir karabiner --target "$(HOME)" home
	@echo "Karabiner config installed"

.PHONY: kubernetes
kubernetes:
	sudo stow --dir kubernetes --target /etc/profile.d profile.d
	@echo "Kubernetes config installed"

.PHONY: nvim
nvim:
	stow --no-folding --dir nvim --target "$(HOME)" home
	sudo stow --dir nvim --target /etc/profile.d profile.d
	@echo "Neovim config installed"

.PHONY: opencode
opencode:
	stow --no-folding --dir opencode --target "$(HOME)" home
	@echo "OpenCode config installed"

.PHONY: podman
podman:
	sudo stow --dir podman --target /etc/profile.d profile.d
	@echo "Podman config installed"

.PHONY: tig
tig:
	stow --no-folding --dir tig --target "$(HOME)" home
	@echo "Tig config installed"

.PHONY: tmux
tmux:
	stow --no-folding --dir tmux --target "$(HOME)" home
	tmux source-file "$(HOME)/.config/tmux/tmux.conf"
	@echo "Tmux config installed and applied"
