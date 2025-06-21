# Lab 01 – Secure VM Deployment with Azure Bastion

## Objective

This lab demonstrates how to deploy a secure Azure Virtual Machine environment without exposing it to the public internet. The VM is accessible only through Azure Bastion. Diagnostic logging is enabled, and a system-assigned managed identity is configured. All traffic is controlled via NSG, and logging is sent to Log Analytics for auditing.

The purpose of this lab is to show how a hardened jump-host VM can be securely deployed in a controlled network environment using Azure-native services and access control patterns.s

## Scope

The following components are deployed:

- Virtual Network with two subnets:
  - `subnet-jumphost-01`
  - `AzureBastionSubnet` (required by Azure Bastion)
- Network Security Group (NSG) with deny-all-inbound by default
- Azure Bastion Host for browser-based RDP/SSH access
- Windows Server 2022 Virtual Machine
- Log Analytics Workspace
- System-assigned managed identity attached to VM
- Diagnostic settings enabled for the VM and NSG

## Architecture Diagram

![VM Bastion Architecture](img/diagram.png)

## Resource Overview

| Resource Type        | Name                                       |
|----------------------|--------------------------------------------|
| Resource Group       | `rg-secure-vm-01`                          |
| VNet                 | `vnet-core-weu01`                          |
| Subnets              | `subnet-jumphost-01`, `AzureBastionSubnet` |
| VM                   | `vm-jumphost-weu01`                        |
| NSG                  | `nsg-jumphost-01`                          |
| Bastion Host         | `bastion-core-weu01`                       |
| Log Analytics        | `log-core-weu01`                           |

Remember that a /27 subnet is required for Bastion

## Step-by-Step Guide

All deployment steps are located in the [`steps/`](steps/) folder:

- [Step 1 - Network and VM Deployment](steps/step01_network_and_vm.md)
- [Step 2 - Bastion and NSG Configuration](steps/step02_bastion_and_nsg.md)
- [Step 3 - Identity and Logging](steps/step03_identity_and_logging.md)
- [Step 4 - Storage and Private Endpoint](steps/step04_storage_and_privateendpoint.md)
- [Step 5 - Landing Zone Lite](steps/step05_landing_zone_lite.md)
- [Step 6 - Zero Trust Web App](steps/step06_zero_trust_webapp.md)
- [Step 7 - Sentinel Pipeline](steps/step07_sentinel_pipeline.md)

Each step includes commands, explanations, and relevant screenshots.

## Infrastructure-as-Code

| Method     | File                          |
|------------|-------------------------------|
| Bicep      | `bicep/main.bicep`            |
| ARM JSON   | `arm/main.json`               |
| Terraform  | `terraform/main.tf`           |

## Enhancements

See [`enhancements/`](enhancements/) for further extensions:

- Enabling Microsoft Defender for Servers
- Azure Backup Vault configuration
- Key Vault integration with the VM
- NSG IP filtering for Bastion access

## Logging & Output

CLI deployment outputs are available in [`test-output.log`](test-output.log)

## Cleanup

To remove all deployed resources:

```bash
az group delete --name rg-secure-vm-01 --yes --no-wait
terraform destroy
```