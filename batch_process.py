#!/usr/bin/env python3
"""
Batch document processor for the Dulux Demo.
Processes multiple documents at once.
"""

import os
import sys
from pathlib import Path
from src.document_processor import DocumentProcessor


def process_multiple_documents(document_paths):
    """
    Process multiple documents in batch.
    
    Args:
        document_paths: List of paths to documents
    """
    processor = DocumentProcessor()
    
    total = len(document_paths)
    successful = 0
    failed = 0
    
    print(f"\n{'='*70}")
    print(f"Batch Processing: {total} document(s)")
    print(f"{'='*70}\n")
    
    for idx, doc_path in enumerate(document_paths, 1):
        print(f"\n[{idx}/{total}] Processing: {doc_path}")
        
        if not os.path.exists(doc_path):
            print(f"❌ Error: File not found - {doc_path}")
            failed += 1
            continue
        
        try:
            processor.process_document(doc_path)
            successful += 1
            print(f"✅ Success: {Path(doc_path).name}")
        except Exception as e:
            print(f"❌ Error processing {doc_path}: {e}")
            failed += 1
    
    print(f"\n{'='*70}")
    print(f"Batch Processing Complete")
    print(f"{'='*70}")
    print(f"Total: {total} | Successful: {successful} | Failed: {failed}")
    print(f"{'='*70}\n")


def main():
    """
    Main entry point for batch processing.
    """
    if len(sys.argv) < 2:
        print("Usage: python batch_process.py <document1> [document2] [document3] ...")
        print("\nExample:")
        print("  python batch_process.py document.pdf report.docx presentation.pptx")
        print("\nSupported formats: PDF, DOCX, PPTX")
        sys.exit(1)
    
    document_paths = sys.argv[1:]
    process_multiple_documents(document_paths)


if __name__ == "__main__":
    main()
