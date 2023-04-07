//General
param subscriptionID string = subscription().subscriptionId
param RG string = resourceGroup().name
param tenantID string = tenant().tenantId

//Connection
param CONDisplayName string


//Logic App
param location string
var logicAppDefinition = json(loadTextContent('definition.json'))
param LADisplayName string

//Log Anlytics Workspace and Sentinel
param LAWDisplayName string
param pricingTier string
param immediatePurgeDataOn30DaysB bool
param dataRetention int

//Automation rule
param ARDisplayName string

//Deploy connection
resource sentinelConnection 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: CONDisplayName
  location: location
  kind: 'V1'
  properties: {
    alternativeParameterValues: {}
    api: {
      id: '/subscriptions/${subscriptionID}/providers/Microsoft.Web/locations/westeurope/managedApis/azuresentinel'
    }
    customParameterValues: {}
    parameterValueType: 'Alternative'
    displayName: 'SentinelApi'
    parameterValueSet: {}
  }
}

//Deploy logicapp
resource logicapp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: LADisplayName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: logicAppDefinition.definition
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            connectionId: sentinelConnection.id
            connectionName: sentinelConnection.name
            id: '/subscriptions/${subscriptionID}/providers/Microsoft.Web/locations/westeurope/managedApis/azuresentinel'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }

            }

          }
        }
      }
    }
  }
}

//Deploy Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
name: LAWDisplayName // must be globally unique
location: location
properties: {
  sku: {
      name: pricingTier
  }
  retentionInDays: dataRetention
  features: {
      immediatePurgeDataOn30Days: immediatePurgeDataOn30DaysB
  }
}
}

//Deploy Sentinel solution
resource azureSentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: concat('SecurityInsights(',workspace.name,')')
  location: location
  properties: {
      workspaceResourceId: workspace.id
  }
  plan: {
      name: concat('SecurityInsights(',workspace.name,')')
      product: 'OMSGallery/SecurityInsights'
      publisher: 'Microsoft'
      promotionCode: ''
  }
  dependsOn:[
    workspace
  ]
}

//Deploy Automation Rule
resource automationRuleGuid 'Microsoft.SecurityInsights/automationRules@2022-10-01-preview' = {
  scope: workspace
  name: LAWDisplayName
  properties: {
    displayName: ARDisplayName
    order: 1
    triggeringLogic: {
      isEnabled: true
      triggersOn: 'Incidents'
      triggersWhen: 'Created'
      conditions: []
    }
    actions: [
      {
        order: 1
        actionType: 'RunPlaybook'
        actionConfiguration: {
          logicAppResourceId: '/subscriptions/${subscriptionID}/resourceGroups/${RG}/providers/Microsoft.Logic/workflows/WortellReady_LogicApp'
          tenantId: '${tenantID}'
        }
      }
    ]
  }
  dependsOn:[
    azureSentinel
    workspace
  ]
}
