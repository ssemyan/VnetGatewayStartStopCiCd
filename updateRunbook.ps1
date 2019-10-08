# Uploads a .ps1 file as a runbook into an azure automation account
# the -Force will update an existing runbook

param(
 [Parameter(Mandatory=$True)]
 [string]
 $runbookPath,

 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $automationAccountName,

 [Parameter(Mandatory=$True)]
 [string]
 $runbookName
)

$ErrorActionPreference = "Stop"

# Verify version of Azure PowerShell
$az = Get-Command Get-AzResource -ErrorAction SilentlyContinue
if($az)
{
	Write-Output "Found new version of Azure PowerShell - Enabling Alias"
	Enable-AzureRmAlias
}

 Write-Output "Updating runbook '$runbookName'"
 Import-AzureRmAutomationRunbook -Path $runbookPath -ResourceGroup $resourceGroupName -AutomationAccountName $automationAccountName -Type PowerShell -Name $runbookName -Force -Published