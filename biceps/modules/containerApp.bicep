//########################################//
//*** Creating Log Analytics Workspace ***//
//########################################//

param environment_name string
param location string 
param logAnaProperties object
param appLogsDestination string
var logAnalyticsWorkspaceName = 'logs-${environment_name}'

resource logAnalyticsWorkspace'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any(logAnaProperties)
}

output clientId string = logAnalyticsWorkspace.properties.customerId

//#####################################//
//*** Creating Application Insights ***//
//#####################################//

@description('Name of Application Insights resource.')
param appInsightname string

@description('Type of app you are deploying. This field is for legacy reasons and will not impact the type of App Insights resource you deploy.')
param type string = 'web'

@description('Source of Azure Resource Manager deployment')
param requestSource string = 'rest'

resource appinsight 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightname
  location: location
  kind: 'other'
  properties: {
    Application_Type: type
    Flow_Type: 'Bluefield'
    Request_Source: requestSource
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

output appinKey string = appinsight.properties.InstrumentationKey
output appinconnstring string = appinsight.properties.ConnectionString

//##############################################//
//*** Creating Manged Env for Container apps ***//
//##############################################//

param managedEnvName string
resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: managedEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: appLogsDestination
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspace.id, '2020-03-01-preview').customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, '2020-03-01-preview').primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: infrastructureSubnetId
      internal: false
    }
    zoneRedundant: true
  }
}

output id string = environment.id
output staticIp string = environment.properties.staticIp

param infrastructureSubnetId string

//resource managedenv_tntinst 'Microsoft.App/managedEnvironments@2022-03-01' = {
//  name: 'tntinstsvcapp-mangedenv'
//  location: location
//  properties: {
 //   appLogsConfiguration: {
 //     destination: appLogsDestination
 //     logAnalyticsConfiguration: {
//        customerId: reference(logAnalyticsWorkspace.id, '2020-03-01-preview').customerId
 //       sharedKey: listKeys(logAnalyticsWorkspace.id, '2020-03-01-preview').primarySharedKey
//      }
//    }
    //daprAIConnectionString: 'string'
    //daprAIInstrumentationKey: 'string'
    //vnetConfiguration: {
      //dockerBridgeCidr: 'string'
      //infrastructureSubnetId: infrastructureSubnetId
      //internal: false
      ///platformReservedCidr: 'string'
      //platformReservedDnsIP: 'string'
      
    //}
    ///zoneRedundant: false
  //}
//}


//###################################//
//*** Container App Common Config ***//
//###################################//

param userAssignedIdentities object
param containerimage string
param conresources object
param scale object

//######################################//
//*** Creating Frontend Container App***//
//######################################//

param frontendappName string
param frontendappingress object

resource frontendapp 'Microsoft.App/containerApps@2022-03-01' = {
  name: frontendappName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: frontendappingress
    }
    template: {
      containers: [
        {
          image: containerimage
          name: frontendappName
          resources: conresources
        }
      ]
      scale: scale
    }
  }
}

//######################################//
//*** Creating Backend Container Apps***//
//######################################//

param backendappingress object
param daprenable bool
param daprAppProtocol string
param backendappNames array

resource backendapp 'Microsoft.App/containerApps@2022-03-01' = [for name in backendappNames: {
  name: '${name}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: backendappingress
      dapr: {
        appPort: 3000
        enabled: daprenable
        appProtocol: daprAppProtocol
      }
    }
    template: {
      containers: [
        {
          image: containerimage
          name: '${name}'
          resources: conresources
        }
      ]
      scale: scale
    }
  }
}]
