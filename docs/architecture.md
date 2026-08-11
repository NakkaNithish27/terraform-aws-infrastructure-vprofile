# Architecture

[← Back to README](../README.md)

## 1. Architecture Overview

This project uses Terraform as the infrastructure control layer for AWS resources.

The architecture evolved from a simple local Terraform configuration into a configuration that uses a centralized Amazon S3 backend for Terraform state.

At the infrastructure level, the core relationship is:

```text
                    Terraform Configuration
                            │
             ┌──────────────┼──────────────┐
             │              │              │
          Provider        Variables      Data Source
             │              │              │
             └──────────────┼──────────────┘
                            │
                     Terraform Graph
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
```

Terraform configuration represents the desired infrastructure, while Terraform state records the infrastructure Terraform manages. Terraform uses these representations when determining what actions are required.

The project therefore has two closely related architecture layers:

1. **Infrastructure architecture** — the AWS resources and their relationships.
2. **Terraform control architecture** — configuration, dependency resolution, state, provisioning, and remote state.

## 2. Terraform Configuration Architecture

Terraform reads all `.tf` files within the same configuration directory as a single configuration.

The files are separated by logical responsibility for human maintainability rather than because Terraform requires the separation.

The project follows this organization:

```text
terraform/
│
├── provider.tf
├── variables.tf
├── data.tf
├── keypair.tf
├── security_group.tf
├── instance.tf
└── backend.tf.example
```

The logical responsibilities are:

```text
provider.tf
    ↓
AWS provider configuration

variables.tf
    ↓
Configurable infrastructure values

data.tf
    ↓
AMI discovery

keypair.tf
    ↓
EC2 SSH key pair

security_group.tf
    ↓
Network access rules

instance.tf
    ↓
EC2 instance

backend.tf
    ↓
Remote Terraform state configuration
```

This follows the project's source material principle of separating logically distinct resources while avoiding both one large configuration file and excessive fragmentation.

## 3. AWS Provider Layer

The AWS provider establishes Terraform's connection to AWS and determines the region in which the resources are managed.

Conceptually:

```text
Terraform
    │
    ↓
AWS Provider
    │
    └── AWS Region
            │
            ├── AMI
            ├── Key Pair
            ├── Security Group
            └── EC2 Instance
```

The provider is the integration layer between Terraform and AWS.

Authentication credentials should remain outside the Terraform source configuration. The project distinguishes provider configuration from credential storage and avoids placing access keys or secret keys directly in code.

## 4. AMI Data Source

The EC2 instance requires an AMI identifier.

Rather than hard-coding an AMI ID, the configuration uses a Terraform data source to discover an appropriate AMI.

The relationship is:

```text
AWS
 │
 └── Available AMIs
          │
          ↓
     Terraform data source
          │
          ↓
       AMI ID
          │
          ↓
    EC2 instance
```

The AMI ID is therefore resolved through the Terraform configuration and referenced by the EC2 resource.

This creates a dependency relationship without manually copying an AMI identifier into the instance definition.

## 5. Key Pair Architecture

The EC2 instance requires an SSH key pair for administrative access.

The key-pair architecture is:

```text
Local SSH key generation
        │
        ├── Private key
        │     └── remains local
        │
        └── Public key
              ↓
        Terraform configuration
              ↓
        AWS Key Pair
              ↓
        EC2 Instance
```

The private key is an environment credential and should not be committed to the repository.

The AWS key-pair resource is referenced by the EC2 instance.

Conceptually:

```text
aws_key_pair
     │
     └── key_name
             ↓
        aws_instance
```

Terraform resolves this relationship through the resource reference and dependency graph.

## 6. Security Group Architecture

The security group provides the network-access boundary for the EC2 instance.

The demonstrated rules include:

```text
Security Group
│
├── Inbound
│   ├── SSH — TCP/22 — restricted source
│   └── HTTP — TCP/80 — public access
│
└── Outbound
    ├── IPv4 outbound
    └── IPv6 outbound
```

The SSH rule is restricted to a specific IP range in the practical, while HTTP is allowed from the internet.

The security group is then associated with the EC2 instance.

```text
Security Group
      │
      │ security_group_id
      ↓
EC2 Instance
```

This means the instance inherits the network access policy defined by the security group.

## 7. EC2 Instance Architecture

The EC2 instance is the primary compute resource in the demonstrated infrastructure.

Its configuration depends on several previously defined components:

```text
              AMI Data Source
                    │
                    │ AMI ID
                    ↓
Key Pair ───────→ EC2 Instance ←────── Security Group
                    │
                    │
                    ↓
              Provisioning
```

The EC2 resource therefore does not operate as an isolated resource.

Terraform resolves its references to:

- the discovered AMI
- the key pair
- the security group
- configurable values such as instance type and region/availability zone

The project uses references such as `resource_type.resource_name.attribute` to establish relationships and allow Terraform to construct the dependency graph.

## 8. Terraform Dependency Graph

The logical dependency graph can be represented as:

```text
AWS Provider
     │
     ├───────────────┐
     │               │
     ↓               ↓
AMI Data Source   Key Pair
     │               │
     │               │
     └───────┬───────┘
             │
             ↓
       EC2 Instance
             ↑
             │
      Security Group
```

