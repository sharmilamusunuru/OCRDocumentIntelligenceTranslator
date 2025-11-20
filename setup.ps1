# Setup script for Dulux Demo - Document Intelligence and Translator
# PowerShell version for Windows

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Dulux Demo Setup Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python is not installed. Please install Python 3.8 or higher." -ForegroundColor Red
    Write-Host "   Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Check pip
try {
    $pipVersion = pip --version 2>&1
    Write-Host "✅ pip found" -ForegroundColor Green
} catch {
    Write-Host "❌ pip is not installed. Please install pip." -ForegroundColor Red
    exit 1
}

# Check Terraform
try {
    $terraformVersion = terraform version 2>&1 | Select-Object -First 1
    Write-Host "✅ Terraform found: $terraformVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Terraform is not installed. You'll need it to deploy infrastructure." -ForegroundColor Yellow
    Write-Host "   Download from: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
}

# Check Azure CLI
try {
    $azVersion = az version --query '"azure-cli"' -o tsv 2>&1
    Write-Host "✅ Azure CLI found: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Azure CLI is not installed. You'll need it for Azure operations." -ForegroundColor Yellow
    Write-Host "   Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Setting up Python environment..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Create virtual environment
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "✅ Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "✅ Virtual environment already exists" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& "venv\Scripts\Activate.ps1"

# Upgrade pip
Write-Host "Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip | Out-Null

# Install dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt

Write-Host "✅ Dependencies installed" -ForegroundColor Green

# Create .env file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host ""
    Write-Host "Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "✅ .env file created" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Edit .env file with your Azure credentials" -ForegroundColor Yellow
    Write-Host "   Run: notepad .env" -ForegroundColor Yellow
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Deploy Azure infrastructure:" -ForegroundColor White
Write-Host "   cd terraform" -ForegroundColor Gray
Write-Host "   terraform init" -ForegroundColor Gray
Write-Host "   terraform plan" -ForegroundColor Gray
Write-Host "   terraform apply" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Configure your .env file with outputs from Terraform:" -ForegroundColor White
Write-Host "   notepad .env" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Process a document:" -ForegroundColor White
Write-Host "   venv\Scripts\Activate.ps1" -ForegroundColor Gray
Write-Host "   python src\document_processor.py" -ForegroundColor Gray
Write-Host ""
Write-Host "For more information, see README.md" -ForegroundColor Cyan
Write-Host ""
