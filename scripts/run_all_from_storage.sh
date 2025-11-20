#!/usr/bin/env bash
set -euo pipefail

# Helper script to process all supported blobs in the 'original' container.
# Usage: ./scripts/run_all_from_storage.sh
# Requires: venv created, .env configured with STORAGE_CONNECTION_STRING and other vars.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -d "venv" ]; then
  echo "Virtualenv not found. Run ./setup.sh first to create venv and install dependencies."
  exit 1
fi

# Activate venv
# shellcheck disable=SC1091
source venv/bin/activate

# Load .env variables (if present)
if [ -f .env ]; then
  echo "Loading environment variables from .env"
  # export all variables defined in .env
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
else
  echo "Warning: .env not found — ensure STORAGE_CONNECTION_STRING and other variables are exported"
fi

# Run processor
echo "Processing all supported blobs in the 'original' container..."
python -c "from src.document_processor import DocumentProcessor; DocumentProcessor().process_document(from_storage=True)"

echo "Processing finished."
