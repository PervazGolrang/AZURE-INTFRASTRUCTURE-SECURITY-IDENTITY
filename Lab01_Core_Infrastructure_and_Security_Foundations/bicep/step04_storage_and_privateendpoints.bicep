// Bicep: Step 4 - Storage and Private Endpoints
// Based on step04_storage_and_privateendpoints.md

// PARAMETERS
param location string = resourceGroup().location
param storageAccountName string = 'stsecureneu01'
param vnetName string = 'vnet-core-neu01'
param subnetName string = 'subnet-jumphost01'
param logAnalyticsName string = 'log-core-neu01'
param containerName string = 'container01'

// EXISTING RESOURCES
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsName
}

// STORAGE ACCOUNT
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'Storage'
  }
}

// BLOB SERVICE
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

// CONTAINER
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

// PRIVATE DNS ZONE
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: {
    Environment: 'Lab'
    Purpose: 'DNS'
  }
}

// PRIVATE DNS ZONE VNET LINK
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-vnet-core'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// PRIVATE ENDPOINT
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-storage-blob'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'conn-storage-blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
  tags: {
    Environment: 'Lab'
    Purpose: 'Private-Endpoint'
  }
}

// PRIVATE DNS ZONE GROUP
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'blob-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// DIAGNOSTIC SETTINGS FOR BLOB SERVICE
resource blobServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-settings-storage'
  scope: blobService
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
  }
}

// OUTPUTS
output storageAccountName string = storageAccount.name
output privateEndpointName string = privateEndpoint.name
output privateDnsZoneName string = privateDnsZone.name
output containerName string = container.name
