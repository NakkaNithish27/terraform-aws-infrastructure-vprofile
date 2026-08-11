# Validation

[← Back to README](../README.md)

## 1. Validation Overview

Validation for this project was performed at multiple levels rather than relying on a single successful `terraform apply`.

The validation model is:

```text
Configuration
      ↓
Formatting
      ↓
Terraform Validation
      ↓
Plan Validation
      ↓
Apply Validation
      ↓
AWS Infrastructure Validation
      ↓
Lifecycle Validation
      ↓
Drift Validation
      ↓
Provisioner Validation
      ↓
Remote State Validation
      ↓
Cleanup Validation
```

Each stage answers a different question.

| Validation Stage | Primary Question |
|---|---|
| `terraform fmt` | Is the configuration consistently formatted? |
| `terraform validate` | Is the configuration syntactically and structurally valid? |
| `terraform plan` | What infrastructure changes does Terraform intend to make? |
| `terraform apply` | Can the planned changes actually be executed against AWS? |
| AWS verification | Does the expected infrastructure actually exist? |
| Lifecycle testing | Does Terraform behave as expected when configuration changes? |
| Drift testing | Does Terraform detect changes that fall within its declared management scope? |
| Provisioner validation | Did the remote configuration steps execute successfully? |
| Output validation | Are expected resource attributes exposed? |
| S3 validation | Is Terraform state actually stored in the remote backend? |
| Destroy validation | Was managed infrastructure successfully removed? |

The project therefore treats validation as a **layered process**, not a single command.

---

## 2. Validation Strategy

The central validation principle is:

> **A Terraform configuration is not considered validated merely because `terraform validate` succeeds.**

The practical demonstrates that different commands detect different classes of problems.

The validation model is:

```text
terraform validate
        ↓
Configuration-level correctness

terraform plan
        ↓
Proposed infrastructure changes

terraform apply
        ↓
Real AWS API execution

AWS Console / resource inspection
        ↓
Actual infrastructure result
```

This distinction is important because the practical demonstrated cases where:

- `terraform validate` succeeded even though a resource reference was logically incorrect.
- `terraform plan` could produce a valid-looking plan that later failed during the real AWS API operation.
- `terraform apply` therefore remained the final execution test.

The source material explicitly identifies `terraform validate` as a syntax/schema-oriented check rather than a complete logical correctness check.

---

## 3. Configuration Formatting Validation

The first configuration-level check is:

```bash
terraform fmt
```

### Purpose

`terraform fmt` checks and normalizes Terraform configuration formatting.

It does not establish that the infrastructure is correct.

The validation question is:

> **Is the Terraform configuration formatted according to Terraform's expected formatting conventions?**

### Validation result

A clean formatting operation means the configuration has been normalized by Terraform's formatter.

### What it proves

```text
terraform fmt
      ↓
Formatting consistency
```

### What it does not prove

It does not prove:

- AWS resources are valid
- provider authentication works
- resource references are correct
- the infrastructure can be created
- the selected availability zone exists in the configured region

Therefore, formatting is the first validation layer rather than the final one.

---

## 4. Terraform Initialization Validation

Before provider-dependent validation can work correctly, the Terraform working directory must be initialized:

```bash
terraform init
```

The source material demonstrates that attempting `terraform validate` before initialization can fail because the required provider has not yet been initialized.

The operational sequence is therefore:

```text
terraform fmt
      ↓
terraform init
      ↓
terraform validate
      ↓
terraform plan
      ↓
terraform apply
```

### What `terraform init` validates

Initialization confirms that Terraform can prepare the working directory and obtain the required provider plugins.

### What it does not prove

Successful initialization does not prove:

- the infrastructure configuration is correct
- AWS resources can be created
- the credentials have every required permission
- the planned infrastructure is safe

It prepares the environment for the subsequent validation stages.

---

## 5. Terraform Configuration Validation

The next check is:

```bash
terraform validate
```

### Purpose

The command checks whether the Terraform configuration is valid at the configuration/schema level.

The validation model is:

