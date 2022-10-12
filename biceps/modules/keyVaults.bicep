param kvappName string

//@maxLength(24)
//param vaultName string = '${kvappName}-${substring(uniqueString(resourceGroup().id), 0, 23 - (length(kvappName) + 3))}' // must be globally unique
param location string = resourceGroup().location
param kv_sku string

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault.')
param tenantId string

@description('The object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies.')
param objectId string

param enabledForDeployment bool = true
param enabledForTemplateDeployment bool = true
param enabledForDiskEncryption bool = true
param enablePurgeProtection bool
param enableSoftDelete bool
param enableRbacAuthorization bool = true
param softDeleteRetentionInDays int = 90

param networkAcls object = {
  ipRules: []
  virtualNetworkRules: []
}

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: kvappName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: kv_sku
    }
    accessPolicies: [
      {
        objectId: objectId
        permissions: {
          keys: [
            'list', 'decrypt', 'get', 'wrapKey', 'unwrapKey'
          ]
        }
        tenantId: tenantId
      }
      {
        //applicationId: 'a232010e-820c-4083-83bb-3ace5fc29d0b'
        objectId: 'e4fb2578-f095-4c3e-8c7d-4e1c4d82dbc7'
        permissions: {
          keys: [
            'list', 'decrypt', 'get', 'wrapKey'
          ]
        }
        tenantId: tenantId
      }
    ]
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    networkAcls: networkAcls
  }
}

output keyVaultName string = keyvault.name
output keyVaultId string = keyvault.id

param csmsKeyName string
param keysProperties object
resource csmsKey 'Microsoft.KeyVault/vaults/keys@2021-06-01-preview' = {
  name: csmsKeyName
  
  parent: keyvault
  properties: keysProperties
}

param stKeyName string
resource stKey 'Microsoft.KeyVault/vaults/keys@2021-06-01-preview' = {
  name: stKeyName
  
  parent: keyvault
  properties: keysProperties
}

output keyVaultKeyUri string = csmsKey.id
