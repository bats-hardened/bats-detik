#!/bin/sh
set -eu

url="${1:?Usage: $0 <url> <destination>}"
destination="${2:?Usage: $0 <url> <destination>}"

set -- \
  --fail \
  --silent \
  --show-error \
  --location \
  --retry 4 \
  --retry-connrefused

case "$url" in
  https://github.com/* | https://api.github.com/*)
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      set -- "$@" --header "Authorization: Bearer $GITHUB_TOKEN"
    fi
    ;;
esac

curl "$@" --output "$destination" "$url"
