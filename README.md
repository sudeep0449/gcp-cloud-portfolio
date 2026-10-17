# Google Cloud Hands-On Portfolio

Hands-on Google Cloud Platform (GCP) projects built in my own GCP project by **Sudeep Kumar Chaurasiya**, a Bachelor of Networking graduate. The focus is cloud networking, compute, identity and operations. Each project maps to the **Google Cloud Associate Cloud Engineer (ACE)** exam domains.

Every project is reproducible. It includes the `gcloud` command-line interface (CLI) scripts, an explanation of the design, verification steps, screenshots and a cleanup script so nothing is left running.

## Projects

| # | Project | Core services | ACE domain |
|---|---------|---------------|------------|
| 01 | [Secure Virtual Private Cloud (VPC) network](01-secure-vpc-network/) | VPC, subnets, firewall rules, Cloud NAT (Network Address Translation), Identity-Aware Proxy (IAP) | Planning and implementing a cloud solution |
| 02 | [Load-balanced, auto-scaling web app](02-load-balanced-web-app/) | Compute Engine, Managed Instance Group (MIG), global HTTP(S) Load Balancer, health checks, autoscaling | Implementing and ensuring successful operation |
| 03 | [Cloud Storage static website](03-cloud-storage-static-site/) | Cloud Storage, Identity and Access Management (IAM), versioning, lifecycle rules | Configuring access and security / data storage |
| 04 | [IAM least-privilege design](04-iam-least-privilege/) | Service accounts, custom roles, Cloud Audit Logs | Configuring access and security |
| 05 | [Monitoring and budget alerts](05-monitoring-and-budget-alerts/) | Cloud Monitoring, Ops Agent, uptime checks, alerting, Cloud Billing budgets | Ensuring successful operation |
| 06 | [Infrastructure as Code (IaC) with Terraform](06-terraform-vpc/) | Terraform, Google provider | Deploying and implementing infrastructure |

## Skills demonstrated

- Designing custom-mode VPC networks with CIDR (Classless Inter-Domain Routing) planning, segmented subnets and Private Google Access
- Writing tag-based ingress firewall rules and restricting SSH (Secure Shell) to the IAP TCP-forwarding range
- Giving private VMs (virtual machines) outbound internet access through Cloud Router and Cloud NAT, without external IPs
- Building layer 7 load balancing with health checks, named ports, backend services and URL (Uniform Resource Locator) maps
- Autoscaling on CPU utilisation with managed instance groups and instance templates
- Least-privilege IAM: predefined roles, custom roles, service accounts and resource-level bindings
- Observability: Ops Agent, uptime checks, alert policies and audit log queries
- Cost control: billing budgets with threshold alerts and scripted cleanup
- Repeatable infrastructure with Terraform (`init`, `plan`, `apply`, `destroy`)

## How to run

1. Read [docs/SETUP.md](docs/SETUP.md) to set up the project, billing safety and Cloud Shell.
2. Open a project folder, read its README, then run `deploy.sh`.
3. Verify the results, take screenshots into the `screenshots/` folder.
4. Run `cleanup.sh` to delete all resources.

Default region is **australia-southeast1 (Sydney)**. To change it, edit `config.sh`.

## Certification path

See [docs/ROADMAP.md](docs/ROADMAP.md) for the study plan: Google Cloud Skills Boost labs, skill badges, these projects and the Associate Cloud Engineer exam.

## Connect

- LinkedIn: [linkedin.com/in/sudeepchaurasiya](https://linkedin.com/in/sudeepchaurasiya)
- GitHub: [github.com/sudeep0449](https://github.com/sudeep0449)
