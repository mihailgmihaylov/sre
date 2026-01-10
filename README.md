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
