# Terraform AWS Infrastructure Provisioning

A Terraform-based AWS infrastructure project demonstrating declarative resource provisioning, infrastructure lifecycle management, configuration parameterization, remote provisioning, state extraction, and centralized S3-backed Terraform state.

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/62e654fd-9ae8-4c2f-ab53-74e8b779f9d9" />


## Overview

This project demonstrates how Terraform can be used to provision and manage AWS infrastructure through declarative configuration.

The implementation progressively covers:

- AWS resource configuration with Terraform
- EC2 instance provisioning
- AMI discovery through Terraform data sources
- Key pair and security group configuration
- Cross-resource dependencies
- Terraform variables and parameterized configuration
- Infrastructure lifecycle and replacement behavior
- Configuration drift
- Remote provisioning with Terraform provisioners
- Terraform outputs and state-derived information
- Remote Terraform state using an Amazon S3 backend

The project is focused on **Terraform infrastructure engineering**, rather than application development.

## Ownership & Scope

I personally performed the Terraform configuration, AWS infrastructure setup, lifecycle experimentation, provisioning configuration, state-output configuration, remote-backend configuration, and validation activities represented in this repository.

The practical also used supplied and third-party artifacts. In particular:

- The web deployment script used in the provisioner exercise was provided as a course companion artifact.
- The website template deployed by the script originated from a third party.
- These artifacts are therefore not presented as original application or script development.

The engineering contribution represented here is the **infrastructure provisioning, configuration, lifecycle management, state management, and validation around the workload**.

## Architecture

At a high level, Terraform acts as the infrastructure control layer:

```text
                    Terraform Configuration
                            │
             ┌──────────────┼──────────────┐
             │              │              │
          Provider        Variables      Data Source
             │              │              │
             └──────────────┼──────────────┘
                            │
                     Resource Graph
                            │
             ┌──────────────┼──────────────┐
             │              │              │
        Key Pair      Security Group    EC2 Instance
                                            │
                                            │
                                      Provisioning
                                            │
                                   ┌────────┴────────┐
                                   │                 │
                                file            remote-exec
                                   │                 │
                                   └────────┬────────┘
                                            │
                                      Configured Host


Terraform State
      │
      ├── Local state during initial exercises
      │
      └── S3 Remote Backend
```

For the detailed architecture and state-management model:

**[Architecture →](docs/architecture.md)**

## Engineering Work

### 1. Declarative AWS Infrastructure

Terraform configuration was used to define the AWS infrastructure rather than creating the resources manually.

The configuration includes:

- AWS provider configuration
- EC2 instance
- AMI data lookup
- EC2 key pair
- Security group
- Resource relationships and references

### 2. Configuration Parameterization

Terraform variables were introduced to separate configurable values from infrastructure definitions.

This allows values such as:

- AWS region
- instance type
- availability zone
- key name
- web user

to be managed independently from the resource configuration.

### 3. Infrastructure Lifecycle

The project examines Terraform's lifecycle behavior through:

```text
terraform init
      ↓
terraform fmt
      ↓
terraform validate
      ↓
terraform plan
      ↓
terraform apply
      ↓
Infrastructure changes
      ↓
terraform destroy
```

The practical also demonstrates the difference between changes that can be made in place and changes that require resource replacement.

### 4. Configuration Drift

The project includes a practical examination of configuration drift by changing the actual AWS instance state outside Terraform and comparing it with Terraform's declared configuration.

This demonstrates an important distinction between:

```text
Terraform configuration
        ↓
Terraform state
        ↓
Actual infrastructure
```

and why Terraform's understanding of infrastructure depends on what it is configured to manage.

### 5. Remote Provisioning

Terraform provisioners were used to demonstrate post-creation configuration of an EC2 instance.

The practical uses:

- `file` provisioner to transfer a script
- `remote-exec` provisioner to execute commands through SSH

The provisioner workflow is:

