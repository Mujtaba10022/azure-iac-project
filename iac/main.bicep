targetScope = 'resourceGroup'

param environment string
param location string = resourceGroup().location
param projectName string = 'GM'

@secure()
param sqlAdminLogin string

@secure()
param sqlAdminPassword string

var suffix = toLower('${projectName}${environment}${uniqueString(resourceGroup().id)}')

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-${suffix}'
  location: location
  properties: {
    addressSpace:  {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'frontend-subnet'
        properties: { addressPrefix: '10.0.1.0/24' }
      }
      {
        name: 'backend-subnet'
        properties: { addressPrefix: '10.0.2.0/24' }
      }
      {
        name:  'data-subnet'
        properties: { addressPrefix: '10.0.3.0/24' }
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: take('st${suffix}', 24)
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: 'sql-${suffix}'
  location:  location
  properties:  {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: 'sqldb-${suffix}'
  location: location
  sku: { name:  'Basic', tier: 'Basic' }
}

resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties:  {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output vnetId string = vnet.id
output storageAccountName string = storageAccount.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
// CI/CD enabled

// Trigger workflow v2

// Trigger v6

// Trigger v7
