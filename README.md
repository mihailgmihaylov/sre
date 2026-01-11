# Site Reliability Engineer tasks

This repo stores two technical problems for an SRE engineer.

## Task 1 – Certificate Expiry Date Checker

The goal is to provide the smallest possible tool that prints when a set of HTTPS certificates will expire. The script runs locally, can be containerised, and is ready for a simple CronJob.

### Project layout

```
cert_checker/
├── cert_checker.py          # Tiny Python script
├── config/
│   └── sites.json           # List of sites to scan
├── Dockerfile               # Container image definition
└── k8s/
    └── cronjob.yaml         # Example CronJob for Kubernetes/minikube
```

### Configuration (`cert_checker/config/sites.json`)

```json
{
  "sites": [
    "example.com",
    {
      "host": "expired.badssl.com",
      "port": 443
    }
  ]
}
```

- An entry can be a string (`"example.com"`, defaults to port 443) or an object with `host` and optional `port`.
- Provide as many sites as you need; the script will loop through them sequentially.

### Local execution

```bash
python3 cert_checker/cert_checker.py \
  --config cert_checker/config/sites.json \
  --timeout 5
```

The output is straightforward, for example:

```
Checking 1 site(s)...
example.com:443 -> expires 2024-06-01 12:00:00 UTC (90 days left)
```

### Docker image

Build the image and run the script inside a container:

```bash
# Build
docker build -t cert-checker:latest cert_checker

# Run
docker run --rm \
  -v "$PWD/cert_checker/config:/config:ro" \
  cert-checker:latest \
  --config /config/sites.json --timeout 5
```

### Kubernetes / minikube

1. Build and push your image to a registry reachable by the cluster (update the image field in `cert_checker/k8s/cronjob.yaml`).
2. Create a namespace (optional but recommended):
   ```bash
   kubectl create namespace sre-tools
   ```
3. Create/update the ConfigMap that provides `sites.json` to the pod:
   ```bash
   kubectl create configmap cert-checker-config \
     --namespace sre-tools \
     --from-file=sites.json=cert_checker/config/sites.json \
     --dry-run=client -o yaml | kubectl apply -f -
   ```
4. Deploy the CronJob:
   ```bash
   kubectl apply -n sre-tools -f cert_checker/k8s/cronjob.yaml
   ```

The CronJob runs the checker every hour (`schedule: "0 * * * *"`). Adjust the schedule or container arguments to fit your needs. Logs can be viewed via `kubectl logs job/<job-name> -n sre-tools`.

---

The second task (infrastructure automation) is currently a placeholder for future work.

## Task 2 – Infrastructure Automation on Google Cloud

The `infra/` directory contains a single Terraform configuration that builds the required stack on Google Cloud:

- A custom VPC with web/database subnets and firewall policies.
- A zonal Managed Instance Group (Debian + Nginx) behind a global HTTP load balancer.
- A MariaDB VM that serves as the database tier and lives on its own subnet.

### Usage overview

1. Follow `infra/README.md` to create a GCS bucket for Terraform state, a Terraform service account, and enable the Compute API.
2. Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars` and populate at least `project_id`, `region`, and the database passwords.
3. Initialize, plan, and apply:
   ```bash
   cd infra
   terraform init
   terraform plan
   terraform apply
   ```
4. Terraform outputs the load-balancer URL (pointing to the simple web app) and the internal IP/connection string for the MariaDB VM.
5. Run `terraform destroy` when you are done with the demo to avoid charges.

The Managed Instance Group plus global HTTP load balancer automatically replaces failed VMs, delivering the required fail-over behavior with minimal code.
