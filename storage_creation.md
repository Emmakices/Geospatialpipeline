# Geospatial ETL ? Phase 1 Documentation

## Provisioning Raw Storage & Validating Ingested Data (Azure + Terraform)

## 1. Purpose of This Phase (What We?re Solving)

The goal of this phase was to build a reliable and auditable raw data ingestion layer for geospatial data (OpenStreetMap .pbf files).

In real-world data engineering:

- Raw data should never go straight into a database
- It should first land in object storage
- Be validated
- Be traceable
- And only then be processed downstream

This phase sets up that foundation.

## 2. Infrastructure as Code: Why Terraform?

We used Terraform to provision Azure resources because:

- Infrastructure becomes repeatable
- Changes are version-controlled
- Environments (dev / prod) are consistent
- It?s the industry standard for cloud data platforms

In production, clicking around the Azure Portal is discouraged. Infrastructure must be code.

## 3. Azure Resources We Created

Using Terraform, we provisioned the following:

### 3.1 Resource Group

A logical container for everything related to this pipeline.

- Name: rg-geospatial-pipeline
- Region: Canada Central

This keeps the project isolated and easy to manage or delete.

### 3.2 Storage Account (Raw Zone)

This is where raw, unmodified datasets are stored.

- Name: geopipe2325
- Type: StorageV2
- Replication: LRS (Local Redundant Storage)
- TLS enforced: TLS 1.2
- Public access disabled
- Blob versioning enabled

Why this matters:

- Raw data is preserved exactly as received
- Versioning allows recovery if files are overwritten
- Security defaults are enforced from day one

### 3.3 Blob Container: Raw Data Landing Zone

Inside the storage account, we created a private container:

- Container name: raw-osm
- Access: Private (no anonymous access)

This container represents the ?Raw / Bronze layer? of the data pipeline.

## 4. Git & Version Control (Very Important)

Before touching any data logic, we:

- Initialized a Git repository
- Added a .gitignore to exclude:
  - .terraform/
  - .tfstate files
  - secrets and env files
- Committed:
  - Terraform files
  - Provider lock file
- Pushed everything to GitHub

Why this matters:

- Infrastructure changes are auditable
- Interviewers expect this
- This is how teams collaborate safely

## 5. Uploading the Raw Dataset

We uploaded the file:

- nigeria-260102.osm.pbf

into Blob Storage at this logical path:

- raw-osm/nigeria/nigeria-260102.osm.pbf

This path structure is intentional:

- raw-osm/ ? raw zone
- nigeria/ ? country partition
- file name ? dataset version

This makes it easy to later add:

- Canada
- UK
- USA
- New versions of the same dataset

## 6. Azure RBAC: Real Enterprise Security

Initially, the upload failed ? and that was expected.

Why?

Terraform created the infrastructure, but data-plane access (uploading blobs) requires RBAC.

We solved this properly by:

- Assigning ourselves the role: Storage Blob Data Contributor
- Scoped directly to the storage account
- Using Azure AD authentication, not storage keys

This is a best practice and something interviewers love to hear.

## 7. Data Validation: Why We Don?t Trust Files Blindly

Even if data comes from a trusted source, validation is mandatory.

We implemented basic but powerful validation.

### 7.1 File Size Validation

We retrieved blob properties and confirmed:

- File size: 664,169,053 bytes
- The file is complete and non-empty

This catches:

- Partial uploads
- Corrupted transfers
- Empty or truncated files

### 7.2 Cryptographic Hash Validation (SHA-256)

We computed a SHA-256 hash locally:

- 7F84C9C628B761774DE0EE7897E19F7F15163121368AA43AC035753F11EA232E

Why this matters:

- Guarantees file integrity
- Prevents duplicate processing
- Enables idempotent pipelines

### 7.3 Metadata Attachment (Critical Design Choice)

Instead of storing validation info elsewhere, we attached it directly to the blob as metadata:

- sha256
- country = NG
- dataset = osm

This means:

- Any pipeline can validate the file without a database
- Metadata travels with the data
- Blob Storage becomes self-describing


## Step-by-step Implementation (with real commands)

### 1) Confirm Terraform + Azure CLI
```powershell
terraform -version
az version
az login
az account show --output table
```
Notes:

- Terraform was upgraded successfully.
- Azure login selected subscription: My-project (a5799817-49f0-4302-b5b4-f0c14252f0a2)

### 2) Terraform configuration files created
Files created:

- main.tf
- variables.tf
- outputs.tf
- terraform.tfvars
- .terraform.lock.hcl

terraform.tfvars (important)
This file must contain only variable values (not resources):

```hcl
storage_account_name = "geopipe2325"
```

### 3) Initialize Terraform
```powershell
terraform init
```

### 4) Troubleshooting: Terraform could not determine subscription ID
Error we got:

```
subscription ID could not be determined and was not specified
```

Fix: we explicitly set the subscription ID in the provider:

