# Implementation

[← Back to README](../README.md)

## 1. Implementation Overview

This project was implemented progressively, starting with a basic Terraform configuration for AWS infrastructure and then extending it with reusable configuration, lifecycle experimentation, provisioning, state extraction, and remote state.

The implementation flow was:

```text
AWS Provider
    ↓
AMI Data Source
    ↓
Key Pair + Security Group
    ↓
EC2 Instance
    ↓
Terraform Lifecycle Operations
    ↓
Variables
    ↓
Provisioners
    ↓
Outputs + local-exec
    ↓
S3 Remote Backend
```

The project used multiple `.tf` files for logical organization. Terraform still evaluates the files in a configuration directory as one configuration.

---

## 2. Terraform Configuration Structure

The final repository organizes the Terraform implementation as:

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

The responsibilities are:

| File | Responsibility |
|---|---|
| `provider.tf` | AWS provider configuration |
| `variables.tf` | Configurable Terraform variables |
| `data.tf` | AMI discovery |
| `keypair.tf` | EC2 SSH key pair |
| `security_group.tf` | EC2 network access rules |
| `instance.tf` | EC2 instance and related provisioning/output logic |
| `backend.tf.example` | Sanitized S3 backend configuration pattern |

The filenames are for human organization. Terraform loads all `.tf` files in the same configuration directory together.

---

## 3. AWS Provider Configuration

The AWS provider was configured as the Terraform integration layer with AWS.

A minimal provider configuration follows the demonstrated pattern:

```hcl
provider "aws" {
  region = var.region
}
```

The region is parameterized through a Terraform variable rather than being embedded directly into the resource definitions.

Authentication credentials are intentionally not stored in the Terraform source code.

The implementation therefore separates:

```text
Provider Configuration
        ≠
Credential Storage
```

Credentials should be supplied through the appropriate external AWS authentication mechanism.

---

## 4. Terraform Variables

Variables were introduced after the initial infrastructure configuration to separate configurable values from infrastructure definitions.

The implementation uses variables for values such as:

```text
region
instance_type
availability_zone
key_name
web_user
```

A representative variable definition is:

```hcl
variable "region" {
  description = "AWS region"
  type        = string
}
```

The resource configuration can then reference:

```hcl
region = var.region
```

The resulting implementation model is:

```text
terraform.tfvars / variable values
            │
            ↓
      Terraform Variables
            │
            ↓
      Resource Configuration
```

This makes infrastructure values easier to change without rewriting the resource structure.

### Variable lookup

The practical also demonstrates variable-based lookup for AMI selection, using a map keyed by region.

Conceptually:

```text
AWS Region
    │
    ↓
AMI Map
    │
    ↓
Matching AMI ID
    │
    ↓
EC2 Instance
```

This allows the same configuration pattern to select an appropriate AMI based on the configured region.

---

## 5. AMI Data Source

The EC2 instance requires an AMI ID.

Instead of relying exclusively on a manually copied AMI identifier, the implementation uses a Terraform data source to discover an appropriate image.

The conceptual configuration is:

```hcl
data "aws_ami" "ubuntu" {
  # image selection criteria
}
```

The EC2 instance then references the resulting AMI:

```hcl
ami = data.aws_ami.ubuntu.id
```

The implementation therefore establishes:

```text
AMI Data Source
       │
       │ .id
       ↓
EC2 Instance
```

This also contributes to Terraform's dependency graph.

---

## 6. SSH Key Pair Implementation

The EC2 instance requires an SSH key pair.

The implementation separates the local private key from the public key registered with AWS.

The workflow is:

```text
ssh-keygen
    │
    ├── Private key
    │      └── kept locally
    │
    └── Public key
           ↓
      Terraform configuration
           ↓
      AWS Key Pair
           ↓
      EC2 Instance
```

A representative Terraform resource is:

```hcl
resource "aws_key_pair" "web" {
  key_name   = var.key_name
  public_key = file("path/to/public-key.pub")
}
```

The private key is then used for SSH connections during the provisioner exercise.

Private keys are environment credentials and must not be committed to Git.

---

## 7. Security Group Implementation

