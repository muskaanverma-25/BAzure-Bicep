resource azbicepasp1 'Microsoft.Web/sites@2021-01-15' = {
  name: 'name'
  location: location
  properties: {
    serverFarmId: 'webServerFarms.id'
  }
}

server

resource webApplication 'Microsoft.Web/sites@2021-01-15' = {
  name: 'name'
  location: location
  properties: {
    serverFarmId: 'webServerFarms.id'
  }
}

vm,subnet,vnet
rds,,nsg,managed identity,19


