# Architecture Overview

This document provides a detailed overview of the Azure Mini Trust Center architecture.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet Users                          │
│                     (Customers/Stakeholders)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Storage Account                        │
│                  (Static Website Hosting)                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  $web Container                                          │  │
│  │  ├── index.html (Dashboard)                              │  │
│  │  ├── data/                                               │  │
│  │  │   ├── uptime.json                                     │  │
│  │  │   ├── security.json                                   │  │
│  │  │   ├── policy.json                                     │  │
│  │  │   ├── changes.json                                    │  │
│  │  │   └── tenable.json                                    │  │
│  │  └── evidence/                                           │  │
│  │      ├── Pentest_Summary_Redacted.pdf                    │  │
│  │      └── Policy_Snapshot_Redacted.pdf                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Updated every 15 minutes
                             │
┌────────────────────────────┴────────────────────────────────────┐
│                         Logic App                               │
│                  (Consumption Plan)                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Trigger: Recurrence (Every 15 minutes)                  │  │
│  │                                                           │  │
│  │  Actions:                                                │  │
│  │  1. Get Availability Tests (HTTP → App Insights)         │  │
│  │  2. Get Secure Score (HTTP → Defender for Cloud)         │  │
│  │  3. Get Security Assessments (HTTP → Defender)           │  │
│  │  4. Get Policy States (HTTP → Azure Policy)              │  │
│  │  5. Get Activity Log (HTTP → Azure Monitor)              │  │
│  │  6. Parse & Compose Data                                 │  │
│  │  7. Put JSON files to Blob Storage                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Authentication: Managed Identity (System-assigned)             │
│  RBAC Roles:                                                    │
│  - Reader (Subscription)                                        │
│  - Security Reader (Subscription)                               │
│  - Monitoring Reader (Subscription)                             │
│  - Storage Blob Data Contributor (Storage Account)              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Queries Azure APIs
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Management APIs                      │
│  ┌──────────────────┬──────────────────┬──────────────────┐    │
│  │ App Insights     │ Defender for     │ Azure Policy     │    │
│  │ Availability     │ Cloud            │ Compliance       │    │
│  │ Tests            │ Secure Score     │ State            │    │
│  └──────────────────┴──────────────────┴──────────────────┘    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Activity Log (Recent Changes)                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Azure Function App                           │
│                  (Node.js, Consumption)                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  /api/health                                             │  │
│  │  Returns: { status: "healthy", timestamp: "..." }        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Purpose: Health check endpoint for availability monitoring     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Monitored by
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Application Insights                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Availability Test                                       │  │
│  │  - Frequency: Every 5 minutes                            │  │
│  │  - Locations: 5 global test locations                    │  │
│  │  - Target: /api/health endpoint                          │  │
│  │  - Alerts: Configured for failures                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Static Website (Azure Storage)

**Purpose**: Host the customer-facing dashboard

**Technology**: HTML5, CSS3, JavaScript (Vanilla)

**Features**:
- Single-page application
- Responsive design (mobile-friendly)
- Client-side data fetching
- Real-time metric display
- Evidence document links

**Files**:
- `index.html` - Main dashboard
- `data/*.json` - Metric data files
- `evidence/*.pdf` - Compliance documents

**Configuration**:
- Static website enabled
- HTTPS only
- Public read access on $web container
- Index document: index.html
- Error document: index.html

### 2. Logic App (Data Collection)

**Purpose**: Automated data collection from Azure APIs

**Trigger**: Recurrence (every 15 minutes)

**Authentication**: Managed Identity (System-assigned)

**Workflow**:
1. **Parallel API Calls** (5 HTTP actions):
   - Application Insights availability results
   - Defender for Cloud Secure Score
   - Defender for Cloud security assessments
   - Azure Policy compliance summary
   - Activity Log recent changes

2. **Parse JSON** (5 parse actions):
   - Extract relevant data from API responses

3. **Compose Data** (4 compose actions):
   - Transform API data into dashboard format
   - Calculate metrics and aggregations
   - Format timestamps

4. **Write to Blob** (4 put actions):
   - Upload JSON files to $web container
   - Overwrite existing files

**Error Handling**:
- Retry policy on HTTP actions
- Continue on failure for non-critical actions
- Logging to Application Insights

### 3. Azure Function (Health Check)

**Purpose**: Provide health check endpoint for monitoring

**Runtime**: Node.js 18

**Hosting Plan**: Consumption (serverless)

