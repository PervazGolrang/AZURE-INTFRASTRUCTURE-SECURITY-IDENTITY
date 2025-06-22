// Terraform: Step 6 - Zero Trust Web App with WAF and Azure AD Authentication
// Based on step06_zero_trust_webapp.md

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

provider "azuread" {}

# Data sources for existing resources
data "azurerm_resource_group" "main" {
  name = "rg-secure-vm-01"
}

data "azurerm_virtual_network" "main" {
  name                = "vnet-core-neu01"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "jumphost" {
  name                 = "subnet-jumphost01"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_log_analytics_workspace" "main" {
  name                = "lab01-log-weu"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_client_config" "current" {}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "plan-core-neu01"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

# Web App
resource "azurerm_linux_web_app" "main" {
  name                = "app-secure-neu01"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  
  public_network_access_enabled = false

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
    http2_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }
}

# Private DNS Zone for Web App
resource "azurerm_private_dns_zone" "webapp" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "webapp" {
  name                  = "webapp-vnet-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.webapp.name
  virtual_network_id    = data.azurerm_virtual_network.main.id
  registration_enabled  = false
}

# Private Endpoint for Web App
resource "azurerm_private_endpoint" "webapp" {
  name                = "pe-app-secure"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.jumphost.id

  private_service_connection {
    name                           = "pe-link-app-secure"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "webapp-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.webapp.id]
  }
}

# WAF Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                = "wafpolicysecure01"
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "Premium_AzureFrontDoor"
  enabled             = true
  mode                = "Prevention"

  custom_rule {
    name                           = "blockbots"
    enabled                        = true
    priority                       = 100
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 10
    type                           = "MatchRule"
    action                         = "Block"

    match_condition {
      match_variable     = "RequestHeader"
      selector           = "User-Agent"
      operator           = "Contains"
      negation_condition = false
      match_values       = ["bot"]
      transforms         = ["Lowercase"]
    }
  }
}

# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "afd-secure-core"
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "Premium_AzureFrontDoor"
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "endpoint-app-secure-neu01"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  enabled                  = true
}

# Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "default-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Origin
resource "azurerm_cdn_frontdoor_origin" "main" {
  name                          = "webapp-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = azurerm_linux_web_app.main.default_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_linux_web_app.main.default_hostname
  priority                       = 1
  weight                         = 1000
}

# Security Policy
resource "azurerm_cdn_frontdoor_security_policy" "main" {
  name                     = "security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# Azure AD App Registration
resource "azuread_application" "main" {
  display_name = "app-secure-neu01"
  owners       = [data.azurerm_client_config.current.object_id]

  web {
    redirect_uris = ["https://${azurerm_linux_web_app.main.default_hostname}/.auth/login/aad/callback"]
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

# Web App Authentication
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
  }
}

# Diagnostic Settings for Web App
resource "azurerm_monitor_diagnostic_setting" "webapp" {
  name                       = "webapp-diagnostics"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Outputs
output "front_door_endpoint_url" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
}

output "web_app_name" {
  value = azurerm_linux_web_app.main.name
}

output "private_endpoint_name" {
  value = azurerm_private_endpoint.webapp.name
}

output "app_registration_client_id" {
  value = azuread_application.main.application_id
}

output "app_registration_client_secret" {
  value     = azuread_application_password.main.value
  sensitive = true
}