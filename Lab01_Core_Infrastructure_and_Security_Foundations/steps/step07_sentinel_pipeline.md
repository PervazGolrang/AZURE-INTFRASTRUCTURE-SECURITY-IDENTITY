# Step 7 - Sentinel Pipeline and Threat Response

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
```

Verify under **Microsoft Defender for Cloud > Environment Settings**.

## 7.2 - Enable Azure Sentinel

```bash
az monitor log-analytics workspace create \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-sentinel-neu01 \
  --location northeurope

az sentinel workspace onboarding-state enable \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-sentinel-neu01
```

Confirm Sentinel is enabled via Azure Portal.

## 7.3 - Connect Data Sources

To monitor the virtual machine and other Azure services in Microsoft Sentinel, you need to set up diagnostic logging that sends important logs into the Sentinel workspace.

1. For the virtual machine, configure Diagnostic Settings to collect logs such as Audit Logs and Security logs. These logs will then be sent to the Sentinel workspace so that Sentinel can analyze them for security monitoring and alerting.

2. In the Microsoft Sentinel portal, go to Data Connectors and connect additional data sources such as Microsoft Defender for Cloud, Azure Active Directory (AAD), and Activity Logs. Enabling these connectors allows Sentinel to gather data from these services for a broader security overview.

These two steps ensures that Sentinel receives logs from the virtual machines and core Azure security services, to give the ability to detect potential threats across the environment.

## Screenshots

- `17-sentinel-overview`