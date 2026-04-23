# Domain: Terraform & Infrastructure as Code
**Loaded when:** Agent is writing or modifying Terraform configurations, provisioning cloud resources, or managing infrastructure state.
**Key concern:** State management. A corrupt or conflicting state file can destroy production infrastructure.

---

## Module Structure

| Tier | Purpose | Example |
|---|---|---|
| **Reusable modules** | Encapsulate a resource pattern (VPC, ECS cluster) | `modules/vpc/` |
| **Root modules** | Compose reusable modules for a specific environment | `environments/prod/` |

Root modules call reusable modules. Keep the dependency tree one level deep.

## State Management

Local state is a single point of failure. Always use remote state with locking.

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

**Rules:**
- One state file per logical resource group (network, compute, database -- not one giant state)
- State locking via DynamoDB (AWS) or native locking (GCS, Azurerm)
- Never manually edit state. Use `terraform state mv` / `terraform state rm`
- Use `terraform_remote_state` data source to read outputs from other states

**Workspaces** share code, switch state files -- use for identical environments differing only in variables. **Directories** duplicate code, isolate completely -- use for structurally different environments.

## Key Patterns

### Plan Before Apply

```bash
terraform plan -out=plan.tfplan   # save the plan
terraform apply plan.tfplan        # apply exactly what was reviewed
```

Never `terraform apply` without reviewing the plan. In CI, use `-detailed-exitcode` (exit 2 = changes pending).

### Data Sources Over Hardcoded Values

```hcl
# WRONG: hardcoded AMI
resource "aws_instance" "app" { ami = "ami-0abcdef1234567890" }

# RIGHT: dynamic lookup
data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]
  filter { name = "name"; values = ["app-*"] }
}
resource "aws_instance" "app" { ami = data.aws_ami.app.id }
```

### Tag Everything

Minimum: `Name`, `Environment`, `Team`, `ManagedBy = "terraform"`. Use `default_tags` in the provider.

### Lifecycle Blocks

```hcl
resource "aws_instance" "app" {
  lifecycle { create_before_destroy = true }
}
```

### Variable Validation

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}
```

## Security Scanning

```bash
terraform validate                   # syntax and consistency
terraform plan -detailed-exitcode    # review changes
checkov -d . --framework terraform   # policy scanning
tfsec .                              # static security analysis
```

## Common Pitfalls

| Pitfall | Why it breaks | Fix |
|---|---|---|
| No state locking | Two applies corrupt state | Enable DynamoDB/native locking |
| One giant state file | Slow plans, blast radius is everything | Split by resource group |
| `terraform destroy` on shared resources | Deletes what other stacks need | Use `prevent_destroy`, review plan |
| Circular module dependencies | Unresolvable dependency graph | Pass values via outputs/variables |
| Hardcoded provider credentials | Secrets in code | Use env vars or IAM roles |
| No `terraform init` after backend change | Wrong state | Always `init -reconfigure` |
| Resources that can't destroy cleanly | Orphaned resources, stuck state | Test create-destroy cycle in dev |
