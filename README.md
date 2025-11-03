# Azure Mini Trust Center

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Azure](https://img.shields.io/badge/Azure-Bicep-0078D4?logo=microsoftazure)](https://azure.microsoft.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A lightweight, serverless trust center dashboard for Azure environments. Display real-time compliance, security, and operational metrics to your customers in a clean, professional interface.

## ✨ Features

### Core Features
- 🎯 **Real-time Metrics**: Live data from Azure APIs (Defender, Policy, Activity Log, App Insights)
- 🔒 **Security Posture**: Microsoft Defender Secure Score and security recommendations
- 📊 **Policy Compliance**: Azure Policy compliance state tracking
- 🔄 **Recent Changes**: Activity log monitoring with customer-friendly descriptions
- 🛡️ **Vulnerability Tracking**: Optional Tenable.io integration
- 📄 **Evidence Documents**: Sample penetration test reports and policy documentation
- 💰 **Cost-Effective**: Serverless architecture (~$5-15/month)
- 🚀 **Easy Deployment**: One-command Bicep deployment with automated setup

### 🆕 Enhanced Features (Production-Ready)
- 📈 **Historical Trends**: 7-day and 30-day trend charts showing compliance improvement over time
- 🌐 **Multi-Subscription Support**: Aggregate compliance data across dev/test/prod subscriptions
- 📋 **Compliance Framework Mapping**: Map Azure policies to SOC 2, ISO 27001, PCI DSS, NIST CSF, GDPR controls
- 🚨 **Proactive Alerting**: Email/Teams notifications when compliance thresholds are exceeded

**See [ENHANCED_FEATURES.md](ENHANCED_FEATURES.md) for detailed documentation on production-ready enhancements.**

## 📸 Screenshot

The dashboard displays:
- **Uptime (24h)**: Availability percentage from Application Insights
- **Security Posture**: Secure Score with high/medium severity recommendations
- **Policy Compliance**: Compliant vs. non-compliant policy assignments
- **Recent Change**: Latest infrastructure change with resource details
- **Vulnerability Summary**: Critical/High/Medium vulnerability counts (Tenable)

Plus links to evidence documents (penetration test summary, security policies).

## 🏗️ Architecture

```
┌─────────────────────────┐
│   Static Website        │ ◄── Customers view dashboard
│   (Azure Storage)       │
└──────────┬──────────────┘
           │
           ├─► data/uptime.json
           ├─► data/security.json
           ├─► data/policy.json
           ├─► data/changes.json
           └─► data/tenable.json
                ▲
                │ Updates every 15 min
                │
      ┌─────────┴──────────────┐
      │     Logic App          │ ◄── Queries Azure APIs
      │  (Managed Identity)    │
      └────────────────────────┘
                │
                ├─► Microsoft Defender for Cloud
                ├─► Azure Policy
                ├─► Activity Log
                └─► Application Insights
```

### Components

| Component | Purpose | Cost |
|-----------|---------|------|
| **Storage Account** | Static website hosting + data files | ~$0.50/month |
| **Azure Function** | Health check endpoint | ~$0-5/month (consumption) |
| **Logic App** | Automated data collection (15 min intervals) | ~$0-2/month (consumption) |
| **Application Insights** | Availability monitoring + logging | ~$0-5/month |
| **Managed Identity** | Secure authentication (no credentials) | Free |
| **🆕 Table Storage** | Historical metrics for trend analysis (30 days) | ~$1-2/month |
| **🆕 Email/Teams Alerts** | Proactive compliance notifications | Free (Office 365) |

**Total: $2.50 - $18/month** (typically $6-10 for demo usage with enhancements)

## 🚀 Quick Start

### Prerequisites

- Azure subscription
- Azure CLI installed ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- Node.js 18+ ([Download](https://nodejs.org/))
- Azure Functions Core Tools ([Install](https://docs.microsoft.com/azure/azure-functions/functions-run-local))

### 1. Clone Repository

```bash
git clone https://github.com/YOUR-USERNAME/azure-mini-trust-center.git
cd azure-mini-trust-center
```

### 2. Deploy Infrastructure

```bash
# Login to Azure
az login

# Create resource group
az group create -n rg-trustcenter-demo -l westus3

# Deploy Bicep template
az deployment group create \
  -g rg-trustcenter-demo \
  -f infra/main.bicep \
  -p siteName=yourcompanyname
```

**Note:** Replace `yourcompanyname` with your organization name (lowercase, no spaces).

### 3. Enable Static Website

```bash
# Get storage account name from deployment output
STORAGE_ACCOUNT=$(az deployment group show -g rg-trustcenter-demo -n main --query properties.outputs.storageAccountName.value -o tsv)

# Enable static website
az storage blob service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --static-website \
  --404-document index.html \
  --index-document index.html
```

### 4. Publish Function App

```bash
cd function/HealthApi
npm install

# Get function app name from deployment
FUNCTION_APP=$(az deployment group show -g rg-trustcenter-demo -n main --query properties.outputs.functionAppName.value -o tsv)

# Publish function
func azure functionapp publish $FUNCTION_APP
```

### 5. Upload Web Files

```bash
cd ../..

# Upload dashboard and data files
az storage blob upload-batch \
  -d '$web' \
  -s web \
  --account-name $STORAGE_ACCOUNT
```

### 6. Assign RBAC Roles (for Real Data)

```bash
# Run the provided script
./assign-rbac.ps1  # Windows
# or
./assign-rbac.sh   # Linux/Mac
```

This assigns the Logic App managed identity:
- Reader
- Security Reader
- Monitoring Reader

### 7. Enable Real Data Collection

```bash
# Update Logic App to use real Azure APIs
./update-logicapp.ps1  # Windows
# or
./update-logicapp.sh   # Linux/Mac
```

### 8. Access Your Dashboard

```bash
# Get dashboard URL
az deployment group show -g rg-trustcenter-demo -n main --query properties.outputs.staticWebsiteUrl.value -o tsv
```

Visit the URL in your browser! 🎉

## 📚 Documentation

- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Detailed deployment instructions
- **[Real Data Setup](REAL_DATA_SETUP.md)** - Configure live Azure metrics
- **[Quick Start Guide](QUICK_START_REAL_DATA.md)** - Fast track to real data
- **[Deployment Success](DEPLOYMENT_SUCCESS.md)** - Post-deployment checklist

## 🔧 Configuration

### Customize Dashboard

Edit `web/index.html` to:
- Change company name and branding
- Modify card layouts and styling
- Add/remove metrics
- Customize thresholds for OK/Attention badges

### Update Evidence Documents

Replace sample PDFs in `web/evidence/`:
- `Pentest_Summary_Redacted.pdf` - Your penetration test report
- `Policy_Snapshot_Redacted.pdf` - Your security policies

Or edit the HTML templates and regenerate:
```bash
./create-evidence-pdfs.ps1  # Windows
```

### Adjust Update Frequency

Edit `infra/main.bicep` and change Logic App recurrence:
```bicep
recurrence: {
  frequency: 'Minute'
  interval: 15  // Change to 30, 60, etc.
}
```

## 🛡️ Security Best Practices

✅ **Use Managed Identity** - No credentials in code or configuration  
✅ **Enable HTTPS Only** - All resources configured for TLS 1.2+  
✅ **Least Privilege RBAC** - Logic App has read-only access  
✅ **No Sensitive Data** - Only aggregated metrics, no resource IDs  
✅ **Regular Updates** - Keep Azure Functions runtime updated  
✅ **Monitor Access** - Review storage account access logs  

## 🧪 Testing

### Local Development

```bash
# Serve static website locally
cd web
python -m http.server 8000
# Visit http://localhost:8000
```

### Validate Deployment

```bash
# Run validation script
./validate-setup.ps1  # Windows
```

Checks:
- RBAC role assignments
- Logic App status
- Recent run history
- Data file accessibility

## 🔄 Updates & Maintenance

### Update Dashboard

```bash
# Make changes to web files
# Then upload
./upload-web.ps1
```

### Update Logic App Workflow

```bash
# Edit automation/logicapp_writer_real_data.json
# Then deploy
./update-logicapp.ps1
```

### Monitor Health

- **Application Insights**: View availability test results
- **Logic App Runs**: Check run history in Azure Portal
- **Function Logs**: Monitor function execution

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Azure serverless services
- Inspired by modern trust center best practices
- Sample compliance frameworks: SOC 2, ISO 27001, PCI DSS v4.0.1, NIST CSF, GDPR, CCPA

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR-USERNAME/azure-mini-trust-center/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR-USERNAME/azure-mini-trust-center/discussions)
- **Documentation**: See `docs/` folder

## 🗺️ Roadmap

### ✅ Completed (Enhanced Features)
- [x] **Historical trend charts** - 7-day and 30-day compliance trends
- [x] **Support for multiple Azure subscriptions** - Aggregate compliance across subscriptions
- [x] **Email/Teams alerts for compliance changes** - Proactive notifications
- [x] **Compliance framework mapping** - SOC 2, ISO 27001, PCI DSS, NIST, GDPR

### 🔜 Planned
- [ ] Add Azure DevOps pipeline for CI/CD
- [ ] Custom branding configuration file
- [ ] Export to PDF functionality
- [ ] Azure Cost Management integration
- [ ] Azure Backup compliance status
- [ ] Drill-down into specific security recommendations

---

**Made with ❤️ by Aftershock Cyber Solutions**

*"Audit-Ready, Every Day."*
