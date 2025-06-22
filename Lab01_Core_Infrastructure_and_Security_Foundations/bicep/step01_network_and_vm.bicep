// Bicep: Step 1 - Network and VM Deployment
// Based on step01_network_and_vm.md

// PARAMETERS
param location string = resourceGroup().location
param vmAdminUsername string = 'labadmin'
@secure()
param vmAdminPassword string

// VARIABLES
var vnetName = 'vnet-core-neu01'
var subnetJumphostName = 'subnet-jumphost01'
var subnetBastionName = 'AzureBastionSubnet'
var nsgName = 'nsg-jumphost01'
var vmName = 'vm-jhost-neu01'
var nicName = '${vmName}-nic'

// NSG with default deny-all rule
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
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

// VNet with both subnets
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.100.0.0/16' ]
    }
    subnets: [
      {
        name: subnetJumphostName
        properties: {
          addressPrefix: '10.100.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: subnetBastionName
        properties: {
          addressPrefix: '10.100.0.0/27'
        }
      }
    ]
  }
}

// NIC for VM
resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetJumphostName)
          }
        }
      }
    ]
  }
}

// Virtual Machine with system-assigned managed identity
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
