# 02 - Load-Balanced, Auto-Scaling Web App

## Objective

Deploy a highly available web tier. A global external Application Load Balancer (layer 7) sits in front of a regional Managed Instance Group (MIG) spread across zones in Sydney. The group heals failed VMs automatically and scales from 2 to 4 instances on CPU (Central Processing Unit) load. The backends have no public IPs.

## Architecture

```
 Client --> Global anycast IP (web-ip) :80
              |
        Forwarding rule (EXTERNAL_MANAGED)
              |
        Target HTTP proxy --> URL map --> Backend service (health check web-hc)
                                               |
                         Regional MIG web-mig (australia-southeast1-a/b/c)
                         +---------+  +---------+  ... up to 4
                         | nginx   |  | nginx   |   no external IPs
                         +---------+  +---------+   egress via Cloud NAT
```

## Key concepts

| Component | Role |
|-----------|------|
| Instance template | Immutable VM blueprint: machine type, image, tags, startup script |
| Regional MIG | Spreads VMs across zones for zone-failure tolerance |
| Autohealing | The MIG recreates a VM that fails the health check |
| Autoscaler | Target 60% CPU, min 2 / max 4 replicas |
| Named port `http:80` | Maps the backend service's port name to the instance port |
| Health-check firewall rule | 130.211.0.0/22 and 35.191.0.0/16 are the Google Front End ranges used by probes and the proxy |
| Global anycast IP | One IP address advertised from Google's edge worldwide |

## Deploy

```bash
cd 02-load-balanced-web-app
./deploy.sh
```

## Verify

```bash
LB_IP=$(gcloud compute addresses describe web-ip --global --format='get(address)')

# 1. Backend health
gcloud compute backend-services get-health web-backend --global

# 2. Traffic is spread across instances (hostname changes)
for i in $(seq 1 10); do curl -s http://$LB_IP | grep -o 'web-mig-[a-z0-9]*'; done

# 3. Autohealing test: stop nginx on one VM, watch the MIG replace it
gcloud compute instance-groups managed list-instances web-mig --region=$REGION
gcloud compute ssh <instance-name> --zone=<its-zone> --tunnel-through-iap --command="sudo systemctl stop nginx"
watch gcloud compute instance-groups managed list-instances web-mig --region=$REGION

# 4. Autoscaling test: generate CPU load on one VM, then watch the instance count rise
gcloud compute ssh <instance-name> --zone=<its-zone> --tunnel-through-iap \
  --command="sudo apt-get install -y stress && stress --cpu 2 --timeout 300"
```

## Screenshots to capture

1. Load balancer details page showing the frontend and backend
2. Backend health: all instances HEALTHY
3. Terminal showing hostnames changing across requests
4. MIG page during autohealing (instance being recreated)
5. MIG page showing more than 2 instances during the CPU test

## Cleanup

```bash
./cleanup.sh
```

## What I learned

- The chain of objects behind a Google Cloud HTTP load balancer and why each one exists
- Why health checks need their own firewall rule
- Difference between autohealing (health) and autoscaling (load)
- Keeping backends private with Cloud NAT for egress only
