@description('Name of the DocumentDB cluster')
param clusterName string

@description('Azure region for the cluster')
param location string = resourceGroup().location

@description('Administrator username')
param adminUsername string

@secure()
@description('Administrator password')
param adminPassword string

@description('Cluster tier (e.g. M10, M30)')
@allowed(['M10', 'M20', 'M30', 'M40', 'M50', 'M60', 'M80'])
param clusterTier string = 'M30'

@description('Tags to apply to the resources')
param tags object = {}

// Azure DocumentDB for MongoDB vCore cluster
resource documentdbCluster 'Microsoft.DocumentDB/mongoClusters@2024-07-01' = {
  name: clusterName
  location: location
  tags: tags
  properties: {
    administrator: {
      userName: adminUsername
      password: adminPassword
    }
    compute: {
      tier: clusterTier
    }
    storage: {
      sizeGb: 32
    }
    sharding: {
      shardCount: 1
    }
    highAvailability: {
      targetMode: 'Disabled'
    }
    serverVersion: '7.0'
  }
}

// Firewall rule to allow Azure services
resource firewallRuleAllowAzure 'Microsoft.DocumentDB/mongoClusters/firewallRules@2024-07-01' = {
  parent: documentdbCluster
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall rule to allow all IPs (for development only - restrict in production)
resource firewallRuleAllowAll 'Microsoft.DocumentDB/mongoClusters/firewallRules@2024-07-01' = {
  parent: documentdbCluster
  name: 'AllowAllForDev'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

output clusterName string = documentdbCluster.name
output connectionString string = documentdbCluster.properties.connectionString
