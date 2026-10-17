# 03 - Cloud Storage Static Website

## Objective

Host a static portfolio website from a Cloud Storage bucket in Sydney, with no servers to manage. The bucket uses uniform bucket-level access, object versioning for rollback and lifecycle rules for cost control. Public access is limited to reading objects.

## Architecture

```
 Browser --HTTPS--> storage.googleapis.com/<project>-static-site/index.html
                           |
             Bucket (australia-southeast1, STANDARD)
             - Uniform bucket-level access
             - allUsers : roles/storage.objectViewer   (read objects only)
             - Versioning ON
             - Lifecycle: STANDARD -> NEARLINE after 30 days
                          delete non-current versions after 30 days or when 3 newer exist
```

## Design decisions

| Decision | Why |
|----------|-----|
| Uniform bucket-level access | One IAM (Identity and Access Management) policy for the bucket; disables per-object ACLs (Access Control Lists), which are easy to misconfigure |
| `roles/storage.objectViewer` for `allUsers` | Visitors can read files but cannot list the bucket or upload |
| Versioning | An overwritten or deleted page can be restored |
| Lifecycle rules | Old versions are cleaned up automatically, so storage cost cannot grow without limit |
| `Cache-Control: max-age=60` | Changes show up within a minute while testing |

## Deploy

```bash
cd 03-cloud-storage-static-site
./deploy.sh
```

## Verify

```bash
BUCKET="$(gcloud config get-value project)-static-site"

# 1. Site loads
curl -I https://storage.googleapis.com/$BUCKET/index.html

# 2. Versioning: change the page, upload, list versions, restore the old one
echo "<h1>v2</h1>" > /tmp/index.html
gcloud storage cp /tmp/index.html gs://$BUCKET/index.html
gcloud storage ls --all-versions gs://$BUCKET/index.html
gcloud storage cp "gs://$BUCKET/index.html#<OLD_GENERATION>" gs://$BUCKET/index.html

# 3. Check the IAM policy and lifecycle config
gcloud storage buckets get-iam-policy gs://$BUCKET
gcloud storage buckets describe gs://$BUCKET --format="yaml(lifecycle_config,versioning_enabled,website_config)"
```

## Screenshots to capture

1. Bucket details: location, storage class, versioning, lifecycle
2. Permissions tab: uniform access and the `allUsers` viewer binding
3. Browser showing the live page
4. Terminal showing multiple object generations and a restore

## Cleanup

```bash
./cleanup.sh
```

## Extension

Put a global external Application Load Balancer with a backend bucket and a Google-managed SSL (Secure Sockets Layer) certificate in front of the bucket to serve it on a custom domain over HTTPS, and enable Cloud CDN (Content Delivery Network).
