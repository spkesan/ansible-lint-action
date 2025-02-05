#! /usr/bin/env bash

set -Eeuo pipefail
set -x

# Filter out arguments that are not available to this action
# args:
#   $@: Arguments to be filtered
parse_args() {
  local opts=""
  while (( "$#" )); do
    case "$1" in
      -q|--quiet)
        opts="$opts -q"
        shift
        ;;
      -c)
        opts="$opts -c $2"
        shift 2
        ;;
      -p)
        opts="$opts -p"
        shift
        ;;
      -r)
        opts="$opts -r $2"
        shift 2
        ;;
      -R)
        opts="$opts -R"
        shift
        ;;
      -t)
        opts="$opts -t $2"
        shift 2
        ;;
      -x)
        opts="$opts -x $2"
        shift 2
        ;;
      --exclude)
        opts="$opts --exclude=$2"
        shift 2
        ;;
      --no-color)
        opts="$opts --no-color"
        shift
        ;;
      --parseable-severity)
        opts="$opts --parseable-severity"
        shift
        ;;
      --) # end argument parsing
        shift
        break
        ;;
      -*) # unsupported flags
        >&2 echo "ERROR: Unsupported flag: '$1'"
        exit 1
        ;;
      *) # positional arguments
        shift  # ignore
        ;;
    esac
  done

  # set remaining positional arguments (if any) in their proper place
  eval set -- "$opts"

  echo "${opts/ /}"
  return 0
}

# Generates client.
# args:
#   $@: additional options
# env:
#   [required] TARGETS : Files or directories (i.e., playbooks, tasks, handlers etc..) to be linted
ansible::lint() {
  : "${TARGETS?No targets to check. Nothing to do.}"
  : "${GITHUB_WORKSPACE?GITHUB_WORKSPACE has to be set. Did you use the actions/checkout action?}"
  pushd "${GITHUB_WORKSPACE}"

  # Packages to install
  PACKAGES_TO_INSTALL="$OVERRIDE"

  # Add ansible-lint to the list of packages to install if not specified in override-deps
  if [[ $PACKAGES_TO_INSTALL != *"ansible-lint"* ]]; then
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL ansible-lint"
  fi

  # Install packages
  [[ -n "${PACKAGES_TO_INSTALL-}" ]] && pip install ${PACKAGES_TO_INSTALL} && pip check
  >&2 echo "Completed installing dependencies..."

  local opts
  opts=$(parse_args $@ || exit 1)

  # Enable recursive glob patterns, such as '**/*.yml'.
  shopt -s globstar
  ansible-lint -v --force-color $opts ${TARGETS}
  shopt -u globstar
}


args=("$@")

if [ "$0" = "${BASH_SOURCE[*]}" ] ; then
  >&2 echo -E "\nRunning Ansible Lint...\n"
  ansible::lint "${args[@]}"
fi
