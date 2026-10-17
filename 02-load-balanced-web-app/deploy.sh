#!/usr/bin/env bash
# Project 02 - Global external Application Load Balancer in front of an autoscaling MIG
set -euo pipefail
cd "$(dirname "$0")"
source ../config.sh

VPC=lb-vpc

echo "== 1. Network =="
gcloud compute networks create "$VPC" --subnet-mode=custom
gcloud compute networks subnets create lb-subnet --network="$VPC" --region="$REGION" --range=10.20.1.0/24

# Only Google Front End health-check / proxy ranges may reach the backends on port 80
gcloud compute firewall-rules create "$VPC"-allow-health-check \
  --network="$VPC" --direction=INGRESS --action=ALLOW --rules=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=lb-backend
gcloud compute firewall-rules create "$VPC"-allow-iap-ssh \
  --network="$VPC" --direction=INGRESS --action=ALLOW --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 --target-tags=lb-backend

echo "== 2. Instance template (backends have no external IP) =="
gcloud compute instance-templates create web-template \
  --machine-type="$MACHINE_TYPE" \
  --network="$VPC" --region="$REGION" --subnet=lb-subnet \
  --no-address --tags=lb-backend \
  --image-family=debian-12 --image-project=debian-cloud \
  --metadata-from-file=startup-script=startup.sh

# Backends need outbound internet to install nginx -> Cloud NAT
gcloud compute routers create lb-router --network="$VPC" --region="$REGION"
gcloud compute routers nats create lb-nat --router=lb-router --region="$REGION" \
  --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges

echo "== 3. Health check + regional MIG with autohealing and autoscaling =="
gcloud compute health-checks create http web-hc --port=80 --request-path=/ \
  --check-interval=10s --timeout=5s --healthy-threshold=2 --unhealthy-threshold=3

gcloud compute instance-groups managed create web-mig \
  --region="$REGION" --template=web-template --size=2 \
  --health-check=web-hc --initial-delay=120
gcloud compute instance-groups managed set-named-ports web-mig \
  --region="$REGION" --named-ports=http:80
gcloud compute instance-groups managed set-autoscaling web-mig \
  --region="$REGION" --min-num-replicas=2 --max-num-replicas=4 \
  --target-cpu-utilization=0.60 --cool-down-period=90

echo "== 4. Load balancer: backend service -> URL map -> HTTP proxy -> forwarding rule =="
gcloud compute backend-services create web-backend \
  --load-balancing-scheme=EXTERNAL_MANAGED --protocol=HTTP \
  --port-name=http --health-checks=web-hc --global
gcloud compute backend-services add-backend web-backend \
  --instance-group=web-mig --instance-group-region="$REGION" \
  --balancing-mode=UTILIZATION --max-utilization=0.8 --global
gcloud compute url-maps create web-map --default-service=web-backend
gcloud compute target-http-proxies create web-proxy --url-map=web-map
gcloud compute addresses create web-ip --ip-version=IPV4 --global
gcloud compute forwarding-rules create web-fr \
  --load-balancing-scheme=EXTERNAL_MANAGED --network-tier=PREMIUM \
  --address=web-ip --target-http-proxy=web-proxy --ports=80 --global

LB_IP=$(gcloud compute addresses describe web-ip --global --format='get(address)')
echo
echo "Load balancer IP: http://$LB_IP  (allow 3-5 minutes for backends to turn healthy)"
