# Insizon Terraform (AWS)

Infrastructure-as-code for Insizon’s AWS stack using **Terraform**.
Single repo, **per-env YAML config**, **remote state** in S3/DynamoDB, and **“dumb” modules** (no file paths or side effects). Root drives all orchestration.

---

## Table of Contents

1. Overview
2. Project Structure
3. Environments & Config
4. Backends (Remote State)
5. Usage
6. Shell Scripts
7. Modules
8. Generated Artifacts (CSV, static uploads)
9. Security Notes
10. Troubleshooting

---

## 1) Overview

* **Environments**: `dev`, `qa`, `prod` (selected by shell/CI; env is **not** inside YAML).
* **Config-first**: Everything toggled via `config/<env>/*.yaml`, each with `enabled: true|false`.
* **Modules are pure**: No filesystem writes; all file exports happen in **root**.
* **Private artifacts**: Stored under `private/insizonxcontractor-<env>-bucket/...`.

---

## 2) Project Structure

```bash
index.sh                  # Interactive launcher (optional)
shell/                    # Ops helpers (plan/apply/destroy/normalize/etc.)
src/
  backend/                # *.hcl (one per env)
  config/
    dev/                  # Env-scoped YAML (no "env:" keys in files)
      apps.yaml
      budget.yaml
      cloudfront.yaml
      codebuild.yaml
      ecr.yaml
      elasticbeanstalk.yaml
      glacier.yaml
      kms.yaml
      lambda-event.yaml
      rds.yaml
      sms.yaml
      sns.yaml
      static-files.yaml
      user-roles.yaml
  modules/                # Terraform modules (dumb/pure)
    beanstalk/
    budgets/
    codebuild/
    ecr/
    iam/
      roles/
      users/
    lambda_event/
    rds/
    s3/
      cloudfront/         # CF submodule (no file writes)
    s3_static_upload/
    glacier/
    kms/
    sms/
  providers.tf
  backend.tf
  variables.tf
  locals.tf               # Loads YAML, validates, builds maps
  root.tf                 # All orchestration & any file exports
  outputs.tf
private/                  # Git-ignored per-env artifacts (normalized)
  dev/
    cloudfront/...
    iam_access_keys/...
    secret_manager_secrets/...
    static-bucket-*/...
```

---

## 3) Environments & Config

* **Selection**: The env (`dev|qa|prod`) is passed from shell/CI and used to pick `src/config/<env>/*.yaml`.
* **Do not put `env:` values inside YAML**, env is **derived**, not declared.
* **Every YAML starts with:**

  ```yaml
  enabled: true   # or false to skip that stack
  ```

* **Key YAML files**:

  * `apps.yaml` – app inventory + CloudFront key-group binding
  * `cloudfront.yaml` – key-groups, behaviors, geo restrictions, public-key aliases
  * `user-roles.yaml` – IAM users/limits/roles (admin/developer/readOnly/serviceAccount)
  * `static-files.yaml` – shared static bucket name + per-app folders/exclusions
  * `lambda-event.yaml`, `elasticbeanstalk.yaml`, `ecr.yaml`, `budget.yaml`, `sns.yaml`
  * `codebuild.yaml`, `kms.yaml`, `rds.yaml`, `glacier.yaml`, `sms.yaml`

Validation is **fail-fast** in `locals.tf`, wrong/missing keys stop the plan with clear messages.

---

## 4) Backends (Remote State)

Backend descriptors live in `src/backend/*.hcl`. Example:

```hcl
# src/backend/dev.hcl
bucket         = "insizon-terraform-remote-state-backend-bucket"
key            = "terraform-aws/dev.tfstate"
region         = "us-east-2"
dynamodb_table = "terraform-locks"
encrypt        = true
```

Use one per env (`dev.hcl`, `qa.hcl`, `prod.hcl`).
Shell scripts wire the correct one during `init`.

---

## 5) Usage

### Interactive

```bash
bash index.sh
```