The important point is that Terraform does not require the infrastructure to be written as a manually ordered shell script.

Instead, references establish relationships.

For example:

```text
aws_security_group.<name>.id
```

references an attribute of another resource.

Terraform uses these relationships to construct the dependency graph and determine execution order.

## 9. Variables and Configuration Layer

Variables provide a separation between infrastructure logic and configurable values.

The architecture becomes:

```text
                 Terraform Variables
                         │
        ┌────────────────┼────────────────┐
        │                │                │
      Region        Instance Type    Availability Zone
        │                │                │
        └────────────────┼────────────────┘
                         ↓
                Resource Configuration
```

This allows infrastructure definitions to remain reusable while values can be changed without rewriting the resource structure.

The project demonstrates variables for values such as AWS region, instance type, availability zone, key name, and web user.

The important architectural principle is:

```text
Infrastructure logic ≠ environment-specific values
```

Variables provide the boundary between them.

## 10. Provisioning Architecture

The project demonstrates Terraform provisioners for post-creation configuration.

The resulting flow is:

```text
Terraform
    │
    ↓
Create EC2
    │
    ↓
Establish SSH connection
    │
    ↓
file provisioner
    │
    ↓
Transfer deployment script
    │
    ↓
remote-exec
    │
    ↓
Execute script on EC2
    │
    ↓
Configured web host
```

Two provisioner mechanisms are demonstrated:

### `file`

Transfers a file from the Terraform execution environment to the remote EC2 host.

### `remote-exec`

Executes commands on the remote host through the configured SSH connection.

The provisioner exercise uses a supplied course companion script for the deployment workload. The repository therefore represents the infrastructure-side provisioning work rather than authorship of that script.

Provisioners are treated as an implementation mechanism demonstrated by the project, not as evidence of a broader configuration-management platform.

## 11. Terraform State Architecture

Terraform state is a central component of the architecture.

The project uses the following model:

```text
Terraform Configuration
        =
Desired state / intent

Terraform State
        =
Terraform's recorded infrastructure state

AWS Infrastructure
        =
Actual infrastructure
```

Terraform uses the state information together with the configuration and infrastructure to determine changes.

Conceptually:

```text
Desired Configuration
        │
        │
        ├──────────────┐
        │              │
        ↓              ↓
Terraform State    Real Infrastructure
        │              │
        └──────┬───────┘
               ↓
          Reconciliation
               │
               ↓
       Required Actions
```

The project demonstrates this through infrastructure creation, modification, replacement, destruction, and drift scenarios.

## 12. Configuration Drift Architecture

The project also demonstrates that Terraform only manages what has been declared.

The relationship is:

```text
Terraform Configuration
        │
        ↓
Declared Attributes
        │
        ↓
Terraform Management Scope
```

If an infrastructure property is outside that declared scope, changing it manually does not necessarily cause Terraform to detect or correct the change.

The practical demonstrates this with EC2 instance state.

The architecture therefore distinguishes:

```text
Declared / Managed
        vs.
Actual / Manually Changed
```

When the desired state is explicitly declared, Terraform can detect the difference and plan corrective action.

This is an important architectural boundary:

> **Terraform manages what the configuration declares.**

## 13. Remote State Architecture

The project evolves from local state to a remote S3 backend.

### Initial model

```text
Developer Machine
│
├── Terraform configuration
└── terraform.tfstate
```

This creates a team synchronization problem because the state exists only on the local machine.

### Remote backend model

```text
Developer A ──────┐
                   │
Developer B ──────┼──→ Amazon S3
                   │       │
Developer C ──────┘       ↓
                      Terraform State
```

The Terraform source code remains in version control:

```text
Git Repository
    │
    └── Terraform configuration
```

while the Terraform state is stored remotely:

```text
Amazon S3
    │
    └── Terraform state
```

The resulting separation is:

```text
Code  → Git
State → S3
```

This is the central state-management architecture demonstrated by the project.

## 14. S3 Backend Structure

The backend configuration follows the structure:

```hcl
terraform {
  backend "s3" {
    bucket = "<bucket-name>"
    key    = "<folder>/<filename>"
    region = "<region>"
  }
}
```

The three important backend parameters are:

| Parameter | Architectural role |
|---|---|
| `bucket` | S3 bucket containing the state |
| `key` | State object's path inside the bucket |
| `region` | AWS region containing the bucket |

The S3 bucket must exist before `terraform init` initializes the backend.

During initialization:

```text
terraform init
      │
      ↓
Initializing the backend...
      │
      ↓
Connect to S3
      │
      ↓
Validate bucket/access
      │
      ↓
Remote backend ready
```

After successful initialization, subsequent Terraform operations use the remote backend for state.

## 15. Code and State Separation

The project intentionally separates source-controlled configuration from runtime state.

```text
                    Git Repository
                         │
                         ↓
                Terraform .tf files
                         │
                         │ defines
                         ↓
                Desired Infrastructure
                         │
                         │ reconciled through
                         ↓
                 Terraform State
                         │
                         ↓
                    Amazon S3
```

