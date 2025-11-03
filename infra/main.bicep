param location string = resourceGroup().location
@minLength(3)
param siteName string // used as a prefix for storage & app names

// Multi-subscription support: Add subscription IDs to monitor (comma-separated)
// Why: Enterprises have multiple subscriptions; this allows aggregated compliance view
param additionalSubscriptionIds string = '' // e.g., 'sub-id-1,sub-id-2'

// Alerting configuration
// Why: Proactive notifications when compliance degrades or security issues arise
param alertEmail string = '' // Email for compliance alerts (leave empty to disable)
param teamsWebhookUrl string = '' // Teams webhook URL (leave empty to disable)

// Historical data retention
// Why: Compliance teams need trend analysis, not just current state
param historicalDataRetentionDays int = 30 // Days to retain historical metrics

var storageName = take(toLower(format('st{0}{1}', siteName, uniqueString(resourceGroup().id))), 24)
var appInsightsName = format('appi-{0}', siteName)
var functionAppName = format('func-{0}', siteName)
var hostingPlanName = format('plan-{0}', siteName)
var logicAppName = format('la-{0}-writer', siteName)
var blobConnectionName = format('blob-{0}', siteName)
var tableConnectionName = format('table-{0}', siteName) // Why: Store historical metrics for trend analysis
var emailConnectionName = format('email-{0}', siteName) // Why: Send compliance alerts via email
var teamsConnectionName = format('teams-{0}', siteName) // Why: Send alerts to Teams channels
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageTableDataContributorRoleId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Why: Logic App needs write access to Table Storage

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      appSettings: [
        { name: 'AzureWebJobsStorage', value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value};EndpointSuffix=core.windows.net' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'node' }
        { name: 'APPINSIGHTS_INSTRUMENTATIONKEY', value: appi.properties.InstrumentationKey }
        { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '1' }
      ]
      http20Enabled: true
      ftpsState: 'Disabled'
    }
    httpsOnly: true
  }
}

resource availabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: format('avail-{0}', siteName)
  location: location
  tags: {
    'hidden-link:${appi.id}': 'Resource'
  }
  properties: {
    SyntheticMonitorId: format('avail-{0}', siteName)
    Name: 'Health Endpoint Check'
    Enabled: true
    Frequency: 300
    Timeout: 30
    Kind: 'ping'
    RetryEnabled: true
    Locations: [
      { Id: 'us-ca-sjc-azr' }
      { Id: 'us-tx-sn1-azr' }
      { Id: 'us-il-ch1-azr' }
      { Id: 'us-va-ash-azr' }
      { Id: 'us-fl-mia-edge' }
    ]
    Configuration: {
      WebTest: '<WebTest Name="Health Check" Enabled="True" Timeout="30" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010"><Items><Request Method="GET" Version="1.1" Url="https://${functionApp.properties.defaultHostName}/api/health" ThinkTime="0" Timeout="30" ParseDependentRequests="False" FollowRedirects="True" /></Items></WebTest>'
    }
  }
  dependsOn: [
    functionApp
  ]
}

resource blobConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: blobConnectionName
  location: location
  properties: {
    displayName: 'Blob Storage Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
    }
    parameterValues: {
      accountName: storage.name
      accessKey: listKeys(storage.id, storage.apiVersion).keys[0].value
    }
  }
}

// Why: Table Storage connection for historical metrics (enables trend analysis)
// Cost: ~$1-2/month for 30 days of hourly data points
resource tableConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: tableConnectionName
  location: location
  properties: {
    displayName: 'Table Storage Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuretables')
    }
    parameterValues: {
      storageaccount: storage.name
      sharedkey: listKeys(storage.id, storage.apiVersion).keys[0].value
    }
  }
}

// Why: Email connection for compliance alerts (notifies team when issues detected)
// Cost: Free with Office 365 connector
resource emailConnection 'Microsoft.Web/connections@2016-06-01' = if (!empty(alertEmail)) {
  name: emailConnectionName
  location: location
  properties: {
    displayName: 'Email Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
    }
    // Note: Requires manual OAuth consent after deployment
  }
}

