# Step 7 - Sentinel Pipeline and Threat Response
# Based on step07_sentinel_pipeline.md

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

# Data sources for existing resources
data "azurerm_resource_group" "main" {
  name = "rg-secure-vm-01"
}

data "azurerm_virtual_machine" "jumphost" {
  name                = "vm-jumphost01"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_client_config" "current" {}

# Log Analytics Workspace for Sentinel
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-sentinel-neu01"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  internet_ingestion_enabled = true
  internet_query_enabled     = true
}

# Enable Microsoft Sentinel
resource "azurerm_log_analytics_solution" "sentinel" {
  solution_name         = "SecurityInsights"
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = data.azurerm_resource_group.main.name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

# Microsoft Defender for Cloud - Virtual Machines
resource "azurerm_security_center_subscription_pricing" "vm" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

# Microsoft Defender for Cloud - Storage Accounts
resource "azurerm_security_center_subscription_pricing" "storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

# Microsoft Defender for Cloud - SQL Servers
resource "azurerm_security_center_subscription_pricing" "sql" {
  tier          = "Standard"
  resource_type = "SqlServers"
}

# Microsoft Defender for Cloud - App Services
resource "azurerm_security_center_subscription_pricing" "appservice" {
  tier          = "Standard"
  resource_type = "AppServices"
}

# Diagnostic Settings for VM
resource "azurerm_monitor_diagnostic_setting" "vm" {
  name                       = "vm-to-sentinel"
  target_resource_id         = data.azurerm_virtual_machine.jumphost.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_metric {
    category = "AllMetrics"
  }
}

# Activity Log Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "activity-log-to-sentinel"
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Policy"
  }
}

# Action Group for Security Alerts
resource "azurerm_monitor_action_group" "security" {
  name                = "security-alerts-ag"
  resource_group_name = data.azurerm_resource_group.main.name
  short_name          = "SecAlerts"
  enabled             = true

  email_receiver {
    name          = "SecurityTeam"
    email_address = "security@company.com"
    use_common_alert_schema = true
  }
}

# Scheduled Query Rule for Failed Login Attempts
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_logins" {
  name                = "multiple-failed-logins"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  evaluation_frequency = "PT5M"
  window_duration      = "PT1H"
  scopes               = [azurerm_log_analytics_workspace.main.id]
  severity             = 2
  enabled              = true

  criteria {
    query                   = <<-QUERY
      SigninLogs
      | where TimeGenerated > ago(1h)
      | where ResultType != "0"
      | summarize FailedAttempts = count() by IPAddress
      | where FailedAttempts >= 5
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.security.id]
  }

  display_name        = "Multiple Failed Login Attempts"
  description         = "Detects multiple failed login attempts from the same IP address"
  auto_mitigation_enabled = false
}

# Sentinel Data Connector for Azure Activity
resource "azurerm_sentinel_data_connector_azure_activity_log" "main" {
  name                       = "azure-activity-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  subscription_id            = data.azurerm_client_config.current.subscription_id
}

# Sentinel Data Connector for Azure Security Center
resource "azurerm_sentinel_data_connector_azure_security_center" "main" {
  name                       = "azure-security-center-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  subscription_id            = data.azurerm_client_config.current.subscription_id
}

# Sentinel Data Connector for Azure Active Directory
resource "azurerm_sentinel_data_connector_azure_active_directory" "main" {
  name                       = "azure-ad-connector"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tenant_id                  = data.azurerm_client_config.current.tenant_id
}

# Sentinel Analytics Rule - Failed Login Attempts
resource "azurerm_sentinel_alert_rule_scheduled" "failed_logins" {
  name                       = "multiple-failed-logins-sentinel"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  display_name               = "Multiple Failed Login Attempts (Sentinel)"
  description                = "Detects multiple failed login attempts from the same IP address"
  severity                   = "Medium"
  enabled                    = true

  query = <<QUERY
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType != "0"
| summarize FailedAttempts = count() by IPAddress, bin(TimeGenerated, 5m)
| where FailedAttempts >= 5
| project TimeGenerated, IPAddress, FailedAttempts
QUERY

  trigger_operator  = "GreaterThan"
  trigger_threshold = 0

  suppression_enabled  = false
  suppression_duration = "PT1H"

  tactics = ["CredentialAccess"]

  entity_mapping {
    entity_type = "IP"
    field_mapping {
      identifier = "Address"
      column_name = "IPAddress"
    }
  }
}

# Security Contact for Defender for Cloud
resource "azurerm_security_center_contact" "main" {
  name  = "personal_email"
  email = "pervazgolrang@protonmail.com"
  
  alert_notifications = true
  alerts_to_admins    = true
}

# Outputs
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}

output "sentinel_workspace_url" {
  value = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_log_analytics_workspace.main.id}/Microsoft_Azure_Security_Insights/WorkspacesOverviewBlade"
}

output "action_group_id" {
  value = azurerm_monitor_action_group.security.id
}