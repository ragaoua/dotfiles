#!/bin/bash
# shellcheck disable=SC2155
set -euo pipefail

declare project_name
declare repo_slug

while [ "${#}" -gt 0 ]; do
  case "${1}" in
    --gh-repo)
      if [ -z "${2}" ]; then
        echo "Missing value for --gh-repo" >&2
        exit 1
      fi
      repo_slug="${2}"
      shift 2
      ;;
    --*)
      echo "Unknown option: ${1}" >&2
      exit 1
      ;;
    *)
      if [ -n "${project_name}" ]; then
        echo "Unexpected extra argument: ${1}" >&2
        exit 1
      fi
      project_name="${1}"
      shift
      ;;
  esac
done

readonly repo_slug
readonly projects_dir="${HOME}/Projects"

if [ -z "${project_name}" ]; then
  if [ -z "${repo_slug}" ]; then
    read -r -p "Project directory name: " project_name
  else
    project_name="$(basename "${repo_slug}")"
  fi
fi

readonly project_name

if [ -z "${project_name}" ] || [[ ! "${project_name}" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo >&2 "Invalid project name: '${project_name}'. Use only letters, numbers, dashes, and underscores."
  exit 2
fi

readonly project_path="${projects_dir}/${project_name}"

if [ -e "${project_path}" ] && [ -n "$(ls -A "${project_path}" 2>/dev/null)" ]; then
  echo "Project directory exists and is not empty: ${project_path}" >&2
  exit 3
fi

if [ -n "${repo_slug}" ]; then
  readonly repo_url="git@github.com:${repo_slug}.git"
  tmux display-popup -E -T "Cloning ${repo_slug}" "git clone \"${repo_url}\" \"${project_path}\""
else
  mkdir -p "${project_path}"
fi

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${script_dir}/open_project_session.sh" "$project_name"
