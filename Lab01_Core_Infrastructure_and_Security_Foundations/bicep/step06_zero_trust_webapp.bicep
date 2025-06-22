// Bicep: Step 6 - Zero Trust Web App with WAF and Azure AD Authentication
// Based on step06_zero_trust_webapp.md

param location string = resourceGroup().location
param prefix string = 'lab01'

var planName = 'plan-core-neu01'
var webAppName = 'app-secure-neu01'
var vnetName = 'vnet-core-neu01'
var subnetName = 'subnet-jumphost01'
var peName = 'pe-app-secure'
var fdName = 'afd-secure-core'
var wafPolicyName = 'wafpolicysecure01'
var logAnalyticsName = '${prefix}-log-neu'

// Reference existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

// Reference existing subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}

// App Service Plan
resource appPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: planName
  location: location
  sku: {
    name: 'P1v2'
    tier: 'PremiumV2'
  }
  properties: {
    reserved: true // Linux Plan
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNET|8'
      localMySqlEnabled: false
      http20Enabled: true
    }
    publicNetworkAccess: 'Disabled' // Ensure private access only
  }
}

// Private Endpoint for Web App
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: peName
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-link-app-secure'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: ['sites']
        }
      }
    ]
  }
}

// Private DNS Zone for Web App
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

// Private DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// Link Private DNS Zone to VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// WAF Policy
resource wafPolicy 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2022-05-01' = {
  name: wafPolicyName
  location: 'global'
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
    }
    customRules: {
      rules: [
        {
          name: 'blockbots'
          priority: 100
          ruleType: 'MatchRule'
          matchConditions: [
            {
              matchVariable: 'RequestHeader'
              selector: 'User-Agent'
              operator: 'Contains'
              matchValue: ['bot']
              transforms: ['Lowercase']
              negateCondition: false
            }
          ]
          action: 'Block'
        }
      ]
    }
  }
}

// Azure Front Door Profile
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: fdName
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
}

// Front Door Endpoint
resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: 'endpoint-${webAppName}'
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Origin Group
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: 'default-origin-group'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

// Origin
resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'webapp-origin'
  properties: {
    hostName: webApp.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: webApp.properties.defaultHostName
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

// Route
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: frontDoorEndpoint
  name: 'default-route'
  properties: {
    customDomains: []
    originGroup: {
      id: originGroup.id
    }
    ruleSets: []
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/*']
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
  dependsOn: [
    origin
  ]
}

// Security Policy to attach WAF
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: frontDoorProfile
  name: 'security-policy'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: ['/*']
        }
      ]
    }
  }
}

// Web App Authentication Configuration
resource webAppAuth 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: webApp
  name: 'authsettingsV2'
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'RedirectToLoginPage'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: 'https://sts.windows.net/${subscription().tenantId}/'
          clientId: 'YOUR_CLIENT_ID'
        }
        login: {
          disableWWWAuthenticate: false
        }
      }
    }
    login: {
      routes: {
        logoutEndpoint: '/.auth/logout'
      }
      tokenStore: {
        enabled: true
      }
    }
    httpSettings: {
      requireHttps: true
      routes: {
        apiPrefix: '/.auth'
      }
    }
  }
}

// Diagnostic Settings for Web App
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'webapp-diagnostics'
  scope: webApp
  properties: {
    workspaceId: resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsName)
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Output
output frontDoorEndpointUrl string = 'https://${frontDoorEndpoint.properties.hostName}'
output webAppName string = webApp.name
output privateEndpointName string = privateEndpoint.name
