# Project 01 - Azure Infrastructure & Security Foundations

This project demonstrates how to design and deploy a secure, modular Azure infrastructure using best practices for access control, logging, policy enforcement, and attack surface minimization. It combines portal-based deployment with infrastructure-as-code (Bicep, ARM, Terraform), along with complete visual walkthroughs and professional documentation.

## Objective

To simulate real-world Azure infrastructure deployment focused on security, visibility, and operational control, as would be expected in an enterprise environment. Mainly written with Azure Cloud Shell.

## Resource Overview

| Resource Type        | Name                                       |
|----------------------|--------------------------------------------|
| Resource Group       | `rg-secure-vm-01`                          |
| VNet                 | `vnet-core-neu01`                          |
| Subnets              | `subnet-jumphost01`, `AzureBastionSubnet`  |
| VM                   | `vm-jhost-neu01`                           |
| NSG                  | `nsg-jumphost-01`                          |
| Bastion Host         | `bastion-core-neu01`                       |
| Log Analytics        | `log-core-neu01`                           |

Bastion requires a /27 subnet.

## Step-by-Step Guide and Breakdown

Screenshots are stored in [`images/`](images/), referenced directly inside each step

| Step | Description                                                                                   |
|------|-----------------------------------------------------------------------------------------------|
| 01   | Deploy a secure virtual network, Azure Bastion, and jump VM with no public IP.                |
| 02   | Configure a private storage with diagnostic logging, firewall rules, and access restrictions. |
| 03   | Enforce RBAC, set up Entra ID PIM for privileged access, and activate identity logging.       |
| 04   | Implement a custom DNS forwarders and user-defined routes.                                    |
| 05   | Deploy a basic landing zone with Azure Firewall, and Azure Policy.                            |
| 06   | Set up a Zero Trust front-end architecture with Front Door and WAF.                           |
| 07   | Enable Microsoft Sentinel, and configure analytics rules.                                     | 

All deployment steps are located in the [`steps/`](steps/) folder:

- [Step 1 - Network and VM Deployment](steps/step01_network_and_vm.md)
- [Step 2 - Bastion and NSG Configuration](steps/step02_bastion_and_nsg.md)
- [Step 3 - Identity and Logging](steps/step03_identity_and_logging.md)
- [Step 4 - Storage and Private Endpoint](steps/step04_storage_and_privateendpoints.md)
- [Step 5 - Landing Zone Lite](steps/step05_landing_zone_lite.md)
- [Step 6 - Zero Trust Web App](steps/step06_zero_trust_webapp.md)
- [Step 7 - Sentinel Pipeline](steps/step07_sentinel_pipeline.md)

Each step includes commands, explanations, and relevant screenshots.

### Services Used

- Azure VNet, NSG, Azure Bastion, Route Tables
- Azure Storage (Private Endpoint + Firewall)
- Log Analytics Workspace, Diagnostic Settings
- Azure Policy, Management Groups, Blueprints
- Azure Front Door, Application Gateway, WAF
- Microsoft Sentinel and Defender for Cloud
- Entra ID (Azure AD), PIM, RBAC, Identity Protection

## Outcome

Upon completing this lab, the environment represents a hardened, observable, policy-compliant, access-controlled Azure deployment, aligned with enterprise security expectations. The structure and documentation are written to reflect the quality expected from a professional cloud engineer.

## Cleanup

To remove all deployed resources:

```bash
az group delete --name rg-secure-vm-01 --yes --no-wait
terraform destroy
```