The EC2 security group provides the network access policy for the instance.

The practical demonstrates inbound rules for:

```text
SSH
TCP/22
Restricted administrative source

HTTP
TCP/80
Public access
```

A simplified implementation pattern is:

```hcl
resource "aws_security_group" "web" {
  name        = "web-security-group"
  description = "Security group for web instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<trusted-ip>/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

The actual values should remain environment-specific and should not be published if they reveal unnecessary personal or infrastructure information.

The security group is referenced by the EC2 instance:

```hcl
vpc_security_group_ids = [
  aws_security_group.web.id
]
```

This creates a Terraform dependency:

```text
Security Group
      │
      │ id
      ↓
EC2 Instance
```

---

## 8. EC2 Instance Implementation

The EC2 instance brings the previous components together.

Conceptually:

```hcl
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone
  key_name               = aws_key_pair.web.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

The instance depends on:

```text
AMI
Key Pair
Security Group
Variables
```

Terraform resolves these relationships through resource references.

The resulting dependency model is:

```text
AMI ────────────────┐
                    │
Key Pair ───────────┼──→ EC2 Instance
                    │
Security Group ─────┘
```

---

## 9. Terraform Resource References

Cross-resource references were used throughout the implementation.

The general pattern is:

```text
resource_type.resource_name.attribute
```

For example:

```hcl
aws_security_group.web.id
```

or:

```hcl
aws_key_pair.web.key_name
```

Terraform evaluates these references when constructing its dependency graph.

This means the implementation does not need to manually define a shell-script-style creation sequence for dependent resources.

Instead:

```text
Reference
   ↓
Dependency
   ↓
Terraform Graph
   ↓
Execution Order
```

---

## 10. Initial Terraform Lifecycle

After preparing the configuration, the standard Terraform workflow was used.

### Initialize

```bash
terraform init
```

This initializes the Terraform working directory and downloads the required provider plugins.

### Format

```bash
terraform fmt
```

This formats Terraform configuration according to Terraform's formatting conventions.

### Validate

```bash
terraform validate
```

This checks whether the configuration is syntactically and structurally valid.

### Plan

```bash
terraform plan
```

This previews the infrastructure actions Terraform intends to perform.

### Apply

```bash
terraform apply
```

Terraform then executes the approved infrastructure changes.

### Destroy

```bash
terraform destroy
```

This removes infrastructure managed by the configuration.

---

## 11. Infrastructure Lifecycle Experiments

The practical did not stop after the first successful deployment.

Infrastructure changes were deliberately introduced to observe Terraform's lifecycle behavior.

The implementation examined:

```text
Initial Configuration
        ↓
terraform apply
        ↓
Infrastructure Exists
        ↓
Configuration Changed
        ↓
terraform plan
        ↓
Terraform Determines Required Action
        ↓
terraform apply
```

Two important classes of change were observed:

### In-place changes

Some attributes can be changed without replacing the resource.

### Replacement changes

Other attributes require Terraform to destroy the existing resource and create a replacement.

The practical included an availability-zone change that produced a replacement operation and then demonstrated a failed apply when the selected availability zone was incompatible with the selected region.

This was useful implementation evidence because the failure occurred during actual infrastructure execution rather than only during configuration validation.

---

## 12. Failed Replacement and Recovery

The failed replacement scenario followed this pattern:

```text
Existing EC2
    ↓
Configuration changed
    ↓
Terraform plans replacement
    ↓
Old instance destroyed
    ↓
Replacement creation attempted
    ↓
Invalid region/AZ combination
    ↓
Apply fails
```

The recovery process was:

```text
Identify invalid configuration
        ↓
Correct availability zone
        ↓
terraform plan
        ↓
Review corrected action
        ↓
terraform apply
        ↓
Infrastructure restored
```

This demonstrates an important operational property:

> A successful `terraform plan` does not guarantee that `terraform apply` will succeed against the real cloud environment.

Planning evaluates the proposed configuration, while apply interacts with the actual provider environment.

---

## 13. Configuration Drift Implementation

The practical also deliberately changed the EC2 instance outside Terraform.

The experiment followed:

