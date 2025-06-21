# Azure Infrastructure & Security Lab Series

This repository contains a structured series of Azure infrastructure and security-focused labs that reflect real-world deployment, configuration, and governance practices. It is designed for my personal exercise and for individuals who want to demonstrate technical depth across Azure administration, networking, identity, monitoring, and security using both manual and automated approaches.

Each lab is isolated, production-relevant, and includes infrastructure-as-code templates (Bicep, ARM JSON, and Terraform), detailed step-by-step documentation, and operational output. Labs follow enterprise standards and include enhancements, architecture diagrams, and optional troubleshooting scenarios.

## Lab Overview

| Lab  | Title                            | Core Topics                                        |
|------|----------------------------------|----------------------------------------------------|
| 01   | Secure VM Deployment (Bastion)   | VM, NSG, Bastion, Log Analytics, Managed Identity  |
| 02   | Private Storage & Logging        | Storage, Private Endpoint, SAS, Diagnostics        |
| 03   | RBAC + PIM Access Design         | IAM, Role Assignment, Privileged Access Management |
| 04   | Networking with UDR & DNS        | UDRs, NSGs, Subnet Design, Custom DNS              |
| 05   | Landing Zone Lite                | Policy, Tags, Budgets, Firewall Deployment         |
| 06   | Zero Trust Web Application       | App Service, Front Door, WAF, TLS, AAD Login       |
| 07   | Microsoft Sentinel Integration   | Defender, Sentinel, Workbooks, Alerts, KQL         |

## Infrastructure as Code

All labs are built with repeatability and automation in mind. Each lab includes:

- **Bicep** - primary deployment method, modular and readable
- **ARM JSON** - for compatibility with legacy or existing systems
- **Terraform** - alternative IaC path for multi-cloud environments

## Structure

Each lab folder includes:

- `README.md` - high-level lab documentation and step breakdown
- `steps/` - logically structured step-by-step execution files
- `bicep/`, `terraform/`, `arm/` — IaC templates for the same deployment
- `img/` - relevant screenshots and architectural diagrams
- `notes/` - deep technical explanation or architectural justification
- `enhancements/` — optional but realistic additional configurations
- `docs/` - reference documents (IP plan, naming convention, etc.)

## Documentation Standards

- Markdown files are formatted for clarity and readability
- Diagrams are created using Draw.io and included as `.drawio` and `.png`
- Screenshots are provided where GUI steps are relevant
- Logs and query outputs are captured in `test-output.log` per lab
- Cleanup instructions are included for all resources

## Requirements

- Azure Subscription with contributor access
- Azure CLI (latest version)
- Terraform CLI (if using Terraform)
- Bicep CLI (if not using native Bicep with Azure CLI)
- Visual Studio Code with markdown preview and Azure extensions