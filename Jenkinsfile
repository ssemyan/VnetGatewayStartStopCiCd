timestamps {

node () {

	// Variables
	storageAccount = 'MyStorageAccount'
	containerName = 'vnetgatewayautomationassets'
	resourceGroup = 'MyResourceGroup'
	automationAccount = 'MyAutomationAccount'
	deployRunbookName = 'CreateVnetGateways'
	destroyRunbookName = 'DeleteVnetGateways'
	deployScheduleName = '0600Weekdays'
	deployScheduleTimeGMT = 20:20:00'
	destroyScheduleName = '1800Weeknights'
	destroyScheduleTimeGMT = '01:00:00'
	
	// The following values are retrieved from the json file later
	gateway1 = ''
	gatewayConnection1 = ''
	gateway2 = ''
	gatewayConnection2 = ''
	deployLocation = ""
	
	// These values are set later
	deployUriBase = ""
	deployJsonUriSasToken = ""

	// End date for schedule hardcoded to next year - would be better to create dynamically 
	endDate = '2020-10-17T00:03Z'

	stage ('Clean before build') {
		sh "rm -rf *"
	}
	
	stage ('Checkout') {
		checkout scm
	}

	stage ('Azure CLI Login') {
		withCredentials([string(credentialsId: 'ServicePrincipalPass', variable: 'sp_pass'), string(credentialsId: 'ServicePrincipalUserId', variable: 'sp_user'), string(credentialsId: 'ServicePrincipalTenant', variable: 'sp_tenant')]) {
		    sh """ 
			az login --service-principal -u $sp_user -p $sp_pass --tenant $sp_tenant
	            """ 
		}
	}

	stage ('Set params from json and CLI') {
		
		// Read in props from parameters file
		def params = readJSON file: 'VNetGatewayJson/parameters.json'
		gateway1 = params.parameters.gatewayName.value
		gatewayConnection1 = params.parameters.gatewayConnectionName.value
		gateway2 = params.parameters.gatewayName2.value
		gatewayConnection2 = params.parameters.gatewayConnectionName2.value

		def rgJson = sh(script: "az group show -n $resourceGroup", returnStdout: true)
		def rg = readJSON text: rgJson
		deployLocation = rg.location
	}

	stage ('Upload JSON and .ps1 files to Blob Storage and get SAS Token') {
		
		sh(script: "az storage blob upload-batch -d $containerName -s VNetGatewayJson --pattern '*.json' --account-name $storageAccount")
		sh(script: "az storage blob upload -c $containerName -f 'deploy.ps1' -n 'deploy.ps1' --account-name $storageAccount")
		sh(script: "az storage blob upload -c $containerName -f 'destroy.ps1' -n 'destroy.ps1' --account-name $storageAccount")
		deployJsonUriSasToken = sh(script: "az storage container generate-sas --account-name $storageAccount -n $containerName --permissions r --expiry $endDate --https-only -o tsv", returnStdout: true)
		deployUriBase = "https://${storageAccount}.blob.core.windows.net/${containerName}/"
	}

	stage ('Update Runbooks, Schedules, and Job Schedules using the REST API') {
		
		// Get access token
		def tokenJson = sh(script: "az account get-access-token", returnStdout: true)
		def token = readJSON text: tokenJson
		def deployJobScheduleId = UUID.randomUUID().toString()
		def destroyJobScheduleId = UUID.randomUUID().toString()

		sh """ 
		        # delete the deploy runbook (if it exists otherwise just fails)
			curl --request DELETE -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/runbooks/${deployRunbookName}?api-version=2015-10-31
			
			# create request json for deploy runbook
			echo '{"properties": {"logVerbose": false,"logProgress": true,"runbookType": "PowerShellWorkflow","publishContentLink": {"uri": "${deployUriBase}deploy.ps1?${deployJsonUriSasToken}"},' > payload.json
			echo '"description": "Description of the Runbook","logActivityTrace": 1}, "name": "${deployRunbookName}", "location": "${deployLocation}" }' >> payload.json

			curl --request PUT --data @payload.json --fail -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/runbooks/${deployRunbookName}?api-version=2015-10-31
			
		        # delete the deploy runbook (if it exists otherwise just fails)
			curl --request DELETE -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/runbooks/${destroyRunbookName}?api-version=2015-10-31

			# create request json for destroy runbook
			echo '{"properties": {"logVerbose": false,"logProgress": true,"runbookType": "PowerShellWorkflow","publishContentLink": {"uri": "${deployUriBase}destroy.ps1?${deployJsonUriSasToken}"},' > payload2.json
			echo '"description": "Description of the Runbook","logActivityTrace": 1}, "name": "${destroyRunbookName}", "location": "${deployLocation}" }' >> payload2.json

			curl --request PUT --data @payload2.json --fail -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/runbooks/${destroyRunbookName}?api-version=2015-10-31

		        # create request json for deploy schedule
			echo '{"name": "${deployScheduleName}", "properties": { "startTime": "${deployScheduleTimeGMT}","expiryTime": "9999-12-31T23:59:00+00:00","interval": 1,"frequency": "Week","advancedSchedule": {"monthDays": null,"monthlyOccurrences": null,"weekDays": ["Monday","Tuesday","Wednesday","Thursday","Friday"]}}}' > payload3.json

			curl --request PUT --data @payload3.json --fail -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/schedules/${deployScheduleName}?api-version=2015-10-31

		        # create request json for destroy schedule
			echo '{"name": "${destroyScheduleName}", "properties": { "startTime": "${destroyScheduleTimeGMT}","expiryTime": "9999-12-31T23:59:00+00:00","interval": 1,"frequency": "Week","advancedSchedule": {"monthDays": null,"monthlyOccurrences": null,"weekDays": ["Monday","Tuesday","Wednesday","Thursday","Friday"]}}}' > payload4.json

			curl --request PUT --data @payload4.json --fail -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/schedules/${destroyScheduleName}?api-version=2015-10-31

			# create request json for deploy scheduled job
			echo '{ "properties": { "runbook": { "name": "${deployRunbookName}" }, "schedule": { "name": "${deployScheduleName}" }, "parameters": { "RESOURCEGROUPNAME": "${resourceGroup}", "templateFileUri": "${deployUriBase}template.json?${deployJsonUriSasToken}", "parametersFileUri": "${deployUriBase}parameters.json?${deployJsonUriSasToken}" } }}' > payload5.json

			curl --request PUT --data @payload5.json --fail -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/jobSchedules/${deployJobScheduleId}?api-version=2015-10-31

			# create request json for destroy scheduled job
			echo '{ "properties": { "runbook": { "name": "${destroyRunbookName}" }, "schedule": { "name": "${destroyScheduleName}" }, "parameters": { "RESOURCEGROUPNAME": "${resourceGroup}", "GATEWAYCONNECTIONNAME": "${gatewayConnection1}", "GATEWAYCONNECTIONNAME2": "${gatewayConnection2}", "GATEWAYNAME": "${gateway1}", "GATEWAYNAME2": "${gateway2}"} }}' > payload6.json

			curl --request PUT --data @payload6.json --fail -H "Content-Type: application/json" --header 'Authorization: Bearer ${token.accessToken}' https://management.azure.com/subscriptions/${token.subscription}/resourceGroups/${resourceGroup}/providers/Microsoft.Automation/automationAccounts/${automationAccount}/jobSchedules/${destroyJobScheduleId}?api-version=2015-10-31
		""" 
	}

	stage ('Azure CLI Logout') {
		sh """ 
		        az logout
		""" 
	}
}
    
}
