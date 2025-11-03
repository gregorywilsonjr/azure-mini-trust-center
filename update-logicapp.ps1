# Get resource group from parameter or use default
param(
    [string]$resourceGroup = "rg-trustcenter-demo"
)

Write-Host "Getting deployment information..." -ForegroundColor Cyan

# Get values dynamically from deployment
$logicAppName = (az deployment group show -g $resourceGroup -n main --query properties.outputs.logicAppName.value -o tsv)
$subscriptionId = (az account show --query id -o tsv)
$storageAccountName = (az deployment group show -g $resourceGroup -n main --query properties.outputs.storageAccountName.value -o tsv)
$appInsightsName = (az deployment group show -g $resourceGroup -n main --query properties.outputs.appInsightsName.value -o tsv)
$location = (az group show -n $resourceGroup --query location -o tsv)

# Get blob connection name (assumes naming pattern from Bicep)
$blobConnectionName = "blob-" + $storageAccountName.Substring(2, 10)
$blobConnectionId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/connections/$blobConnectionName"

if ([string]::IsNullOrEmpty($logicAppName)) {
    Write-Host "❌ Could not get Logic App name from deployment" -ForegroundColor Red
    Write-Host "   Make sure the infrastructure is deployed first" -ForegroundColor Yellow
    exit 1
}

Write-Host "Logic App: $logicAppName" -ForegroundColor Gray
Write-Host "Storage Account: $storageAccountName" -ForegroundColor Gray
Write-Host "Location: $location" -ForegroundColor Gray
Write-Host ""
Write-Host "Updating Logic App to use real data..." -ForegroundColor Cyan

# Read the workflow definition
$workflowJson = Get-Content "automation/logicapp_writer_real_data.json" -Raw | ConvertFrom-Json

# Create the complete Logic App resource with parameters
$logicAppResource = @{
    location = $location
    properties = @{
        state = "Enabled"
        definition = $workflowJson
        parameters = @{
            '$connections' = @{
                value = @{
                    azureblob = @{
                        connectionId = $blobConnectionId
                        connectionName = $blobConnectionName
                        id = "/subscriptions/$subscriptionId/providers/Microsoft.Web/locations/$location/managedApis/azureblob"
                    }
                }
            }
            subscriptionId = @{
                value = $subscriptionId
            }
            resourceGroupName = @{
                value = $resourceGroup
            }
            storageAccountName = @{
                value = $storageAccountName
            }
            appInsightsName = @{
                value = $appInsightsName
            }
        }
    }
}

# Convert to JSON
$logicAppJson = $logicAppResource | ConvertTo-Json -Depth 20

# Save to temp file
$tempFile = "temp-logicapp-update.json"
$logicAppJson | Out-File -FilePath $tempFile -Encoding utf8

Write-Host "Deploying updated Logic App workflow..." -ForegroundColor Yellow

# Update the Logic App
az resource update `
    --resource-group $resourceGroup `
    --resource-type Microsoft.Logic/workflows `
    --name $logicAppName `
    --properties "@$tempFile"

# Clean up temp file
Remove-Item $tempFile

Write-Host ""
Write-Host "✅ Logic App updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Triggering a manual run to test..." -ForegroundColor Yellow

# Trigger a run
az rest --method post --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Logic/workflows/$logicAppName/triggers/Every_15_Minutes/run?api-version=2016-06-01"

Write-Host ""
Write-Host "✅ Manual run triggered!" -ForegroundColor Green
Write-Host ""

# Get dashboard URL
$dashboardUrl = (az deployment group show -g $resourceGroup -n main --query properties.outputs.staticWebsiteUrl.value -o tsv)

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 2-3 minutes for the workflow to complete" -ForegroundColor Gray
Write-Host "  2. Check run history in Azure Portal" -ForegroundColor Gray
Write-Host "  3. Refresh dashboard: $dashboardUrl" -ForegroundColor Gray
Write-Host ""
