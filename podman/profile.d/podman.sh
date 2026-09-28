alias pc="podman-compose"

__podman_machine="$(podman machine inspect --format '{{.State}} {{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
if [ "$__podman_machine" == "running" ]; then
  export DOCKER_HOST="unix://${__podman_machine#* }"
  export TESTCONTAINERS_RYUK_DISABLED=true
fi
unset __podman_machine