```text
Terraform
    ↓
EC2 created
    ↓
Manual AWS Console change
    ↓
Actual infrastructure differs
    ↓
terraform plan
    ↓
Observe Terraform behavior
```

The important implementation lesson was that Terraform does not automatically manage every possible property of a cloud resource.

The configuration must declare the desired attribute for Terraform to manage that aspect.

The experiment therefore distinguished:

```text
Declared configuration
        ↓
Terraform-managed behavior

Undeclared property
        ↓
May remain outside Terraform's management scope
```

This is an important boundary when designing Terraform configurations.

---

## 14. Provisioner Implementation

Provisioners were introduced to perform post-creation configuration on the EC2 instance.

The demonstrated workflow is:

```text
EC2 creation
      ↓
SSH connection
      ↓
File provisioner
      ↓
Transfer web.sh
      ↓
remote-exec
      ↓
Execute web.sh
      ↓
Web server configured
```

The project uses:

- `file`
- `remote-exec`
- `connection`

inside the EC2 resource.

---

## 15. SSH Connection Configuration

The provisioners require an SSH connection.

The connection configuration provides:

```text
Protocol
SSH

User
Ubuntu user

Private key
Local private key

Host
EC2 public IP
```

A representative structure is:

```hcl
connection {
  type        = "ssh"
  user        = var.web_user
  private_key = file("path/to/private-key")
  host        = self.public_ip
}
```

The use of:

```hcl
self.public_ip
```

allows the provisioner connection to refer to the public IP of the current EC2 resource.

The private key is never part of the repository.

---

## 16. File Provisioner

The file provisioner transfers the deployment script to the EC2 instance.

The implementation pattern is:

```hcl
provisioner "file" {
  source      = "web.sh"
  destination = "/tmp/web.sh"
}
```

The flow is:

```text
Local Terraform execution environment
              │
              │ source
              ↓
           web.sh
              │
              │ SSH/SCP-style transfer
              ↓
       EC2 /tmp/web.sh
```

The destination under `/tmp` allows the SSH user to receive the file without requiring elevated permissions for the copy operation.

The script is subsequently executed with the privileges required by its commands.

### Ownership boundary

`web.sh` was supplied as a course companion artifact.

Therefore, this repository should describe:

> **Used the supplied deployment script through Terraform provisioners.**

It should not claim:

> **Developed the deployment script.**

---

## 17. Remote-Exec Provisioner

After transferring the script, `remote-exec` executes commands on the remote instance.

The conceptual sequence is:

```hcl
provisioner "remote-exec" {
  inline = [
    "chmod +x /tmp/web.sh",
    "sudo /tmp/web.sh"
  ]
}
```

The flow is:

```text
Terraform
    ↓
SSH
    ↓
EC2
    ↓
chmod
    ↓
sudo web.sh
    ↓
Software installation/configuration
    ↓
Website deployment
```

Terraform controls the execution of the provisioner but does not maintain a detailed state model of everything the script changes inside the operating system.

This is an important limitation of the provisioner approach.

---

## 18. Provisioner Failure Handling

The practical identifies several failure signatures.

| Failure | Likely Cause |
|---|---|
| SSH timeout | Port 22 not allowed or incorrect key |
| Script hangs | Package installation requiring confirmation |
| Permission denied | Script is not executable |
| Website unavailable | Port 80 or instance initialization issue |
| `web.sh` not found | Incorrect local source path |
| `terraform validate` failure | Variable/reference mismatch |

The implementation approach is therefore:

```text
Failure
  ↓
Identify execution layer
  ↓
Check configuration
  ↓
Check AWS networking
  ↓
Check SSH
  ↓
Check script
  ↓
Re-run validation
```

---

## 19. Provisioner Design Boundary

Provisioners were used because they are part of the practical and demonstrate how Terraform can perform post-creation actions.

However, the source material explicitly presents provisioners as a mechanism with limitations.

The key implementation limitation is:

```text
Terraform manages
       ↓
Resource lifecycle

Provisioner changes
       ↓
Operating-system configuration
       ↓
Not fully represented in Terraform state
```

The source material identifies alternatives such as:

