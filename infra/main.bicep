targetScope = 'subscription'

// General parameters
@description('Specifies the location for all resources.')
param location string = 'westeurope'
@allowed([
  'dev'
  'test'
  'acc'
  'prod'
]) 

@description('Specifies the environment of the deployment.')
param environment string = 'dev'

@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string = 'demo'


// General variables
var name = toLower('${prefix}-${environment}')
var envShort = substring(environment,0,1)
var tags = {
  billable_application: 'azure_data_platform_datacore'
  team: 'data_core_building_blocks'
  env: environment
  Owner: 'Data Platform Ops'
  Project: 'Data Landing Zone'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}

//Resources

// Storage Resources
resource storageresourcegroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefix}-storage-${envShort}-rg'
  location: location
  tags: tags
}

module storageServices 'modules/storage-module.bicep' = {
  name: 'storageServices'
  scope: storageresourcegroup
  params: {
    environment: environment
    location: location    
    prefix: prefix
    tags: tags  
  }
}
