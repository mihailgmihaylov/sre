# Task 2 – Terraform on Google Cloud

## Remote state setup (Google Cloud Storage)

Terraform configurations in this repository will store their remote state in a Google Cloud Storage (GCS) bucket. Follow the steps below once per project. The commands assume that you have already authenticated via `gcloud auth login` and `gcloud auth application-default login`.

1. **Select the project**
   ```bash
   gcloud config set project <PROJECT_ID>
   ```

2. **Choose a globally unique bucket name**
   Terraform requires the state bucket name to be unique across all of Google Cloud. A common pattern is `<project-id>-tf-state`.

3. **Create the bucket (in a region close to your resources)**
   ```bash
   gsutil mb -p <PROJECT_ID> -l <REGION> -b on gs://<BUCKET_NAME>/
   ```
   - `-b on` enables uniform bucket-level access for simpler IAM control.

4. **Enable object versioning (recommended)**
   ```bash
   gsutil versioning set on gs://<BUCKET_NAME>/
   ```
   This allows Terraform state rollbacks if a bad change is applied.

5. **Reference the bucket from Terraform**
   Backend configuration will be placed in `infra/backend.tf`, for example:
   ```hcl
   terraform {
     backend "gcs" {
       bucket  = "<BUCKET_NAME>"
       prefix  = "terraform/state"
     }
   }
   ```
   Replace `<BUCKET_NAME>` with the bucket created above. The `prefix` determines the folder path inside the bucket and can be adjusted per environment.

Once these steps are complete, running `terraform init` inside the `infra` directory will configure the remote backend automatically.
