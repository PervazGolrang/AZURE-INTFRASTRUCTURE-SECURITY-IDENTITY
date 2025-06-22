# Terraform: Step 2 - Azure Bastion and NSG Configuration
# Based on step02_bastion_and_nsg.md

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

# Variables
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "North Europe"
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

variable "subnet_jumphost_name" {
  description = "Jumphost subnet name"
  type        = string
  default     = "subnet-jumphost01"
}

variable "subnet_bastion_name" {
  description = "Bastion subnet name"
  type        = string
  default     = "AzureBastionSubnet"
}

# Data sources for existing resources
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "jumphost" {
  name                 = var.subnet_jumphost_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "bastion" {
  name                 = var.subnet_bastion_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "bastion-pip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Lab"
    Purpose     = "Bastion"
  }
}

# Network Security Group with rules
resource "azurerm_network_security_group" "jumphost" {
  name                = "nsg-jumphost-01"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-RDP-from-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureMonitor"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureMonitor"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny_All_Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Security"
  }
}

# Associate NSG with jumphost subnet
resource "azurerm_subnet_network_security_group_association" "jumphost" {
  subnet_id                 = data.azurerm_subnet.jumphost.id
  network_security_group_id = azurerm_network_security_group.jumphost.id
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  name                = "bastion-core-neu01"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = data.azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Remote-Access"
  }
}

# Outputs
output "bastion_name" {
  description = "Name of the Azure Bastion host"
  value       = azurerm_bastion_host.main.name
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}

output "bastion_fqdn" {
  description = "FQDN of the Bastion host"
  value       = azurerm_public_ip.bastion.fqdn
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = azurerm_network_security_group.jumphost.name
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = azurerm_network_security_group.jumphost.id
}