```text
Terraform HCL
     ↓
Terraform parser
     ↓
Provider schema
     ↓
Configuration validation
```

### What it can catch

Examples include:

- syntax errors
- incorrect argument types
- malformed blocks
- schema-level configuration errors
- invalid structural configuration

### What it may not catch

The practical demonstrates that `terraform validate` can succeed even when a resource reference is logically wrong.

For example:

```text
Reference to a non-existent resource
```

may only become apparent during:

```bash
terraform plan
```

because the plan phase evaluates the dependency relationships and actual resource references.

### Validation boundary

Therefore:

```text
validate ≠ complete correctness
```

It is a configuration validation layer.

---

## 6. Plan Validation

The next stage is:

```bash
terraform plan
```

The source material describes `terraform plan` as a three-way comparison involving:

```text
.tf configuration
       ↕
Terraform state
       ↕
Actual AWS infrastructure
```

Terraform uses this comparison to determine what should be:

```text
+
create

~
change

-
destroy

-/+
replace
```

### Primary validation question

> **What will Terraform actually attempt to change?**

---

## 7. Plan Reading Procedure

The practical establishes a specific reading order for plan output.

When Terraform displays:

```text
Plan: X to add, Y to change, Z to destroy.
```

the recommended reading order is:

```text
1. DESTROY
2. CHANGE
3. ADD
```

### Why destroy comes first

Destruction is the most dangerous operation because it can cause:

- service interruption
- resource replacement
- data loss
- unexpected infrastructure changes

The plan therefore functions as a safety gate before applying infrastructure changes.

### Evidence to retain

A useful plan screenshot should show:

- the Terraform command
- the relevant resource
- the operation symbol
- the final plan summary

Sensitive values should be redacted.

---

## 8. Plan Validation Boundaries

A successful plan is valuable but is **not proof that apply will succeed**.

The practical demonstrates this with an availability-zone mismatch.

The configuration contained:

```text
Provider region:
us-east-1

Configured availability zone:
us-east-2a
```

The plan could still produce a replacement plan because the availability-zone value was syntactically valid.

The actual AWS API rejected the request during `terraform apply`.

The sequence was:

```text
terraform validate
        ↓
SUCCESS

terraform plan
        ↓
SUCCESS / replacement planned

terraform apply
        ↓
AWS API rejects configuration
        ↓
FAILURE
```

This is one of the most important validation lessons from the project:

> **Plan is a prediction of the intended actions, not a guarantee that the cloud provider will accept every operation.**

---

## 9. Apply Validation

The next validation stage is:

```bash
terraform apply
```

Before confirmation, the plan should be reviewed.

The confirmation prompt acts as the final safety gate:

```text
terraform apply
        ↓
Plan displayed again
        ↓
Review
        ↓
yes
        ↓
Execute
```

The `yes` confirmation should only be provided after checking the proposed changes.

### What apply validates

`terraform apply` performs the actual provider operations.

It therefore tests things that earlier stages cannot completely establish:

```text
AWS API compatibility
AWS resource availability
Provider-side validation
Permissions
Actual resource creation
Actual resource modification
Actual resource replacement
```

---

## 10. Infrastructure Creation Validation

After a successful apply, the resulting AWS infrastructure should be checked independently.

The expected resource model is:

```text
AWS
│
├── EC2 Instance
├── Key Pair
└── Security Group
```

The EC2 instance should be checked for the expected:

- instance existence
- instance state
- AMI
- instance type
- availability zone
- key pair association
- security group association

The security group should be checked for the intended:

```text
SSH
TCP/22
restricted source

HTTP
TCP/80
public access
```

### What this proves

```text
terraform apply
      +
AWS inspection
      ↓
Infrastructure exists as intended
```

This is stronger evidence than showing only Terraform terminal output.

---

## 11. Dependency Validation

The project uses cross-resource references.

The expected dependency chain is:

```text
AMI Data Source
       │
       ↓
EC2 Instance

Key Pair
       │
       ↓
EC2 Instance

Security Group
       │
       ↓
EC2 Instance
```

Validation should confirm that Terraform created the dependent resources successfully and that the EC2 instance references the expected supporting resources.

