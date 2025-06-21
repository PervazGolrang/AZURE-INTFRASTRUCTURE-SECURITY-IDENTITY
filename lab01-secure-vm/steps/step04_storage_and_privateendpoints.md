# Step 4 - Storage and Private Endpoints  - WIP

This step configures a secure Azure Storage Account with logging, private endpoint access, and access control via shared access signatures (SAS). It avoids public exposure while retaining diagnostic and operational capability.

## 4.1 - Create Storage Account

```bash
az storage account create \
  --name stsecureweu01 \
  --resource-group rg-secure-vm-01 \
  --location westeurope \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-hierarchical-namespace false \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false
```

Confirm it's created with secure defaults:
- Public access disabled
- HTTPS only
- TLS 1.2 minimum

## 4.2 - Enable Storage Account Diagnostics

Enable platform logging to Log Analytics:

```bash
az monitor diagnostic-settings create \
  --name diag-settings-storage \
  --resource-group rg-secure-vm-01 \
  --resource /subscriptions/<SUB_ID>/resourceGroups/rg-secure-vm-01/providers/Microsoft.Storage/storageAccounts/stsecureweu01 \
  --workspace log-core-weu01 \
  --logs '[{"category": "StorageRead", "enabled": true}, {"category": "StorageWrite", "enabled": true}, {"category": "StorageDelete", "enabled": true}]'
```

Replace `<SUB_ID>` with your subscription ID.

## 4.3 - Create Private Endpoint for Storage

This removes public network dependency.

```bash
az network private-endpoint create \
  --name pe-storage-blob \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-weu01 \
  --subnet subnet-jumphost-01 \
  --private-connection-resource-id $(az storage account show --name stsecureweu01 --query id -o tsv) \
  --group-id blob \
  --connection-name conn-storage-blob
```

Approve the connection if not auto-approved.

## 4.4 - Create Private DNS Zone and Link

```bash
az network private-dns zone create \
  --resource-group rg-secure-vm-01 \
  --name privatelink.blob.core.windows.net

az network private-dns link vnet create \
  --resource-group rg-secure-vm-01 \
  --zone-name privatelink.blob.core.windows.net \
  --name link-vnet-core \
  --virtual-network vnet-core-weu01 \
  --registration-enabled false

az network private-endpoint dns-zone-group create \
  --resource-group rg-secure-vm-01 \
  --endpoint-name pe-storage-blob \
  --name blob-zone-group \
  --private-dns-zone privatelink.blob.core.windows.net \
  --zone-name privatelink.blob.core.windows.net
```

Test that `stsecureweu01.blob.core.windows.net` resolves to a private IP from the VM.

## 4.5 - Generate Shared Access Signature (SAS)

```bash
az storage container create \
  --account-name stsecureweu01 \
  --name container01 \
  --auth-mode login

az storage container generate-sas \
  --account-name stsecureweu01 \
  --name container01 \
  --permissions rwl \
  --expiry 2025-12-31T23:59Z \
  --auth-mode login \
  --as-user \
  --output tsv
```

Store the SAS token securely.

## 4.6 - Validate Access from VM

SSH or RDP into the VM via Bastion.

Install Azure CLI or use PowerShell to access blob using SAS:

```powershell
az storage blob upload \
  --account-name stsecureweu01 \
  --container-name container01 \
  --file testfile.txt \
  --name uploadedfile.txt \
  --sas-token "<sas-token>"
```

Or use `curl`/`wget` to access via HTTPS endpoint and confirm connectivity.

## 4.7 - KQL Log Verification

```kusto
AzureDiagnostics
| where Resource contains "stsecureweu01"
| sort by TimeGenerated desc
```

## Screenshots

Save:
- `08-private-endpoint-blob.png`
- `09-dns-resolution.png`
- `10-log-storage-access.png`