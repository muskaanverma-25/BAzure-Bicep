param location string = resourceGroup().location
param virtualNetworkName string
param snet1Name string
//param snet2Name string
param addprefvnet string
param addprefsnet1 string
//param addprefsnet2 string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {

  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addprefvnet
      ]
    }
    subnets: [
      {
        name: snet1Name
        properties: {
          addressPrefix: addprefsnet1
          networkSecurityGroup: {
            id: nsg.id
            location: location
          }      

        }
      }
      //{
      //  name: snet2Name
      //  properties: {
      //    addressPrefix: addprefsnet2
       // }
      //}
    ]
  }

  resource subnet1 'subnets' existing = {
    name: snet1Name
  }
}

output subnet1ResourceId string = virtualNetwork::subnet1.id
//output subnet2ResourceId string = virtualNetwork::subnet2.id


resource nsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg_${snet1Name}'
  location: location
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  properties: {
    flushConnection: false
    securityRules: [
      {
        //id: 'string'
        name: 'httpsTrafficInbound'
        properties: {
          access: 'Allow'
          description: 'https for container apps'
          destinationAddressPrefix: '0.0.0.0'
          destinationPortRange: '80'
          direction: 'Inbound'
          priority: 160
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        } // properties (securityrules) ends here
        //type: 'string'
      }
      {
        //id: 'string'
        name: 'httpsTrafficOutbound'
        properties: {
          access: 'Allow'
          description: 'https for container apps'
          destinationAddressPrefix: '0.0.0.0'
          destinationPortRange: '80'
          direction: 'Outbound'
          priority: 160
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        } // properties (securityrules) ends here
        //type: 'string'
      }
    ] // securityrules ends here
  } // nsg properties ends here
}
