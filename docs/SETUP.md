# Setup and Cost Safety

## 1. Account and trial

- Sign up for the Google Cloud Free Trial: US$300 credit, valid for 90 days. Google states you are not billed for usage during the trial.
- If the console says **"Your free trial requires a prepayment"**, the trial stays **pending** until the prepayment clears. Products can be limited for up to 24 hours. The prepayment is held on your billing account as a balance. Pay the smallest amount it allows.
- Trial limits: no GPUs (Graphics Processing Units), no Windows Server VMs, no Marketplace, no quota increases. None of these projects need them.

## 2. Set a budget alert first

Console → **Billing → Budgets & alerts → Create budget**
- Scope: all projects
- Amount: a small amount, for example 10 in your billing currency
- Alert thresholds: 50%, 90%, 100% (email to billing admins)

Project 05 scripts this with `gcloud billing budgets create`.

## 3. Use Cloud Shell

Open **Cloud Shell** (the `>_` icon at the top right of the console). It has the `gcloud` CLI, `git` and Terraform pre-installed and is already authenticated.

```bash
git clone https://github.com/sudeep0449/gcp-cloud-portfolio.git
cd gcp-cloud-portfolio
gcloud config set project YOUR_PROJECT_ID
chmod +x */*.sh
```

## 4. Enable the APIs used across the projects

```bash
gcloud services enable compute.googleapis.com iap.googleapis.com \
  monitoring.googleapis.com logging.googleapis.com \
  billingbudgets.googleapis.com cloudresourcemanager.googleapis.com iam.googleapis.com
```

## 5. Golden rules

1. Run `cleanup.sh` as soon as you have your screenshots.
2. Check **Billing → Reports** weekly.
3. Never commit service account keys to GitHub (`.gitignore` blocks common key names).
4. Hide your project ID and billing account ID in screenshots before posting them publicly.
