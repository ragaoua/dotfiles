alias ll='ls -l --color'
alias lla='ls -lA --color'

# Change  the  current  directory then list its content
cdl() {
    if [ "$#" -gt 1 ] ; then
      echo "Usage: cdl <directory>"
      return 1
    fi

    cd "$1" || return
    ll .
}
