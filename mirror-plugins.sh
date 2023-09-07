#!/bin/bash

ORG_NAME="walrus-catalog"
# GitHub API URL
API_URL="https://api.github.com/orgs/${ORG_NAME}/repos"

# mkdir templates.
mkdir -p templates

prepare () {
	repos=$(curl -s "$API_URL")
	for repo in $(echo "$repos" | jq -r '.[].name'); do
		git clone https://github.com/${ORG_NAME}/${repo} templates/${repo}
	done
}

cleanup () {
  rm -rf mirror-plugins.sh templates
}

prepare
trap cleanup INT TERM EXIT

for template in templates/*; do
	if [ -d "$template" ]; then
    # Prepare implied local mirror.
    # See https://developer.hashicorp.com/terraform/cli/config/config-file#implied-local-mirror-directories.
		terraform -chdir="${template}" init
	fi
done
