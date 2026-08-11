# Limitations and Future Work

[← Back to README](../README.md)

## 1. Purpose

This document defines the boundaries of the current Terraform AWS infrastructure project and identifies the next engineering capabilities that follow from the learning material.

The current foundation includes:

```text
Provider configuration
        ↓
Resource definitions
        ↓
Data sources
        ↓
Multi-file organization
        ↓
Cross-resource references
        ↓
Terraform state
        ↓
Lifecycle management
        ↓
Provisioners
        ↓
Remote S3 state
```

The next stage is to build on this foundation progressively.

---

## 2. Current Project Scope

The current project demonstrates:

- AWS provider configuration
- Terraform resource definitions
- AMI data lookup
- EC2 instance provisioning
- EC2 key-pair configuration
- Security-group configuration
- Cross-resource references
- Terraform variables
- Infrastructure lifecycle operations
- Configuration drift concepts
- Terraform outputs
- `local-exec`
- `file` provisioner
- `remote-exec` provisioner
- SSH-based remote provisioning
- S3 Terraform backend

---

# 3. Limitations

## 3.1 Resource-Based Configuration Only

The project primarily uses individual Terraform resources such as:

```text
aws_instance
aws_key_pair
aws_security_group
```

This provides granular control and makes the underlying infrastructure relationships visible.

However, the configuration does not yet demonstrate reusable Terraform modules.

The current model is:

```text
Resources
    ↓
Raw building blocks
    ↓
Full control and visibility
```

Modules are intentionally outside the current implementation scope.

---

## 3.2 No Terraform Module Implementation

Terraform modules were introduced as the next abstraction layer but were not implemented in this project.

A module packages multiple Terraform resources into a reusable configuration.

Conceptually:

```text
Module
  │
  ├── Resource A
  ├── Resource B
  ├── Resource C
  └── Resource D
```

The current project does not demonstrate:

- module creation
- module inputs
- module outputs
- module composition
- module versioning
- consumption of registry modules

The current project therefore establishes resource fundamentals before introducing module abstraction.

---

## 3.3 Provisioner State Limitation

The project uses Terraform provisioners to demonstrate post-creation configuration.

The workflow is:

```text
EC2 creation
      ↓
file provisioner
      ↓
remote-exec
      ↓
Operating-system configuration
```

The limitation is that Terraform manages the resource lifecycle but does not maintain detailed state for everything the remote script changes inside the operating system.

For example:

```text
Terraform
    ↓
Creates EC2
    ↓
Runs web.sh
    ↓
Apache installed
    ↓
Website files created
```

If someone later modifies or deletes the website files manually, Terraform does not automatically represent those internal filesystem changes as managed resource state.

Therefore:

```text
Resource lifecycle
    → Terraform managed

Remote configuration state
    → Not fully represented by Terraform
```

---

## 3.4 Provisioners Are Not the Preferred General Configuration Model

Provisioners are useful for demonstrating remote execution and for situations where an action must occur during resource creation.

However, they have state-management limitations and should not be presented as a complete configuration-management solution.

The current project demonstrates:

```text
Provisioner
    ↓
Post-creation action
```

rather than:

```text
Provisioner
    ↓
Complete configuration management
```

Future work can explore pre-built images and configuration-management tools.

---

## 3.5 No Packer-Based Image Pipeline

The current project does not use Packer to build a pre-configured AMI.

The current provisioner workflow is:

```text
Base AMI
   ↓
EC2 launch
   ↓
Provisioner
   ↓
Install/configure software
```

A future image-based approach could be:

```text
Base Image
    ↓
Packer
    ↓
Configured AMI
    ↓
Terraform
    ↓
EC2 launch
    ↓
Ready instance
```

This can provide more predictable and consistent instance initialization.

---

## 3.6 Limited Infrastructure Architecture

The current project focuses primarily on a single EC2-based workload.

It does not implement a broader AWS network architecture such as:

```text
VPC
├── Public Subnet
├── Private Subnet
├── Internet Gateway
├── Route Tables
└── NAT Gateway
```

VPC automation is intentionally left for future Terraform work.

The intended progression is:

```text
Understand VPC manually
        ↓
Create manually
        ↓
Understand dependencies
        ↓
Recreate with Terraform
```

---

## 3.7 No Kubernetes Terraform Implementation

The project does not implement Terraform-based Kubernetes cluster management.

It therefore does not demonstrate:

- Kubernetes cluster provisioning with Terraform
- Kubernetes provider usage
- Terraform-managed Kubernetes resources
- AWS Kubernetes cluster architecture
- Terraform-based Kubernetes lifecycle management

Kubernetes is a later application of Terraform rather than part of this project.

---

## 3.8 No Terraform CI/CD Pipeline

The project does not implement an automated Terraform CI/CD workflow.

There is currently no demonstrated pipeline for:

```text
Git Push
    ↓
Terraform fmt
    ↓
Terraform validate
    ↓
Terraform plan
    ↓
Approval
    ↓
Terraform apply
```

