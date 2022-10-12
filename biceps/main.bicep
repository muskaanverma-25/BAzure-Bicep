//#########################################################################################//
//#########################################################################################//
//*** Created this file to to convert the existing separate bicep files to use a module ***//
//#########################################################################################//
//#########################################################################################//

//###########################################//
//########## Managed Identity ###############//
//###########################################//

param userAssignedIdentities object = {'${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', managedidentityName)}': {}}
param location string = resourceGroup().location

param managedidentityName string

resource managedidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedidentityName
  location: location
}

output principalId string = managedidentity.properties.principalId
output clientId string = managedidentity.properties.clientId

//###############################//
//*** Creating Storage Account***//
//###############################//

//@minLength(3)
//@maxLength(11)
param uniqueStorageName string
param storageSKU string
param storagekind string
param storagesupportsHttpsTrafficOnly bool
//param blobServiceName string
param blobContainerName string
param blobServiceProperties object
param blobContainerProperties object

module stgModule 'modules/stg.bicep' = {
  name: 'storageDeploy'
  
  params: {
    uniqueStorageName: uniqueStorageName
    location: location
    storageSKU: storageSKU
    storagekind: storagekind
    storagesupportsHttpsTrafficOnly: storagesupportsHttpsTrafficOnly
    userAssignedIdentities: userAssignedIdentities
    blobServiceProperties: blobServiceProperties
    blobContainerName: blobContainerName
    blobContainerProperties: blobContainerProperties
  }
  dependsOn:[
    managedidentity
  ]
}

output storageEndpoint object = stgModule.outputs.storageEndpoint

//###################//
//*** Creating ACR***//
//###################//

param acrName string
param acrSku string
param adminUserEnabled bool

module acrModule 'modules/acr.bicep' = {
  name: 'acrDeploy'
  
  params: {
    acrName: acrName
    location: location
    acrSku: acrSku
    adminUserEnabled: adminUserEnabled
    userAssignedIdentities: userAssignedIdentities
  }
  dependsOn:[
    managedidentity
  ]
}

//####################//
//*** Creating VNET***//
//####################//

param virtualNetworkName string
param snet1Name string
//param snet2Name string
param addprefvnet string
param addprefsnet1 string
//param addprefsnet2 string

module vnetModule 'modules/vnet.bicep' = {
  name: 'vnetDeploy'
  
  params: {
    virtualNetworkName: virtualNetworkName
    location: location
    addprefvnet: addprefvnet
    snet1Name: snet1Name
    addprefsnet1: addprefsnet1
    //snet2Name: snet2Name
    //addprefsnet2:addprefsnet2
  }
}

//#########################//
//*** Creating COSMOS DB***//
//#########################//

param databaseName string
param containerName string
param accountName string
param databaseAccountOfferType string
param dbdefaultConsistencyLevel string
param enableFreeTier bool
param partitionKey object
param indexingPolicy object
param throughput int
//param keyVaultKeyUri string

module csmsdbModule 'modules/csmsdb.bicep' = {
  name: 'csmsdbDeploy'
  
  params: {
    databaseName: databaseName
    location: location
    containerName: containerName
    accountName: accountName
    databaseAccountOfferType: databaseAccountOfferType
    dbdefaultConsistencyLevel: dbdefaultConsistencyLevel
    enableFreeTier: enableFreeTier
    partitionKey: partitionKey
    indexingPolicy: indexingPolicy
    throughput: throughput
    userAssignedIdentities: userAssignedIdentities
    //keyVaultKeyUri: 'https://${kvappName}${environment().suffixes.keyvaultDns}/keys/${csmsKeyName}'
  }
  dependsOn:[
    managedidentity
  ]
}

//#############################//
//*** Creating Container App***//
//#############################//

param environment_name string
param appLogsDestination string
param logAnaProperties object
param managedEnvName string
param containerimage string
param frontendappName string
param frontendappingress object
param backendappNames array
param backendappingress object
param daprenable bool
param daprAppProtocol string
param conresources object
param scale object

//param infrastructureSubnetId string = vnetModule.outputs.subnet1ResourceId
//param runtimeSubnetId string

@description('Name of Application Insights resource.')
param appInsightname string

module containerapp 'modules/containerApp.bicep' = {
  name: 'containerAppDeploy'
  
  params: {
    location: location
    environment_name: environment_name
    appLogsDestination: appLogsDestination
    logAnaProperties: logAnaProperties
    appInsightname: appInsightname
    managedEnvName: managedEnvName
    containerimage: containerimage
    frontendappName: frontendappName
    frontendappingress: frontendappingress
    backendappNames: backendappNames
    backendappingress: backendappingress
    daprenable: daprenable
    daprAppProtocol: daprAppProtocol
    conresources: conresources
    scale: scale
    userAssignedIdentities: userAssignedIdentities
    infrastructureSubnetId: vnetModule.outputs.subnet1ResourceId
  }
  dependsOn:[
    managedidentity
    vnetModule
  ]
}

output appinKey string = containerapp.outputs.appinKey
output appinconnstring string = containerapp.outputs.appinconnstring

//##########################//
//*** Creating Key Vault ***//
//##########################//

param kvappName string

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault.')
param tenantId string

param kv_sku string
param enabledForDeployment bool = true
param enabledForTemplateDeployment bool = true
param enabledForDiskEncryption bool = true
param enableRbacAuthorization bool = true
param softDeleteRetentionInDays int = 90
param enablePurgeProtection bool
param enableSoftDelete bool

param networkAcls object = {
  ipRules: []
  virtualNetworkRules: []
}

param csmsKeyName string
param stKeyName string

//@description('The object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies.')
//param objectId string
param keysProperties object

module keyVault './modules/keyVaults.bicep' = {
  name: 'keyVault_deploy'
  
  params: {
    location: location
    kvappName: kvappName
    tenantId: tenantId
    objectId: managedidentity.properties.principalId
    kv_sku: kv_sku
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    networkAcls: networkAcls
    csmsKeyName: csmsKeyName
    stKeyName: stKeyName
    keysProperties: keysProperties
    // note: no need for access policies here!
  }
}
// create role assignment
//var KEY_VAULT_SECRETS_USER_ROLE_GUID = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

//resource keyVaultWebsiteUser 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//  name: guid('SecretsUser')
//  scope: resourceGroup()
//  properties: {
//    principalId: managedidentity.properties.principalId
//    roleDefinitionId: KEY_VAULT_SECRETS_USER_ROLE_GUID
//  }
//}
