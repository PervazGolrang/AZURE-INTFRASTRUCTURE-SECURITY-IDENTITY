# Terraform: Step 4 - Storage and Private Endpoints
# Based on step04_storage_and_privateendpoints.md

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

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
  default     = "stsecureneu01"
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "vnet-core-neu01"
}

variable "subnet_name" {
  description = "Subnet name for private endpoint"
  type        = string
  default     = "subnet-jumphost01"
}

variable "log_analytics_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "log-core-neu01"
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "container01"
}

# DATA SOURCES (EXISTING RESOURCES)
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

data "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  resource_group_name = var.resource_group_name
}

# STORAGE ACCOUNT
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  is_hns_enabled                = false
  min_tls_version              = "TLS1_2"
  https_traffic_only_enabled   = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled = false

  tags = {
    Environment = "Lab"
    Purpose     = "Storage"
  }
}

# CONTAINER
resource "azurerm_storage_container" "main" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# PRIVATE DNS ZONE
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "Lab"
    Purpose     = "DNS"
  }
}

# PRIVATE DNS ZONE VNET LINK
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-vnet-core"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
  registration_enabled  = false
}

# PRIVATE ENDPOINT
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-storage-blob"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.main.id

  private_service_connection {
    name                           = "conn-storage-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Private-Endpoint"
  }
}

# DIAGNOSTIC SETTINGS FOR STORAGE ACCOUNT
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-settings-storage"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}

# OUTPUTS
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "private_endpoint_name" {
  description = "Name of the private endpoint"
  value       = azurerm_private_endpoint.blob.name
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = azurerm_private_dns_zone.blob.name
}

output "container_name" {
  description = "Name of the storage container"
  value       = azurerm_storage_container.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}