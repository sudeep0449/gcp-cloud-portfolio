# 01 - Secure Virtual Private Cloud (VPC) Network

## Objective

Build a production-style, two-tier network on Google Cloud. A public web tier and a private application tier are separated by firewall rules. Administrators use SSH (Secure Shell) through Identity-Aware Proxy (IAP), so no SSH port is open to the internet. Private VMs reach the internet for updates through Cloud NAT (Network Address Translation) without external IP addresses.

## Architecture

```
                     Internet
                        |  tcp:80 only (tag: web)
        +---------------v----------------------------------+
        |  prod-vpc (custom mode)        australia-southeast1
        |                                                   |
        |  web-subnet 10.10.1.0/24      app-subnet 10.10.2.0/24
        |  +-----------+  tcp:8080,ICMP  +-----------+      |
        |  |  web-vm   | --------------> |  app-vm   |      |
        |  | ext IP    |  (tag web->app) | no ext IP |      |
        |  +-----------+                 +-----+-----+      |
        |        ^                             | egress     |
        |        | SSH from 35.235.240.0/20    v            |
        |      IAP tunnel               Cloud Router + NAT  |
        +---------------------------------------------------+
```

## Design decisions

| Decision | Why |
|----------|-----|
| Custom-mode VPC | Full control over CIDR (Classless Inter-Domain Routing) ranges; auto-mode creates a subnet in every region and can overlap with on-premises ranges |
| /24 per tier inside 10.10.0.0/16 | Leaves room for more tiers and future VPN or peering without overlap |
| SSH only from 35.235.240.0/20 | This is Google's IAP TCP forwarding range. Access is controlled by IAM (Identity and Access Management) instead of open port 22 |
| Tag-based rules (web → app) | Rules follow the workload, not the IP. A new web VM gets access by its tag |
| Cloud NAT with logging | Private VMs can patch and update; NAT logs give an audit trail of outbound connections |
| Private Google Access on app-subnet | VMs without external IPs can still reach Google APIs such as Cloud Storage |

## Deploy

```bash
cd 01-secure-vpc-network
./deploy.sh
```

## Verify

```bash
# 1. Web tier answers on HTTP from the internet
WEB_IP=$(gcloud compute instances describe web-vm --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
curl http://$WEB_IP

# 2. SSH to the private VM through IAP (no external IP needed)
gcloud compute ssh app-vm --zone=$ZONE --tunnel-through-iap

# 3. Inside app-vm: outbound internet works via Cloud NAT
curl -s ifconfig.me ; echo      # shows the NAT IP, not a VM IP
sudo apt-get update             # succeeds through NAT

# 4. Inside app-vm: confirm it has no external interface address
ip -4 addr show

# 5. Review the effective firewall rules
gcloud compute firewall-rules list --filter="network:prod-vpc" \
  --format="table(name,direction,sourceRanges.list(),sourceTags.list(),targetTags.list(),allowed[].map().firewall_rule().list())"
```

Expected: web page loads, IAP SSH works, `curl ifconfig.me` shows the NAT address, and an SSH attempt straight to the web-vm's external IP from your PC times out.

## Screenshots to capture

1. VPC network → subnets list
2. Firewall rules list
3. Cloud NAT gateway details
4. Terminal: IAP SSH session into `app-vm` with `curl ifconfig.me`
5. Browser showing the web-vm page

## Cleanup

```bash
./cleanup.sh
```

## What I learned

- How Google Cloud's implied deny-all ingress and allow-all egress rules shape firewall design
- Using network tags to apply rules to workloads instead of fixed IPs
- Why Cloud NAT is a regional, software-defined service attached to a Cloud Router, not a VM appliance
- IAP TCP forwarding as a bastion-host replacement
