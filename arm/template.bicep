@description('The name of the Managed Cluster resource.')
param resourceName string

@description('The location of AKS resource.')
param location string

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@minValue(0)
@maxValue(1023)
@description('Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
param osDiskSizeGB int = 0

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.7.7'

@allowed([
  'azure'
  'kubenet'
])
@description('Network plugin used for building Kubernetes network.')
param networkPlugin string

@description('Boolean flag to turn on and off of RBAC.')
param enableRBAC bool = true

@description('Boolean flag to turn on and off of virtual machine scale sets')
param vmssNodePool bool = false

@description('Boolean flag to turn on and off of virtual machine scale sets')
param windowsProfile bool = false

@description('Enable private network access to the Kubernetes cluster.')
param enablePrivateCluster bool = false

@description('Boolean flag to turn on and off http application routing.')
param enableHttpApplicationRouting bool = true

@description('Boolean flag to turn on and off Azure Policy addon.')
param enableAzurePolicy bool = false

@description('Boolean flag to turn on and off omsagent addon.')
param enableOmsAgent bool = true

@description('Specify the region for your OMS workspace.')
param workspaceRegion string = 'East US'

@description('Specify the name of the OMS workspace.')
param workspaceName string

@description('Specify the resource id of the OMS workspace.')
param omsWorkspaceId string

@allowed([
  'free'
  'standalone'
  'pernode'
])
@description('Select the SKU for your workspace.')
param omsSku string = 'standalone'

@description('Specify the name of the Azure Container Registry.')
param acrName string

@description('The name of the resource group the container registry is associated with.')
param acrResourceGroup string

@description('The unique id used in the role assignment of the kubernetes service to the container registry service. It is recommended to use the default value.')
param guidValue string = newGuid()

@description('Resource ID of virtual network subnet used for nodes and/or pods IP assignment.')
param vnetSubnetID string

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param serviceCidr string

@description('Containers DNS server IP address.')
param dnsServiceIP string

@description('A CIDR notation IP for Docker bridge.')
param dockerBridgeCidr string

resource resourceName_resource 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  location: location
  name: resourceName
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: 3
        enableAutoScaling: false
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        storageProfile: 'ManagedDisks'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        vnetSubnetID: vnetSubnetID
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: networkPlugin
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      dockerBridgeCidr: dockerBridgeCidr
    }
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: enableHttpApplicationRouting
      }
      azurepolicy: {
        enabled: enableAzurePolicy
      }
      omsAgent: {
        enabled: enableOmsAgent
        config: {
          logAnalyticsWorkspaceResourceID: omsWorkspaceId
        }
      }
    }
  }
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    aks_lab_vnet
  ]
}

module SolutionDeployment_20210716154946 './nested_SolutionDeployment_20210716154946.bicep' = {
  name: 'SolutionDeployment-20210716154946'
  scope: resourceGroup(split(omsWorkspaceId, '/')[2], split(omsWorkspaceId, '/')[4])
  params: {
    workspaceRegion: workspaceRegion
    omsWorkspaceId: omsWorkspaceId
  }
  dependsOn: []
}

module ConnectAKStoACR_f5110618_1816_498d_8304_fb76373ee03c './nested_ConnectAKStoACR_f5110618_1816_498d_8304_fb76373ee03c.bicep' = {
  name: 'ConnectAKStoACR-f5110618-1816-498d-8304-fb76373ee03c'
  scope: resourceGroup(acrResourceGroup)
  params: {
    reference_parameters_resourceName_2021_02_01_identityProfile_kubeletidentity_objectId: reference(resourceName, '2021-02-01')
    resourceId_parameters_acrResourceGroup_Microsoft_ContainerRegistry_registries_parameters_acrName: resourceId(acrResourceGroup, 'Microsoft.ContainerRegistry/registries/', acrName)
    acrName: acrName
    guidValue: guidValue
  }
  dependsOn: [
    resourceName_resource
    AcrDeployment_f5110618_1816_498d_8304_fb76373ee03d
  ]
}

module AcrDeployment_f5110618_1816_498d_8304_fb76373ee03d './nested_AcrDeployment_f5110618_1816_498d_8304_fb76373ee03d.bicep' = {
  name: 'AcrDeployment-f5110618-1816-498d-8304-fb76373ee03d'
  scope: resourceGroup('98bc5d13-2aa1-45cb-bf49-45aa47e220bf', 'aks-lab')
  params: {}
}

module ClusterMonitoringMetricPulisherRoleAssignmentDepl_20210716154946 './nested_ClusterMonitoringMetricPulisherRoleAssignmentDepl_20210716154946.bicep' = {
  name: 'ClusterMonitoringMetricPulisherRoleAssignmentDepl-20210716154946'
  scope: resourceGroup('98bc5d13-2aa1-45cb-bf49-45aa47e220bf', 'aks-lab')
  params: {
    reference_parameters_resourceName_addonProfiles_omsAgent_identity_objectId: resourceName_resource.properties
  }
  dependsOn: [
    '/subscriptions/98bc5d13-2aa1-45cb-bf49-45aa47e220bf/resourceGroups/aks-lab/providers/Microsoft.ContainerService/managedClusters/akslab'
  ]
}

resource aks_lab_vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'aks-lab-vnet'
  location: 'westeurope'
  properties: {
    subnets: [
      {
        name: 'default'
        id: '/subscriptions/98bc5d13-2aa1-45cb-bf49-45aa47e220bf/resourceGroups/aks-lab/providers/Microsoft.Network/virtualNetworks/aks-lab-vnet/subnets/default'
        properties: {
          addressPrefix: '10.240.0.0/16'
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
  }
  tags: {}
}

module ClusterSubnetRoleAssignmentDeployment_20210716154946 './nested_ClusterSubnetRoleAssignmentDeployment_20210716154946.bicep' = {
  name: 'ClusterSubnetRoleAssignmentDeployment-20210716154946'
  scope: resourceGroup('98bc5d13-2aa1-45cb-bf49-45aa47e220bf', 'aks-lab')
  params: {
    reference_parameters_resourceName_2021_02_01_Full_identity_principalId: reference(resourceName, '2021-02-01', 'Full')
  }
  dependsOn: [
    aks_lab_vnet
  ]
}

output controlPlaneFQDN string = resourceName_resource.properties.fqdn