**Endpoint**: `/api/health`

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-22T12:00:00Z"
}
```

**Configuration**:
- HTTPS only
- CORS enabled for dashboard domain
- Application Insights integration
- Managed Identity enabled

### 4. Application Insights

**Purpose**: Monitoring and availability testing

**Features**:
- Availability test (5-minute intervals)
- Function App telemetry
- Logic App diagnostics
- Custom metrics and logs

**Availability Test**:
- Test locations: 5 global regions
- Frequency: Every 5 minutes
- Success criteria: HTTP 200 response
- Alert on failures

### 5. API Connection (Azure Blob)

**Purpose**: Logic App connection to Storage Account

**Authentication**: Storage account key (managed by Azure)

**Permissions**: Read/Write access to $web container

**Usage**: Logic App uses this connection to write JSON files

## Data Flow

### Real-Time Data Collection

```
Every 15 minutes:
1. Logic App trigger fires
2. Parallel HTTP calls to Azure APIs
3. Parse JSON responses
4. Compose dashboard data
5. Write JSON files to blob storage
6. Dashboard auto-refreshes (client-side polling)
```

### Dashboard Loading

```
User visits dashboard:
1. Browser loads index.html from blob storage
2. JavaScript fetches data/*.json files
3. Parse JSON and render cards
4. Display metrics with OK/Attention badges
5. Provide links to evidence documents
```

### Health Monitoring

```
Every 5 minutes:
1. App Insights availability test runs
2. HTTP GET to /api/health endpoint
3. Function returns health status
4. Test result recorded
5. Alert triggered if failure
```

## Security Architecture

### Authentication & Authorization

**Managed Identity**:
- System-assigned identity for Logic App
- No credentials in code or configuration
- Automatic token management by Azure

**RBAC Roles**:
- Reader: Read Azure resources
- Security Reader: Read security data
- Monitoring Reader: Read monitoring data
- Storage Blob Data Contributor: Write to blob storage

### Network Security

**HTTPS Only**:
- All resources configured for TLS 1.2+
- HTTP automatically redirects to HTTPS
- No unencrypted traffic

**Public Access**:
- Static website: Public read (required for dashboard)
- Function App: Public HTTPS endpoint
- Logic App: Internal only (no public endpoint)

**Data Protection**:
- Data at rest: Encrypted by Azure Storage
- Data in transit: TLS 1.2+
- No sensitive data in JSON files (aggregated metrics only)

## Scalability

**Current Design**:
- Serverless architecture (auto-scaling)
- Consumption plans (pay-per-use)
- No always-on resources
- Minimal resource requirements

**Scaling Considerations**:
- Static website: Handles high traffic (CDN-backed)
- Function App: Auto-scales based on requests
- Logic App: Single instance (sufficient for 15-min intervals)
- Storage: Virtually unlimited capacity

## Cost Optimization

**Consumption-Based Pricing**:
- Storage: ~$0.50/month (minimal data)
- Function App: ~$0-5/month (low traffic)
- Logic App: ~$0-2/month (96 runs/day)
- Application Insights: ~$0-5/month (basic monitoring)

**Total: $1.50 - $15/month** (typically under $5)

**Cost Reduction Tips**:
- Increase Logic App interval (30 min instead of 15)
- Reduce availability test frequency
- Use Application Insights sampling
- Archive old logs regularly

## Monitoring & Observability

**Application Insights**:
- Function App execution logs
- Logic App run history
- Availability test results
- Custom metrics and events

**Azure Monitor**:
- Resource health status
- Activity log (deployment changes)
- Metrics (storage usage, function executions)

**Alerting**:
- Availability test failures
- Logic App run failures
- Function App errors
- Storage account issues

## Disaster Recovery

**Backup Strategy**:
- Infrastructure: Bicep templates in source control
- Configuration: Documented in deployment guides
- Data: JSON files regenerated every 15 minutes
- Evidence: PDFs stored in source control

**Recovery Procedures**:
1. Redeploy infrastructure from Bicep
2. Run deployment scripts
3. Logic App regenerates data files
4. Dashboard operational within 15 minutes

**RTO/RPO**:
- Recovery Time Objective: < 1 hour
- Recovery Point Objective: 15 minutes (data refresh interval)

## Future Enhancements

**Planned Improvements**:
- Multi-subscription support
- Historical data retention
- Trend analysis and charts
- Email/Teams notifications
- Custom branding configuration
- Export to PDF functionality
- Additional compliance frameworks

---

For implementation details, see the source code and deployment guides.
