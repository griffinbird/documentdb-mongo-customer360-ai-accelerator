@description('Name of the Azure OpenAI resource')
param openAiName string

@description('Azure region for the OpenAI resource')
param location string = resourceGroup().location

@description('Name of the embeddings deployment')
param embeddingsDeploymentName string = 'text-embedding-ada-002'

@description('Name of the embeddings model')
param embeddingsModelName string = 'text-embedding-ada-002'

@description('Embeddings model version')
param embeddingsModelVersion string = '2'

@description('Name of the completions deployment')
param completionsDeploymentName string = 'gpt-4.1'

@description('Name of the completions model')
param completionsModelName string = 'gpt-4.1'

@description('Completions model version')
param completionsModelVersion string = '2025-04-14'

@description('Tags to apply to the resources')
param tags object = {}

@description('Capacity (TPM in thousands) for embeddings deployment')
param embeddingsCapacity int = 30

@description('Capacity (TPM in thousands) for completions deployment')
param completionsCapacity int = 30

// Azure OpenAI resource
resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
  }
}

// Embeddings deployment
resource embeddingsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAi
  name: embeddingsDeploymentName
  sku: {
    name: 'Standard'
    capacity: embeddingsCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingsModelName
      version: embeddingsModelVersion
    }
  }
}

// Completions deployment
resource completionsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAi
  name: completionsDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: completionsCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: completionsModelName
      version: completionsModelVersion
    }
  }
  dependsOn: [
    embeddingsDeployment
  ]
}

output openAiName string = openAi.name
output openAiEndpoint string = openAi.properties.endpoint
output openAiId string = openAi.id
output embeddingsDeploymentName string = embeddingsDeployment.name
output embeddingsModelName string = embeddingsModelName
output completionsDeploymentName string = completionsDeployment.name