```text
EC2 created
    ↓
SSH connection
    ↓
web.sh transferred
    ↓
Execute permission granted
    ↓
Script executed remotely
    ↓
Web server configured
```

The deployment script itself is treated as a supplied course artifact rather than original application-development work.

### 6. Terraform Outputs

Terraform `output` blocks were used to expose resource attributes such as:

- public IP
- private IP
- instance information

The project also demonstrates `local-exec` for exporting resource information to a local file.

### 7. Remote Terraform State

The project progresses from local Terraform state to a centralized S3-backed remote state.

The resulting model is:

```text
Terraform Source Code
        │
        └── Git repository

Terraform State
        │
        └── Amazon S3
```

This separation allows Terraform state to be shared centrally rather than maintained independently on individual machines.

For implementation details:

**[Implementation →](docs/implementation.md)**

## Validation

Validation was performed at multiple levels:

### Configuration Validation

```bash
terraform fmt
terraform validate
```

### Change Validation

```bash
terraform plan
```

was used to inspect proposed infrastructure changes before applying them.

### Infrastructure Validation

The resulting AWS resources were checked after Terraform execution.

### Lifecycle Validation

Infrastructure changes, replacement behavior, failed execution scenarios, and configuration drift were examined during the practical.

### Remote State Validation

The S3 backend was verified by confirming that Terraform state was stored in the configured S3 location rather than remaining solely in the local project directory.

Detailed validation methodology and evidence mapping are documented here:

**[Validation →](docs/validation.md)**

## Project Boundaries

This project demonstrates Terraform-based AWS infrastructure provisioning and state management.

It does **not** establish:

- Terraform module implementation
- Terraform CI/CD pipelines
- Terraform-managed VPC architecture
- Kubernetes infrastructure managed with Terraform
- production-grade Terraform governance
- enterprise-scale infrastructure automation
- development of the application workload
- authorship of the supplied web deployment script
- development of the third-party website template

Terraform modules are introduced as a subsequent learning direction but were not implemented as part of this project.

Further boundaries and possible extensions are documented here:

**[Limitations & Future Work →](docs/limitations-and-future-work.md)**

## Technologies

- Terraform
- AWS
- Amazon EC2
- Amazon S3
- HCL
- SSH
- Bash
- Git

## Evidence

High-signal project evidence can be found in:

**[Evidence →](evidence/screenshots/)**

Evidence should represent the completed environment personally performed during the practical and should be sanitized before public publication.

## Repository Structure

```text
terraform-aws-infrastructure/
│
├── README.md
├── .gitignore
├── .terraform.lock.hcl
│
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── data.tf
│   ├── keypair.tf
│   ├── security_group.tf
│   ├── instance.tf
│   └── backend.tf.example
│
├── docs/
│   ├── architecture.md
│   ├── implementation.md
│   ├── validation.md
│   └── limitations-and-future-work.md
│
└── evidence/
    └── screenshots/
```

## Documentation

| Document | Purpose |
|---|---|
| [Architecture](docs/architecture.md) | Architecture, resource relationships, dependency model, and state architecture |
| [Implementation](docs/implementation.md) | Terraform configuration and implementation sequence |
| [Validation](docs/validation.md) | Validation strategy, results, and evidence mapping |
| [Limitations & Future Work](docs/limitations-and-future-work.md) | Current boundaries and future engineering evolution |

## Security

Do not commit:

- AWS access keys
- AWS secret keys
- private SSH keys
- passwords
- tokens
- sensitive Terraform state
- environment-specific secrets

Environment-specific values should be replaced with placeholders or examples before publication.

Terraform state should not be treated as ordinary source code. The project demonstrates remote state through Amazon S3 to separate infrastructure state from the Terraform source configuration.

---

## Project Position

This repository represents a focused Terraform/AWS infrastructure engineering project.

The primary capability demonstrated is:

> **Using Terraform to declaratively provision, modify, validate, and manage AWS infrastructure while understanding Terraform's dependency, lifecycle, provisioning, and state-management models.**
