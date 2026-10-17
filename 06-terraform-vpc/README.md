# 06 - Infrastructure as Code (IaC) with Terraform

## Objective

Rebuild the Project 01 network as code with Terraform: a custom VPC, subnets with VPC Flow Logs, firewall rules, Cloud Router with Cloud NAT and a private Shielded VM. The whole environment can be created, reviewed and destroyed with three commands, and every change goes through `terraform plan` first.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider and all resources |
| `variables.tf` | Region, zone, prefix, machine type, subnet map |
| `outputs.tf` | VPC name, subnet ranges, VM internal IP, IAP SSH command |
| `terraform.tfvars.example` | Template for your project ID (the real `.tfvars` is git-ignored) |

## Features shown

- `for_each` over a map to create one subnet per tier
- Implicit dependencies through resource references (`google_compute_network.vpc.id`)
- VPC Flow Logs on each subnet for network troubleshooting
- Cloud NAT error logging
- Private VM with no external IP and Secure Boot enabled

## Run (in Cloud Shell, where Terraform is pre-installed)

```bash
cd 06-terraform-vpc
cp terraform.tfvars.example terraform.tfvars
sed -i "s/your-project-id/$(gcloud config get-value project)/" terraform.tfvars

terraform init       # downloads the Google provider
terraform fmt -check # style check
terraform validate   # syntax check
terraform plan       # preview: expect 9 resources to add
terraform apply      # type 'yes'
```

## Verify

```bash
terraform output
$(terraform output -raw ssh_command)       # IAP SSH into the private VM
# inside the VM:
curl -s ifconfig.me ; echo                  # Cloud NAT address

# Drift detection: change something in the console (for example, delete the http firewall rule), then:
terraform plan                              # Terraform reports the drift and plans to recreate it
```

View flow logs in **Logs Explorer** with `log_id("compute.googleapis.com/vpc_flows")`.

## Screenshots to capture

1. `terraform plan` summary
2. `terraform apply` complete with outputs
3. VPC created in the console with the `tf-` prefix
4. Drift detected by `terraform plan`
5. `terraform destroy` complete

## Cleanup

```bash
terraform destroy    # type 'yes'
```

## Next steps

- Store state in a Cloud Storage backend bucket with versioning
- Split into reusable modules (network, compute)
- Run `terraform plan` in a CI (Continuous Integration) pipeline with GitHub Actions