```text
Packer
    ↓
Pre-built AMI
    ↓
Ready-to-run EC2
```

or configuration-management tools such as Ansible.

Therefore, this project demonstrates provisioners without presenting them as the preferred architecture for all production configuration management.

---

## 20. Terraform Outputs

Terraform outputs were added to expose resource attributes after infrastructure creation.

A representative output is:

```hcl
output "web_public_ip" {
  description = "Public IP address of the web instance"
  value       = aws_instance.web.public_ip
}
```

After `terraform apply`, Terraform displays the output.

The attribute path follows:

```text
resource_type
      .
resource_name
      .
attribute
```

For example:

```text
aws_instance.web.public_ip
```

The implementation therefore provides a human-readable interface to selected Terraform state information.

---

## 21. Local-Exec State Export

The project also demonstrates the `local-exec` provisioner.

Unlike `remote-exec`, which runs commands on the EC2 instance:

```text
remote-exec
    ↓
Remote EC2 host
```

`local-exec` runs on the machine executing Terraform:

```text
local-exec
    ↓
Terraform execution machine
```

The practical uses it to export a resource attribute to a local file.

Conceptually:

```hcl
provisioner "local-exec" {
  command = "echo ${aws_instance.web.private_ip} >> private_ips.txt"
}
```

The resulting data flow is:

```text
AWS Resource
     ↓
Terraform State
     ↓
Resource Attribute
     ↓
local-exec
     ↓
Local File
```

This demonstrates the difference between:

```text
Output
  → human-readable terminal information

local-exec
  → machine-readable/local file export
```

The generated `private_ips.txt` file is an execution artifact and should not be committed to the public repository.

---

## 22. Remote Backend Implementation

The final implementation stage moves Terraform state from local storage to an Amazon S3 backend.

The motivation is:

```text
Local State
    ↓
Single machine
    ↓
Poor team synchronization
```

The remote implementation becomes:

```text
Terraform Configuration
        │
        ├── Git
        │
        └── S3 Backend
              │
              └── Terraform State
```

---

## 23. S3 Bucket Preparation

The S3 backend requires a bucket to exist before Terraform initializes the backend.

The practical flow is:

```text
AWS Console
    ↓
S3
    ↓
Create unique bucket
    ↓
Create terraform folder
    ↓
Configure backend.tf
```

The bucket name must be globally unique.

The state object is stored under a key such as:

```text
terraform/backend
```

The S3 bucket itself was created separately rather than being created by the same Terraform configuration being migrated to that backend.

---

## 24. Backend Configuration

The backend configuration uses:

```hcl
terraform {
  backend "s3" {
    bucket = "<bucket-name>"
    key    = "terraform/backend"
    region = "<region>"
  }
}
```

The three key settings are:

### `bucket`

The S3 bucket containing the Terraform state.

### `key`

The path of the state object within the bucket.

### `region`

The AWS region containing the bucket.

The configured region must match the actual S3 bucket region.

For public GitHub publication, environment-specific values should be replaced with placeholders.

---

## 25. Backend Initialization

After adding the backend configuration:

```bash
terraform init
```

Terraform performs a distinct backend initialization phase.

The expected output contains:

```text
Initializing the backend...
```

The initialization process is:

```text
terraform init
      ↓
Read backend.tf
      ↓
Detect S3 backend
      ↓
Connect to S3
      ↓
Validate bucket/access
      ↓
Initialize remote state
```

If initialization fails, the first checks are:

```text
Bucket name
Region
AWS credentials/permissions
```

---

## 26. Applying with Remote State

After successful backend initialization:

```bash
terraform plan
```

followed by:

```bash
terraform apply
```

Terraform uses the configured S3 backend for state operations.

The resulting architecture is:

```text
Terraform apply
      │
      ├── Create/update AWS resources
      │
      └── Write state
              │
              ↓
          Amazon S3
```

The state is updated at runtime rather than requiring a separate manual upload step.

---

## 27. Remote State Verification

The implementation verifies the backend in two directions.

### Local verification

The local `terraform.tfstate` no longer contains the normal resource state data.

### S3 verification

The S3 bucket contains the configured state object:

