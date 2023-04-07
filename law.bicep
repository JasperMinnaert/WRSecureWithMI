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
      id: '/subscriptions/6996cd12-78ad-45c8-b272-40e0d1d4e1f7/providers/Microsoft.Web/locations/westeurope/managedApis/azuresentinel'
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
            id: '/subscriptions/6996cd12-78ad-45c8-b272-40e0d1d4e1f7/providers/Microsoft.Web/locations/westeurope/managedApis/azuresentinel'
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
          logicAppResourceId: '/subscriptions/6996cd12-78ad-45c8-b272-40e0d1d4e1f7/resourceGroups/rg-wortellready-weu/providers/Microsoft.Logic/workflows/WortellReady_LogicApp'
          tenantId: '2ce25f97-14be-4506-bc50-9505a266b45b'
        }
      }
    ]
  }
  dependsOn:[
    azureSentinel
    workspace
  ]
}
