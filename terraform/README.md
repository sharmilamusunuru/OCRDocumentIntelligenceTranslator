# Terraform Infrastructure for Document Intelligence Demo

This directory contains Terraform configuration files to provision Azure resources for the Document Intelligence and Translator demo.

## Resources Created

1. **Resource Group**: Container for all resources
2. **Storage Account**: Blob storage with three containers
   - `original`: For source documents
   - `translated`: For translated documents
   - `ocrresult`: For OCR results
3. **Document Intelligence (Form Recognizer)**: For OCR capabilities
4. **Translator Service**: For text translation

## Prerequisites

- Terraform >= 1.0
- Azure CLI installed and authenticated (`az login`)
- Active Azure subscription
- Appropriate permissions to create resources

## Quick Start

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

## Customization

### Using Custom Variables

Create a `terraform.tfvars` file to customize deployment:

```hcl
resource_group_name        = "rg-my-demo"
location                   = "eastus"
storage_account_name       = "stmydemo12345"  # Must be globally unique
document_intelligence_name = "di-my-demo"
translator_name            = "tr-my-demo"
environment                = "dev"
```

### Using Command Line Variables

```bash
terraform apply \
  -var="resource_group_name=rg-custom-demo" \
  -var="storage_account_name=stcustom12345" \
  -var="location=westus2"
```

## Outputs

After successful deployment, Terraform will output:

- Resource group name
- Storage account name
- Document Intelligence endpoint and key
- Translator endpoint and key
- Container names

### Viewing Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output storage_account_name

# View sensitive outputs (e.g., keys)
terraform output document_intelligence_key

# Export all outputs to JSON (including sensitive values)
terraform output -json > outputs.json
```

## Configuration for Python Application

After deployment, use the outputs to configure your Python application:

```bash
# Get the required values
echo "DOCUMENT_INTELLIGENCE_ENDPOINT=$(terraform output -raw document_intelligence_endpoint)" >> ../.env
echo "DOCUMENT_INTELLIGENCE_KEY=$(terraform output -raw document_intelligence_key)" >> ../.env
echo "TRANSLATOR_ENDPOINT=$(terraform output -raw translator_endpoint)" >> ../.env
echo "TRANSLATOR_KEY=$(terraform output -raw translator_key)" >> ../.env
echo "TRANSLATOR_LOCATION=$(terraform output -raw translator_location)" >> ../.env
echo "STORAGE_CONNECTION_STRING=$(terraform output -raw storage_account_primary_connection_string)" >> ../.env
```

## State Management

This configuration uses local state by default. For team environments, consider using remote state:

### Azure Storage Backend

Add to `main.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate"
    container_name       = "tfstate"
    key                  = "dulux-demo.tfstate"
  }
}
```

## Important Notes

1. **Storage Account Naming**: Must be 3-24 characters, lowercase letters and numbers only, globally unique
2. **Translator Location**: Should be set to "global" for multi-service resource
3. **Costs**: Review Azure pricing before deployment
4. **Security**: Outputs containing keys are marked as sensitive

## Cleanup

To remove all resources:

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

## Troubleshooting

### Name Already Exists
```
Error: A resource with the ID already exists
```
**Solution**: Change the `storage_account_name` variable to a unique value.

### Insufficient Permissions
```
Error: Authorization failed
```
**Solution**: Ensure you have Contributor or Owner role on the subscription.

### Quota Exceeded
```
Error: Quota has been exceeded
```
**Solution**: Request quota increase or use a different region.

## File Structure

```
terraform/
├── main.tf         # Main resource definitions
├── variables.tf    # Input variables
├── outputs.tf      # Output values
└── README.md       # This file
```

## Additional Resources

- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Azure Cognitive Services](https://azure.microsoft.com/en-us/services/cognitive-services/)
