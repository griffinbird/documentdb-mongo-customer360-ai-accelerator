targetScope = 'subscription'

// ---- Parameters ----

@minLength(1)
@maxLength(64)
@description('Name of the environment (used for resource naming)')
param environmentName string

@minLength(1)
@description('Primary Azure region for all resources')
param location string

@description('DocumentDB administrator username')
param documentdbAdminUsername string = 'docdbadmin'

@secure()
@description('DocumentDB administrator password')
param documentdbAdminPassword string

@description('DocumentDB cluster tier')
@allowed(['M10', 'M20', 'M30', 'M40', 'M50', 'M60', 'M80'])
param documentdbClusterTier string = 'M30'

@description('Azure OpenAI embeddings deployment name')
param openAiEmbeddingsDeploymentName string = 'text-embedding-ada-002'

@description('Azure OpenAI embeddings model name')
param openAiEmbeddingsModelName string = 'text-embedding-ada-002'

@description('Azure OpenAI completions deployment name')
param openAiCompletionsDeploymentName string = 'gpt-4.1'

@description('Azure OpenAI location (some models may not be available in all regions)')
param openAiLocation string = ''

// ---- Variables ----
var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
}

var effectiveOpenAiLocation = empty(openAiLocation) ? location : openAiLocation

// ---- Resource Group ----
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// ---- DocumentDB Module ----
module documentdb 'documentdb.bicep' = {
  name: 'documentdb'
  scope: rg
  params: {
    clusterName: '${abbrs.documentDBMongoClusters}${resourceToken}'
    location: location
    adminUsername: documentdbAdminUsername
    adminPassword: documentdbAdminPassword
    clusterTier: documentdbClusterTier
    tags: tags
  }
}

// ---- Azure OpenAI Module ----
module openai 'openai.bicep' = {
  name: 'openai'
  scope: rg
  params: {
    openAiName: '${abbrs.cognitiveServicesOpenAI}${resourceToken}'
    location: effectiveOpenAiLocation
    embeddingsDeploymentName: openAiEmbeddingsDeploymentName
    embeddingsModelName: openAiEmbeddingsModelName
    completionsDeploymentName: openAiCompletionsDeploymentName
    tags: tags
  }
}

// ---- Outputs ----
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name

// DocumentDB outputs
output DOCUMENTDB_CLUSTER_NAME string = documentdb.outputs.clusterName
output DOCUMENTDB_CONN_STRING string = documentdb.outputs.connectionString

// OpenAI outputs
output OPENAI_API_ENDPOINT string = openai.outputs.openAiEndpoint
output OPENAI_EMBEDDINGS_DEPLOYMENT string = openai.outputs.embeddingsDeploymentName
output OPENAI_EMBEDDINGS_MODEL_NAME string = openai.outputs.embeddingsModelName
output OPENAI_COMPLETIONS_DEPLOYMENT string = openai.outputs.completionsDeploymentName
output OPENAI_API_TYPE string = 'azure'
output OPENAI_API_VERSION string = '2024-10-21'