The project uses references such as:

```text
resource_type.resource_name.attribute
```

to establish dependency relationships.

### Evidence

A useful evidence item can show the final EC2 instance and its associated security group/key pair.

---

## 12. Variable Validation

Variables were introduced to separate configuration values from infrastructure definitions.

Validation should confirm that changing the intended variable values produces the expected Terraform behavior.

Examples include:

```text
region
instance_type
availability_zone
key_name
web_user
```

The validation sequence is:

```text
Change variable
      ↓
terraform plan
      ↓
Review affected resources
      ↓
terraform apply
      ↓
Verify resulting infrastructure
```

### What this proves

The project demonstrates that configuration values can be changed independently of the underlying resource structure.

### What it does not prove

It does not establish a full multi-environment Terraform system or production-grade variable validation framework.

---

## 13. Lifecycle Validation

The project deliberately tested infrastructure changes after initial creation.

The lifecycle validation model is:

```text
Initial Infrastructure
        ↓
Modify Terraform configuration
        ↓
terraform plan
        ↓
Observe planned action
        ↓
terraform apply
        ↓
Verify AWS result
```

The practical demonstrates both:

```text
In-place update
```

and:

```text
Replacement
```

behavior.

The plan output identifies replacement using the destroy/create behavior associated with immutable changes.

---

## 14. Mutable Change Validation

Some infrastructure changes can be performed without replacing the resource.

Examples demonstrated in the learning material include changes such as:

- security group rule changes
- tags
- instance name

The validation process is:

```text
Configuration change
       ↓
terraform plan
       ↓
Observe in-place update
       ↓
terraform apply
       ↓
Verify resource remains available
```

The key expected result is:

```text
Resource ID remains the same
```

where the tested attribute is mutable.

This demonstrates Terraform's ability to update an existing resource rather than unnecessarily recreating it.

---

## 15. Replacement Validation

Other changes require resource replacement.

The learning material identifies examples such as:

- EC2 AMI changes
- EC2 key-pair changes
- availability-zone changes

The expected plan pattern is:

```text
-/+
destroy + recreate
```

The validation question is:

> **Does Terraform correctly identify the attribute as requiring replacement?**

The practical confirmed this behavior by modifying the availability zone.

---

## 16. Failed Replacement Validation

The failed availability-zone experiment is an important validation artifact.

The sequence was:

```text
Existing EC2
      ↓
Change availability zone
      ↓
terraform plan
      ↓
Replacement planned
      ↓
terraform apply
      ↓
Old resource destroyed
      ↓
Replacement creation fails
```

The reason was a mismatch between:

```text
Configured AWS region
```

and:

```text
Configured availability zone
```

The practical uses this scenario to demonstrate that plan can succeed while apply fails against the real AWS API.

### Why this evidence matters

A successful deployment screenshot only proves success.

A controlled failure followed by recovery demonstrates:

- reading Terraform plans
- understanding replacement behavior
- interpreting provider errors
- correcting configuration
- re-planning
- recovering infrastructure

This is higher-value engineering evidence.

---

## 17. Recovery Validation

After correcting the invalid availability zone:

```text
Correct configuration
       ↓
terraform plan
       ↓
Review replacement
       ↓
terraform apply
       ↓
EC2 recreated
       ↓
AWS verification
```

The recovery is considered validated when:

- Terraform completes successfully
- the replacement EC2 exists
- the instance is in the expected state
- the expected supporting resources remain correctly associated

The important validation pattern is:

```text
Failure
  ↓
Diagnosis
  ↓
Correction
  ↓
Re-validation
  ↓
Successful convergence
```

---

## 18. Configuration Drift Validation

The project deliberately changed infrastructure outside Terraform.

The experiment demonstrates the distinction between:

```text
Terraform configuration
        ↓
Declared management scope

Actual AWS infrastructure
        ↓
Current reality
```

The central lesson is:

> **Terraform only manages what you declare.**

---

## 19. Instance State Drift

The practical stopped the EC2 instance manually through AWS.

Terraform initially did not detect this as drift because the Terraform configuration did not declare the desired running/stopped state.

