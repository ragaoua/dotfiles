PS1='[\[$(if [[ $EUID -eq 0 ]]; then echo "\e[91m"; else echo "\e[33m"; fi)\]\u\[\e[00m\]@\[\e[36m\]\w\[\e[m\]\[\e[32m\]$(git branch --show-current 2>/dev/null | sed "s/.*/ (&)/")\[\e[00m\]] $ '

