# Terraform: Step 5 - Landing Zone Lite with Azure Firewall and Governance
# Based on step05_landing_zone_lite.md

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# VARIABLES
variable "location" {
  description = "Azure region"
  type        = string
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-secure-vm-01"
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "vnet-core-neu01"
}

variable "subnet_name" {
  description = "Subnet name to associate with route table"
  type        = string
  default     = "subnet-jumphost01"
}

variable "firewall_name" {
  description = "Azure Firewall name"
  type        = string
  default     = "fw-core-neu01"
}

variable "public_ip_name" {
  description = "Public IP name for firewall"
  type        = string
  default     = "pip-fw-core-neu01"
}

variable "route_table_name" {
  description = "Route table name"
  type        = string
  default     = "rt-secure"
}

variable "firewall_subnet_prefix" {
  description = "Address prefix for Azure Firewall subnet"
  type        = string
  default     = "10.100.2.0/24"
}

variable "source_address_prefix" {
  description = "Source address prefix for firewall rules"
  type        = string
  default     = "10.100.1.0/24"
}

variable "firewall_private_ip" {
  description = "Private IP address for firewall (next hop)"
  type        = string
  default     = "10.100.2.4"
}

variable "budget_amount" {
  description = "Budget limit in USD"
  type        = number
  default     = 10
}

variable "budget_alert_email" {
  description = "Email address for budget alerts"
  type        = string
  default     = "your-email@domain.com"
}

# DATA SOURCES
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "main" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# AZURE FIREWALL SUBNET
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = data.azurerm_virtual_network.main.name
  address_prefixes     = [var.firewall_subnet_prefix]
}

# PUBLIC IP FOR FIREWALL
resource "azurerm_public_ip" "firewall" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Lab"
    Purpose     = "Firewall"
  }
}

# AZURE FIREWALL
resource "azurerm_firewall" "main" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "fw-config"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Security"
  }
}

# FIREWALL APPLICATION RULE COLLECTION
resource "azurerm_firewall_application_rule_collection" "main" {
  name                = "app-allow"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-ms-update"

    source_addresses = [
      var.source_address_prefix
    ]

    target_fqdns = [
      "*.windowsupdate.com"
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

# ROUTE TABLE
resource "azurerm_route_table" "main" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  route {
    name           = "fw-default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Routing"
  }
}

# ASSOCIATE ROUTE TABLE WITH SUBNET
resource "azurerm_subnet_route_table_association" "main" {
  subnet_id      = data.azurerm_subnet.main.id
  route_table_id = azurerm_route_table.main.id
}

# BUDGET
resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "budget-secure-rg"
  resource_group_id = data.azurerm_resource_group.main.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = "2025-01-01T00:00:00Z"
    end_date   = "2030-12-31T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Percentage"

    contact_emails = [
      var.budget_alert_email
    ]
  }
}

# OUTPUTS
output "firewall_name" {
  description = "Name of the Azure Firewall"
  value       = azurerm_firewall.main.name
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "route_table_name" {
  description = "Name of the route table"
  value       = azurerm_route_table.main.name
}

output "budget_name" {
  description = "Name of the budget"
  value       = azurerm_consumption_budget_resource_group.main.name
}