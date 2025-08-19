# Tmux configuration

```bash
mkdir -p "${HOME}/.config/tmux"
ln "tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
```

Note: when running `tmux` for the first time after that, the config will try
and bootstrap `tpm` by cloning it then installing all plugins configured. So,
the first execution of tmux might take a while.
