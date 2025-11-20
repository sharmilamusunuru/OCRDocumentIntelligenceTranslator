# Quick Start Guide

This guide will help you get up and running with the Dulux Demo in under 10 minutes.

## Prerequisites Checklist

- [ ] Azure subscription
- [ ] Azure CLI installed
- [ ] Terraform installed
- [ ] Python 3.8+ installed
- [ ] Git installed

## Step-by-Step Setup

### 1. Clone the Repository (1 min)

```bash
git clone https://github.com/sharmilamusunuru/duluxdemo.git
cd duluxdemo
```

### 2. Run Setup Script (2 mins)

**Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

**Windows PowerShell:**
```powershell
.\setup.ps1
```

### 3. Deploy Azure Infrastructure (3 mins)

```bash
# Login to Azure
az login

# Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# Save outputs for later
terraform output -json > outputs.json
cd ..
```

### 4. Configure Environment (1 min)

**Linux/Mac:**
```bash
chmod +x configure_env.sh
./configure_env.sh
```

**Windows PowerShell:**
```powershell
.\configure_env.ps1
```

### 5. Process a Document (2 mins)

```bash
# Activate virtual environment
# Linux/Mac:
source venv/bin/activate

# Windows:
# venv\Scripts\Activate.ps1

# Set document path in .env or use command line
export DOCUMENT_PATH="path/to/your/document.pdf"  # Linux/Mac
# $env:DOCUMENT_PATH = "path\to\your\document.pdf"  # Windows

# Run the processor
python src/document_processor.py
```

## Quick Commands Reference

### Process a Single Document
```bash
python src/document_processor.py
```

### Process Multiple Documents
```bash
python batch_process.py doc1.pdf doc2.docx doc3.pptx
```

### Check Terraform Resources
```bash
cd terraform
terraform show
terraform output
```

### View Processing Results

Check the Azure Portal or use Azure Storage Explorer to view:
- **original** container: Source documents
- **ocrresult** container: OCR results (JSON)
- **translated** container: Translated text files

### Update Infrastructure
```bash
cd terraform
terraform plan
terraform apply
```

### Destroy Infrastructure
```bash
cd terraform
terraform destroy -auto-approve
```

## Common Issues and Quick Fixes

### Issue: Storage account name already exists
**Fix:** Edit `terraform/variables.tf` and change `storage_account_name` to a unique value

### Issue: Python dependencies fail to install
**Fix:** Upgrade pip first: `pip install --upgrade pip`

### Issue: Terraform authentication fails
**Fix:** Run `az login` and ensure you have proper permissions

### Issue: Document not found
**Fix:** Check the `DOCUMENT_PATH` in your `.env` file or pass the correct path

### Issue: Empty OCR results
**Fix:** Ensure your document contains actual text (not just images of text)

## Testing Your Setup

### Test 1: Verify Infrastructure
```bash
cd terraform
terraform output
```
You should see all resource endpoints and names.

### Test 2: Verify Python Installation
```bash
source venv/bin/activate  # or venv\Scripts\Activate.ps1 on Windows
python -c "import azure.ai.formrecognizer; print('✅ Azure SDK installed')"
```

### Test 3: Verify Azure Connection
```bash
az account show
```
You should see your subscription details.

## Next Steps

1. Review the full [README.md](README.md) for detailed information
2. Check [CONTRIBUTING.md](CONTRIBUTING.md) if you want to contribute
3. Explore the Terraform configuration in `terraform/`
4. Review the Python code in `src/document_processor.py`

## Support

For issues or questions:
1. Check the main [README.md](README.md)
2. Review Terraform documentation in `terraform/README.md`
3. Open an issue on GitHub

## Cost Warning ⚠️

Remember that Azure resources incur costs. Don't forget to run `terraform destroy` when you're done testing!

```bash
cd terraform
terraform destroy
```
