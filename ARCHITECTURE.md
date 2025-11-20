# Architecture Overview

This document describes the architecture of the Dulux Demo solution.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User / Application                       │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                │ (1) Upload Document
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Python Application Layer                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │         DocumentProcessor Class                            │ │
│  │  - upload_to_storage()                                     │ │
│  │  - perform_ocr()                                           │ │
│  │  - translate_text()                                        │ │
│  │  - save_ocr_result()                                       │ │
│  │  - translate_document()                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────┬───────────────┬─────────────────────┬─────────────────────┘
      │               │                     │
      │ (2) Store    │ (3) Analyze         │ (4) Translate
      │              │                     │
      ▼               ▼                     ▼
┌────────────┐ ┌────────────────┐  ┌──────────────────┐
│   Azure    │ │     Azure      │  │     Azure        │
│  Storage   │ │   Document     │  │   Translator     │
│  Account   │ │  Intelligence  │  │    Service       │
└────────────┘ └────────────────┘  └──────────────────┘
      │
      │ (5) Save Results
      │
      ▼
┌─────────────────────────────────────────────┐
│   Storage Containers                        │
│   ┌─────────────┐  ┌──────────────┐        │
│   │  original   │  │  translated  │        │
│   │ (source     │  │ (French text)│        │
│   │  docs)      │  │              │        │
│   └─────────────┘  └──────────────┘        │
│   ┌─────────────┐                          │
│   │  ocrresult  │                          │
│   │ (JSON data) │                          │
│   └─────────────┘                          │
└─────────────────────────────────────────────┘
```

## Component Details

### 1. Infrastructure Layer (Terraform)

**Purpose:** Provision and manage Azure resources

**Components:**
- **Resource Group:** Container for all resources
- **Storage Account:** Blob storage for documents and results
- **Document Intelligence:** OCR and document analysis
- **Translator Service:** Text translation capabilities

**Files:**
- `terraform/main.tf`: Resource definitions
- `terraform/variables.tf`: Configuration parameters
- `terraform/outputs.tf`: Resource outputs

### 2. Application Layer (Python)

**Purpose:** Orchestrate document processing workflow

**Key Class: DocumentProcessor**

```
DocumentProcessor
├── __init__()
│   └── Initialize Azure SDK clients
├── upload_to_storage()
│   └── Upload files to Azure Blob Storage
├── perform_ocr()
│   └── Extract text using Document Intelligence
├── translate_text()
│   └── Translate text using Translator API
├── save_ocr_result()
│   └── Save OCR results as JSON
├── translate_document()
│   └── Translate and save full document
└── process_document()
    └── Complete workflow orchestration
```

**Files:**
- `src/document_processor.py`: Main application logic
- `batch_process.py`: Batch processing utility
- `requirements.txt`: Python dependencies

### 3. Storage Layer

**Purpose:** Store documents and processing results

**Containers:**

1. **original**
   - Stores source documents (PDF, DOCX, PPTX)
   - Private access
   - Input for OCR processing

2. **translated**
   - Stores translated text files
   - Output format: TXT (UTF-8)
   - Naming: `{filename}_translated_fr.txt`

3. **ocrresult**
   - Stores OCR results as JSON
   - Contains text, positions, and metadata
   - Naming: `{filename}_ocr_result.json`

### 4. Azure Services

#### Document Intelligence (Form Recognizer)

**Purpose:** Extract text and structure from documents

**Features Used:**
- `prebuilt-read`: Extract text with position data
- Supports PDF, DOCX, PPTX formats
- Provides page-level information
- Returns text with bounding boxes

**API Flow:**
```
1. Send document URL to API
2. Receive operation ID
3. Poll for completion
4. Retrieve results with text and positions
```

#### Translator Service

**Purpose:** Translate text between languages

**Features Used:**
- REST API v3.0
- English to French translation
- Batch text translation
- Character limit: 5000 per request

**API Flow:**
```
1. Send text with source/target languages
2. Receive translated text
3. Handle chunking for large texts
```

## Data Flow

### Document Processing Workflow

```
Step 1: Upload
  Local File → Azure Blob Storage (original container)
  
Step 2: OCR
  Blob URL → Document Intelligence API → Text + Positions
  
Step 3: Save OCR Results
  OCR Data → JSON → Azure Blob Storage (ocrresult container)
  
Step 4: Translation
  Extracted Text → Translator API → French Text
  
Step 5: Save Translation
  Translated Text → TXT → Azure Blob Storage (translated container)
```

### Detailed Flow Diagram

```
┌──────────────┐
│ Local File   │
│ (PDF/DOCX/   │
│  PPTX)       │
└──────┬───────┘
       │
       │ upload_to_storage()
       │
       ▼
┌──────────────────────┐
│ Azure Blob Storage   │
│ Container: original  │
└──────┬───────────────┘
       │
       │ Get Blob URL
       │
       ▼
┌──────────────────────────┐
│ Document Intelligence    │
│ - Analyze document       │
│ - Extract text & layout  │
│ - Return structured data │
└──────┬───────────────────┘
       │
       │ OCR Results
       │
       ├──────────────────┐
       │                  │
       │                  ▼
       │          ┌────────────────┐
       │          │ Save as JSON   │
       │          │ Container:     │
       │          │ ocrresult      │
       │          └────────────────┘
       │
       │ Extract full_text
       │
       ▼
