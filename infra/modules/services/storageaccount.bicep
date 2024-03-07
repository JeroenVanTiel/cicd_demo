// This template is used to create a datalake.
targetScope = 'resourceGroup'

// Parameters
param environment string
param location string
param tags object
param storageName string
param fileSystemNames array

// Variables
var storageNameCleaned = replace(storageName, '-', '')
var storageZrsEnvironments = [
  'ACC'
  'PROD'
]

// Resources
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageNameCleaned
  location: location
  tags: tags
  sku: {
    name: contains(storageZrsEnvironments, environment) ? 'Standard_ZRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'    
    allowSharedKeyAccess: false
    azureFilesIdentityBasedAuthentication: {
      defaultSharePermission:'None'
      directoryServiceOptions:'None'
    }
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'    
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: true
    isNfsV3Enabled: false //NFS doesn't work with ACL, so disabled for now.
    isSftpEnabled: false  //sftp sink service requires local users to be created for storage account, hence disbled.
    keyPolicy: {
      keyExpirationPeriodInDays: 30
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'Metrics'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []      
    }
    routingPreference: {  
      routingChoice: 'MicrosoftRouting'
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: true
    }
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
  }
}

resource storageManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2022-09-01' = {
  parent: storage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'default'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToCool: {                  
                  daysAfterModificationGreaterThan: 90
                }                
              }              
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: []
            }
          }
        }
      ]
    }
  }
}

resource storageBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storage
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource storageFileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for fileSystemName in fileSystemNames: {
  parent: storageBlobServices
  name: fileSystemName
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

// Outputs
output storageId string = storage.id
output storageFileSystemIds array = [for fileSystemName in fileSystemNames: {
  storageFileSystemId: resourceId('Microsoft.Storage/storageAccounts/blobServices/containers', storageNameCleaned, 'default', fileSystemName)
}]
