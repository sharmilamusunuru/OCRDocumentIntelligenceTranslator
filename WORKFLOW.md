# Document Processing Workflow

This document provides a visual guide to the document processing workflow.

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    START: User Has Document                  │
│                    (PDF, DOCX, or PPTX)                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Upload Document                                     │
│  ─────────────────────────                                   │
│  Function: upload_to_storage()                               │
│  Input:    Local file path                                   │
│  Output:   Blob URL in 'original' container                  │
│  Status:   ✅ Document stored in Azure                       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Perform OCR                                         │
│  ─────────────────────                                       │
│  Function: perform_ocr()                                     │
│  Service:  Azure Document Intelligence                       │
│  Input:    Blob URL                                          │
│  Process:                                                    │
│    1. Send document to Document Intelligence API            │
│    2. API analyzes document structure                        │
│    3. Extracts text with position data                       │
│    4. Returns page-by-page results                           │
│  Output:                                                     │
│    - full_text: Complete extracted text                      │
│    - pages: Array of pages with lines and positions          │
│    - metadata: Document information                          │
│  Status:   ✅ Text extracted from document                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Save OCR Results                                    │
│  ───────────────────────                                     │
│  Function: save_ocr_result()                                 │
│  Input:    OCR result dictionary                             │
│  Format:   JSON with structure:                              │
│    {                                                         │
│      "file_name": "document.pdf",                            │
│      "pages": [...],                                         │
│      "full_text": "..."                                      │
│    }                                                         │
│  Output:   JSON file in 'ocrresult' container                │
│  Naming:   {filename}_ocr_result.json                        │
│  Status:   ✅ OCR results saved                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Translate Text                                      │
│  ─────────────────────                                       │
│  Function: translate_text()                                  │
│  Service:  Azure Translator                                  │
│  Input:    Extracted text (full_text)                        │
│  Process:                                                    │
│    1. Check text length                                      │
│    2. If > 5000 chars, split into chunks                     │
│    3. For each chunk:                                        │
│       - Send to Translator API                               │
│       - Translate EN → FR                                    │
│       - Collect translated chunk                             │
│    4. Combine all chunks                                     │
│  Output:   Translated text in French                         │
│  Status:   ✅ Text translated                                │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Save Translation                                    │
│  ────────────────────────                                    │
│  Function: translate_document()                              │
│  Input:    Translated text                                   │
│  Format:   Plain text (UTF-8)                                │
│  Output:   TXT file in 'translated' container                │
│  Naming:   {filename}_translated_fr.txt                      │
│  Status:   ✅ Translation saved                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    END: Processing Complete                  │
│                                                              │
│  Results Available:                                          │
│  ✅ Original document in 'original' container                │
│  ✅ OCR results (JSON) in 'ocrresult' container              │
│  ✅ Translation (TXT) in 'translated' container              │
└─────────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
Each Step:
  ├── Try operation
  ├── Success? → Continue to next step
  └── Error?
      ├── Log error details
      ├── Raise exception
      └── Stop processing
```

## Batch Processing Flow

```
Multiple Documents
  │
  ├── Document 1 → Process → Results
  ├── Document 2 → Process → Results
  ├── Document 3 → Process → Results
  └── ...
      │
      └── Summary:
          - Total processed
          - Successful
          - Failed
```

## Time Estimates

| Step | Typical Duration | Notes |
|------|-----------------|-------|
| Upload | 1-5 seconds | Depends on file size and network |
| OCR | 10-30 seconds | Depends on document complexity |
| Save OCR | 1-2 seconds | JSON serialization and upload |
| Translation | 5-15 seconds | Depends on text length |
| Save Translation | 1-2 seconds | Text upload |
| **Total** | **~20-60 seconds** | Per document |

## Storage Structure After Processing

```
Storage Account: stduluxdemo
│
├── Container: original/
│   ├── document1.pdf
│   ├── document2.docx
│   └── document3.pptx
│
├── Container: ocrresult/
│   ├── document1_ocr_result.json
│   ├── document2_ocr_result.json
│   └── document3_ocr_result.json
│
└── Container: translated/
    ├── document1_translated_fr.txt
    ├── document2_translated_fr.txt
    └── document3_translated_fr.txt
