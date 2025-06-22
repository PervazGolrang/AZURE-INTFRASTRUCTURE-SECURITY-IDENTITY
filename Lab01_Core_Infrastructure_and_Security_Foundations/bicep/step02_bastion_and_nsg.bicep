// Bicep: Step 2 - Azure Bastion and NSG Configuration
// Based on step02_bastion_and_nsg.md

// PARAMETERS
param location string = resourceGroup().location
param vnetName string = 'vnet-core-neu01'
param subnetJumphostName string = 'subnet-jumphost01'
param subnetBastionName string = 'AzureBastionSubnet'
param nsgName string = 'nsg-jumphost-01'
param bastionName string = 'bastion-core-neu01'
param bastionPipName string = 'bastion-pip'

// EXISTING RESOURCES
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: vnetName
}

resource subnetJumphost 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: vnet
  name: subnetJumphostName
}

resource subnetBastion 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: vnet
  name: subnetBastionName
}

// PUBLIC IP FOR BASTION
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: bastionPipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// NETWORK SECURITY GROUP WITH RULES
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-from-Bastion'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'Allow-AzureMonitor'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureMonitor'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Deny_All_Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// UPDATE SUBNET TO ASSOCIATE WITH NSG
resource subnetUpdate 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = {
  parent: vnet
  name: subnetJumphostName
  properties: {
    addressPrefix: subnetJumphost.properties.addressPrefix
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// AZURE BASTION HOST
resource bastion 'Microsoft.Network/bastionHosts@2023-02-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: subnetBastion.id
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
  dependsOn: [
    bastionPip
  ]
}

// OUTPUTS
output bastionName string = bastion.name
output bastionPipAddress string = bastionPip.properties.ipAddress
output nsgName string = nsg.name
