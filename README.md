# Terraform Deployer

[![](https://img.shields.io/github/actions/workflow/status/seal-io/terraform-deployer/docker-build.yml?label=build)](https://github.com/seal-io/terraform-deployer/actions)
[![](https://img.shields.io/docker/image-size/sealio/terraform-deployer/main?label=docker)](https://hub.docker.com/r/sealio/terraform-deployer/tags)
[![](https://img.shields.io/github/v/tag/seal-io/terraform-deployer?label=release)](https://github.com/seal-io/terraform-deployer/releases)

This image is used for rapid deployment by [Walrus](https://github.com/seal-io/walrus), it's close to [hashicorp/terroform](https://hub.docker.com/r/hashicorp/terraform), but provides Terraform mirroring ability.

This tool is maintained by [Seal](https://github.com/seal-io).

To build specific Terraform version with the following script. 

```shell
$ docker build --build-arg TERRAFORM_VERSION=<VERSION> --tag sealio/terraform-deployer:dev -f Dockerfile . 
```

## Implied Mirroring

The [Implied Local Mirror Directories](https://developer.hashicorp.com/terraform/cli/config/config-file#implied-local-mirror-directories) power this mode.

Terraform will try all configs below `provider_installation` to select the newest Provider version available across them, this causes local mirroring cache failure due to a new remote version.

To caching succeed, Terraform Deployer searches the Provider Mirror directory(`/usr/share/terraform/providers/plugins`) and construct a proper [Terraform Client Configuration](https://developer.hashicorp.com/terraform/cli/config/config-file) as below for Terraform running.

```hcl
# find /usr/share/terraform/providers -type d -maxdepth 3 -mindepth 3
provider_installation {
  filesystem_mirror {
    path    = "/usr/share/terraform/providers/plugins"
  }
  direct {
    exclude = [
      "registry.terraform.io/hashicorp/kubernetes",
      "registry.terraform.io/hashicorp/helm",
      "registry.terraform.io/hashicorp/aws",
      ...
    ]
  }
}
```

> Please use [terraform providers mirror](https://developer.hashicorp.com/terraform/cli/commands/providers/mirror) to generate the Provider Mirror directory.

By default, this image hosts the Terraform Providers retrived from the [Walrus Catalog](https://github.com/walrus-catalog).

## Network Mirroring

Generally, when Terraform template declares its Provider version that matches or ranges in the caching versions of [Implied Mirroring](#implied-mirroring), the Implied Mirroring works well. But if out of the [Version Constraints](https://developer.hashicorp.com/terraform/language/expressions/version-constraints), the Implied Mirroring will panic.

```
╷
│ Error: Failed to query available provider packages
│
│ Could not retrieve the list of available versions for provider
```

At the same time, Implied Mirroring always outputs some annoying warning messages, even if the Provider not be used in the Terraform template.

```
2023-12-25T14:48:09.013Z [WARN]  ignoring file "registry.terraform.io/aliyun/alicloud/1.214.0.json" as possible package for registry.terraform.io/aliyun/alicloud: filename lacks expected prefix "terraform-provider-alicloud_"
...
```
> Terraform Deployer has cleaned the non-provider files in the Provider Mirror directory, so the warning messages are not presented.

Fortunately, we can reduce the preparation latency for the first deployment and not worry about the version constraints through [network_mirror](https://developer.hashicorp.com/terraform/cli/config/config-file#network_mirror).

Terraform [Provider Network Mirror Protocol](https://developer.hashicorp.com/terraform/internals/provider-network-mirror-protocol) wants [HTTPS](https://en.wikipedia.org/wiki/HTTPS) access and always verifies the CA available. But for development or private usage, we may need a way to skip insecure(CA) verification.

Terraform Deploy detects the `TF_CLI_NETWORK_MIRROR_URL` environment variable to construct the following [Terraform Client Configuration](https://developer.hashicorp.com/terraform/cli/config/config-file), and allows accessing insecure network mirror server by `TF_CLI_NETWORK_MIRROR_INSECURE_SKIP_VERIFY`.

```hcl
# TF_CLI_NETWORK_MIRROR_URL="https://example.com/v1/providers/"
provider_installation {
  network_mirror {
    url = "https://example.com/v1/providers/"
  }
}
```

# License

Copyright (c) 2023 [Seal, Inc.](https://seal.io)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [LICENSE](./LICENSE) file for details.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
