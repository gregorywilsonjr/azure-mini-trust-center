# Get resource group from parameter or use default
param(
    [string]$resourceGroup = "rg-trustcenter-demo"
)

Write-Host "=== Validating Trust Center Setup ===" -ForegroundColor Cyan
Write-Host ""

# Get values dynamically from deployment
Write-Host "Getting deployment information..." -ForegroundColor Yellow
$principalId = (az deployment group show -g $resourceGroup -n main --query properties.outputs.logicAppPrincipalId.value -o tsv)
$logicAppName = (az deployment group show -g $resourceGroup -n main --query properties.outputs.logicAppName.value -o tsv)
$storageAccountName = (az deployment group show -g $resourceGroup -n main --query properties.outputs.storageAccountName.value -o tsv)
$subscriptionId = (az account show --query id -o tsv)

if ([string]::IsNullOrEmpty($principalId)) {
    Write-Host "❌ Could not get deployment information" -ForegroundColor Red
    Write-Host "   Make sure the infrastructure is deployed first" -ForegroundColor Yellow
    exit 1
}

Write-Host "Logic App: $logicAppName" -ForegroundColor Gray
Write-Host "Storage Account: $storageAccountName" -ForegroundColor Gray
Write-Host ""

# Check RBAC roles
Write-Host "1. Checking RBAC Role Assignments..." -ForegroundColor Yellow
$roles = az role assignment list --assignee $principalId --output json | ConvertFrom-Json
if ($roles.Count -gt 0) {
    Write-Host "   ✅ Found $($roles.Count) role assignments:" -ForegroundColor Green
    foreach ($role in $roles) {
        Write-Host "      - $($role.roleDefinitionName)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ No role assignments found" -ForegroundColor Red
}
Write-Host ""

# Check Logic App status
Write-Host "2. Checking Logic App Status..." -ForegroundColor Yellow
$logicApp = az resource show --resource-group $resourceGroup --resource-type Microsoft.Logic/workflows --name $logicAppName --output json | ConvertFrom-Json
Write-Host "   State: $($logicApp.properties.state)" -ForegroundColor $(if ($logicApp.properties.state -eq "Enabled") { "Green" } else { "Red" })
Write-Host ""

# Check recent Logic App runs
Write-Host "3. Checking Logic App Run History..." -ForegroundColor Yellow
$runs = az rest --method get --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Logic/workflows/$logicAppName/runs?api-version=2016-06-01&`$top=5" --output json | ConvertFrom-Json

if ($runs.value.Count -gt 0) {
    Write-Host "   ✅ Found $($runs.value.Count) recent runs:" -ForegroundColor Green
    foreach ($run in $runs.value) {
        $status = $run.properties.status
        $color = switch ($status) {
            "Succeeded" { "Green" }
            "Running" { "Yellow" }
            "Failed" { "Red" }
            default { "Gray" }
        }
        $startTime = [DateTime]::Parse($run.properties.startTime).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "      - $startTime : $status" -ForegroundColor $color
    }
} else {
    Write-Host "   ⚠️  No runs found yet" -ForegroundColor Yellow
}
Write-Host ""

# Check blob storage files
Write-Host "4. Checking Data Files in Blob Storage..." -ForegroundColor Yellow
$blobs = az storage blob list --container-name '$web' --account-name $storageAccountName --prefix data/ --auth-mode login --output json 2>$null | ConvertFrom-Json

if ($blobs.Count -gt 0) {
    Write-Host "   ✅ Found $($blobs.Count) data files:" -ForegroundColor Green
    foreach ($blob in $blobs) {
        $modified = [DateTime]::Parse($blob.properties.lastModified).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "      - $($blob.name) (Modified: $modified)" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ No data files found" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan

# Get dashboard URL
$dashboardUrl = (az deployment group show -g $resourceGroup -n main --query properties.outputs.staticWebsiteUrl.value -o tsv)

Write-Host "Dashboard URL: $dashboardUrl" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  - If Logic App hasn't run yet, wait up to 15 minutes for first run" -ForegroundColor Gray
Write-Host "  - To manually trigger: Go to Azure Portal → Logic App → Run Trigger" -ForegroundColor Gray
Write-Host "  - To enable real data: Update Logic App workflow (see REAL_DATA_SETUP.md)" -ForegroundColor Gray
Write-Host ""
