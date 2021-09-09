@description('vnet name')
param vnetname string
@description('vnet location')
param location string = resourceGroup().location

@description('The IP address range for all virtual networks to use.')
param virtualNetworkAddressPrefix string = '10.0.0.0/8'

@description('The name and IP address range for each subnet in the virtual networks.')
param subnets array = [
  {
    name: 'default'
    ipAddressRange: '10.240.0.0/16'
  }
]

var subnetProperties = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.ipAddressRange
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: vnetname
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

output subnetIds array = [for subnet in subnetProperties: '${vnet.id}/subnets/${subnet.name}']
output vnetId string = vnet.id

