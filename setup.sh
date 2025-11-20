#!/bin/bash

# Setup script for Dulux Demo - Document Intelligence and Translator

set -e

echo "=========================================="
echo "Dulux Demo Setup Script"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi
echo "✅ Python3 found: $(python3 --version)"

# Check pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip."
    exit 1
fi
echo "✅ pip3 found"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "⚠️  Terraform is not installed. You'll need it to deploy infrastructure."
    echo "   Download from: https://www.terraform.io/downloads.html"
else
    echo "✅ Terraform found: $(terraform version | head -n1)"
fi

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "⚠️  Azure CLI is not installed. You'll need it for Azure operations."
    echo "   Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
else
    echo "✅ Azure CLI found: $(az version --query '"azure-cli"' -o tsv)"
fi

echo ""
echo "=========================================="
echo "Setting up Python environment..."
echo "=========================================="
echo ""

# Install system packages required for building some Python packages (ReportLab / pycairo)
install_system_deps() {
    if command -v apt-get &> /dev/null; then
        echo "Installing system dependencies for PDF generation (requires sudo)..."
        sudo apt-get update
        sudo apt-get install -y build-essential cmake pkg-config \
            libcairo2-dev libjpeg-dev libfreetype6-dev libffi-dev \
            libssl-dev python3-dev
        echo "✅ System dependencies installed"
    else
        echo "⚠️  System package manager not detected (apt-get). Please install cairo and build tools manually if PDF support is required."
    fi
}

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Install system deps optionally via env var INSTALL_SYS_DEPS=1 or interactively
if [ "${INSTALL_SYS_DEPS:-}" = "1" ]; then
    install_system_deps
else
    read -r -p "Install system dependencies for PDF generation (ReportLab/pycairo)? [y/N]: " INSTALL_SYS_DEPS_PROMPT
    INSTALL_SYS_DEPS_PROMPT=${INSTALL_SYS_DEPS_PROMPT:-N}
    if [[ "$INSTALL_SYS_DEPS_PROMPT" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_system_deps
    fi
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip > /dev/null 2>&1

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

echo "✅ Dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo ""
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env file with your Azure credentials"
    echo "   Run: nano .env  (or use your preferred editor)"
else
    echo "✅ .env file already exists"
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Deploy Azure infrastructure:"
echo "   cd terraform"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "2. Configure your .env file with outputs from Terraform:"
echo "   nano .env"
echo ""
echo "3. Process documents from storage (default):"
echo "   source venv/bin/activate"
echo "   # Process all supported blobs in the 'original' container"
echo "   python -c \"from src.document_processor import DocumentProcessor; DocumentProcessor().process_document(from_storage=True)\""
echo "   # Or process a single blob by name using BLOB_NAME env var"
echo "   BLOB_NAME=invoice1.pdf python -c \"from src.document_processor import DocumentProcessor; DocumentProcessor().process_document(from_storage=True, blob_name=\'$BLOB_NAME\')\""
echo ""
echo "For more information, see README.md"
echo ""
