# Start and Stop VNet Gateways with CI/CD

This sample shows how to use the Azure Powershell modules to create and destroy a pair of VNet gatweways that perform VNet-VNet (Site to Site) VPN. 

This code can be run on a schedule in Azure Automation. By using Azure DevOps the schedule and runbook scripts can be automatically updated in an Automation Account on every check-in. 

![Process Diagram](https://github.com/ssemyan/VnetGatewayStartStopCiCd/raw/master/ProcessDiagram.png)

This project shows how the above can be accomplished. 

*Update: Jenkins Implementation added - [see below](#jenkins-implementation)*

Prereqs: 

The following should be set up ahead of time.

1. Azure DevOps project with a Service Connection that gives contribute access to an Azure Automation account.
1. Azure Automation Account with a RunAs Service Principal that has contribute access to the Resource Group where the VNet Gateways will be deployed.
1. The Azure Automation Account needs the AzureRm.Network module installed. To add it, go to the modules blade for the account, click 'Browse Gallery', then choose AzureRm.Network
1. A Resource Group with the following resources:
   1. 2 static Public IP Addressss (one for each Gateway)
   1. 2 VNets to be joined via the Site-to-Site VPN
   1. A KeyVault to hold the connection shared key. The RunAs Service Principal should be given read access to the secrets and the account needs to have the **Azure Resource Manager for template deployment** setting enabled.
   1. An Azure Storage account with a private container to hold the json files. 

To run the project, fill in your own variables in the **parameters.json** and **azure-pipelines.yml** files, and check into an Azure DevOps repo. 

This project consists of the following: 

**template.json**, **parameters.json** (in the VNetGatewayJson directory)
These files are the ARM template and parameter files that describe the two VNet Gateways that are created. **parameters.json** should be edited to include the names of the resources created in the prereq steps above. 

**deploy.ps1** 
This file is the Powershell script that creates the two VNet Gateways. The values used in the script are passed in from the parameters included in the job schedule(see below). Note that it first logs into Azure using the RunAs account.

```
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
```

**destroy.ps1** 
This is the Powershell script that will delete the connections between the two VNets and then deletes the VNet Gateways. As with the deploy script, the parameters are passed in via the schedule. 

**azure-pipelines.yml**
This is the Azure DevOps Pipeline that runs on every check-in into the master branch. It performs the following tasks (mostly by running Powershell scripts included in the project):

1. Copies the .json files into the Azure Storage Account container specified. Note: the script will create a SAS token to access this directory that is good for 1 year.
1. Updates the code for the deploy and delete runbooks (based on deploy.ps1 and destroy.ps1)
1. Updates the schedules.
1. Associates the schedules with the runbooks.

**updateRunbook.ps1** 
Copies the indicated Powershell script into the automation account as a runbook. It will update the runbook if it already exists.

**updateSchedule.ps1**
Creates or updates a schedule based on the input parameters. 

**updateRunbookSchedule.ps1**
Associates a runbook with a schedule. New jobs will be created on the scheduled times for the runbook. 

## Jenkins Implementation

This directory also contains a Jenkinsfile that does the same work as the Azure Devops Pipeline. The Jenkins version uses the [Azure Cross-platform CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest)

The process is mostly the same as the pipeline with a few differences:

1. There is currently no commands for Azure Automation using the Azure CLI so instead I use the REST interfaces with Curl, and using a Bearer token obtained using the CLI. 
1. I copy the **deploy.ps1** and **destroy.ps1** along with the .json files into the Azure Storage Account so that I can reference them in the REST calls that create the runbooks.
1. As there is no elegant way to update Runbook Scheduled Jobs, I delete the runbook first (which also deletes the scheduled job) and then create the runbook from scratch. This might be problematic if there is a job currently running. 

The Jenkinsfile requires the following to be installed:

1. Azure CLI
1. Credentials Binding Plugin
1. Git Plugin
1. Pipeline Plugin
1. Pipeline Utility Steps Plugin

To run, the Jenkinsfile needs the following credentials:

1. sp_pass - Service Principal Password
1. sp_user - Service Principal User Id
1. sp_tenant - Service Principal Tenant
