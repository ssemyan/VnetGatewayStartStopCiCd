# Creates or Updates a schedule in an azure automation account
# the -Force will update an existing runbook

param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,

 [Parameter(Mandatory=$True)]
 [string]
 $automationAccountName,

 [Parameter(Mandatory=$True)]
 [string]
 $scheduleName,

 [Parameter(Mandatory=$True)]
 [string]
 $runbookName,

 [Parameter(Mandatory=$True)]
 [hashtable]
 $runbookParams
)

$ErrorActionPreference = "Stop"

# Verify version of Azure PowerShell
$az = Get-Command Get-AzResource -ErrorAction SilentlyContinue
if($az)
{
	Write-Output "Found new version of Azure PowerShell - Enabling Alias"
	Enable-AzureRmAlias
}

# Remove schedule if it already exists
$currSched = Get-AzureRmAutomationScheduledRunbook -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -RunbookName $runbookName -ScheduleName $scheduleName -ErrorAction SilentlyContinue
if($currSched)
{
	Write-Output "Removing existing schedule $scheduleName from runbook $runbookName"
	Unregister-AzureRmAutomationScheduledRunbook -AutomationAccountName $automationAccountName -ResourceGroupName $resourceGroupName -RunbookName $runbookName -ScheduleName $scheduleName -Force
}

Write-Output "Setting schedule $scheduleName for runbook $runbookName ..."
Register-AzureRmAutomationScheduledRunbook -AutomationAccountName $automationAccountName -Name $runbookName -ScheduleName $scheduleName -ResourceGroupName $resourceGroupName -Parameters $runbookParams