The reasoning was:

```text
Terraform configuration
    ↓
Instance exists
    ↓
AMI correct
    ↓
Key pair correct
    ↓
Security group correct
    ↓
No declared instance-state requirement
```

Therefore, the stopped state remained outside the configuration's management scope.

The practical then introduced `aws_ec2_instance_state` to explicitly declare the desired state.

The resulting model is:

```text
Desired:
running

Actual:
stopped

        ↓

terraform plan

        ↓

Start instance
```

### Validation lesson

This demonstrates that drift detection is tied to the attributes Terraform is actually configured to manage.

---

## 20. Provisioner Validation

The provisioner workflow should be validated in stages.

```text
EC2 available
      ↓
SSH connection
      ↓
File transfer
      ↓
Script execution
      ↓
Web server configuration
      ↓
Web service verification
```

### File provisioner

Validate that the deployment script reaches the intended remote path.

Expected:

```text
/tmp/web.sh
```

### Remote-exec

Validate that:

- the script becomes executable
- the script executes
- the expected software/configuration is installed

### Application-level validation

Where appropriate, verify that the resulting HTTP service is reachable.

The deployment script should be described as a **supplied course artifact**, not as personally authored application code.

---

## 21. Provisioner Failure Validation

Several failures are useful diagnostic checkpoints.

| Validation Failure | Investigation |
|---|---|
| SSH timeout | Security group, host, key, network |
| Permission denied | SSH user/key/file permissions |
| Script not found | File provisioner source/destination |
| Script hangs | Remote command/package behavior |
| HTTP unavailable | Port 80, service, instance status |
| Terraform validation failure | HCL/type/reference configuration |

The troubleshooting model is:

```text
Failure
   ↓
Identify layer
   ↓
Terraform?
   ↓
AWS networking?
   ↓
SSH?
   ↓
Remote filesystem?
   ↓
Script?
   ↓
Application?
```

This prevents treating every failure as a Terraform syntax problem.

---

## 22. Output Validation

Terraform outputs expose selected resource attributes.

For example:

```text
aws_instance.web.public_ip
```

The validation process is:

```bash
terraform apply
```

followed by inspection of:

```text
Outputs:
    web_public_ip = ...
```

### What this proves

The output expression successfully resolved the resource attribute.

### Additional validation

The displayed public IP can be compared against the EC2 instance's actual public IP in AWS.

This creates a useful cross-check:

```text
Terraform Output
       ↕
AWS EC2 Console
```

---

## 23. Local-Exec Validation

The project also demonstrates exporting state-derived information to a local file using `local-exec`.

The validation sequence is:

```text
terraform apply
      ↓
local-exec runs
      ↓
private_ips.txt created/updated
      ↓
Inspect file
```

The expected result is that the file contains the selected resource attribute.

This validates that:

```text
Terraform resource attribute
        ↓
local-exec
        ↓
Local file
```

The generated file is environment-specific and should not be committed to the public repository.

---

## 24. Remote State Validation

The final validation stage checks the S3 backend.

The expected architecture is:

```text
Terraform Code
      ↓
Git

Terraform State
      ↓
Amazon S3
```

The validation process is:

```text
Configure S3 backend
       ↓
terraform init
       ↓
terraform plan
       ↓
terraform apply
       ↓
Inspect S3
```

The S3 bucket should contain the configured state object.

Conceptually:

```text
S3 Bucket
└── terraform/
    └── backend
```

---

## 25. Backend Initialization Validation

After adding the backend configuration:

```bash
terraform init
```

should report successful backend initialization.

The validation question is:

> **Can Terraform successfully use the configured S3 backend?**

Common configuration values to verify if initialization fails include:

```text
bucket
key
region
AWS permissions
```

The S3 bucket must exist before Terraform can initialize against that backend.

---

## 26. Remote State Location Validation

Remote state should be validated from both sides.

### Local side

Confirm that the normal Terraform state is no longer being maintained as the primary local state object.

### S3 side

Confirm that the expected state object exists in the configured bucket.

The intended result is:

