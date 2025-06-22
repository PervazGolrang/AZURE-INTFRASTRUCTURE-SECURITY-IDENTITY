# Step 4 - Storage and Private Endpoints  - WIP

This step configures a secure Azure Storage Account with logging, private endpoint access, and access control via shared access signatures (SAS). It avoids public exposure while retaining diagnostic and operational capability.

## 4.1 - Create Storage Account

```bash
az storage account create \
  --name stsecureneu01 \
  --resource-group rg-secure-vm-01 \
  --location northeurope \
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

I recommend using the Azure Portal, it’s quicker and avoids the messy CLI syntax or needing your subscription ID.

This can be accomplished at Storage Account (stsecureneu01) > Monitoring > Diagnostic Settings. Click on **blob**. Then click **+ Add diagnoistic settings**, name is `diag-settings-storage`. Under **Log** check:
- StorageRead
- StorageWrite
- StorageDelete

Check **send to Log Analytics workspace**. Then choose your workspace `log-core-neu01`.

### Azure Cloud Shell method:
Enable platform logging to Log Analytics:

```bash
az monitor diagnostic-settings create \
  --name diag-settings-storage \
  --resource-group rg-secure-vm-01 \
  --resource /subscriptions/<SUB_ID>/resourceGroups/rg-secure-vm-01/providers/Microsoft.Storage/storageAccounts/stsecureneu01 \
  --workspace log-core-neu01 \
  --logs '[{"category": "StorageRead", "enabled": true}, {"category": "StorageWrite", "enabled": true}, {"category": "StorageDelete", "enabled": true}]'
```

Replace `<SUB_ID>` with your subscription ID.

## 4.3 - Create Private Endpoint for Storage

This removes public network dependency.

```bash
az network private-endpoint create \
  --name pe-storage-blob \
  --resource-group rg-secure-vm-01 \
  --vnet-name vnet-core-neu01 \
  --subnet subnet-jumphost01 \
  --private-connection-resource-id $(az storage account show --name stsecureneu01 --query id -o tsv) \
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
  --virtual-network vnet-core-neu01 \
  --registration-enabled false

az network private-endpoint dns-zone-group create \
  --resource-group rg-secure-vm-01 \
  --endpoint-name pe-storage-blob \
  --name blob-zone-group \
  --private-dns-zone privatelink.blob.core.windows.net \
  --zone-name privatelink.blob.core.windows.net
```

Test that `stsecureneu01.blob.core.windows.net` resolves to a private IP from the VM.

## 4.5 - Generate Shared Access Signature (SAS)

```bash
az storage container create \
  --account-name stsecureneu01 \
  --name container01 \
  --auth-mode login

# Highly recommended to use CLI.
az storage container generate-sas \
  --account-name stsecureneu01 \
  --name container01 \
  --permissions rwl \
  --expiry $(date -u -d "+6 days" +"%Y-%m-%dT%H:%MZ") \
  --auth-mode login \
  --as-user \
  --output tsv
```

The main reason to use the CLI instead of the Portal is that the Web UI only supports key-based SAS tokens, not user delegation SAS (`--as-user`). This is a limitation in Azure, not a feature gap. If you want a SAS token tied to your Microsoft Entra ID, you must use the CLI. Do note that the `--as-user` supports a maximum of 7 days.

## 4.6 - Validate Access from VM

SSH or RDP into the VM via Bastion.

- Install PowerShell to access blob using SAS
- Create a testfile.txt

```powershell
az storage blob upload \
  --account-name stsecureneu01 \
  --container-name container01 \
  --file "C:\Users\labadmin\textfile" \
  --name uploadedfile.txt \
  --sas-token "<sas-token>"
```

Or use `curl`/`wget` to access via HTTPS endpoint and confirm connectivity.

## Screenshots

![07-private-endpoint-blob.png](images/07-private-endpoint-blob.png)
![08-dns-resolution.png](images/08-dns-resolution.png)
![09-sas.png](images/09-sas.png)