The project demonstrates Terraform execution from the configured environment rather than automated infrastructure delivery through a CI/CD system.

---

## 3.9 Limited State Governance

The project introduces an S3 remote backend, providing centralized state storage.

The resulting model is:

```text
Terraform Code
      ↓
Git

Terraform State
      ↓
S3
```

This is an improvement over purely local state.

However, the project does not establish a complete enterprise state-management platform.

When using S3 directly, operational concerns include:

- bucket permissions
- encryption
- versioning
- access control
- state protection

Therefore:

```text
S3 backend
    ≠
Complete enterprise Terraform governance
```

---

## 3.10 No Enterprise Terraform Governance

The project does not implement:

- centralized policy enforcement
- organization-wide Terraform standards
- advanced state governance
- enterprise access-control design
- approval workflows
- policy-as-code
- centralized Terraform execution management

These are outside the current learning scope.

---

## 3.11 No Production-Grade Infrastructure Claim

The infrastructure demonstrated in this project should not be interpreted as a production-ready AWS platform.

The project is primarily a learning and portfolio implementation focused on Terraform fundamentals.

It does not establish:

```text
High availability
        ✗

Multi-AZ architecture
        ✗

Auto scaling
        ✗

Load balancing
        ✗

Production networking
        ✗

Disaster recovery
        ✗

Enterprise security architecture
        ✗
```

These would require additional AWS architecture work beyond the current project.

---

## 3.12 Application Workload Is Not the Primary Engineering Contribution

The EC2 instance is used to demonstrate Terraform infrastructure and provisioning.

The web deployment script used in the provisioner exercise was supplied as a course companion artifact.

The website template deployed by that script originated from a third party.

Therefore, this project does not claim:

- authorship of the deployment script
- authorship of the website template
- application-development expertise based on the deployed website

The engineering contribution represented here is the infrastructure automation around the workload.

---

# 4. Future Work

## 4.1 Terraform Modules

The most direct next Terraform abstraction is modules.

The current resource-based model is:

```text
Terraform
   ↓
Resource
   ↓
Resource
   ↓
Resource
```

The future module-based model is:

```text
Terraform
   ↓
Module
   ↓
Multiple Resources
```

The module approach provides:

- reuse
- standardization
- abstraction
- faster infrastructure creation
- encapsulation of resource relationships

A future project could create or consume a module for a common infrastructure pattern such as:

```text
EC2 Web Server Module
        │
        ├── Security Group
        ├── Key Pair
        └── EC2 Instance
```

---

## 4.2 Terraform Registry Workflow

Future Terraform work should continue using the Terraform Registry as the primary discovery source.

The resource workflow is:

```text
Terraform Registry
        ↓
Browse Providers
        ↓
AWS
        ↓
Documentation
        ↓
Find Resource
        ↓
Example Usage
        ↓
Modify
        ↓
Test
```

The module workflow is:

```text
Terraform Registry
        ↓
Browse Modules
        ↓
Select Provider
        ↓
Find Module
        ↓
Read Inputs/Outputs
        ↓
Use Module
        ↓
Test
```

The registry is part of the ongoing Terraform engineering workflow.

---

## 4.3 AWS VPC with Terraform

The next major AWS infrastructure extension is VPC management.

The intended progression is:

```text
AWS VPC
    ↓
Understand manually
    ↓
Create manually
    ↓
Understand dependencies
    ↓
Recreate with Terraform
```

A future Terraform VPC project could include:

```text
VPC
│
├── Public Subnet
├── Private Subnet
├── Internet Gateway
├── Route Tables
├── NAT Gateway
└── Security Groups
```

This would extend the current EC2-focused infrastructure into a more complete AWS network architecture.

---

## 4.4 Kubernetes with Terraform

Another future application is Kubernetes infrastructure management.

The future progression would be:

```text
Terraform Fundamentals
        ↓
AWS Infrastructure
        ↓
AWS VPC
        ↓
Kubernetes on AWS
        ↓
Terraform-managed Kubernetes infrastructure
```

This would extend the project from traditional cloud infrastructure into container orchestration.

---

## 4.5 Improve Remote State Architecture

The current project uses S3 for remote state.

A future implementation could deepen the state-management design by addressing the operational concerns associated with managing S3 directly:

```text
S3 Bucket
    │
    ├── Access control
    ├── Encryption
    ├── Versioning
    └── State protection
```

The goal would be to move from:

```text
Remote state storage
```

toward:

```text
Remote state governance
```

---

## 4.6 Configuration Management Beyond Provisioners

The current project demonstrates:

```text
Terraform
    ↓
EC2
    ↓
file
    ↓
remote-exec
```

A future architecture could separate infrastructure lifecycle from operating-system configuration:

```text
Terraform
    ↓
EC2 infrastructure

Packer
    ↓
Machine image

Ansible / configuration management
    ↓
Operating-system/application configuration
```

