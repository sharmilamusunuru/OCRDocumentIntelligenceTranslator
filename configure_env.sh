#!/bin/bash

# Helper script to extract Terraform outputs and configure .env file

set -e

echo "=========================================="
echo "Terraform Outputs to .env Configuration"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "terraform" ]; then
    echo "❌ Error: terraform directory not found"
    echo "   Please run this script from the project root directory"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
fi

echo "Extracting Terraform outputs..."
echo ""

cd terraform

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: No terraform state found"
    echo "   Please run 'terraform apply' first"
    exit 1
fi

# Extract outputs
echo "Reading outputs from Terraform state..."

DI_ENDPOINT=$(terraform output -raw document_intelligence_endpoint 2>/dev/null || echo "")
DI_KEY=$(terraform output -raw document_intelligence_key 2>/dev/null || echo "")
TR_ENDPOINT=$(terraform output -raw translator_endpoint 2>/dev/null || echo "")
TR_KEY=$(terraform output -raw translator_key 2>/dev/null || echo "")
TR_LOCATION=$(terraform output -raw translator_location 2>/dev/null || echo "")
STORAGE_CONN=$(terraform output -raw storage_account_primary_connection_string 2>/dev/null || echo "")

cd ..

# Update .env file
echo "Updating .env file..."

# Backup existing .env
cp .env .env.backup

# Update values
if [ ! -z "$DI_ENDPOINT" ]; then
    sed -i.tmp "s|DOCUMENT_INTELLIGENCE_ENDPOINT=.*|DOCUMENT_INTELLIGENCE_ENDPOINT=$DI_ENDPOINT|" .env
fi

if [ ! -z "$DI_KEY" ]; then
    sed -i.tmp "s|DOCUMENT_INTELLIGENCE_KEY=.*|DOCUMENT_INTELLIGENCE_KEY=$DI_KEY|" .env
fi

if [ ! -z "$TR_ENDPOINT" ]; then
    sed -i.tmp "s|TRANSLATOR_ENDPOINT=.*|TRANSLATOR_ENDPOINT=$TR_ENDPOINT|" .env
fi

if [ ! -z "$TR_KEY" ]; then
    sed -i.tmp "s|TRANSLATOR_KEY=.*|TRANSLATOR_KEY=$TR_KEY|" .env
fi

if [ ! -z "$TR_LOCATION" ]; then
    sed -i.tmp "s|TRANSLATOR_LOCATION=.*|TRANSLATOR_LOCATION=$TR_LOCATION|" .env
fi

if [ ! -z "$STORAGE_CONN" ]; then
    sed -i.tmp "s|STORAGE_CONNECTION_STRING=.*|STORAGE_CONNECTION_STRING=$STORAGE_CONN|" .env
fi

# Clean up temp files
rm -f .env.tmp

echo "✅ Configuration complete!"
echo ""
echo "Updated .env file with Terraform outputs"
echo "Backup saved as .env.backup"
echo ""
echo "You can now run the application:"
echo "  source venv/bin/activate"
echo "  python src/document_processor.py"
echo ""
