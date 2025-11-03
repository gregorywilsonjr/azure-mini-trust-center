# Repository Structure

Clean, production-ready structure for GitHub publication.

## 📁 Core Files & Folders

```
azure-mini-trust-center/
├── .gitignore                  # Git ignore rules
├── README.md                   # Main project documentation
├── LICENSE                     # MIT License
├── CONTRIBUTING.md             # Contribution guidelines
├── CHANGELOG.md                # Version history
├── netlify.toml               # Netlify deployment config (optional)
│
├── infra/                      # Infrastructure as Code
│   ├── main.bicep             # Main Bicep template
│   └── main.json              # Compiled ARM template
│
├── function/                   # Azure Function App
│   └── HealthApi/             # Health check endpoint
│       ├── index.js
│       ├── function.json
│       ├── package.json
│       └── host.json
│
├── automation/                 # Logic App Workflows
│   ├── logicapp_writer.json                    # Mock data workflow
│   ├── logicapp_writer_real_data.json          # Real Azure API workflow
│   └── logicapp_writer_real_data_enhanced.json # Enhanced workflow
│
├── web/                        # Static Website
│   ├── index.html             # Main dashboard
│   ├── data/                  # JSON data files
│   │   ├── uptime.json
│   │   ├── security.json
│   │   ├── policy.json
│   │   ├── changes.json
│   │   ├── tenable.json
│   │   └── compliance-frameworks.json
│   └── evidence/              # Sample compliance documents
│       ├── Pentest_Summary_Redacted.pdf
│       └── Policy_Snapshot_Redacted.pdf
│
├── tenable/                    # Tenable.io Integration (Optional)
│   ├── tenable_export.py      # Export vulnerability data
│   ├── push_blob.py           # Upload to Azure Storage
│   └── requirements.txt       # Python dependencies
│
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md        # Technical architecture
│   └── CLEANUP.md             # Resource cleanup guide
│
└── Scripts (PowerShell)        # Deployment & Management
    ├── assign-rbac.ps1        # Assign RBAC roles to Logic App
    ├── update-logicapp.ps1    # Update Logic App workflow
    ├── validate-setup.ps1     # Validate deployment
    └── upload-web.ps1         # Upload web files to storage
```

## 🗂️ Xtras Folder (Not in Git)

The `Xtras/` folder contains additional reference materials that are **not needed** for the core functionality:

- GitHub preparation documentation
- Deployment success templates
- Enhanced features documentation
- Quick start guides
- Extra helper scripts
- Learning guides (Parts 1-4)
- Implementation summaries

**Note:** The `Xtras/` folder is excluded from Git via `.gitignore` and can be moved elsewhere for personal reference.

## 🎯 What Gets Committed to GitHub

Only the essential files listed above will be committed to GitHub:

- ✅ Core documentation (README, LICENSE, CONTRIBUTING, CHANGELOG)
- ✅ Infrastructure code (Bicep templates)
- ✅ Function app code
- ✅ Logic App workflows
- ✅ Static website files
- ✅ Essential scripts (4 PowerShell scripts)
- ✅ Essential docs (ARCHITECTURE, CLEANUP)
- ✅ Tenable integration (optional feature)

## 📊 File Count

**GitHub Repository:**
- ~15 core files
- 3 main folders (infra, function, automation, web, tenable, docs)
- 4 essential scripts
- Clean, focused structure

**Xtras Folder (excluded):**
- ~20 reference files
- Learning materials
- Extra documentation
- Helper scripts

## 🚀 Ready for GitHub

The repository is now clean and ready for publication with only the essential files needed for:
- Deployment
- Usage
- Contribution
- Documentation

All extra materials are safely stored in the `Xtras/` folder for your personal reference.
