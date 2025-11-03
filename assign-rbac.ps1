# Get resource group from parameter or use default
param(
    [string]$resourceGroup = "rg-trustcenter-demo"
)

Write-Host "Getting deployment information..." -ForegroundColor Cyan

# Get values dynamically from deployment
$principalId = (az deployment group show -g $resourceGroup -n main --query properties.outputs.logicAppPrincipalId.value -o tsv)
$subscriptionId = (az account show --query id -o tsv)

if ([string]::IsNullOrEmpty($principalId)) {
    Write-Host "❌ Could not get Logic App principal ID from deployment" -ForegroundColor Red
    Write-Host "   Make sure the infrastructure is deployed first" -ForegroundColor Yellow
    exit 1
}

Write-Host "Principal ID: $principalId" -ForegroundColor Gray
Write-Host "Subscription: $subscriptionId" -ForegroundColor Gray
Write-Host ""
Write-Host "Assigning RBAC roles to Logic App managed identity..." -ForegroundColor Cyan

# Assign Reader role
Write-Host "Assigning Reader role..."
az role assignment create `
  --assignee $principalId `
  --role "Reader" `
  --scope "/subscriptions/$subscriptionId"

# Assign Security Reader role
Write-Host "Assigning Security Reader role..."
az role assignment create `
  --assignee $principalId `
  --role "Security Reader" `
  --scope "/subscriptions/$subscriptionId"

# Assign Monitoring Reader role
Write-Host "Assigning Monitoring Reader role..."
az role assignment create `
  --assignee $principalId `
  --role "Monitoring Reader" `
  --scope "/subscriptions/$subscriptionId"

Write-Host "RBAC roles assigned successfully!"
