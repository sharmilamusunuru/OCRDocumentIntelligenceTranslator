# Helper script to extract Terraform outputs and configure .env file
# PowerShell version for Windows

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Terraform Outputs to .env Configuration" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "terraform")) {
    Write-Host "❌ Error: terraform directory not found" -ForegroundColor Red
    Write-Host "   Please run this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item .env.example .env
}

Write-Host "Extracting Terraform outputs..." -ForegroundColor Yellow
Write-Host ""

Push-Location terraform

# Check if terraform state exists
if (-not (Test-Path "terraform.tfstate")) {
    Write-Host "❌ Error: No terraform state found" -ForegroundColor Red
    Write-Host "   Please run 'terraform apply' first" -ForegroundColor Yellow
    Pop-Location
    exit 1
}

# Extract outputs
Write-Host "Reading outputs from Terraform state..." -ForegroundColor Yellow

try {
    $DI_ENDPOINT = terraform output -raw document_intelligence_endpoint 2>$null
    $DI_KEY = terraform output -raw document_intelligence_key 2>$null
    $TR_ENDPOINT = terraform output -raw translator_endpoint 2>$null
    $TR_KEY = terraform output -raw translator_key 2>$null
    $TR_LOCATION = terraform output -raw translator_location 2>$null
    $STORAGE_CONN = terraform output -raw storage_account_primary_connection_string 2>$null
} catch {
    Write-Host "❌ Error reading Terraform outputs: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Update .env file
Write-Host "Updating .env file..." -ForegroundColor Yellow

# Backup existing .env
Copy-Item .env .env.backup -Force

# Read current .env content
$envContent = Get-Content .env

# Update values
if ($DI_ENDPOINT) {
    $envContent = $envContent -replace "DOCUMENT_INTELLIGENCE_ENDPOINT=.*", "DOCUMENT_INTELLIGENCE_ENDPOINT=$DI_ENDPOINT"
}

if ($DI_KEY) {
    $envContent = $envContent -replace "DOCUMENT_INTELLIGENCE_KEY=.*", "DOCUMENT_INTELLIGENCE_KEY=$DI_KEY"
}

if ($TR_ENDPOINT) {
    $envContent = $envContent -replace "TRANSLATOR_ENDPOINT=.*", "TRANSLATOR_ENDPOINT=$TR_ENDPOINT"
}

if ($TR_KEY) {
    $envContent = $envContent -replace "TRANSLATOR_KEY=.*", "TRANSLATOR_KEY=$TR_KEY"
}

if ($TR_LOCATION) {
    $envContent = $envContent -replace "TRANSLATOR_LOCATION=.*", "TRANSLATOR_LOCATION=$TR_LOCATION"
}

if ($STORAGE_CONN) {
    $envContent = $envContent -replace "STORAGE_CONNECTION_STRING=.*", "STORAGE_CONNECTION_STRING=$STORAGE_CONN"
}

# Write updated content
$envContent | Set-Content .env

Write-Host "✅ Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Updated .env file with Terraform outputs" -ForegroundColor White
Write-Host "Backup saved as .env.backup" -ForegroundColor Gray
Write-Host ""
Write-Host "You can now run the application:" -ForegroundColor Yellow
Write-Host "  venv\Scripts\Activate.ps1" -ForegroundColor Gray
Write-Host "  python src\document_processor.py" -ForegroundColor Gray
Write-Host ""
