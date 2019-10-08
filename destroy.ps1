# Note: if using in Azure Automation it requires the AzureRm.Network module
# To Add, go to the modules blade and click Browse Gallery, then choose AzureRm.Network

param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $gatewayName, 
 
 [Parameter(Mandatory=$True)]
 [string]
 $gatewayName2, 
 
 [Parameter(Mandatory=$True)]
 [string]
 $gatewayConnectionName, 
 
 [Parameter(Mandatory=$True)]
 [string]
 $gatewayConnectionName2
)

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# remove the connections first
$resourceName = $gatewayConnectionName
$resource = Get-AzureRmVirtualNetworkGatewayConnection -Name $resourceName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if(!$resource)
{
    Write-Output "VNet Gateway Connection $resourceName not found";
}
else{
    Write-Output "Deleting Gateway Connection $resourceName ...";
	$resource | Remove-AzureRmVirtualNetworkGatewayConnection -Force
}

$resourceName = $gatewayConnectionName2
$resource = Get-AzureRmVirtualNetworkGatewayConnection -Name $resourceName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if(!$resource)
{
    Write-Output "VNet Gateway Connection $resourceName not found";
}
else{
    Write-Output "Deleting Gateway Connection $resourceName ...";
	$resource | Remove-AzureRmVirtualNetworkGatewayConnection -Force
}

# now remove the Gateways
$resourceName = $gatewayName
$resource = Get-AzureRmVirtualNetworkGateway -Name $resourceName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if(!$resource)
{
    Write-Output "VNet Gateway $resourceName not found";
}
else{
    Write-Output "Deleting Gateway $resourceName ...";
	$resource | Remove-AzureRmVirtualNetworkGateway -Force
}

$resourceName = $gatewayName2
$resource = Get-AzureRmVirtualNetworkGateway -Name $resourceName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if(!$resource)
{
    Write-Output "VNet Gateway $resourceName not found";
}
else{
    Write-Output "Deleting Gateway $resourceName ...";
	$resource | Remove-AzureRmVirtualNetworkGateway -Force
}