This separation is important because the two artifacts have different purposes and update patterns:

| Artifact | Purpose | Location |
|---|---|---|
| `.tf` files | Infrastructure intent/configuration | Git |
| Terraform state | Recorded infrastructure state | S3 |
| `.terraform/` | Provider/plugin working files | Local/generated |
| Credentials | Authentication | External to source code |

The project's central principle is:

> **Code lives in Git, state lives in S3.**

## 16. Overall Architecture Flow

Combining the infrastructure and Terraform control layers:

```text
                         Git Repository
                              │
                              │
                    Terraform Configuration
                              │
               ┌──────────────┼──────────────┐
               │              │              │
           Provider        Variables      Data Source
               │              │              │
               └──────────────┼──────────────┘
                              │
                       Dependency Graph
                              │
             ┌────────────────┼────────────────┐
             │                │                │
          Key Pair      Security Group    AMI Lookup
             │                │                │
             └────────────────┼────────────────┘
                              │
                              ↓
                         EC2 Instance
                              │
                              ↓
                        SSH Connection
                              │
                       ┌──────┴──────┐
                       │             │
                    file        remote-exec
                       │             │
                       └──────┬──────┘
                              ↓
                       Configured Host


Terraform State
      │
      └──────────────→ Amazon S3
```

This represents the final conceptual architecture demonstrated by the project.

## 17. Security Boundaries

The demonstrated architecture includes several security boundaries.

### SSH Access

SSH is restricted through the security group rather than being opened universally.

```text
Allowed Administrative Source
             │
             ↓
          TCP/22
             │
             ↓
      Security Group
             │
             ↓
        EC2 Instance
```

### HTTP Access

HTTP is exposed through the security group for the demonstrated web workload.

```text
Internet
    │
    ↓
TCP/80
    │
    ↓
Security Group
    │
    ↓
EC2 Instance
```

### Credentials

Credentials and private keys are not part of the public repository.

```text
Terraform Source
      ≠
Credentials
      ≠
Private SSH Key
```

### State

Terraform state is treated separately from source code and stored remotely through S3.

## 18. Architecture Decisions

### Decision 1 — Separate Terraform Files by Logical Responsibility

The configuration is divided into provider, variables, data, key-pair, security-group, instance, and backend responsibilities.

**Reason:** Improve maintainability and navigation without changing Terraform's unified configuration model.

### Decision 2 — Use Resource References Instead of Hard-Coded Relationships

Resources reference other resources through Terraform expressions.

**Reason:** Terraform can resolve the dependency relationship dynamically and construct the dependency graph.

```text
Resource A
    ↓
attribute reference
    ↓
Resource B
```

### Decision 3 — Parameterize Configuration with Variables

Configurable values are separated from resource definitions.

**Reason:** Avoid embedding every environment-specific value directly into the infrastructure definition.

### Decision 4 — Use Data-Driven AMI Discovery

The EC2 instance obtains its AMI through a data source.

**Reason:** Avoid relying solely on a manually copied AMI identifier.

### Decision 5 — Introduce Remote State with S3

The project progresses from local state to centralized S3-backed state.

**Reason:** A local state file does not provide a shared team source of truth.

**Result:**

```text
Terraform Code → Git
Terraform State → S3
```

### Decision 6 — Demonstrate Provisioners Without Treating Them as the Overall Deployment Architecture

Provisioners were used because they were part of the practical.

They demonstrate:

- file transfer
- remote command execution
- SSH-based post-creation configuration

However, the project does not claim to have built a general configuration-management system.

## 19. Architecture Boundaries

This architecture deliberately stops at the capabilities demonstrated by the practical.

It does not include:

```text
Terraform Modules
        ✗

Terraform CI/CD
        ✗

Terraform-managed VPC
        ✗

Kubernetes infrastructure
        ✗

Enterprise Terraform governance
        ✗

Production infrastructure platform
        ✗
```

The final “What Next” material introduces modules as a future abstraction over resources and identifies VPC and Kubernetes Terraform work as upcoming areas. It does not demonstrate their implementation in this project.

## 20. Architecture Summary

The project's architecture can be compressed into five layers:

```text
┌─────────────────────────────────────────┐
│  1. Configuration                       │
│     Terraform .tf files                 │
├─────────────────────────────────────────┤
│  2. Dependency Model                    │
│     Provider / Data / Resources         │
├─────────────────────────────────────────┤
│  3. AWS Infrastructure                  │
│     Key Pair / SG / EC2                 │
├─────────────────────────────────────────┤
│  4. Provisioning & State                │
│     Provisioners / Outputs / State      │
├─────────────────────────────────────────┤
│  5. Remote State                        │
│     Amazon S3 Backend                   │
└─────────────────────────────────────────┘
```

The central engineering model is:

```text
Terraform Configuration
        ↓
Dependency Graph
        ↓
AWS Infrastructure
        ↓
Terraform State
        ↓
Remote S3 State
```

The project therefore demonstrates not only how to create AWS resources with Terraform, but also how Terraform's **configuration, dependency, lifecycle, provisioning, and state-management models fit together as one infrastructure system**.

[← Back to README](../README.md)
