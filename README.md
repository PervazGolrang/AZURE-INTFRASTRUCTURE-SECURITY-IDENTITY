# Azure Infrastructure, Security, and Identity Lab Series

This repository provides a curated set of advanced hands-on lab projects focused on Azure infrastructure deployment, security hardening, hybrid connectivity, and enterprise-grade identity management. Each lab project is built with a realistic step-by-step approach using both the Azure portal and infrastructure-as-code (Bicep, ARM, and Terraform), and includes professional documentation and visual walkthroughs.

## Objectives

- Build production-aligned Azure environments using industry best practices
- Reinforce AZ-104, AZ-500, and AZ-305 knowledge through practical application
- Demonstrate cloud engineering proficiency through design, deployment, and security
- Show layered understanding of access control, policy enforcement, observability, and recovery

## Technologies and Services

- Azure Virtual Network, Bastion, NSG, UDR, DNS
- Azure Storage, Diagnostic Settings, Azure Monitor
- RBAC, Privileged Identity Management, Conditional Access, Defender for Cloud
- Azure Firewall, Azure Policy, Management Groups, Blueprints
- Web Application Firewall (WAF), Azure Front Door
- Log Analytics, Azure Sentinel, Identity Protection
- VPN Gateway, ExpressRoute, Hybrid DNS, Private Link, Application Gateway
- Entra ID (Azure AD), PIM, Access Reviews, App Proxy, SSO

## Labs Overview

### Project 01: Core Infrastructure & Security Foundations
A full secure infrastructure deployment, covering VM isolation, diagnostics, access security, identity hardening, network control, and Sentinel integration. Built mainly with Azure Cloud Shell.

- Step 01: Secure VNet, NSG, VM Deployment with Bastion (no public IP)
- Step 02: Private Storage Account with Logging and Firewalls
- Step 03: RBAC and Privileged Identity Management
- Step 04: UDR and Custom DNS Forwarders
- Step 05: Landing Zone with Azure Firewall and Policies
- Step 06: Zero Trust Web App with Azure Front Door and WAF
- Step 07: Log Analytics and Microsoft Sentinel Alerting

### Project 02: Advanced Enterprise Infrastrucure
A hybrid cloud architecture integrating multi-region deployment, private DNS, secure connectivity (VPN/ExpressRoute), and high-availability practices. Includes modern governance using Azure Policy and Template Specs, plus cost enforcement and monitoring automation.

- Step 01: Governance Framework (Policy, Tags, and Cost Controls with Template Specs)
- Step 02: Hybrid Connectivity (VPN Gateway and ExpressRoute with IPsec Routing)
- Step 03: Identity Bridge with Entra Connect, Seamless SSO, and Conditional Access
- Step 04: Highly Available Web Application Deployment
- Step 05: Network Virtual Appliance (NVA), UDR, and Custom Routing
- Step 06: Monitoring, Alerts, Dashboards, and Automated Remediation

### Project 03: Enterprise Identity & Conditional Access
A Zero Trust-aligned identity architecture focused on secure authentication, least-privilege access, external collaboration control, workload identity protection, and advanced analytics. All configurations follow Microsoft-recommended best practices and are deployed using Bicep.

(Coming soon - documented in full once Project 02 is finalized.)

## Features

- Step-by-step `.md` walkthroughs for every task
- Clean, readable, and production-aligned code (Bicep, ARM, Terraform)
- Visual topology diagrams and screenshots throughout
- Optional enhancement sections per lab (e.g., Key Vault, Defender, Sentinel tuning)
- Cleanup automation and resource lifecycle management
- Written as if already part of a professional SOC or infra team

## Intended Audience

This repository was mainly built for testing my knowledge, however, it also is intended for engineers and professionals preparing for roles in Azure infrastructure, cloud security, or hybrid cloud design. The content reflects what would be expected from a cloud engineer with practical experience, even without official work experience.

## Requirements

- Azure subscription with Contributor or Owner access
- Azure CLI and Terraform CLI installed locally
- Bicep CLI or Azure CLI with native Bicep support
- Visual Studio Code or equivalent editor
- Basic familiarity with PowerShell or Bash
- Budget of €15. (**Remember to cleanup**) 