```text
S3 bucket
└── terraform/
    └── backend
```

The state object contains the Terraform state information that would previously have been stored locally.

The verification therefore confirms:

```text
Before:
Code → Local
State → Local

After:
Code → Git
State → S3
```

---

## 28. Implementation Security

The public repository must not contain:

```text
AWS access keys
AWS secret keys
Private SSH keys
Passwords
Tokens
Terraform state
Sensitive environment data
```

Environment-specific values should be represented using placeholders or example files.

Examples:

```text
<aws-region>
<bucket-name>
<trusted-ip>
<key-name>
```

The actual values belong to the execution environment rather than the public source repository.

---

## 29. Generated Artifacts

Several artifacts are generated during Terraform execution.

Examples include:

```text
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
private_ips.txt
```

Their repository treatment differs.

### `.terraform/`

Generated provider/plugin working directory.

**Public repository:** Exclude.

### `.terraform.lock.hcl`

Provider dependency lock file.

**Public repository:** Keep when publishing the Terraform configuration because it contributes to provider reproducibility.

### `terraform.tfstate`

Runtime infrastructure state.

**Public repository:** Exclude.

### `terraform.tfstate.backup`

Generated state backup.

**Public repository:** Exclude.

### `private_ips.txt`

Generated environment-specific output.

**Public repository:** Exclude.

---

## 30. Final Implementation Flow

The entire implementation can be reconstructed as:

```text
1. Configure AWS provider
          ↓
2. Define Terraform variables
          ↓
3. Discover AMI
          ↓
4. Generate/register SSH key pair
          ↓
5. Configure security group
          ↓
6. Define EC2 instance
          ↓
7. Resolve resource dependencies
          ↓
8. terraform init
          ↓
9. terraform fmt
          ↓
10. terraform validate
          ↓
11. terraform plan
          ↓
12. terraform apply
          ↓
13. Validate infrastructure
          ↓
14. Test lifecycle changes
          ↓
15. Test configuration drift
          ↓
16. Add provisioners
          ↓
17. Transfer and execute supplied web.sh
          ↓
18. Add outputs
          ↓
19. Add local-exec state export
          ↓
20. Create S3 backend
          ↓
21. Configure backend
          ↓
22. terraform init
          ↓
23. terraform plan/apply
          ↓
24. Verify state in S3
          ↓
25. terraform destroy
```

---

## 31. Implementation Decisions

### Multi-file Terraform configuration

The configuration was separated into logical files to improve readability and maintainability.

### Variables

Variables were introduced to separate configurable values from resource definitions.

### Data source

AMI discovery was separated from the EC2 resource through a data source.

### Resource references

Cross-resource references were used to establish Terraform dependencies.

### Provisioners

Provisioners were used to demonstrate post-creation remote configuration, while recognizing their state-management limitations.

### Outputs

Outputs were used to expose selected resource attributes.

### Local-exec

`local-exec` demonstrated exporting state-derived resource information to the local execution environment.

### S3 backend

Remote state was introduced to separate Terraform source code from centralized runtime state.

---

## 32. Implementation Boundaries

The implementation does not include:

```text
Terraform modules
Terraform CI/CD
Terraform-managed VPC
Kubernetes infrastructure
Enterprise Terraform governance
Automated infrastructure testing
Production deployment pipelines
```

The final learning material introduces Terraform modules as a future abstraction but does not implement them in this project.

Similarly, VPC and Kubernetes Terraform management are identified as later course applications rather than completed capabilities of this repository.

---

## 33. Implementation Summary

The implementation evolved from direct Terraform resource definitions into a more complete infrastructure-management workflow:

```text
Resource Definition
       ↓
Dependency Management
       ↓
Configuration Reuse
       ↓
Lifecycle Management
       ↓
Post-Creation Provisioning
       ↓
State Extraction
       ↓
Remote State
```

The central implementation lesson is:

> **Terraform configuration defines the infrastructure intent, resource references establish dependencies, Terraform manages infrastructure lifecycle through state, provisioners can perform post-creation actions when required, and an S3 backend provides centralized state storage.**

[← Back to README](../README.md)
