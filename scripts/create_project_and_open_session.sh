#!/bin/bash
# shellcheck disable=SC2155
set -euo pipefail

project_name="${1-}"

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly projects_dir="${HOME}/Projects"

if [ -z "${project_name}" ]; then
  read -r -p "Project directory name: " project_name
fi

if [ -z "${project_name}" ]; then
  exit 0
fi
readonly project_name

mkdir -p "$projects_dir/${project_name}"

"${script_dir}/open_project_session.sh" "$project_name"
