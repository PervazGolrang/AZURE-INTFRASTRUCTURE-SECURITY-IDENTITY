# Step 7 - Sentinel Pipeline and Threat Response - WIP

This step builds a security monitoring pipeline using:
- Microsoft Defender for Cloud (recommendations, alerts)
- Azure Sentinel (SIEM solution)
- Workbook dashboards
- Kusto Query Language (KQL) for custom analytics
- Alert rules triggering playbooks or actions

## 7.1 - Enable Microsoft Defender for Cloud

```bash
az security pricing create \
  --name VirtualMachines \
  --tier Standard \
  --resource-type "Microsoft.Compute/virtualMachines"
```

Verify under **Microsoft Defender for Cloud > Environment Settings**.

## 7.2 - Enable Azure Sentinel

```bash
az monitor log-analytics workspace create \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-sentinel-weu01 \
  --location westeurope

az sentinel workspace onboarding-state enable \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-sentinel-weu01
```

Confirm Sentinel is enabled via Azure Portal.

## 7.3 - Connect Data Sources

```bash
az monitor diagnostic-settings create \
  --name vm-diagnostics \
  --resource /subscriptions/<SUB_ID>/resourceGroups/rg-secure-vm-01/providers/Microsoft.Compute/virtualMachines/vm-jump \
  --workspace log-sentinel-weu01 \
  --logs '[{"category": "AuditLogs","enabled": true},{"category": "Security","enabled": true}]'
```

Also connect Defender, AAD, and Activity Logs via Sentinel UI.

## 7.4 - Create Workbook Dashboard

- Go to Azure Sentinel > Workbooks
- Create a new workbook using template: **"Security Events Overview"**
- Customize charts: VM logins, NSG rejections, AAD sign-ins

Save workbook as `Sentinel Security Dashboard`.

## 7.5 - Create Alert Rule with KQL

```kusto
SecurityEvent
| where EventID == 4625
| where AccountType == "User"
| summarize FailedLogons=count() by Account, bin(TimeGenerated, 1h)
| where FailedLogons > 3
```

Create alert rule:
- Condition: KQL above
- Trigger: Every 5 minutes
- Action: Email + Logic App

## 7.6 - Auto-Remediation Logic App

Create a Logic App that:
- Disables the user account via Graph API
- Sends Teams alert to SOC
- Tags VM with `under_attack=true`

Use `az logicapp create` or designer UI.

## Screenshots

Save:
- `19-sentinel-overview.png`
- `20-defender-recommendations.png`
- `21-workbook-dashboard.png`
- `22-alert-fired.png`

## Validation

- Sentinel receives logs
- Workbook displays useful graphs
- Alert triggered on brute-force simulation
- Optional: auto-remediation works

## Completion

You now have:
- Secure VM with Bastion
- Logging and NSG
- Storage and RBAC best practices
- Network isolation and governance
- Zero Trust app with WAF and identity
- SIEM pipeline with alerting and dashboards

## Enhancements

- Integrate Microsoft Purview for DLP
- Add custom connectors for third-party firewalls or tools
- Create workbook for cost monitoring via `Usage` table