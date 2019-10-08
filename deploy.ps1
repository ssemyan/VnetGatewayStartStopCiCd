# To retrieve secrets from the KeyVault be sure to enable the setting "Azure Resource Manager for template deployment" in the access policies blade

param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $templateFileUri,

 [Parameter(Mandatory=$True)]
 [string]
 $parametersFileUri
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

# URIs might get passed in escaped so unescape them first
$templateFileUri = [System.Text.RegularExpressions.Regex]::Unescape($templateFileUri)
$parametersFileUri = [System.Text.RegularExpressions.Regex]::Unescape($parametersFileUri)

# Start the deployment
$deploymentName = "GatewayDeployment_$(get-date -f yyyy_MM_dd_ss)"
Write-Host "Starting deployment $deploymentName ...";
New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateUri $templateFileUri -TemplateParameterUri $parametersFileUri -Verbose;