```hcl
provider "azurerm" {
  features {}
  subscription_id = "a5799817-49f0-4302-b5b4-f0c14252f0a2"
}
```

Then:

```powershell
terraform plan
```

### 5) Troubleshooting: Terraform container deprecation warning
Warning: `storage_account_name` for container is deprecated.

Fix: update container resource to use `storage_account_id`:

```hcl
resource "azurerm_storage_container" "raw" {
  name                  = var.raw_container_name
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}
```

### 6) Terraform plan and apply
```powershell
terraform plan
terraform apply
```

Terraform created 3 resources:

- Resource Group
- Storage Account
- Raw container (`raw-osm`)

## Phase 1 - Upload Raw File to Blob Storage

### 7) Upload Nigeria OSM PBF file
Local file path used:

```
C:\osm_etl\nigeria-260102.osm.pbf
```

Upload command:

```powershell
az storage blob upload `
  --account-name geopipe2325 `
  --container-name raw-osm `
  --name nigeria/nigeria-260102.osm.pbf `
  --file "C:\osm_etl\nigeria-260102.osm.pbf" `
  --auth-mode login
```

### 8) Troubleshooting: Permission error (RBAC missing)
Error we got:

```
You do not have the required permissions needed to perform this operation.
```

Why it happened (real-world explanation): Terraform created the storage account, but data-plane access (uploading blobs) requires RBAC roles.

Fix: assign role Storage Blob Data Contributor.

Get signed-in user object ID:

```powershell
az ad signed-in-user show --query id --output tsv
```

Assign role:

```powershell
az role assignment create `
  --assignee df7eb6d5-1fa4-4864-afd9-4efe1be8b037 `
  --role "Storage Blob Data Contributor" `
  --scope /subscriptions/a5799817-49f0-4302-b5b4-f0c14252f0a2/resourceGroups/rg-geospatial-pipeline/providers/Microsoft.Storage/storageAccounts/geopipe2325
```

Then rerun the upload command.

## Phase 1 - Validation (File Integrity + Traceability)

### 9) Validate blob properties (size, etag)
```powershell
az storage blob show `
  --account-name geopipe2325 `
  --container-name raw-osm `
  --name nigeria/nigeria-260102.osm.pbf `
  --auth-mode login `
  --query "{name:name,size:properties.contentLength,lastModified:properties.lastModified,etag:properties.etag,crc64:properties.contentSettings.contentCrc64}"
```

Result (example):

- Name: nigeria/nigeria-260102.osm.pbf
- Size: 664169053 bytes
- ETag: "0x8DE4BF4C49C211F"

### 10) Compute SHA-256 hash locally
```powershell
Get-FileHash "C:\osm_etl\nigeria-260102.osm.pbf" -Algorithm SHA256 | Format-List
```

Hash used:

```
7F84C9C628B761774DE0EE7897E19F7F15163121368AA43AC035753F11EA232E
```

### 11) Attach hash + dataset metadata to the blob (best practice)
This makes the raw file self-describing for downstream ETL steps.

```powershell
az storage blob metadata update `
  --account-name geopipe2325 `
  --container-name raw-osm `
  --name "nigeria/nigeria-260102.osm.pbf" `
  --auth-mode login `
  --metadata sha256=7F84C9C628B761774DE0EE7897E19F7F15163121368AA43AC035753F11EA232E country=NG dataset=osm
```

Verify metadata:

```powershell
az storage blob show `
  --account-name geopipe2325 `
  --container-name raw-osm `
  --name "nigeria/nigeria-260102.osm.pbf" `
  --auth-mode login `
  --query "metadata"
```

Expected:

```json
{
  "country": "NG",
  "dataset": "osm",
  "sha256": "7F84C9C628B761774DE0EE7897E19F7F15163121368AA43AC035753F11EA232E"
}
```

## Git & GitHub Workflow (Phase 1)

### 12) Initialize Git repo + ignore Terraform state
```powershell
git init
```

Created `.gitignore` to avoid committing:

- .terraform/
- *.tfstate
- *.tfstate.*
- .env

### 13) Commit Terraform infrastructure
```powershell
git add .
git commit -m "Provision raw OSM storage (Terraform): RG, Storage Account, raw container"
```

### 14) Push to GitHub (best practice: main branch)
```powershell
git remote add origin https://github.com/Emmakices/Geospatialpipeline.git
git branch -M main
git push -u origin main
```

## Errors We Encountered (Quick Reference)

### A) Terraform plan failed: tfvars contained resources
Symptom:

```
Unexpected "resource" block on terraform.tfvars
Blocks are not allowed here.
```

Root cause: `terraform.tfvars` should contain only variable assignments, not Terraform resources.

Fix: remove the invalid content and recreate it:

```powershell
Remove-Item -Path .\terraform.tfvars -Force
'storage_account_name = "geopipe2325"' | Out-File -FilePath .\terraform.tfvars -Encoding ascii
```
