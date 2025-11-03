# Get resource group from parameter or use default
param(
    [string]$resourceGroup = "rg-trustcenter-demo"
)

# Get storage account name dynamically from deployment
$storageAccount = (az deployment group show -g $resourceGroup -n main --query properties.outputs.storageAccountName.value -o tsv)

if ([string]::IsNullOrEmpty($storageAccount)) {
    Write-Host "❌ Could not get storage account name from deployment" -ForegroundColor Red
    Write-Host "   Make sure the infrastructure is deployed first" -ForegroundColor Yellow
    exit 1
}

$container = "`$web"

Write-Host "Uploading web files to $storageAccount/$container..." -ForegroundColor Cyan

az storage blob upload-batch `
    --destination $container `
    --source ./web `
    --account-name $storageAccount `
    --auth-mode key `
    --overwrite

Write-Host ""
Write-Host "✅ Upload complete!" -ForegroundColor Green

# Get and display dashboard URL
$dashboardUrl = (az deployment group show -g $resourceGroup -n main --query properties.outputs.staticWebsiteUrl.value -o tsv)
Write-Host ""
Write-Host "Dashboard URL: $dashboardUrl" -ForegroundColor White
Write-Host ""
