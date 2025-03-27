# Change  the  current  directory then list its content
cdll() {
    if [ "$#" -gt 1 ] ; then
      echo "Usage: cdll <directory>"
      return 1
    fi

    cd "$1" || return
    ls -l --color=auto
}
