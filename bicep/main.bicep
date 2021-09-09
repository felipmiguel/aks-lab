@description('The name of the Managed Cluster resource.')
param clusterName string = 'aks101cluster'

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@minValue(0)
@maxValue(1023)
@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
param osDiskSizeGB int = 0

@minValue(1)
@maxValue(50)
@description('The number of nodes for the cluster.')
param agentCount int = 3

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_DS2_v2'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string

@description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

@allowed([
  'Linux'
])
@description('The type of operating system.')
param osType string = 'Linux'

@maxValue(3)
@minValue(0)
param zones int = 0

@allowed([
  'azure'
  'kubenet'
])
@description('Network plugin used for building Kubernetes network.')
param networkPlugin string = 'azure'

param serviceCidr string

var azs = [for i in range(1, zones): '${i}']

var dnsPrefix = '${clusterName}-dns'

var vnetName = '${clusterName}-vnet'

var virtualNetworkAddressPrefix = '10.0.0.0/8'
var subnets = [
  {
    name: 'default'
    ipAddressRange: '10.240.0.0/16'
  }
]



var defaultSubnetId = '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/default'

// module network 'modules/network.bicep'={
//   name: 'vnetname'
//   params: {
//     vnetname: vnetName
//     location: location
//     virtualNetworkAddressPrefix: '10.0.0.0/8'
//     subnets: [
//       {
//         name: 'default'
//         ipAddressRange: '10.240.0.0/16'
//       }
//     ]

//   }
// }

var subnetProperties = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.ipAddressRange
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetName
  location: location
  properties: {
    subnets: subnetProperties
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
  }
}


resource podIdentityNamespace1 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'sampleAksPodIdentityNs1'
  location: resourceGroup().location
}

resource managedIdentityOperatorDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing ={
  name: 'Managed Identity Operator'
}

output idopdef object = managedIdentityOperator

var roleAssignmentName = guid(podIdentityNamespace1.id, 'managedidentityoperator')
var roledefid = 'f1a07417-d97a-45cb-824c-7a7467783830'

resource managedIdentityOperator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview'={
  name: roleAssignmentName
  scope: resourceGroup(clusterName_resource.properties.nodeResourceGroup)
  properties:{
    // roleDefinitionId: managedIdentityOperatorDefinition.id
    roleDefinitionId: roledefid
    principalId: podIdentityNamespace1.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource clusterName_resource 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: clusterName
  location: location
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'syspool'
        osDiskSizeGB: 0
        count: 3
        vmSize: agentVMSize
        osType: osType
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        availabilityZones: azs
        // vnetSubnetID: '${network.outputs.vnetId}/subnets/default'
        vnetSubnetID: '${vnet.id}/subnets/default'
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
    networkProfile: {
      // loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
      // serviceCidr: serviceCidr
      // dnsServiceIP: dns
    }
    podIdentityProfile:{
      enabled: true
      userAssignedIdentities: [
        {
          identity: podIdentityNamespace1
          name: 'identity1'
          namespace: 'app1'
        }
      ]

    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output controlPlaneFQDN string = clusterName_resource.properties.fqdn
