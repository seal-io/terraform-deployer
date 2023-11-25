#!/bin/bash
API_URL_PREFIX="https://api.github.com/orgs/"
# mkdir templates.
mkdir -p templates
org_names=("walrus-catalog" "walrus-catalog-sandbox")

prepare () {
	org_name=$1
	api_url="${API_URL_PREFIX}${org_name}/repos"
	repos=$(curl -s "$api_url")
	for repo in $(echo "$repos" | jq -r '.[].name'); do
		git clone https://github.com/${org_name}/${repo} templates/${repo}
	done
}

cleanup () {
  rm -rf mirror-plugins.sh templates
}

for org_name in "${org_names[@]}"; do
	prepare "$org_name"
done

trap cleanup INT TERM EXIT

for template in templates/*; do
	if [ -d "$template" ]; then
	# Prepare implied local mirror.
	# See https://developer.hashicorp.com/terraform/cli/config/config-file#implied-local-mirror-directories.
		terraform -chdir="${template}" init &&
		terraform -chdir="${template}" providers mirror "$HOME/.terraform.d/plugins"
	fi
done