```text
Before:

Terraform
   └── Local State


After:

Terraform
   └── S3 Backend
          └── Remote State
```

This verifies that the backend migration was effective.

---

## 27. State Safety Validation

Terraform state should be treated as sensitive infrastructure information.

Validation before publishing the repository should include:

```text
terraform.tfstate
        ↓
NOT committed

terraform.tfstate.backup
        ↓
NOT committed

Private SSH key
        ↓
NOT committed

AWS credentials
        ↓
NOT committed
```

The repository should instead contain:

```text
backend.tf.example
```

with environment-specific values replaced by placeholders where appropriate.

---

## 28. Destroy Validation

The final lifecycle cleanup command is:

```bash
terraform destroy
```

The validation flow is:

```text
terraform destroy
       ↓
Review destruction plan
       ↓
Confirm
       ↓
Resources deleted
       ↓
Verify AWS
```

### AWS verification

After destruction, verify that Terraform-managed resources no longer remain:

```text
EC2 instance
Key pair
Security group
```

where those resources were managed by the configuration.

### State verification

Terraform state should reflect that the managed infrastructure no longer exists.

---

## 29. Evidence Strategy

The repository should retain a small number of **high-signal evidence artifacts** rather than a large collection of screenshots.

Recommended evidence:

### Evidence 1 — Successful Terraform Plan/Apply

Shows:

```text
terraform plan
terraform apply
Apply complete
```

**Proves:**

Terraform successfully executed the configuration.

---

### Evidence 2 — AWS Infrastructure

A sanitized AWS Console screenshot showing the resulting EC2 infrastructure.

**Proves:**

The Terraform execution produced real AWS infrastructure.

---

### Evidence 3 — Lifecycle/Failure Scenario

A sanitized plan or failure/recovery screenshot showing the replacement scenario.

**Proves:**

The project tested infrastructure lifecycle behavior rather than only performing a one-time deployment.

---

### Evidence 4 — S3 Remote State

A sanitized S3 screenshot showing the Terraform state object.

**Proves:**

The remote backend was configured and used.

---

## 30. Evidence Mapping

The recommended mapping is:

| Project Claim | Validation | Evidence |
|---|---|---|
| Provisioned AWS infrastructure | Apply + AWS inspection | Terraform/AWS screenshot |
| Configured resource dependencies | Plan + AWS inspection | Plan/resource screenshot |
| Used Terraform variables | Plan after variable change | Plan screenshot |
| Tested replacement behavior | Plan + apply | Lifecycle screenshot |
| Investigated failure | Failed apply + recovery | Error/recovery screenshot |
| Tested drift | Manual change + plan | Drift evidence |
| Used provisioners | Apply + remote verification | Provisioner evidence |
| Used outputs | Apply output | Terminal screenshot |
| Used local-exec | Generated file | Sanitized terminal/file evidence |
| Configured S3 backend | `terraform init` + S3 inspection | Backend/S3 screenshot |
| Used remote state | S3 inspection | S3 screenshot |
| Cleaned up infrastructure | Destroy + AWS inspection | Optional cleanup evidence |

Not every row requires a screenshot in the final public repository.

The goal is to retain enough evidence to support the major claims.

---

## 31. Evidence Quality Rules

Good evidence should:

- show the relevant command/result
- be readable
- contain enough context to establish what happened
- avoid exposing credentials
- avoid exposing private keys
- avoid unnecessary IP addresses or identifiers
- avoid unrelated terminal history
- avoid excessive screenshots of the same operation

### Sanitize

Before publication, inspect screenshots for:

```text
AWS account identifiers
Private IPs
Sensitive public IPs
Access keys
Secret keys
SSH private keys
Tokens
Bucket names if environment-specific
Resource IDs where unnecessary
```

Evidence should prove the engineering work without exposing the environment.

---

## 32. Validation Boundaries

Validation in this project establishes that the demonstrated Terraform workflow worked in the tested environment.

It does **not** establish:

```text
Production readiness
        ✗

Enterprise-scale reliability
        ✗

Terraform CI/CD
        ✗

Automated infrastructure testing
        ✗

Multi-region production architecture
        ✗

Terraform module quality
        ✗

Enterprise state governance
        ✗
```

