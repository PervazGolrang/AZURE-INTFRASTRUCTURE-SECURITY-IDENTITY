// Bicep: Step 5 - Landing Zone Lite with Azure Firewall and Governance
// Based on step05_landing_zone_lite.md

// PARAMETERS
param location string = resourceGroup().location
param vnetName string = 'vnet-core-neu01'
param subnetName string = 'subnet-jumphost01'
param firewallName string = 'fw-core-neu01'
param publicIpName string = 'pip-fw-core-neu01'
param routeTableName string = 'rt-secure'
param firewallSubnetPrefix string = '10.100.2.0/24'
param sourceAddressPrefix string = '10.100.1.0/24'
param firewallPrivateIp string = '10.100.2.4'
param budgetAmount int = 10
param budgetAlertEmail string = 'your-email@domain.com'

// EXISTING RESOURCES
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName
}

// AZURE FIREWALL SUBNET
resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: firewallSubnetPrefix
  }
}

// PUBLIC IP FOR FIREWALL
resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'Firewall'
  }
}

// AZURE FIREWALL
resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'fw-config'
        properties: {
          publicIPAddress: {
            id: firewallPublicIp.id
          }
          subnet: {
            id: firewallSubnet.id
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'app-allow'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-ms-update'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*.windowsupdate.com'
              ]
              sourceAddresses: [
                sourceAddressPrefix
              ]
            }
          ]
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'Security'
  }
  dependsOn: [
    firewallSubnet
  ]
}

// ROUTE TABLE
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: routeTableName
  location: location
  properties: {
    routes: [
      {
        name: 'fw-default-route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'Routing'
  }
}

// ASSOCIATE ROUTE TABLE WITH SUBNET
resource subnetUpdate 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: subnet.properties.addressPrefix
    routeTable: {
      id: routeTable.id
    }
    // Preserve existing properties
    networkSecurityGroup: subnet.properties.networkSecurityGroup
    privateEndpointNetworkPolicies: subnet.properties.privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: subnet.properties.privateLinkServiceNetworkPolicies
  }
}

// BUDGET (Note: Budgets are subscription-level resources)
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'budget-secure-rg'
  properties: {
    timePeriod: {
      startDate: '2025-01-01'
      endDate: '2030-12-31'
    }
    timeGrain: 'Monthly'
    amount: budgetAmount
    category: 'Cost'
    notifications: {
      'Alert80Percent': {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          budgetAlertEmail
        ]
        thresholdType: 'Percentage'
      }
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroup().name
        ]
      }
    }
  }
}

// OUTPUTS
output firewallName string = firewall.name
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = firewallPublicIp.properties.ipAddress
output routeTableName string = routeTable.name
output budgetName string = budget.name
