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

5. **Grant bucket permissions**

   If other users or automation need access, grant them Storage roles on the bucket. Example for another engineer:
   ```bash
   gsutil iam ch user:teammate@example.com:roles/storage.objectAdmin gs://<BUCKET_NAME>
   ```

6. **Create a Terraform service account (recommended)**

   ```bash
   gcloud iam service-accounts create terraform --display-name "Terraform"
   ```

   Grant it the permissions required for both the state bucket and the resources Terraform will manage. As a starting point:
   ```bash
   # GCS access for Terraform state
   gcloud projects add-iam-policy-binding <PROJECT_ID> \
     --member "serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" \
     --role roles/storage.objectAdmin

   # Resource management (adjust to match the services you provision)
   gcloud projects add-iam-policy-binding <PROJECT_ID> \
     --member "serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" \
     --role roles/compute.admin
   gcloud projects add-iam-policy-binding <PROJECT_ID> \
     --member "serviceAccount:terraform@<PROJECT_ID>.iam.gserviceaccount.com" \
     --role roles/iam.serviceAccountUser
   ```

   Optional: generate a key for local runs (Cloud Shell can impersonate without a key):
   ```bash
   gcloud iam service-accounts keys create terraform-sa.json \
     --iam-account terraform@<PROJECT_ID>.iam.gserviceaccount.com
   ```
   Keep the key file secure and consider rotating it periodically.

7. **Reference the bucket from Terraform**
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

8. **Configure credentials for Terraform**

   - If you created a key file, set:
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS="$PWD/terraform-sa.json"
     ```
   - If you prefer impersonation (no key file), run:
     ```bash
     gcloud auth application-default login \
       --impersonate-service-account terraform@<PROJECT_ID>.iam.gserviceaccount.com
     ```

9. **Initialize Terraform**

   ```bash
   cd infra
   terraform init
   ```
   Terraform will now use the remote backend in the GCS bucket with the permissions of the Terraform service account.
