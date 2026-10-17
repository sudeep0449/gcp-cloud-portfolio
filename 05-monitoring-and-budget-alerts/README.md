# 05 - Monitoring and Budget Alerts

## Objective

Run a cloud service the way an operations team would. The Ops Agent collects VM metrics and logs. An uptime check probes the site from several regions. Alert policies email me when the site is down or the VM is under pressure. A billing budget warns at 50%, 90% and 100% of spend, plus a forecast alert.

## Architecture

```
           Uptime check (probes from multiple regions)
                        |
  mon-vm (nginx + Ops Agent) --metrics/logs--> Cloud Monitoring / Cloud Logging
                                                       |
                                     Alert policies (uptime failure, CPU > 80%)
                                                       |
                                          Email notification channel
  Cloud Billing ---> Budget (50/90/100% actual, 100% forecast) ---> billing email
```

## Deploy

```bash
cd 05-monitoring-and-budget-alerts
export ALERT_EMAIL=your-email@example.com
export BUDGET_AMOUNT=10
# export BUDGET_CURRENCY=AUD   # only if the budget step says the currency does not match
./deploy.sh
```

## Create the alert policies (console, about 5 minutes)

**Monitoring → Alerting → Create policy**

1. **mon-uptime-failure**: metric *Uptime check → Check passed* for `mon-vm-http`. Condition: fails from 2 or more regions for 1 minute. Channel: *Cloud alerts email*.
2. **mon-high-cpu**: metric *VM Instance → CPU utilization* for `mon-vm`. Condition: above 80% for 5 minutes. Channel: *Cloud alerts email*. Add documentation text such as "Check top processes with `top`, then scale up or investigate."

Name both policies starting with `mon-` so `cleanup.sh` removes them.

## Verify

```bash
# 1. Ops Agent is running
gcloud compute ssh mon-vm --zone=$ZONE --command="sudo systemctl status google-cloud-ops-agent --no-pager | head -5"

# 2. Fire the uptime alert: stop nginx, wait about 3 minutes for the email, then start it again
gcloud compute ssh mon-vm --zone=$ZONE --command="sudo systemctl stop nginx"
gcloud compute ssh mon-vm --zone=$ZONE --command="sudo systemctl start nginx"

# 3. Fire the CPU alert
gcloud compute ssh mon-vm --zone=$ZONE --command="sudo apt-get install -y stress && stress --cpu 2 --timeout 420"

# 4. Read nginx access logs collected by the Ops Agent
gcloud logging read 'resource.type="gce_instance" AND log_id("nginx_access")' --limit=5

# 5. Confirm the budget
gcloud billing budgets list --billing-account=$(gcloud billing projects describe $PROJECT_ID --format='value(billingAccountName)' | sed 's|billingAccounts/||')
```

## Screenshots to capture

1. Uptime check dashboard with probe regions
2. Alert incident page (opened and then resolved)
3. The alert email received (hide personal details)
4. VM metrics from the Ops Agent (memory and disk)
5. Budget page with thresholds (hide the billing account ID)

## Cleanup

```bash
./cleanup.sh
```

The budget stays in place on purpose, because it protects every other project.

## What I learned

- Agent-based metrics (memory, disk, application logs) vs the default hypervisor metrics
- Building alert conditions that avoid noise: duration windows and multi-region uptime failures
- Incident lifecycle: open, acknowledge, resolve
- Budgets alert but do not stop spending; cleanup and quotas are what actually cap cost
