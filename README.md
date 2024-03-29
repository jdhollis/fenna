# fenna

`fenna` is a thin wrapper for Terraform built around a set of conventions extracted from my experience introducing Terraform into teams. The overall goal is to support collaboration through a consistent developer experience.

With `fenna`, developers can develop against their own instances of a [service](#service) while ensuring the same Terraform is deployed across all [environments](#environments). This is especially handy if you are [programming with infrastructure](https://theconsultingcto.com/posts/continuous-delivery-with-terraform/#programming-with-infrastructure).

For a longer discussion of the motivations behind `fenna`, check out my post “[Terraform for Teams](https://theconsultingcto.com/posts/terraform-for-teams)”.

For an in-depth example of bootstrapping a multi-account setup with AWS using version 1 of `fenna`, check out “[How to Bootstrap Multiple Environments on AWS with Terraform & Fenna](https://theconsultingcto.com/posts/how-to-bootstrap-multiple-environments-on-aws-with-terraform-and-fenna/)”.

This documentation assumes familiarity with the basics of Terraform, so if you’re new to Terraform, you’ll want to start [here](https://learn.hashicorp.com/terraform).

Currently, `fenna` only supports AWS and Git.

You can find the `README` for version 1 of `fenna` [here](https://github.com/jdhollis/fenna/blob/58a0daafd3d649855f91ea7025fab8d76a2f9998/README.md).

I discuss version 2 [here](https://theconsultingcto.com/posts/fenna-2/).

## Conventions

`fenna` introduces some high-level conventions that make working with Terraform and communicating with your team simpler.

### Service

A service is a collection of AWS resources and code that fulfills a desired function. It has a well-defined interface that other services and users can interact with. And it is something we want to deploy and test as a unit.

### Environment

An environment is where we want to deploy a [service](#service). Each environment has a single [backend](https://www.terraform.io/docs/backends/config.html), and each environment is typically isolated in its own AWS account. An environment’s backend is not typically stored in the environment—instead, we create an environment dedicated to storing things like Terraform state.

### Root

The `root` [environment](#environment) is where access control to the other environments is managed. Similarly, a developer’s `root` [profile](#profiles) holds the credentials for accessing the `root` environment.

Each developer can name their `root` profile anything they like (which comes in handy when, like me, you’re regularly working with more than one team).

### Profile

`fenna` uses [named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) to standardize and simplify access to each [environment](#environment).

Dependence on AWS profiles is probably the single biggest blocker to supporting other backends and providers. Pull requests to resolve this are most welcome.

`fenna` assumes profile names will follow this convention: `[root profile]-[env]`.

For example, here is a sample AWS configuration with `ops` as the `root` profile:

#### `~/.aws/credentials`

```ini
[ops]
aws_access_key_id=[insert-access-key-id-here]
aws_secret_access_key=[insert-secret-access-key-here]
```

#### `~/.aws/config`

```ini
[profile ops]

[profile ops-tools]
source_profile = ops
role_arn = arn:aws:iam::[insert-account-id-here]:role/Ops

[profile ops-dev]
source_profile = ops
role_arn = arn:aws:iam::[insert-account-id-here]:role/Ops

[profile ops-stage]
source_profile = ops
role_arn = arn:aws:iam::[insert-account-id-here]:role/Ops

[profile ops-prod]
source_profile = ops
role_arn = arn:aws:iam::[insert-account-id-here]:role/Ops
```

### Backends

`fenna` keeps backend configuration DRY across multiple services via [Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) and symlinks. You can manually create backend configuration files at `.fenna/backends` for each service, but you’re better off extracting all backend configuration into its own repository.

`fenna` assumes each backend configuration will be stored at the root of the `backends` repository in a file named for its corresponding [environment](#environment)—for example, `root.tfvars`, `tools.tfvars`, `dev.tfvars`, etc.

Each file should contain the necessary [partial configuration](https://www.terraform.io/docs/backends/config.html#partial-configuration) for each backend:

```hcl
bucket         = ""
region         = ""
dynamodb_table = ""
encrypt        = true
kms_key_id     = ""
```

Now you only need a minimal `terraform` block:

```hcl
terraform {
  required_version = "1.5.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.4.0"
    }
  }
}
```

### Target

A target is the combination of an [environment](#environment), a [profile](#profile), and, optionally, a [suffix](#suffix).

### Suffix

To prevent name collisions within an [environment](#environment), a developer can configure a `suffix` that is appended to the service’s [state key](https://www.terraform.io/docs/backends/types/s3.html#key) on `init` and passed into the service’s top-level Terraform module as a variable on every `plan`.

Should developers need to collaborate on the same infrastructure, they need only set the same `suffix`.

To simplify usage of the `suffix` within your HCL (and automatically handle a blank `suffix`), use `local.suffix` instead of `var.suffix`.

If you don’t need a suffix, feel free to leave it blank.

## Installation

If you're using [Homebrew](https://brew.sh):

```bash
brew tap jdhollis/fenna
brew install fenna
```

Alternatively, you can [download the `fenna` script](https://raw.githubusercontent.com/jdhollis/fenna/master/fenna) and drop it somewhere in your `PATH`.

### Migrating from Version 1

If you're already using `fenna` and would like to upgrade your services to support targets, run this command from the service root:

```bash
fenna migrate
```

This will convert your existing environment or sandbox to a target and reconfigure `fenna` to support the new UI. Backups of `.fenna` and `.terraform` are made in the process (just in case).

If you don't feel like migrating, the v1 UI will continue to work as before. But any new services you bootstrap will automatically use v2.

## Usage

### `bootstrap`

When creating a new service that uses `fenna`, run the following from the service’s root module:

```bash
fenna bootstrap
```

`fenna` will ask a couple of questions to configure the service for everyone. (It will then follow on with the `onboard` process for you.)

Commit any changed files to the repo—this will serve as the base configuration for any developers collaborating on the service in the future.

### `onboard`

When a developer starts working on a service for the first time, they need to run the following from the service’s root module:

```bash
fenna onboard
```

This will configure the developer’s [`root`](#root) profile. If [targets](#target) are already configured for the repository, it will also ask which target the developer would like to use and take them through configuration of that target.

The files generated by `fenna onboard` are ignored by Git by default—they are developer-specific and should not be committed to the repository.

### `target`

When you want to use a particular target, run the following from the service’s root module:

```bash
fenna target [target name]
```

If the target already exists and is configured for you, it will update the `.fenna/target` and `.terraform` symlinks to point to the chosen target.

If the target does not exist, `fenna` will take you through configuration of that target.

And if the target exists, but you haven't configured it for your own use, `fenna` will take you through that part of the process.

### `backends`, `targets`

```bash
fenna backends
fenna targets
```

These commands simply list the available backends and targets. (You can always use `ls` instead.)


### `init`, `plan`, `apply`

```bash
fenna init
fenna plan
fenna apply
```

These commands are wrappers around `terraform`. You can pass additional arguments to `terraform` through them.

For example:

```bash
fenna init -upgrade
```

Or:

```bash
fenna plan -destroy
fenna apply
```

`init` injects the necessary backend details into `terraform` for the current [target](#target). `init` needs to be run at least once for each target.

`plan` injects the necessary variables and `.tfvars` files for the current target.

`apply` just applies the plan.

## CI/CD

`fenna` is intended for local usage, but we always want to use identical HCL across all environments whenever possible.

There is an `assume_role_arn` variable that can be added to your `provider` blocks for injecting the proper role ARN during an automated build:

```hcl
provider "aws" {
  region  = var.region
  profile = var.profile

  assume_role {
    role_arn = var.assume_role_arn
  }
}
```

In CI/CD, you'll also need to handle injecting the backend details and sensitive variables.
