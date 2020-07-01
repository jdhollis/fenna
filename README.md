# fenna

`fenna` is a thin wrapper for Terraform built around a set of conventions extracted from my experience introducing Terraform into teams. The overall goal is to support collaboration through a consistent developer experience.

With `fenna`, developers can develop against their own instances of a [service](#service) while ensuring the same Terraform is deployed across all [environments](#environments). This is especially handy if you are [programming with infrastructure](https://theconsultingcto.com/posts/continuous-delivery-with-terraform/#programming-with-infrastructure).

For a longer discussion of the motivations behind `fenna`, check out my post “[Terraform for Teams](https://theconsultingcto.com/posts/terraform-for-teams)”.

This documentation assumes familiarity with the basics of Terraform, so if you’re new to Terraform, you’ll want to start [here](https://learn.hashicorp.com/terraform).

Currently, `fenna` only supports AWS and Git.

## Conventions

`fenna` introduces some high-level conventions that make working with Terraform and communicating with your team simpler.

### Service

[A service is a collection of AWS resources and code that fulfills a desired function. It has a well-defined interface that other services and users can interact with. And it is something we want to deploy and test as a unit.](https://theconsultingcto.com/posts/continuous-delivery-with-terraform/#services)

### Environment

An environment is where we want to deploy a [service](#service). Each environment has a single [backend](https://www.terraform.io/docs/backends/config.html), and each environment is isolated in its own AWS account. An environment’s backend is not typically stored in the environment—instead, we create an environment dedicated to storing things like Terraform state.

### Sandbox

A sandbox is an [environment](#environment) where a developer can safely create their own instance of a service for development and testing.

### Suffix

To prevent name collisions in a [sandbox](#sandbox), a developer can configure a `suffix` that is appended to the service’s [state key](https://www.terraform.io/docs/backends/types/s3.html#key) on `init` and passed into the service’s top-level Terraform module as a variable on every `plan`.

Should developers need to collaborate on the same sandbox infrastructure, they need only set the same `suffix`.

### Root

The `root` [environment](#environment) is where access control to the other environments is managed. Similarly, a developer’s `root` [profile](#profiles) holds the credentials for accessing the `root` environment.

Each developer can name their `root` profile anything they like (which comes in handy when, like me, you’re regularly working with more than one team).

### Profiles

`fenna` uses [named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) to standardize and simplify access to each [environment](#environment).

Dependence on AWS profiles is probably the single biggest blocker to supporting other backends and providers. Pull requests to resolve this are most welcome.

`fenna` assumes profile names will follow this convention: `[root profile]-[env]`.

For example, here is a sample AWS configuration with `ops` as the `root` profile—

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

`fenna` assumes each backend configuration will be stored at the root of the `backends` repository in a file named for its corresponding [environment](/#environment)—for example, `root.tfvars`, `tools.tfvars`, `dev.tfvars`, etc.

Each file should contain the necessary [partial configuration](https://www.terraform.io/docs/backends/config.html#partial-configuration) for each backend:

```hcl
bucket         = ""
region         = ""
dynamodb_table = ""
encrypt        = true
kms_key_id     = ""
```

## Installation

If you're using [Homebrew](https://brew.sh)—

```bash
brew tap jdhollis/fenna
brew install fenna
```

Alternatively, you can [download the `fenna` script](https://raw.githubusercontent.com/jdhollis/fenna/master/fenna) and drop it somewhere in your `PATH`.

## Usage

### `bootstrap`

When creating a new service that uses `fenna`, run the following from the service’s root module:

```bash
fenna bootstrap
```

`fenna` will ask a series of questions to configure the service for everyone. (It will then follow on with the `onboard` process for you.)

Commit any changed files to the repo—this will serve as the base configuration for any developers collaborating on the service in the future.

### `onboard`

When a developer starts working on a service for the first time, they need to run the following from the service’s root module:

```bash
fenna onboard
```

This will configure the developer’s [`root`](/#root) profile and, if necessary, [`suffix`](/#suffix).

The files generated by `fenna onboard` are ignored by Git by default—they are developer-specific and should not be committed to the repository.

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
