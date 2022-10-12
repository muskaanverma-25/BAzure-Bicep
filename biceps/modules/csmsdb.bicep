@description('Cosmos DB account name')
param accountName string

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The name for the SQL API database')
param databaseName string

@description('The name for the SQL API container')
param containerName string
param databaseAccountOfferType string
param dbdefaultConsistencyLevel string
param enableFreeTier bool
param userAssignedIdentities object
//param keyVaultKeyUri string

resource account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: toLower(accountName)
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  properties: {
    enableFreeTier: enableFreeTier
    databaseAccountOfferType: databaseAccountOfferType
    consistencyPolicy: {
      defaultConsistencyLevel: dbdefaultConsistencyLevel
    }
    locations: [
      {
        locationName: location
      }
    ]
    //keyVaultKeyUri: keyVaultKeyUri
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  name: '${account.name}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
}

param partitionKey object
param indexingPolicy object
param throughput int

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  name: '${database.name}/${containerName}'
  properties: {
    resource: {
      id: containerName
      partitionKey: partitionKey
      indexingPolicy: indexingPolicy
    }
    options: {
      throughput: throughput
    }
  }
}

output cosmosAccountId string = account.id
