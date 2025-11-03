# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-22

### Added
- Initial release of Azure Mini Trust Center
- Static website dashboard with responsive design
- Real-time data collection from Azure APIs
- Logic App with managed identity authentication
- Azure Function health check endpoint
- Application Insights availability monitoring
- Sample evidence documents (Pen Test, Policy Snapshot)
- Bicep infrastructure-as-code deployment
- PowerShell deployment scripts
- Comprehensive documentation

### Features
- **Uptime Monitoring**: 24-hour availability tracking from Application Insights
- **Security Posture**: Microsoft Defender Secure Score and recommendations
- **Policy Compliance**: Azure Policy compliance state tracking
- **Recent Changes**: Activity log monitoring with customer-friendly descriptions
- **Vulnerability Tracking**: Optional Tenable.io integration
- **Evidence Documents**: Professional PDF samples for penetration tests and policies

### Security
- Managed Identity for all Azure API access
- RBAC-based permissions (Reader, Security Reader, Monitoring Reader)
- HTTPS-only configuration
- No credentials stored in code or configuration
- TLS 1.2+ enforcement

### Compliance Frameworks
- SOC 2 Type II
- ISO 27001
- PCI DSS v4.0.1
- NIST Cybersecurity Framework
- GDPR
- CCPA

### Documentation
- README.md with quick start guide
- DEPLOYMENT_GUIDE.md with detailed instructions
- REAL_DATA_SETUP.md for configuring live metrics
- DEPLOYMENT_SUCCESS.md post-deployment checklist
- CONTRIBUTING.md for contributors
- LICENSE (MIT)

### Scripts
- `assign-rbac.ps1` - Assign RBAC roles to Logic App
- `update-logicapp.ps1` - Update Logic App with real data workflow
- `upload-web.ps1` - Upload web files to Azure Storage
- `validate-setup.ps1` - Validate deployment status
- `create-evidence-pdfs.ps1` - Generate PDF evidence documents
- `check-logicapp-status.ps1` - Check Logic App run status

### Infrastructure
- Azure Storage Account with static website hosting
- Azure Function App (Node.js 18, Consumption plan)
- Logic App (Consumption plan, 15-minute recurrence)
- Application Insights with availability test
- API Connection for Azure Blob Storage
- Role assignments for managed identity

### Cost Optimization
- Consumption-based pricing for all services
- Estimated cost: $1.50 - $15/month (typically under $5)
- No always-on resources
- Efficient data collection (15-minute intervals)

## [Unreleased]

### Planned
- Azure DevOps CI/CD pipeline
- Multi-subscription support
- Custom branding configuration
- Email alerts for compliance changes
- Historical trend charts
- PDF export functionality
- Additional compliance frameworks
- Mobile-responsive improvements

---

For more details, see the [commit history](https://github.com/YOUR-USERNAME/azure-mini-trust-center/commits/main).
