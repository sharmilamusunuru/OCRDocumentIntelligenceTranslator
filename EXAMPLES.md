# Example Scenarios

This document provides examples of how to use the Dulux Demo for different scenarios.

## Scenario 1: Single Document Processing

### Use Case
You have a single PDF invoice that needs to be processed for OCR and translation.

### Steps
```bash
# 1. Place your document in the project directory
cp ~/Documents/invoice.pdf ./

# 2. Set the document path
export DOCUMENT_PATH="invoice.pdf"  # Linux/Mac
# $env:DOCUMENT_PATH = "invoice.pdf"  # Windows

# 3. Run the processor
python src/document_processor.py
```

### Expected Output
```
====================================================
Processing document: invoice.pdf
====================================================

Uploaded invoice.pdf to original container
Starting OCR analysis for invoice.pdf...
OCR analysis completed for invoice.pdf
Saved OCR results to invoice_ocr_result.json in ocrresult container
Starting translation for invoice.pdf...
Saved translated document to invoice_translated_fr.txt in translated container

====================================================
Processing completed for invoice.pdf
====================================================
```

## Scenario 2: Batch Processing Multiple Documents

### Use Case
You have multiple documents in different formats that need processing.

### Steps
```bash
# Place all documents in a folder
mkdir documents_to_process
cp ~/Documents/*.pdf documents_to_process/
cp ~/Documents/*.docx documents_to_process/
cp ~/Documents/*.pptx documents_to_process/

# Process all documents
python batch_process.py documents_to_process/*.pdf documents_to_process/*.docx documents_to_process/*.pptx
```

### Alternative: Process specific files
```bash
python batch_process.py report.pdf presentation.pptx contract.docx
```

## Scenario 3: Processing Documents from Azure Storage

### Use Case
Documents are already in Azure Storage and you want to process them directly.

### Steps
Create a custom script `process_from_storage.py`:

```python
from src.document_processor import DocumentProcessor
from pathlib import Path
import os

processor = DocumentProcessor()

# List blobs in original container
container_client = processor.blob_service_client.get_container_client("original")
blobs = container_client.list_blobs()

# Process each blob
for blob in blobs:
    print(f"Processing {blob.name}...")
    
    # Download temporarily
    temp_path = f"/tmp/{blob.name}"
    processor.download_from_storage(blob.name, "original", temp_path)
    
    # Get blob URL for OCR
    blob_client = processor.blob_service_client.get_blob_client(
        container="original",
        blob=blob.name
    )
    
    # Perform OCR and translation
    ocr_result = processor.perform_ocr(blob_client.url, blob.name)
    processor.save_ocr_result(ocr_result, blob.name)
    
    if ocr_result["full_text"].strip():
        processor.translate_document(blob.name, ocr_result)
    
    # Clean up temp file
    os.remove(temp_path)
    
    print(f"Completed {blob.name}\n")
```

Run it:
```bash
python process_from_storage.py
```

## Scenario 4: Custom Translation Language

### Use Case
You want to translate documents to a language other than French.

### Steps
Modify the `document_processor.py` or create a wrapper script:

```python
from src.document_processor import DocumentProcessor

processor = DocumentProcessor()

# Process document
blob_url = processor.upload_to_storage("document.pdf", processor.original_container)
ocr_result = processor.perform_ocr(blob_url, "document.pdf")
processor.save_ocr_result(ocr_result, "document.pdf")

# Translate to Spanish instead of French
if ocr_result["full_text"].strip():
    translated_text = processor.translate_text(ocr_result["full_text"], target_language="es")
    
    # Save with custom name
    blob_client = processor.blob_service_client.get_blob_client(
        container=processor.translated_container,
        blob="document_translated_es.txt"
    )
    blob_client.upload_blob(translated_text, overwrite=True)
    print("Translated to Spanish")
```

### Supported Language Codes
- **French**: `fr`
- **Spanish**: `es`
- **German**: `de`
- **Italian**: `it`
- **Portuguese**: `pt`
- **Chinese (Simplified)**: `zh-Hans`
- **Japanese**: `ja`
- **Korean**: `ko`