The project therefore uses evidence to support **what was actually tested**, rather than extrapolating from the results to broader production claims.

---

## 33. Validation Matrix

| Capability | Test | Expected Result | Evidence Level |
|---|---|---|---|
| Terraform formatting | `terraform fmt` | Configuration formatted | Low |
| Initialization | `terraform init` | Providers/backend initialized | Medium |
| Configuration validity | `terraform validate` | Configuration passes validation | Medium |
| Resource planning | `terraform plan` | Expected add/change/destroy actions | High |
| Infrastructure creation | `terraform apply` | Resources created | High |
| AWS correctness | AWS inspection | Expected resources exist | High |
| Mutable update | Plan/apply | Resource updated in place | Medium |
| Replacement | Plan/apply | Resource replaced | High |
| Failure handling | Invalid AZ apply | Provider rejects invalid operation | High |
| Recovery | Correct + reapply | Infrastructure restored | High |
| Drift | Manual state change | Behavior matches declared scope | High |
| Provisioning | file/remote-exec | Remote configuration succeeds | Medium |
| Outputs | Apply output | Resource attributes displayed | Medium |
| Local execution | `local-exec` | File generated | Low |
| S3 backend | `terraform init` | Backend initialized | High |
| Remote state | S3 inspection | State object exists remotely | High |
| Cleanup | `terraform destroy` | Managed resources removed | Medium |

---

## 34. Final Validation Workflow

The complete validation workflow can be reconstructed as:

```text
                    Terraform Configuration
                              │
                              ↓
                       terraform fmt
                              │
                              ↓
                       terraform init
                              │
                              ↓
                     terraform validate
                              │
                              ↓
                       terraform plan
                              │
                       ┌──────┴──────┐
                       │             │
                    Review        Problems
                       │             │
                       ↓             ↓
                 terraform apply   Correct
                       │
                       ↓
                 AWS Verification
                       │
          ┌────────────┼────────────┐
          │            │            │
       Lifecycle     Drift      Provisioning
          │            │            │
          └────────────┼────────────┘
                       ↓
                  Outputs Check
                       │
                       ↓
                 S3 Backend Check
                       │
                       ↓
                terraform destroy
                       │
                       ↓
                 AWS Cleanup Check
```

---

## 35. What Validation Demonstrates

The validation process demonstrates the following capabilities:

### Configuration-level understanding

The project distinguishes formatting, initialization, and configuration validation.

### Plan interpretation

The project uses `terraform plan` as a safety and impact-analysis step rather than blindly applying changes.

### Real infrastructure validation

The project checks actual AWS resources after Terraform execution.

### Lifecycle understanding

The project distinguishes in-place changes from replacement operations.

### Failure analysis

The project experienced and analyzed an actual apply-time AWS failure caused by an invalid region/availability-zone combination.

### Drift understanding

The project demonstrates that Terraform only manages attributes declared in the configuration.

### Provisioner validation

The project verifies remote execution through SSH and Terraform provisioners.

### State understanding

The project validates the transition from local Terraform state to an S3-backed remote state.

---

## 36. Final Validation Summary

The project's validation model can be compressed into:

```text
validate
   ↓
"Is the configuration structurally valid?"

plan
   ↓
"What does Terraform intend to do?"

apply
   ↓
"Can AWS actually execute it?"

AWS verification
   ↓
"Did the intended infrastructure result occur?"

lifecycle testing
   ↓
"Does Terraform behave correctly when configuration changes?"

drift testing
   ↓
"What does Terraform actually manage?"

S3 verification
   ↓
"Is state stored remotely as intended?"

destroy verification
   ↓
"Was managed infrastructure successfully cleaned up?"
```

The central validation lesson is:

> **Terraform validation is layered. `terraform validate` checks configuration structure, `terraform plan` previews and analyzes changes, `terraform apply` tests real provider execution, and independent AWS/state inspection confirms the resulting infrastructure and state.**

[← Back to README](../README.md)
