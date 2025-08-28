# Notes - Lab 01: Secure VM Deployment with Azure Bastion

This file contains detailed notes, rationale, and justifications behind the architecture, configurations, and decisions made during this lab.

---

## Why No Public IP?

The VM is intentionally deployed without a public IP to enforce perimeter control. By removing external exposure:

- Attack surface is significantly reduced
- RDP/SSH brute-force risks are eliminated
- Network access is only possible through hardened services (Bastion or jump server via VPN)

This is aligned with Zero Trust principles and industry-standard security baselines.

---

## Why Azure Bastion?

Azure Bastion provides secure and audited RDP/SSH access:

- No need to manage jump host keys or NSG port exceptions
- Traffic never exits Azure's backbone
- All access sessions are logged and can be monitored
- Ideal for emergency access or security-first operations

I chose the **Basic SKU** for cost-effectiveness, as I did not need custom DNS and IP-based connection support.

---

# Why Use System-Assigned Managed Identity?

This is to avoid using credentials or secrets:

- Managed identities are automatically rotated and secured
- Permissions can be granted via RBAC on Key Vaults, storage, automation, etc.
- Prepares the environment for automation and policy enforcement

---

## NSG Configuration

Best practice: start with **deny-all-inbound**. Only allow what is explicitly required:

- In this lab, **no inbound traffic** is allowed to the subnet or VM
- Future labs will show how UDRs and firewalls further shape traffic
- This model aligns with security baselines such as CIS or Microsoft CAF

---

## Subnet Design

Two subnets:
- `subnet-jumphost-01` → for the secure VM
- `AzureBastionSubnet` → reserved subnet for the Bastion service

This separation enforces:
- Isolation of Bastion infrastructure
- More explicit NSG, UDR, and monitoring design
- Compliance with Azure subnet naming and usage rules

---

## Log Analytics Workspace

Log Analytics is a central logging backend:
- VM logs, NSG flows, future Defender data, Sentinel ingest, and more will stream here
- Provides deep visibility into environment behavior
- Prepares us for detection engineering in Step 7

Workspace naming and region (`log-core-neu01`, North Europe) match best practice conventions.

---

## Naming Conventions

We use lowercase + hyphen + region codes:

- `vm-jumphost-weu01`
- `rg-secure-vm-01`
- `log-core-neu01`

This naming style:
- Matches Microsoft Cloud Adoption Framework
- Is easy to parse by scripts and IaC templates
- Improves environment consistency

---

## Alternative Options

| Task                      | Alternative Approach                   |
|---------------------------|----------------------------------------|
| Secure access             | Point-to-Site VPN instead of Bastion   |
| VM OS                     | Ubuntu LTS instead of Windows Server   |
| Monitoring                | Azure Monitor Agent instead of MMA     |
| Identity                  | User-assigned managed identity         |

I selected defaults that balance **realism**, **simplicity**, and **best practice**.