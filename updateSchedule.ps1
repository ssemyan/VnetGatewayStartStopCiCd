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
 $startTime
)

$ErrorActionPreference = "Stop"

# Verify version of Azure PowerShell
$az = Get-Command Get-AzResource -ErrorAction SilentlyContinue
if($az)
{
	Write-Output "Found new version of Azure PowerShell - Enabling Alias"
	Enable-AzureRmAlias
}

$startDateTime = $(Get-Date $startTime)
if ($startDateTime -lt (Get-Date).AddMinutes(5))
{
	$startDateTime = $startDateTime.AddDays(1)
}
$timeZone = "UTC"
[System.DayOfWeek[]]$WeekDays = @([System.DayOfWeek]::Monday..[System.DayOfWeek]::Friday)
Write-Output "Setting schedule $scheduleName starting $startDateTime ..."
New-AzureRmAutomationSchedule -AutomationAccountName $automationAccountName -Name $scheduleName -StartTime $startDateTime -WeekInterval 1 -DaysOfWeek $WeekDays -ResourceGroupName $resourceGroupName -TimeZone $timeZone