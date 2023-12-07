#!/bin/bash

prepare () {
  git clone https://github.com/seal-io/modules && cd modules
}

cleanup () {
  cd .. && \
  rm -rf mirror-plugins.sh modules
}

prepare
trap cleanup INT TERM EXIT

for module_dir in */*/; do
    # Prepare implied local mirror.
    # See https://developer.hashicorp.com/terraform/cli/config/config-file#implied-local-mirror-directories.
    terraform -chdir="$module_dir" init && \
    terraform -chdir="$module_dir" providers mirror "$HOME/.terraform.d/plugins"
done

# Remove non-provider plugin files to avoid Terraform warnings.
find /var/terraform/.terraform.d/plugins -type f ! -name "terraform-provider-*" -delete
