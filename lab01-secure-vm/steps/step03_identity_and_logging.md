# Step 3 – Identity and Logging

This step enables monitoring to a Log Analytics workspace, assigns a managed identity to the VM, and configures RBAC permissions.

## 3.1 – Create Log Analytics Workspace

Create a workspace for diagnostics:

```bash
az monitor log-analytics workspace create \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-core-neu01 \
  --location northeurope
```

Get the workspace ID:

```bash
az monitor log-analytics workspace show \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-core-neu01 \
  --query customerId --output tsv
```

## 3.2 – Enable VM Insights (guest metrics)

VM Insights installs the Azure Monitor Agent on the VM and connects it to the workspace.

This can be done via the Azure Portal:
VM > Monitoring > Insights > Enable, then select your Log Analytics workspace.

## 3.3 – Enable system-assigned managed identity

Enable the system-assigned identity for the VM. This creates a secure service principal for the VM:

```bash
az vm identity assign \
  --resource-group rg-secure-vm-01 \
  --name vm-jhost-neu01
```

Confirm the identity:

```bash
az vm show \
  --resource-group rg-secure-vm-01 \
  --name vm-jhost-neu01 \
  --query identity
```

Remember the <principalId>.

## 3.4 – Assign Reader role to the VM identity

Assign a role to the VM’s identity to demonstrate RBAC in action:

```bash
az role assignment create \
  --assignee-object-id <principalId> \
  --role Reader \
  --scope /subscriptions/<sub_ID>/resourceGroups/rg-secure-vm-01
```
Replace <principalId> with the value returned in step 3.3.
Replace <sub_ID> with your subscribtion ID.

## 3.5 – Validate that data arrives in Log Analytics

Go to the Log Analytics workspace > Logs and run this KQL query:

```kusto
Heartbeat
| where Resource contains "vm-jhost-neu01"
| sort by TimeGenerated desc
```

You should see heartbeat records every minute.
Guest metrics (CPU, memory, disk) will appear in the InsightsMetrics table after a few minutes.

Confirm:
- Heartbeat logs exist
- Guest metrics and performance counters appear
- Logs are being sent from the VM

Save screenshots:
- `05-loganalytics-heartbeat.png`
- `06-rbac-assignment.png`

## 3.6 – Allow the VM to read secrets from Key Vault

This part is optional, however, I consider it best practice, you can now give this VM access to a Key Vault via its identity using:

```bash
az keyvault set-policy \
  --name kv-core-neu01 \
  --object-id <principalId> \
  --secret-permissions get list
```

This will allow the VM to retrieve secrets (e.g., connection strings) securely with no credentials stored in code.