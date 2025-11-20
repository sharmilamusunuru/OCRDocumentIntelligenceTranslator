# Contributing to Dulux Demo

Thank you for your interest in contributing to the Dulux Demo project!

## Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/duluxdemo.git`
3. Run the setup script:
   - Linux/Mac: `./setup.sh`
   - Windows: `.\setup.ps1`

## Project Structure

```
duluxdemo/
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Main resource definitions
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Resource outputs
│   └── README.md          # Terraform documentation
├── src/                   # Python application source
│   └── document_processor.py  # Main processing logic
├── batch_process.py       # Batch processing script
├── setup.sh              # Setup script (Linux/Mac)
├── setup.ps1             # Setup script (Windows)
├── configure_env.sh      # Environment configuration (Linux/Mac)
├── configure_env.ps1     # Environment configuration (Windows)
├── requirements.txt      # Python dependencies
├── .env.example          # Environment variables template
├── .gitignore           # Git ignore rules
└── README.md            # Main documentation
```

## Development Workflow

### 1. Making Changes to Terraform

- Test changes locally: `terraform plan`
- Validate syntax: `terraform validate`
- Format code: `terraform fmt`

### 2. Making Changes to Python Code

- Follow PEP 8 style guidelines
- Test your changes locally
- Ensure all imports are in requirements.txt

### 3. Testing

Before submitting changes:

1. Validate Terraform configuration:
   ```bash
   cd terraform
   terraform validate
   terraform fmt -check
   ```

2. Check Python syntax:
   ```bash
   python -m py_compile src/document_processor.py
   python -m py_compile batch_process.py
   ```

3. Test the application with actual documents (if you have Azure resources)

## Code Style

### Python
- Follow PEP 8 guidelines
- Use meaningful variable names
- Add docstrings to functions and classes
- Maximum line length: 100 characters

### Terraform
- Use consistent naming conventions
- Add descriptions to all variables
- Mark sensitive outputs appropriately
- Use tags for resource management

## Adding New Features

### Adding Support for New Document Formats

1. Update `process_document()` in `document_processor.py`
2. Add the new format to `supported_formats` list
3. Update documentation in README.md

### Adding New Translation Languages

1. Update `translate_text()` method to accept dynamic target languages
2. Add language code validation
3. Update documentation

### Adding New Storage Containers

1. Add container resource in `terraform/main.tf`
2. Add container output in `terraform/outputs.tf`
3. Update Python code to reference new container
4. Update documentation

## Commit Message Guidelines

Use clear and descriptive commit messages:

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

Example:
```
feat: Add support for XLSX document format
fix: Handle empty documents gracefully
docs: Update setup instructions for Windows
```

## Pull Request Process

1. Ensure all tests pass
2. Update documentation if needed
3. Add description of changes
4. Link any related issues

## Questions or Issues?

- Open an issue for bugs or feature requests
- Use discussions for general questions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