### Direct

```bash
# Plan / Apply / Destroy
bash shell/plan.sh dev
bash shell/apply.sh dev
bash shell/destroy.sh dev

# Show outputs
bash shell/output.sh dev

# Format TF
bash shell/fmt.sh
```

> Ensure you have AWS creds/profile configured before running.

---

## 6) Shell Scripts

* `backend_init.sh` – `terraform init` with the correct `*.hcl`
* `ensure_backend.sh` – sanity checks for S3/DynamoDB backends
* `plan.sh`, `apply.sh`, `destroy.sh`, `output.sh`, `fmt.sh`
* `normalize_private.sh` – keeps `private/` in the normalized per-env layout

  * Dry-run: `bash shell/normalize_private.sh`
  * Apply:   `bash shell/normalize_private.sh --apply`

---

## 7) Modules

Modules are intentionally **dumb**: no paths, no local writes.

* **s3/** – private S3 bucket (versioning/encryption optional) + optional CloudFront via submodule
* **s3/cloudfront/** – CloudFront distribution & OAC. **No file exports.**
* **iam/users** – creates users/keys (no CSV write)
* **iam/roles** – role matrix (privileged/readonly), per `user-roles.yaml`
* **beanstalk**, **ecr**, **budgets**, **lambda\_event**, **rds**, **kms**, **glacier**, **sms**, **sns**, **s3\_static\_upload**

**All file exports (CSV, etc.) are handled in `root.tf`.**

---

## 8) Generated Artifacts (CSV, static uploads)

**Where:**
`private/insizonxcontractor-<env>-bucket/...`

**What generates them:**

* **CloudFront CSV** (per app) – created at **root**:

  ```bash
  private/.../cloudfront/id/<app>-<env>-KeyPair-n-DistributionSubdomain.csv
  ```

  Columns: `Aws_CloudFront_KeyPairId, Aws_Cloudfront_DistributionSubdomain, S3_Bucket`

* **IAM credentials CSV** – optional (created at **root** if export is enabled there):

  ```bash
  private/.../iam_access_keys/<user>-keys.csv
  ```

  Columns: `access_key, secret_key, console_password`

* **Static uploads** (from `static-files.yaml`) via `s3_static_upload` module to shared bucket:

  ```bash
  <static_folder_name>-<env>
  ```

> Everything in `private/` is git-ignored. Keep it encrypted at rest (disk/Vault) as needed.

---

## 9) Security Notes

* **Never** commit credentials or tokens.
* Keep `private/` outside backups shared with untrusted parties.
* Use **AWS SSM Parameter Store / Secrets Manager** for runtime secrets; YAML only points to names/paths, never raw secrets.
* Limit IAM policies by role and app per `user-roles.yaml` with `limit:` lists.

---

## 10) Troubleshooting

* **“file … not found”**
  Ensure the normalized path `private/<env>/...` exists.

* **Backend lock errors**
  Recreate `terraform-locks` DynamoDB table or point scripts to the correct one. Make sure the S3 bucket exists and you have access.

* **YAML validation failures**
  Read the exact assertion in plan output and fix the missing keys or set `enabled: false` for that stack.

* **CloudFront/OAC policy race**
  Root depends on the CloudFront module outputs when building S3 bucket policy. The provided code already wires those dependencies; don’t inline CF in S3.

---

### Quick Start

```bash
# Clone the repo
git clone https://github.com/insizon/terraform-aws.git

# ensure aws credentials named profile exists and is correctly defined in shared_credentials_file
backends/*.hcl      # review dev, qa, prod files before running script
profile=insizon     # match with ~/.aws/credentials

# run script
./index.sh

# Select environment
(dev, qa, prod)

# Pull private directory from bucket
- Dry run to see changes
- Pull to apply changes

# Open terraform menu
Select the desired action to perform (i.e. format, plan, apply, output, destroy)
```

That’s it. AWS-only, config-driven, with modules kept clean and all paths centralized at root.