```

## Sample OCR Result Structure

```json
{
  "file_name": "sample.pdf",
  "pages": [
    {
      "page_number": 1,
      "width": 8.5,
      "height": 11.0,
      "unit": "inch",
      "lines": [
        {
          "content": "Hello World",
          "polygon": [
            {"x": 1.0, "y": 2.0},
            {"x": 3.0, "y": 2.0},
            {"x": 3.0, "y": 2.5},
            {"x": 1.0, "y": 2.5}
          ]
        }
      ]
    }
  ],
  "full_text": "Hello World\n..."
}
```

## Translation Example

**Input (English):**
```
This is a sample document.
It contains multiple sentences.
The text will be translated to French.
```

**Output (French):**
```
Ceci est un exemple de document.
Il contient plusieurs phrases.
Le texte sera traduit en français.
```

## API Calls Made

For each document:

1. **Storage API**
   - 1x Blob Upload (original)
   - 1x Blob Upload (OCR result JSON)
   - 1x Blob Upload (translation TXT)

2. **Document Intelligence API**
   - 1x Analyze Document (prebuilt-read model)
   - Multiple polling requests until complete

3. **Translator API**
   - N requests (where N = ceil(text_length / 5000))
   - Each request translates up to 5000 characters

## Resource Usage

| Resource | Operation | Cost Impact |
|----------|-----------|-------------|
| Storage | Transactions | Minimal |
| Storage | Data stored | Per GB/month |
| Document Intelligence | Pages analyzed | Per 1000 pages |
| Translator | Characters translated | Per million chars |

## Scalability Considerations

### Current (Single Thread)
```
Document 1 → Process (60s) → Done
Document 2 → Process (60s) → Done
Document 3 → Process (60s) → Done
Total: 180 seconds
```

### Parallel Processing
```
Document 1 ─┐
Document 2 ─┼→ Process → Done
Document 3 ─┘
Total: 60 seconds
```

### Serverless (Azure Functions)
```
Upload Trigger → Auto Process → Results
- Unlimited concurrent processing
- Pay per execution
- Auto-scaling
```

## Best Practices

1. **Validate Input**
   - Check file format before processing
   - Verify file size is within limits

2. **Handle Errors**
   - Wrap operations in try-except
   - Log errors for debugging
   - Don't stop batch processing on single failure

3. **Optimize Costs**
   - Process during off-peak hours
   - Use appropriate service tiers
   - Delete processed files if not needed

4. **Monitor Performance**
   - Track processing time per document
   - Monitor API response times
   - Set up alerts for failures

5. **Security**
   - Never log sensitive data
   - Use secure connections (HTTPS)
   - Rotate credentials regularly
   - Use managed identities in production

## Troubleshooting

### OCR Returns Empty Text
- **Cause**: Document contains only images
- **Solution**: Ensure document has selectable text or use custom trained model

### Translation Fails
- **Cause**: Text too long or network issue
- **Solution**: Check chunking logic, verify network connectivity

### Storage Upload Fails
- **Cause**: Invalid credentials or permissions
- **Solution**: Verify connection string and container permissions

### Slow Processing
- **Cause**: Large documents or network latency
- **Solution**: Use Azure region close to storage, optimize document size

## Performance Optimization Tips

1. **Use Async Processing** for large batches
2. **Cache frequently processed documents**
3. **Use Azure CDN** for faster downloads
4. **Enable compression** for large text files
5. **Process during off-peak hours** for better performance
6. **Use parallel processing** for multiple documents
7. **Monitor and optimize** API call patterns