This would address the state-management limitation of provisioners.

---

## 4.7 Automated Terraform Workflow

A future project can introduce CI/CD around Terraform:

```text
Developer
    ↓
Git Push
    ↓
CI
    ├── terraform fmt
    ├── terraform validate
    └── terraform plan
             ↓
        Review / Approval
             ↓
        terraform apply
             ↓
        AWS
```

This would turn the current manually executed Terraform workflow into an automated infrastructure delivery process.

---

## 4.8 Reusable Infrastructure Patterns

Once modules are introduced, repeated infrastructure patterns can be standardized.

For example:

```text
modules/
├── ec2-web/
├── security-group/
├── vpc/
└── application-stack/
```

A higher-level project could then compose them:

```text
Application Environment
        │
        ├── VPC Module
        ├── Security Module
        ├── EC2 Module
        └── Application Module
```

This follows the resources-to-abstractions progression.

---

# 5. Recommended Evolution Path

The project should evolve incrementally rather than attempting all future capabilities at once.

The recommended sequence is:

```text
CURRENT
Terraform resources
        ↓
CURRENT
S3 remote state
        ↓
NEXT
Terraform modules
        ↓
NEXT
AWS VPC with Terraform
        ↓
NEXT
Configuration management / image baking
        ↓
NEXT
Terraform CI/CD
        ↓
NEXT
Kubernetes with Terraform
```

This preserves the learning principle:

```text
Primitives
    ↓
Abstractions
    ↓
Larger infrastructure
    ↓
Automation
    ↓
Platform-level usage
```

The broader progression is:

```text
Resources → Modules
Manual → Automated
```

---

# 6. Future Portfolio Position

The current project should be positioned as the **Terraform foundation project** rather than as a complete infrastructure platform.

Its strongest portfolio value is demonstrating understanding of:

```text
Terraform
   ↓
Provider
   ↓
Resources
   ↓
Dependencies
   ↓
State
   ↓
Lifecycle
   ↓
Provisioning
   ↓
Remote State
```

Future projects can then demonstrate progression:

```text
Project 1
Terraform AWS Fundamentals
        ↓
Project 2
Terraform Modules / Reusable Infrastructure
        ↓
Project 3
Terraform AWS VPC
        ↓
Project 4
Terraform + CI/CD
        ↓
Project 5
Terraform + Kubernetes
```

This makes the portfolio progression visible rather than attempting to make a single project demonstrate every Terraform capability.

---

# 7. What Should Not Be Claimed

Until the corresponding work is actually implemented, this project should not claim:

- Terraform module development
- Terraform CI/CD
- Terraform-managed VPC architecture
- Kubernetes cluster management with Terraform
- enterprise Terraform governance
- production-grade infrastructure architecture
- Packer-based image pipelines
- Ansible-based configuration management
- enterprise-scale remote-state management

The README and supporting documents should distinguish between:

```text
Implemented
```

and:

```text
Future Work
```

This keeps the project technically defensible during interviews.

---

# 8. Future Work Matrix

| Future Capability | Current Status | Why It Matters |
|---|---|---|
| Terraform resources | Implemented | Foundation for infrastructure management |
| Terraform variables | Implemented | Configuration reuse |
| Cross-resource dependencies | Implemented | Declarative infrastructure relationships |
| Lifecycle management | Implemented | Change/replacement understanding |
| Provisioners | Implemented | Post-creation configuration demonstration |
| Terraform outputs | Implemented | Resource information exposure |
| S3 remote state | Implemented | Centralized state |
| Terraform modules | Future | Reuse and abstraction |
| AWS VPC with Terraform | Future | Larger AWS infrastructure architecture |
| Packer | Future | Pre-baked machine images |
| Configuration management | Future | State-aware OS/application configuration |
| Terraform CI/CD | Future | Automated infrastructure delivery |
| Kubernetes with Terraform | Future | Container-orchestration infrastructure |
| Enterprise governance | Future | Policy, access, and organizational controls |

---

# 9. Final Perspective

The current project is intentionally limited.

Those limitations are useful because they define the boundary of what has actually been learned and implemented.

The current foundation establishes:

```text
Provider
   ↓
Resource
   ↓
Dependency
   ↓
State
   ↓
Lifecycle
   ↓
Provisioning
   ↓
Remote State
```

The next level introduces abstraction:

```text
Resources
   ↓
Modules
```

The following level expands infrastructure scope:

```text
EC2
   ↓
VPC
   ↓
Kubernetes
```

The automation layer can then expand the delivery model:

```text
Manual Terraform
   ↓
Terraform CI/CD
```

And the configuration model can evolve from provisioners toward more predictable approaches:

```text
Provisioners
   ↓
Packer / Configuration Management
```

The central progression is:

> **Learn the primitives deeply, then introduce abstractions and larger infrastructure systems without losing the ability to reason about the underlying resources.**

[← Back to README](../README.md)