See [Azure Translator documentation](https://docs.microsoft.com/en-us/azure/cognitive-services/translator/language-support) for full list.

## Scenario 5: Extracting Only OCR Without Translation

### Use Case
You only need OCR results, not translation.

### Steps
Create a custom script `ocr_only.py`:

```python
from src.document_processor import DocumentProcessor
import sys

if len(sys.argv) < 2:
    print("Usage: python ocr_only.py <document_path>")
    sys.exit(1)

document_path = sys.argv[1]
processor = DocumentProcessor()

# Upload and perform OCR only
blob_url = processor.upload_to_storage(document_path, processor.original_container)
ocr_result = processor.perform_ocr(blob_url, document_path)
processor.save_ocr_result(ocr_result, document_path)

print(f"OCR completed. Results saved to ocrresult container")
print(f"Extracted {len(ocr_result['full_text'])} characters")
```

Run it:
```bash
python ocr_only.py document.pdf
```

## Scenario 6: Processing and Downloading Results

### Use Case
You want to process documents and download all results locally.

### Steps
```python
from src.document_processor import DocumentProcessor
from pathlib import Path
import os

processor = DocumentProcessor()

# Process document
document_path = "report.pdf"
processor.process_document(document_path)

# Create output directory
os.makedirs("results", exist_ok=True)

# Download OCR results
ocr_blob_name = f"{Path(document_path).stem}_ocr_result.json"
processor.download_from_storage(
    ocr_blob_name,
    processor.ocrresult_container,
    f"results/{ocr_blob_name}"
)

# Download translated document
translated_blob_name = f"{Path(document_path).stem}_translated_fr.txt"
processor.download_from_storage(
    translated_blob_name,
    processor.translated_container,
    f"results/{translated_blob_name}"
)

print(f"Results downloaded to results/ directory")
```

## Scenario 7: Integration with Azure Functions

### Use Case
Automatically process documents when they are uploaded to storage.

### Steps

1. Create an Azure Function with blob trigger:

```python
import azure.functions as func
from src.document_processor import DocumentProcessor
import os

def main(myblob: func.InputStream):
    logging.info(f"Processing blob: {myblob.name}")
    
    processor = DocumentProcessor()
    
    # Save blob temporarily
    temp_path = f"/tmp/{os.path.basename(myblob.name)}"
    with open(temp_path, "wb") as f:
        f.write(myblob.read())
    
    # Process
    try:
        processor.process_document(temp_path)
        logging.info(f"Successfully processed {myblob.name}")
    except Exception as e:
        logging.error(f"Error processing {myblob.name}: {e}")
    finally:
        os.remove(temp_path)
```

2. Configure function.json:
```json
{
  "bindings": [
    {
      "name": "myblob",
      "type": "blobTrigger",
      "direction": "in",
      "path": "original/{name}",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

## Scenario 8: Monitoring and Logging

### Use Case
You want to track processing metrics and logs.

### Steps
Create `process_with_logging.py`:

```python
from src.document_processor import DocumentProcessor
import logging
import time
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('processing.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

processor = DocumentProcessor()
document_path = "document.pdf"

try:
    start_time = time.time()
    logging.info(f"Starting processing: {document_path}")
    
    processor.process_document(document_path)
    
    elapsed_time = time.time() - start_time
    logging.info(f"Processing completed in {elapsed_time:.2f} seconds")
    
except Exception as e:
    logging.error(f"Processing failed: {e}", exc_info=True)
```

## Best Practices

1. **Always validate document format** before processing
2. **Handle errors gracefully** with try-except blocks
3. **Use batch processing** for multiple documents
4. **Monitor storage costs** regularly
5. **Clean up temporary files** after processing
6. **Use environment variables** for configuration
7. **Implement retry logic** for network operations
8. **Log all operations** for debugging

## Performance Tips

- For large documents, consider splitting into smaller chunks
- Use parallel processing for multiple documents
- Cache frequently accessed resources
- Optimize network calls by batching operations
- Use Azure regions close to your location for better performance
