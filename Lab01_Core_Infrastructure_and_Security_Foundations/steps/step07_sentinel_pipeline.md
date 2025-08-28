# Step 7 - Sentinel Pipeline and Threat Response

This step sets up a cloud-native security monitoring and response pipeline. It will connect the Defender for Cloud and Azure Sentinel to detect threats, visualize data with workbooks, analyze logs using KQL, and trigger automated responses with alert rules and playbooks.

## 7.1 - Enable the Microsoft Defender for Cloud

```bash
az security pricing create \
  --name VirtualMachines \
  --tier Standard \
```

Verify under `Microsoft Defender for Cloud > Environment Settings`.

## 7.2 - Enable the Microsoft Sentinel

```bash
az monitor log-analytics workspace create \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-sentinel-neu01 \
  --location northeurope

az sentinel workspace onboarding-state enable \
  --resource-group rg-secure-vm-01 \
  --workspace-name log-sentinel-neu01
```

Confirm Sentinel is enabled via the Azure Portal.

## 7.3 - Connect the Data Sources

The VM and other Azure Services in Microsoft Sentinel can be monitored after setting up the diagnostic logging.

1. For the VM, configure the Diagnostic Settings to collect logs such as Audit Logs and Security logs. These logs will then be sent to the Sentinel workspace so that Sentinel can analyze them for security monitoring and alerting.

2. In the Microsoft Sentinel portal, go to Data Connectors and connect additional data sources such as Microsoft Defender for Cloud, Microsoft Entra ID, and Activity Logs. Enabling these connectors allows Sentinel to gather data from these services for a broader security overview.

These two steps ensure that the Sentinel receives logs from the virtual machines and core Azure security services, so it can detect potential threats across the Azure environment.

## Screenshots

- [`17-sentinel-overview`](/Lab01_Core_Infrastructure_and_Security_Foundations/images/17-sentinel-overview.png)