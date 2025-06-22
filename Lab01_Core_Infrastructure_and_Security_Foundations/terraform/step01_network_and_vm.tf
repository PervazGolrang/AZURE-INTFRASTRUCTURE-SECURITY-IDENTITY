# Terraform: Step 1 - Network and VM Deployment
# Based on step01_network_and_vm.md

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

variable "vm_admin_username" {
  description = "VM administrator username"
  type        = string
  default     = "labadmin"
}

variable "vm_admin_password" {
  description = "VM administrator password"
  type        = string
  sensitive   = true
  default     = "Strongpass123"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Network Security Group
resource "azurerm_network_security_group" "jumphost" {
  name                = "nsg-jumphost01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

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

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-core-neu01"
  address_space       = ["10.100.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = "Lab"
    Purpose     = "Networking"
  }
}

# Jumphost Subnet
resource "azurerm_subnet" "jumphost" {
  name                 = "subnet-jumphost01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.100.1.0/24"]
}

# Azure Bastion Subnet
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.100.0.0/27"]
}

# Associate NSG with Jumphost Subnet
resource "azurerm_subnet_network_security_group_association" "jumphost" {
  subnet_id                 = azurerm_subnet.jumphost.id
  network_security_group_id = azurerm_network_security_group.jumphost.id
}

# Network Interface for VM
resource "azurerm_network_interface" "vm" {
  name                = "vm-jhost-neu01-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.jumphost.id
    private_ip_address_allocation = "Dynamic"
  }

    tags = {
    Environment = "Lab"
    Purpose     = "VM-Network"
  }
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "jumphost" {
  name                = "vm-jhost-neu01"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B2s"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  # Enable automatic updates and VM agent
  enable_automatic_updates = true
  provision_vm_agent       = true

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Jumphost"
  }
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.jumphost.name
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_managed_identity_principal_id" {
  description = "Principal ID of the VM's managed identity"
  value       = azurerm_windows_virtual_machine.jumphost.identity[0].principal_id
}