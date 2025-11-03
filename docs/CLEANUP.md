# Cleanup Guide

This guide explains how to remove all Azure resources created by the Azure Mini Trust Center.

## ⚠️ Warning

Deleting resources is **permanent** and **cannot be undone**. Make sure you:
- Have backed up any important data
- Exported any evidence documents you need
- Documented any custom configurations

## Quick Cleanup (Recommended)

The fastest way to remove all resources is to delete the entire resource group:

### PowerShell

```powershell
# Delete resource group and all resources
az group delete --name rg-trustcenter-demo --yes --no-wait

# Verify deletion (optional)
az group show --name rg-trustcenter-demo
```

### Bash

```bash
# Delete resource group and all resources
az group delete --name rg-trustcenter-demo --yes --no-wait

# Verify deletion (optional)
az group show --name rg-trustcenter-demo
```

**Note**: The `--no-wait` flag returns immediately. Actual deletion takes 5-10 minutes.

## Verify Deletion

Check if the resource group is deleted:

```bash
# Should return "ResourceGroupNotFound" error when deleted
az group show --name rg-trustcenter-demo
```

## Individual Resource Cleanup

If you need to delete resources individually (not recommended):

### 1. Delete Logic App

```bash
az resource delete \
  --resource-group rg-trustcenter-demo \
  --resource-type Microsoft.Logic/workflows \
  --name la-aftershocktrust-writer
```

### 2. Delete Function App

```bash
az functionapp delete \
  --name func-aftershocktrust \
  --resource-group rg-trustcenter-demo
```

### 3. Delete App Service Plan

```bash
az appservice plan delete \
  --name plan-aftershocktrust \
  --resource-group rg-trustcenter-demo \
  --yes
```

### 4. Delete Application Insights

```bash
az monitor app-insights component delete \
  --app appi-aftershocktrust \
  --resource-group rg-trustcenter-demo
```

### 5. Delete Availability Test

```bash
az resource delete \
  --resource-group rg-trustcenter-demo \
  --resource-type Microsoft.Insights/webtests \
  --name avail-aftershocktrust
```

### 6. Delete API Connection

```bash
az resource delete \
  --resource-group rg-trustcenter-demo \
  --resource-type Microsoft.Web/connections \
  --name blob-aftershocktrust
```

### 7. Delete Storage Account

```bash
az storage account delete \
  --name <your-storage-account> \
  --resource-group <your-resource-group> \
  --yes
```

### 8. Delete Role Assignments

```bash
# Get Logic App principal ID
PRINCIPAL_ID="61949914-9bbc-4495-bc9b-2c83744b84f9"

# List and delete role assignments
az role assignment list --assignee $PRINCIPAL_ID --query "[].id" -o tsv | \
  xargs -I {} az role assignment delete --ids {}
```

### 9. Delete Resource Group

```bash
az group delete --name rg-trustcenter-demo --yes
```

## Cost After Deletion

After deletion, you should see:
- ✅ No more charges for storage
- ✅ No more charges for function executions
- ✅ No more charges for Logic App runs
- ✅ No more charges for Application Insights

**Note**: Some charges may appear for a few hours after deletion due to Azure billing cycles.

## Cleanup Verification Checklist

- [ ] Resource group deleted
- [ ] No resources remain in Azure Portal
- [ ] Role assignments removed
- [ ] No ongoing charges in Cost Management
- [ ] Dashboard URL no longer accessible

## Troubleshooting

### Resource Group Won't Delete

**Error**: "Cannot delete resource group because it contains resources"

**Solution**:
1. Check for locks on the resource group
2. Remove any locks: `az lock delete --name <lock-name> --resource-group rg-trustcenter-demo`
3. Try deletion again

### Role Assignments Remain

**Error**: Role assignments still showing after resource group deletion

**Solution**:
```bash
# Manually delete role assignments
az role assignment list --assignee <principal-id> --query "[].id" -o tsv | \
  xargs -I {} az role assignment delete --ids {}
```

### Storage Account Soft Delete

**Note**: Storage accounts have soft delete enabled by default. Deleted accounts can be recovered within 14 days.

**To permanently delete**:
```bash
# List deleted storage accounts
az storage account list --include-deleted

# Permanently delete (if needed)
az storage account delete --name <account-name> --yes
```

## Redeployment

To redeploy after cleanup:

1. Follow the [Quick Start Guide](../README.md#quick-start)
2. Use the same or different resource group name
3. All resources will be recreated fresh

## Data Backup (Before Deletion)

If you want to keep any data before deletion:

### Export Evidence Documents

```bash
# Download PDFs
az storage blob download-batch \
  -d ./backup \
  -s '$web/evidence' \
  --account-name <your-storage-account>
```

### Export Data Files

```bash
# Download JSON data
az storage blob download-batch \
  -d ./backup \
  -s '$web/data' \
  --account-name <your-storage-account>
```

### Export Configuration

```bash
# Export Logic App definition
az logic workflow show \
  --resource-group rg-trustcenter-demo \
  --name la-aftershocktrust-writer \
  > backup/logicapp-definition.json

# Export Function App settings
az functionapp config appsettings list \
  --name func-aftershocktrust \
  --resource-group rg-trustcenter-demo \
  > backup/function-settings.json
```

## Support

If you encounter issues during cleanup:
- Check Azure Portal for resource status
- Review Activity Log for error details
- Open an issue on GitHub
- Contact Azure Support if needed

---

**Remember**: Always verify deletion to avoid unexpected charges!
