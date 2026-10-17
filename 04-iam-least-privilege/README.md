# 04 - IAM Least-Privilege Design

## Objective

Apply the principle of least privilege with Identity and Access Management (IAM). A workload VM runs as a dedicated service account that can only **create** objects in one backup bucket. It cannot read, list, overwrite or delete them. A custom role gives an operator start/stop control of VMs without create or delete rights. Every change is traced in Cloud Audit Logs.

## Design

| Identity | Role | Scope | Can | Cannot |
|----------|------|-------|-----|--------|
| `backup-writer` service account | `roles/storage.objectCreator` | `gs://<project>-backups` only | Upload new backup files | List, read, overwrite or delete; touch any other bucket |
| Operator (optional second Google account) | Custom `vmOperator` | Project | Start, stop, reset, view VMs | Create, delete or modify VMs |

**Why not the default service account?** The Compute Engine default service account often holds the broad **Editor** role on the project. A compromised VM would then control almost everything. A dedicated, narrowly bound service account limits the damage.

## Deploy

```bash
cd 04-iam-least-privilege
./deploy.sh
```

## Verify (the "allowed vs denied" test)

```bash
gcloud compute ssh iam-test-vm --zone=$ZONE
# --- inside the VM (it authenticates as backup-writer automatically) ---
BUCKET="$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id)-backups"
echo "backup $(date)" > backup.txt

gcloud storage cp backup.txt gs://$BUCKET/          # ALLOWED  - objectCreator
gcloud storage ls gs://$BUCKET/                     # DENIED   - no storage.objects.list
gcloud storage rm gs://$BUCKET/backup.txt           # DENIED   - no storage.objects.delete
gcloud compute instances list                       # DENIED   - no compute permissions
exit
```

Optional: grant the custom role to a second Google account and confirm it can stop a VM but not create one.

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:SECOND_ACCOUNT@gmail.com" --role="projects/$PROJECT_ID/roles/vmOperator"
```

### Audit trail

Admin Activity audit logs are always on. Find who changed IAM policies:

```bash
gcloud logging read \
  'protoPayload.methodName:"SetIamPolicy" OR protoPayload.methodName:"CreateRole"' \
  --limit=10 --format="table(timestamp,protoPayload.authenticationInfo.principalEmail,protoPayload.methodName,resource.type)"
```

Use the IAM **Policy Analyzer** or **Policy Troubleshooter** in the console to explain why a request was denied.

## Screenshots to capture

1. IAM page showing the service account and the custom role
2. Bucket Permissions tab with the `objectCreator` binding
3. Terminal: one ALLOWED and three DENIED (403) results
4. Logs Explorer showing the `SetIamPolicy` audit entries

## Cleanup

```bash
./cleanup.sh
```

## What I learned

- Binding roles at the lowest resource level (bucket) instead of the project
- Predefined vs custom roles, and the permissions inside a role
- How VMs get credentials from the metadata server, so no key files are needed
- Reading Admin Activity audit logs for change tracking
