# Terraform: Step 3 - Identity and Logging
# Based on step03_identity_and_logging.md

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

variable "vm_name" {
  description = "Virtual machine name"
  type        = string
  default     = "vm-jhost-neu01"
}

variable "log_analytics_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = "log-core-neu01"
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
  default     = "kv-core-neu01"
}

variable "create_key_vault" {
  description = "Whether to create Key Vault"
  type        = bool
  default     = false
}

# Data sources for existing resources
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_client_config" "current" {}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "Lab"
    Purpose     = "Monitoring"
  }
}

# Azure Monitor Agent Extension
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                 = "AzureMonitorWindowsAgent"
  virtual_machine_id   = data.azurerm_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorWindowsAgent"
  type_handler_version = "1.0"

  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true

  tags = {
    Environment = "Lab"
    Purpose     = "Monitoring"
  }
}

# Data Collection Rule for VM Insights
resource "azurerm_monitor_data_collection_rule" "vm_insights" {
  name                = "dcr-vminsights-${var.vm_name}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "la-workspace"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["la-workspace"]
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["la-workspace"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Processor Information(_Total)\\% Privileged Time",
        "\\Processor Information(_Total)\\% User Time",
        "\\Processor Information(_Total)\\Processor Frequency",
        "\\System\\Processes",
        "\\Process(_Total)\\Thread Count",
        "\\Process(_Total)\\Handle Count",
        "\\System\\System Up Time",
        "\\System\\Context Switches/sec",
        "\\System\\Processor Queue Length",
        "\\Memory\\Available Bytes",
        "\\Memory\\Committed Bytes",
        "\\Memory\\Cache Bytes",
        "\\Memory\\Pool Paged Bytes",
        "\\Memory\\Pool Nonpaged Bytes",
        "\\Memory\\Pages/sec",
        "\\Memory\\Page Faults/sec",
        "\\Process(_Total)\\Working Set",
        "\\Process(_Total)\\Working Set - Private",
        "\\LogicalDisk(_Total)\\% Disk Time",
        "\\LogicalDisk(_Total)\\% Disk Read Time",
        "\\LogicalDisk(_Total)\\% Disk Write Time",
        "\\LogicalDisk(_Total)\\% Idle Time",
        "\\LogicalDisk(_Total)\\Disk Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Transfers/sec",
        "\\LogicalDisk(_Total)\\Disk Reads/sec",
        "\\LogicalDisk(_Total)\\Disk Writes/sec",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
        "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
        "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
        "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
        "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
        "\\LogicalDisk(_Total)\\% Free Space",
        "\\LogicalDisk(_Total)\\Free Megabytes",
        "\\Network Interface(*)\\Bytes Total/sec",
        "\\Network Interface(*)\\Bytes Sent/sec",
        "\\Network Interface(*)\\Bytes Received/sec",
        "\\Network Interface(*)\\Packets/sec",
        "\\Network Interface(*)\\Packets Sent/sec",
        "\\Network Interface(*)\\Packets Received/sec",
        "\\Network Interface(*)\\Packets Outbound Errors",
        "\\Network Interface(*)\\Packets Received Errors"
      ]
      name = "perfCounterDataSource60"
    }

    windows_event_log {
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0)]]",
        "Security!*[System[(band(Keywords,13510798882111488))]]",
        "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0)]]"
      ]
      name = "eventLogsDataSource"
    }
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Data-Collection"
  }
}

# Associate Data Collection Rule with VM
resource "azurerm_monitor_data_collection_rule_association" "vm_insights" {
  name                    = "dcra-vminsights-${var.vm_name}"
  target_resource_id      = data.azurerm_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights.id
}

# RBAC Assignment - VM Identity as Reader on Resource Group
resource "azurerm_role_assignment" "vm_reader" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_virtual_machine.vm.identity[0].principal_id
}

# Optional: Key Vault for Secrets Management
resource "azurerm_key_vault" "main" {
  count                       = var.create_key_vault ? 1 : 0
  name                        = var.key_vault_name
  location                    = data.azurerm_resource_group.main.location
  resource_group_name         = data.azurerm_resource_group.main.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_virtual_machine.vm.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List",
    ]
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Secrets"
  }
}

# Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "vm_principal_id" {
  description = "Principal ID of the VM's managed identity"
  value       = data.azurerm_virtual_machine.vm.identity[0].principal_id
}

output "data_collection_rule_name" {
  description = "Name of the data collection rule"
  value       = azurerm_monitor_data_collection_rule.vm_insights.name
}

output "key_vault_name" {
  description = "Name of the Key Vault (if created)"
  value       = var.create_key_vault ? azurerm_key_vault.main[0].name : "Not created"
}

output "kql_heartbeat_query" {
  description = "KQL query to check VM heartbeat"
  value       = <<-EOT
    Heartbeat
    | where Computer contains "${var.vm_name}"
    | sort by TimeGenerated desc
  EOT
}