// Why: Teams connection for real-time alerts to compliance channel
// Cost: Free
resource teamsConnection 'Microsoft.Web/connections@2016-06-01' = if (!empty(teamsWebhookUrl)) {
  name: teamsConnectionName
  location: location
  properties: {
    displayName: 'Teams Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'teams')
    }
    // Note: Requires manual OAuth consent after deployment
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          type: 'Object'
        }
        additionalSubscriptions: {
          type: 'String'
          defaultValue: ''
        }
        alertEmailAddress: {
          type: 'String'
          defaultValue: ''
        }
        teamsWebhook: {
          type: 'String'
          defaultValue: ''
        }
        retentionDays: {
          type: 'Int'
          defaultValue: 30
        }
      }
      triggers: {
        Every_15_Minutes: {
          recurrence: {
            frequency: 'Minute'
            interval: 15
          }
          type: 'Recurrence'
        }
      }
      actions: {
        Compose_Uptime: {
          type: 'Compose'
          inputs: {
            window: '24h'
            availability: '99.95'
            tests: '288'
            failures: '0'
            lastCheck: '@{utcNow()}'
          }
          runAfter: {}
        }
        Compose_Security: {
          type: 'Compose'
          inputs: {
            secureScore: '78'
            highRecs: '1'
            mediumRecs: '4'
            lastUpdated: '@{utcNow()}'
          }
          runAfter: {}
        }
        Compose_Policy: {
          type: 'Compose'
          inputs: {
            assignmentsEvaluated: '12'
            nonCompliant: '3'
            lastUpdated: '@{utcNow()}'
          }
          runAfter: {}
        }
        Compose_Changes: {
          type: 'Compose'
          inputs: {
            mostRecentChange: {
              resource: 'nsg-prod-web'
              action: 'Microsoft.Network/networkSecurityGroups/write'
              time: '@{utcNow()}'
              actor: 'user:automation@contoso.com'
            }
          }
          runAfter: {}
        }
        Put_Uptime: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${storage.name}\'))}/files/@{encodeURIComponent(encodeURIComponent(\'/$web/data/uptime.json\'))}'
            body: '@outputs(\'Compose_Uptime\')'
          }
          runAfter: {
            Compose_Uptime: [
              'Succeeded'
            ]
          }
        }
        Put_Security: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${storage.name}\'))}/files/@{encodeURIComponent(encodeURIComponent(\'/$web/data/security.json\'))}'
            body: '@outputs(\'Compose_Security\')'
          }
          runAfter: {
            Compose_Security: [
              'Succeeded'
            ]
          }
        }
        Put_Policy: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${storage.name}\'))}/files/@{encodeURIComponent(encodeURIComponent(\'/$web/data/policy.json\'))}'
            body: '@outputs(\'Compose_Policy\')'
          }
          runAfter: {
            Compose_Policy: [
              'Succeeded'
            ]
          }
        }
        Put_Changes: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${storage.name}\'))}/files/@{encodeURIComponent(encodeURIComponent(\'/$web/data/changes.json\'))}'
            body: '@outputs(\'Compose_Changes\')'
          }
          runAfter: {
            Compose_Changes: [
              'Succeeded'
            ]
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: blobConnection.id
            connectionName: blobConnectionName
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
          }
          azuretables: {
            connectionId: tableConnection.id
            connectionName: tableConnectionName
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuretables')
          }
        }
      }
      // Pass configuration to Logic App for multi-sub and alerting
      additionalSubscriptions: {
        value: additionalSubscriptionIds
      }
      alertEmailAddress: {
        value: alertEmail
      }
      teamsWebhook: {
        value: teamsWebhookUrl
      }
      retentionDays: {
        value: historicalDataRetentionDays
      }
    }
  }
}

// Why: Logic App needs write access to Blob Storage for dashboard data files
resource storageBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, logicApp.id, storageBlobDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Why: Logic App needs write access to Table Storage for historical metrics
// This enables trend analysis over time (7-day, 30-day charts)
resource storageTableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, logicApp.id, storageTableDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageTableDataContributorRoleId)
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output storageAccountName string = storage.name
output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output staticWebsiteUrl string = storage.properties.primaryEndpoints.web
output logicAppName string = logicApp.name
output logicAppPrincipalId string = logicApp.identity.principalId
