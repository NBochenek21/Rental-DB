#!/usr/bin/env bash
# Usuwa bazę rental_db i tworzy ją od nowa (uruchamia setup.sh).
set -euo pipefail

DB_NAME="${DB_NAME:-rental_db}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">> Usuwanie bazy ${DB_NAME} (jeśli istnieje)"
dropdb --if-exists "${DB_NAME}"

echo ">> Odtwarzanie..."
DB_NAME="${DB_NAME}" "${SCRIPT_DIR}/setup.sh"