┌──────────────────────┐
│ Split into chunks    │
│ (if > 5000 chars)    │
└──────┬───────────────┘
       │
       │ For each chunk
       │
       ▼
┌──────────────────────┐
│ Azure Translator     │
│ - Translate EN → FR  │
│ - Return translated  │
└──────┬───────────────┘
       │
       │ Translated Text
       │
       ▼
┌──────────────────────┐
│ Combine chunks       │
│ Save as TXT          │
│ Container:           │
│ translated           │
└──────────────────────┘
```

## Security Architecture

### Authentication & Authorization

```
┌─────────────────────────────────────┐
│ Python Application                  │
│ ┌─────────────────────────────────┐ │
│ │ Environment Variables (.env)    │ │
│ │ - API Keys                      │ │
│ │ - Connection Strings            │ │
│ │ - Endpoints                     │ │
│ └─────────────────────────────────┘ │
└───────────┬─────────────────────────┘
            │
            │ Credentials
            │
            ▼
┌───────────────────────────────────────┐
│ Azure Resources                       │
│ ┌───────────────────────────────────┐ │
│ │ Managed Identity / API Keys       │ │
│ │ - Storage Account Key             │ │
│ │ - Document Intelligence Key       │ │
│ │ - Translator Key                  │ │
│ └───────────────────────────────────┘ │
└───────────────────────────────────────┘
```

### Best Practices

1. **Credential Management**
   - Store credentials in `.env` file (never commit)
   - Use Azure Key Vault for production
   - Rotate keys regularly

2. **Network Security**
   - Use private endpoints for storage
   - Enable firewall rules
   - Restrict access by IP

3. **Access Control**
   - Use RBAC for resource access
   - Minimal permission principle
   - Separate dev/prod environments

## Scalability Considerations

### Current Architecture
- **Synchronous processing**: One document at a time
- **Single thread**: Sequential operations
- **Local execution**: Runs on developer machine

### Scaling Options

1. **Horizontal Scaling**
   ```
   Multiple Processors → Process Multiple Documents
   Use threading/multiprocessing
   ```

2. **Azure Functions**
   ```
   Blob Trigger → Auto-process on upload
   Serverless scaling
   ```

3. **Azure Batch**
   ```
   Batch Processing → Large document sets
   Parallel processing
   ```

4. **Queue-Based Architecture**
   ```
   Upload → Queue Message → Process → Complete
   Decoupled components
   ```

## Monitoring & Observability

### Logging Points

```
Application Layer:
├── Upload events
├── OCR start/completion
├── Translation start/completion
├── Error events
└── Performance metrics

Azure Services:
├── Document Intelligence metrics
├── Translator usage
├── Storage transactions
└── Cost tracking
```

### Metrics to Track

- Documents processed per hour
- Average processing time
- OCR accuracy (manual validation)
- Translation quality
- Storage costs
- API call costs
- Error rates

## Cost Structure

### Resource Costs

1. **Storage Account**
   - Storage: $0.02/GB/month
   - Transactions: Minimal

2. **Document Intelligence (S0)**
   - $1.50 per 1,000 pages

3. **Translator (S1)**
   - $10 per million characters

### Cost Optimization

- Use lower tiers for development
- Delete processed files regularly
- Implement caching for repeated documents
- Monitor usage with Azure Cost Management

## Deployment Topology

### Development Environment
```
Developer Machine
├── Python Application
├── Terraform CLI
└── Azure CLI
       │
       ▼
   Azure Cloud
   └── Dev Resource Group
       ├── Storage (dev)
       ├── Document Intelligence (dev)
       └── Translator (dev)
```

### Production Environment
```
CI/CD Pipeline
├── Terraform (IaC)
└── Application Deployment
       │
       ▼
   Azure Cloud
   └── Prod Resource Group
       ├── Storage (prod)
       ├── Document Intelligence (prod)
       ├── Translator (prod)
       └── Key Vault (secrets)
```

## Technology Stack

### Infrastructure
- **Terraform**: v1.0+
- **Azure Provider**: v3.0+

### Application
- **Python**: 3.8+
- **Azure SDK for Python**:
  - azure-ai-formrecognizer: 3.3.0
  - azure-ai-translation-document: 1.0.0
  - azure-storage-blob: 12.19.0
- **Supporting Libraries**:
  - python-dotenv: 1.0.0
  - requests: 2.31.0

### Cloud Services
- **Azure Storage Account**: Standard LRS
- **Azure Document Intelligence**: S0 tier
- **Azure Translator**: S1 tier

## Extension Points

### Adding New Features

1. **New Document Formats**
   - Update `supported_formats` list
   - Add format-specific handling

2. **Additional Languages**
   - Modify `translate_text()` method
   - Add language parameter

3. **Custom OCR Models**
   - Train custom Document Intelligence model
   - Update model ID in API calls

4. **Output Formats**
   - Add new export methods
   - Support PDF, Word output

5. **Workflow Orchestration**
   - Integrate with Azure Logic Apps
   - Add Azure Durable Functions

## References

- [Azure Document Intelligence Documentation](https://docs.microsoft.com/en-us/azure/cognitive-services/form-recognizer/)
- [Azure Translator Documentation](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/)
- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
