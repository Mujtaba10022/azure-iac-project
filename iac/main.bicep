// Main Bicep template for Azure Multi-Tier Application

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Project name')
param projectName string = 'gmapp'

// Variables
var vnetName = 'vnet-${projectName}-${environment}'
var webSubnetName = 'snet-web-${environment}'
var dbSubnetName = 'snet-db-${environment}'
var nsgWebName = 'nsg-web-${environment}'
var nsgDbName = 'nsg-db-${environment}'
var appServicePlanName = 'asp-${projectName}-${environment}'
var webAppName = 'app-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'

// Network Security Group for Web Tier
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgWebName
  location: location
  properties: {
    securityRules:  [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTP'
        properties:  {
          priority:  110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Network Security Group for Database Tier
resource nsgDb 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name:  nsgDbName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebSubnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol:  'Tcp'
          sourcePortRange: '*'
          destinationPortRange:  '1433'
          sourceAddressPrefix: '10.0.1.0/24'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyInternet'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange:  '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location:  location
  properties:  {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: webSubnetName
        properties:  {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgWeb. id
          }
          delegations: [
            {
              name: 'delegation'
              properties:  {
                serviceName: 'Microsoft. Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: dbSubnetName
        properties:  {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsgDb.id
          }
        }
      }
    ]
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Web App
resource webApp 'Microsoft. Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion:  'NODE|18-lts'
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion:  '1.2'
    }
    httpsOnly: true
    virtualNetworkSubnetId:  vnet.properties. subnets[0].id
  }
}

// Outputs
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output vnetId string = vnet.id