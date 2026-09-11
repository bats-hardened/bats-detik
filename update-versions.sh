#!/usr/bin/env bash
set -eu

script_dir="$(cd "$(dirname "$0")" && pwd)"
dockerfile="$script_dir/Dockerfile"
temp_dir="$(mktemp -d)"

declare -a curl_args=(
  --fail
  --silent
  --show-error
  --location
  --retry 4
  --retry-connrefused
)
declare -a github_curl_args=("${curl_args[@]}")

if [ -n "${GITHUB_TOKEN:-}" ]; then
  github_curl_args+=(--header "Authorization: Bearer $GITHUB_TOKEN")
fi

latest_github_tag() {
  local repo="$1"
  local release

  release="$(curl "${github_curl_args[@]}" \
    "https://api.github.com/repos/$repo/releases/latest")"
  printf '%s' "$release" \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
}

download_sha256() {
  local url="$1"
  local archive="$2"
  local use_github_token="${3:-false}"
  local sha256

  if [[ $use_github_token == true ]]; then
    curl "${github_curl_args[@]}" --output "$archive" "$url"
  else
    curl "${curl_args[@]}" --output "$archive" "$url"
  fi
  sha256="$(sha256sum "$archive")"
  rm -f "$archive"
  printf '%s' "${sha256%% *}"
}

update_pin() {
  local version_variable="$1"
  local sha256_variable="$2"
  local version="$3"
  local sha256="$4"

  sed -i \
    -e "s/^ARG ${version_variable}=.*/ARG ${version_variable}=$version/" \
    -e "s/^ARG ${sha256_variable}=.*/ARG ${sha256_variable}=$sha256/" \
    "$dockerfile"
  echo "${version_variable}: $version" >&2
}

bats_tag="$(latest_github_tag bats-core/bats-core)"
case "$bats_tag" in
  v*) bats_version="${bats_tag#v}" ;;
  *) echo "Failed to resolve a v-prefixed Bats release tag" >&2; exit 1 ;;
esac
bats_sha256="$(download_sha256 \
  "https://github.com/bats-core/bats-core/archive/refs/tags/$bats_tag.tar.gz" \
  "$temp_dir/bats-core.tar.gz" true)"
update_pin BATS_VERSION BATS_SHA256 "$bats_version" "$bats_sha256"

kubectl_version="$(curl "${curl_args[@]}" https://dl.k8s.io/release/stable.txt)"
case "$kubectl_version" in
  v*) ;;
  *) echo "Failed to resolve a v-prefixed kubectl version" >&2; exit 1 ;;
esac
kubectl_sha256="$(download_sha256 \
  "https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl" \
  "$temp_dir/kubectl")"
update_pin KUBECTL_VERSION KUBECTL_SHA256 "$kubectl_version" "$kubectl_sha256"

helm_version="$(latest_github_tag helm/helm)"
case "$helm_version" in
  v*) ;;
  *) echo "Failed to resolve a v-prefixed Helm release tag" >&2; exit 1 ;;
esac
helm_sha256="$(download_sha256 \
  "https://get.helm.sh/helm-$helm_version-linux-amd64.tar.gz" \
  "$temp_dir/helm.tar.gz")"
update_pin HELM_VERSION HELM_SHA256 "$helm_version" "$helm_sha256"

rmdir "$temp_dir"
