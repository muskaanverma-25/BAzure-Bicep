//@minLength(3)
//@maxLength(11)
//param storagePrefix string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSKU string
param storagekind string
param location string
param storagesupportsHttpsTrafficOnly bool
param uniqueStorageName string
param userAssignedIdentities object
//'${storagePrefix}${uniqueString(resourceGroup().id)}'
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: uniqueStorageName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  sku: {
    name: storageSKU
  }
  kind: storagekind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      resourceAccessRules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: storagesupportsHttpsTrafficOnly
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

output storageEndpoint object = stg.properties.primaryEndpoints

//param blobServiceName string
param blobContainerName string
param blobContainerProperties object
param blobServiceProperties object

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: stg
  name: 'default'
  properties: blobServiceProperties
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobService
  name: blobContainerName
  properties: blobContainerProperties
}
