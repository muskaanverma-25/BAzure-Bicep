//*** ACR Creation ***//

@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
param acrSku string
param adminUserEnabled bool
param userAssignedIdentities object

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
  }
}

@description('Output the login server property for later use')
output loginServer string = acrResource.properties.loginServer


