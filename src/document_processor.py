import os
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential
from datetime import datetime, timedelta
from azure.storage.blob import BlobServiceClient, ContainerClient, generate_blob_sas, BlobSasPermissions
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from io import BytesIO
import requests
import json
import uuid
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


class DocumentProcessor:
    """
    Document processor for OCR and translation using Azure services.
    Supports PDF, DOCX, and PPTX formats.
    """
    
    def __init__(self):
        # Azure Document Intelligence credentials
        self.di_endpoint = os.getenv("DOCUMENT_INTELLIGENCE_ENDPOINT")
        self.di_key = os.getenv("DOCUMENT_INTELLIGENCE_KEY")
        # Azure Translator credentials
        self.translator_endpoint = os.getenv("TRANSLATOR_ENDPOINT")
        self.translator_key = os.getenv("TRANSLATOR_KEY")
        self.translator_location = os.getenv("TRANSLATOR_LOCATION")

        # Azure Storage credentials
        self.storage_connection_string = os.getenv("STORAGE_CONNECTION_STRING")

        # Container names
        self.original_container = "original"
        self.translated_container = "translated"
        self.ocrresult_container = "ocrresult"

        # Initialize clients
        self.document_client = DocumentAnalysisClient(
            endpoint=self.di_endpoint,
            credential=AzureKeyCredential(self.di_key)
        )
        self.blob_service_client = BlobServiceClient.from_connection_string(
            self.storage_connection_string
        )

    def upload_to_storage(self, local_file_path, container_name):
        """
        Upload a file to Azure Blob Storage.

        Args:
            local_file_path: Path to the local file
            container_name: Name of the target container
            
        Returns:
            Blob URL
        """
        blob_name = Path(local_file_path).name
        blob_client = self.blob_service_client.get_blob_client(
            container=container_name,
            blob=blob_name
        )
        
        with open(local_file_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)
        
        print(f"Uploaded {blob_name} to {container_name} container")
        return blob_client.url
    
    def download_from_storage(self, blob_name, container_name, local_file_path):
        """
        Download a file from Azure Blob Storage.
        
        Args:
            blob_name: Name of the blob
            container_name: Name of the source container
            local_file_path: Path to save the file locally
        """
        blob_client = self.blob_service_client.get_blob_client(
            container=container_name,
            blob=blob_name
        )
        
        with open(local_file_path, "wb") as download_file:
            download_file.write(blob_client.download_blob().readall())
        
        print(f"Downloaded {blob_name} from {container_name} container to {local_file_path}")

    def list_blobs_in_container(self, container_name):
        """
        List blobs in a container.
        Returns a list of blob names.
        """
        container_client = self.blob_service_client.get_container_client(container_name)
        return [b.name for b in container_client.list_blobs()]

    def process_blob(self, blob_name):
        """
        Process a blob that already exists in the original container: download,
        OCR, translate and save results back to storage.
        """
        # Download blob to a temporary local file
        tmp_dir = Path("/tmp/dulux_processor")
        tmp_dir.mkdir(parents=True, exist_ok=True)
        local_path = tmp_dir / blob_name

        print(f"Starting processing for blob: {blob_name}")
        self.download_from_storage(blob_name, self.original_container, str(local_path))

        # Reuse existing workflow: upload (skip since blob already exists), OCR, translate
        blob_client = self.blob_service_client.get_blob_client(container=self.original_container, blob=blob_name)
        # Generate a short-lived SAS URL so Form Recognizer can download the blob
        sas_url = self._generate_blob_sas_url(blob_client, expiry_hours=1)
        ocr_result = self.perform_ocr(sas_url, blob_name)
        self.save_ocr_result(ocr_result, blob_name)
        if ocr_result["full_text"].strip():
            self.translate_document(blob_name, ocr_result)
        else:
            print(f"Warning: No text extracted from {blob_name}, skipping translation")
        print(f"Completed processing for blob: {blob_name}")

    def _generate_blob_sas_url(self, blob_client, expiry_hours=1):
        """
        Generate a read-only SAS URL for a blob that expires after expiry_hours.
        Falls back to returning the blob url if account key not found.
        """
        try:
            conn_str = (self.storage_connection_string or "")
            parts = dict(p.split('=', 1) for p in conn_str.split(';') if p)

            # If the connection string is SAS-only (contains SharedAccessSignature), append it
            sas_value = parts.get('SharedAccessSignature')
            if sas_value:
                token = sas_value.lstrip('?')
                return f"{blob_client.url}?{token}"

            # If account key present, generate a short-lived SAS
            account_name = parts.get('AccountName')
            account_key = parts.get('AccountKey')
            if account_name and account_key:
                sas_token = generate_blob_sas(
                    account_name=account_name,
                    container_name=blob_client.container_name,
                    blob_name=blob_client.blob_name,
                    account_key=account_key,
                    permission=BlobSasPermissions(read=True),
                    expiry=datetime.utcnow() + timedelta(hours=expiry_hours)
                )
                return f"{blob_client.url}?{sas_token}"

            # No SAS or account key available
            print("Storage connection string does not contain AccountKey or SharedAccessSignature; returning blob url without SAS")
            return blob_client.url
        except Exception as e:
            print(f"Failed to generate SAS for blob {blob_client.blob_name}: {e}")
            return blob_client.url
    
    def perform_ocr(self, blob_url, file_name):
        """
        Perform OCR on a document using Azure Document Intelligence.
        
        Args:
            blob_url: URL of the blob in Azure Storage
            file_name: Name of the file
            
        Returns:
            OCR results as dictionary
        """
        print(f"Starting OCR analysis for {file_name}...")
        
        poller = self.document_client.begin_analyze_document_from_url(
            "prebuilt-read",
            blob_url
        )
        result = poller.result()
        
        # Extract text content
        ocr_result = {
            "file_name": file_name,
            "pages": [],
            "full_text": ""
        }
        
        full_text_parts = []
        
        for page in result.pages:
            page_info = {
                "page_number": page.page_number,
                "width": page.width,
                "height": page.height,
                "unit": page.unit,
                "lines": []
            }
            
            for line in page.lines:
                page_info["lines"].append({
                    "content": line.content,
                    "polygon": [{"x": p.x, "y": p.y} for p in line.polygon] if line.polygon else []
                })
                full_text_parts.append(line.content)
            
            ocr_result["pages"].append(page_info)
        
        ocr_result["full_text"] = "\n".join(full_text_parts)
        
        print(f"OCR analysis completed for {file_name}")
        return ocr_result
    
    def save_ocr_result(self, ocr_result, file_name):
        """
        Save OCR results to the OCRResult container.
        
        Args:
            ocr_result: OCR results dictionary
            file_name: Original file name
        """
        result_file_name = f"{Path(file_name).stem}_ocr_result.json"
        result_json = json.dumps(ocr_result, indent=2)
        
        blob_client = self.blob_service_client.get_blob_client(
            container=self.ocrresult_container,
            blob=result_file_name
        )
        
        blob_client.upload_blob(result_json, overwrite=True)
        print(f"Saved OCR results to {result_file_name} in {self.ocrresult_container} container")
    
    def translate_text(self, text, target_language="fr"):
        """
        Translate text using Azure Translator API.
        
        Args:
            text: Text to translate
            target_language: Target language code (default: "fr" for French)
            
        Returns:
            Translated text
        """
        path = '/translate'
        constructed_url = self.translator_endpoint + path
        
        params = {
            'api-version': '3.0',
            'from': 'en',
            'to': target_language
        }
        
        headers = {
            'Ocp-Apim-Subscription-Key': self.translator_key,
            'Ocp-Apim-Subscription-Region': self.translator_location,
            'Content-type': 'application/json',
            'X-ClientTraceId': str(uuid.uuid4())
        }
        
        body = [{'text': text}]
        
        response = requests.post(constructed_url, params=params, headers=headers, json=body)
        response.raise_for_status()
        
        translation = response.json()
        translated_text = translation[0]['translations'][0]['text']
        
        return translated_text
    
    def translate_document(self, file_name, ocr_result):
        """
        Translate the OCR extracted text and save to translated container.
        
        Args:
            file_name: Original file name
            ocr_result: OCR results dictionary
        """
        print(f"Starting translation for {file_name}...")
        
        # Split text into chunks if needed (Translator API has limits)
        full_text = ocr_result["full_text"]
        
        # Translate text in chunks (max 5000 characters per request)
        max_chunk_size = 5000
        translated_chunks = []
        
        if len(full_text) <= max_chunk_size:
            translated_text = self.translate_text(full_text)
            translated_chunks.append(translated_text)
        else:
            # Split by paragraphs/lines
            lines = full_text.split('\n')
            current_chunk = ""
            
            for line in lines:
                if len(current_chunk) + len(line) + 1 <= max_chunk_size:
                    current_chunk += line + "\n"
                else:
                    if current_chunk:
                        translated_chunks.append(self.translate_text(current_chunk))
                    current_chunk = line + "\n"
            
            if current_chunk:
                translated_chunks.append(self.translate_text(current_chunk))
        
        translated_text = "\n".join(translated_chunks)
        
        # Save translated text as TXT
        translated_txt_name = f"{Path(file_name).stem}_translated_fr.txt"
        txt_blob_client = self.blob_service_client.get_blob_client(
            container=self.translated_container,
            blob=translated_txt_name
        )
        txt_blob_client.upload_blob(translated_text, overwrite=True)
        print(f"Saved translated document to {translated_txt_name} in {self.translated_container} container")

        # Also render translated text into a PDF to preserve document format
        pdf_bytes = self._render_translated_pdf(file_name, ocr_result, translated_text)
        translated_pdf_name = f"{Path(file_name).stem}_translated_fr.pdf"
        pdf_blob_client = self.blob_service_client.get_blob_client(
            container=self.translated_container,
            blob=translated_pdf_name
        )
        pdf_blob_client.upload_blob(pdf_bytes.getvalue(), overwrite=True)
        print(f"Saved translated PDF to {translated_pdf_name} in {self.translated_container} container")

    def _render_translated_pdf(self, file_name, ocr_result, translated_text):
        """
        Create a simple PDF containing the translated text. This attempts to preserve
        page breaks and basic line structure from OCR results, but will not fully
        preserve complex original layout (images, tables, fonts).
        Returns a BytesIO containing PDF data.
        """
        packet = BytesIO()
        # Use letter size by default; could be improved by mapping OCR page size
        c = canvas.Canvas(packet, pagesize=letter)
        width, height = letter
        # Simple layout: write translated text page by page based on OCR pages
        lines_per_page = 50
        # If OCR provided pages, split translated_text roughly per OCR pages count
        if ocr_result.get("pages"):
            pages = ocr_result["pages"]
            # Split translated_text into equal chunks per page count
            all_lines = translated_text.split('\n')
            per_page = max(1, len(all_lines) // max(1, len(pages)))
            idx = 0
            for p in range(len(pages)):
                c.setFont("Helvetica", 10)
                y = height - 40
                for _ in range(per_page):
                    if idx >= len(all_lines):
                        break
                    text_line = all_lines[idx]
                    c.drawString(40, y, text_line[:1000])
                    y -= 14
                    idx += 1
                c.showPage()
            # Any remaining lines
            while idx < len(all_lines):
                c.setFont("Helvetica", 10)
                y = height - 40
                for _ in range(lines_per_page):
                    if idx >= len(all_lines):
                        break
                    c.drawString(40, y, all_lines[idx][:1000])
                    y -= 14
                    idx += 1
                c.showPage()
        else:
            # No page info; just write all text flowing
            all_lines = translated_text.split('\n')
            idx = 0
            while idx < len(all_lines):
                c.setFont("Helvetica", 10)
                y = height - 40
                for _ in range(lines_per_page):
                    if idx >= len(all_lines):
                        break
                    c.drawString(40, y, all_lines[idx][:1000])
                    y -= 14
                    idx += 1
                c.showPage()
        c.save()
        packet.seek(0)
        return packet
    
    def process_document(self, local_file_path=None, from_storage=False, blob_name=None):
        """
        Complete workflow. Two modes supported:
          - local file: supply local_file_path
          - storage blob: set from_storage=True and provide blob_name or none to process all blobs

        Args:
            local_file_path: Path to the local document file
            from_storage: Boolean - if True process blobs from `original` container
            blob_name: Optional single blob name to process (when from_storage=True)
        """
        supported_formats = ['.pdf', '.docx', '.pptx']

        if from_storage:
            # Process a single blob or all blobs
            if blob_name:
                self.process_blob(blob_name)
                return
            blobs = self.list_blobs_in_container(self.original_container)
            if not blobs:
                print(f"No blobs found in container '{self.original_container}'")
                return
            for b in blobs:
                # Skip non-supported extensions
                if Path(b).suffix.lower() not in supported_formats:
                    print(f"Skipping unsupported blob format: {b}")
                    continue
                self.process_blob(b)
            return

        # Local file mode
        if not local_file_path:
            raise ValueError("local_file_path must be provided when from_storage=False")

        file_name = Path(local_file_path).name
        file_extension = Path(local_file_path).suffix.lower()

        if file_extension not in supported_formats:
            raise ValueError(f"Unsupported file format: {file_extension}. Supported formats: {supported_formats}")

        print(f"\n{'='*60}")
        print(f"Processing local document: {file_name}")
        print(f"{'='*60}\n")

        # Step 1: Upload to original container
        blob_url = self.upload_to_storage(local_file_path, self.original_container)

        # Step 2: Perform OCR
        ocr_result = self.perform_ocr(blob_url, file_name)

        # Step 3: Save OCR results
        self.save_ocr_result(ocr_result, file_name)

        # Step 4: Translate document
        if ocr_result["full_text"].strip():
            self.translate_document(file_name, ocr_result)
        else:
            print(f"Warning: No text extracted from {file_name}, skipping translation")

        print(f"\n{'='*60}")
        print(f"Processing completed for {file_name}")
        print(f"{'='*60}\n")


def main():
    # Main function to demonstrate the document processing workflow.
    processor = DocumentProcessor()
    
    # Example usage - process a document
    # Replace with actual file path
    document_path = os.getenv("DOCUMENT_PATH", "sample_document.pdf")
    
    if os.path.exists(document_path):
        try:
            processor.process_document(document_path)
        except Exception as e:
            print(f"Error processing document: {e}")
            raise
    else:
        print(f"Document not found: {document_path}")
        print("\nUsage:")
        print("1. Set environment variables in .env file:")
        print("   - DOCUMENT_INTELLIGENCE_ENDPOINT")
        print("   - DOCUMENT_INTELLIGENCE_KEY")
        print("   - TRANSLATOR_ENDPOINT")
        print("   - TRANSLATOR_KEY")
        print("   - TRANSLATOR_LOCATION")
        print("   - STORAGE_CONNECTION_STRING")
        print("   - DOCUMENT_PATH (optional, path to document to process)")
        print("\n2. Place your document (PDF, DOCX, or PPTX) and set DOCUMENT_PATH")
        print("3. Run: python src/document_processor.py")


if __name__ == "__main__":
    main()
