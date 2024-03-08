// This template is used as a module from the main.bicep template. 
// The module contains a template to create storage resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param environment string


// Variables
var storageDemo_1_Name = '${prefix}-cicd-1-${environment}'
var storageDemo_2_Name = '${prefix}-cicd-2-${environment}'


var domainFileSytemNames = [
  'welcome'
  'azure'
  'data'
  'guild'
]
var datalakes = [
  {
    name: 'storageDemo1'
    storageName: storageDemo_1_Name
  }
  {
    name: 'storageDemo2'
    storageName: storageDemo_2_Name
  }
]

// Resources
module storageacct 'services/storageaccount.bicep' = [for datalake in datalakes: {
  name: datalake.name
  scope: resourceGroup()
  params: {
    environment: environment
    location: location
    tags: tags
    storageName: datalake.storageName    
    fileSystemNames: domainFileSytemNames       
  }
}]


// Outputs
output deployeddatalakes array = [for (datalake,i) in datalakes: {
  datalakename: storageacct[i].name  
}]
