#!/usr/bin/env bash
# Project 01 - Secure custom-mode VPC with segmented subnets, IAP SSH and Cloud NAT
set -euo pipefail
cd "$(dirname "$0")"
source ../config.sh

VPC=prod-vpc

echo "== 1. Custom-mode VPC (no auto subnets) =="
gcloud compute networks create "$VPC" --subnet-mode=custom --bgp-routing-mode=regional

echo "== 2. Subnets: public web tier and private app tier =="
gcloud compute networks subnets create web-subnet \
  --network="$VPC" --region="$REGION" --range=10.10.1.0/24
gcloud compute networks subnets create app-subnet \
  --network="$VPC" --region="$REGION" --range=10.10.2.0/24 \
  --enable-private-ip-google-access

echo "== 3. Firewall rules (default deny ingress is implied) =="
# SSH only from Google's IAP TCP forwarding range - no SSH open to the internet
gcloud compute firewall-rules create "$VPC"-allow-iap-ssh \
  --network="$VPC" --direction=INGRESS --action=ALLOW --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 --priority=1000
# HTTP from the internet to web-tagged VMs only
gcloud compute firewall-rules create "$VPC"-allow-http \
  --network="$VPC" --direction=INGRESS --action=ALLOW --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 --target-tags=web --priority=1000
# Web tier may reach app tier on 8080 and ICMP; nothing else east-west
gcloud compute firewall-rules create "$VPC"-allow-web-to-app \
  --network="$VPC" --direction=INGRESS --action=ALLOW --rules=tcp:8080,icmp \
  --source-tags=web --target-tags=app --priority=1000

echo "== 4. Cloud Router + Cloud NAT for private VMs' outbound traffic =="
gcloud compute routers create nat-router --network="$VPC" --region="$REGION"
gcloud compute routers nats create nat-config \
  --router=nat-router --region="$REGION" \
  --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges \
  --enable-logging

echo "== 5. VMs =="
gcloud compute instances create web-vm \
  --zone="$ZONE" --machine-type="$MACHINE_TYPE" \
  --subnet=web-subnet --tags=web \
  --image-family=debian-12 --image-project=debian-cloud \
  --metadata=startup-script='#! /bin/bash
apt-get update && apt-get install -y nginx
echo "<h1>web-vm - $(hostname) - Project 01</h1>" > /var/www/html/index.html'

# Private VM: no external IP (--no-address); internet only through Cloud NAT
gcloud compute instances create app-vm \
  --zone="$ZONE" --machine-type="$MACHINE_TYPE" \
  --subnet=app-subnet --tags=app --no-address \
  --image-family=debian-12 --image-project=debian-cloud

echo
echo "Done. Verify with the steps in README.md, then run ./cleanup.sh"
gcloud compute instances list --filter="name~'-vm$'"
