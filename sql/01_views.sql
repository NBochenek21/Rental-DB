#!/usr/bin/env bash
# Tworzy bazę rental_db i ładuje cały schemat + dane w poprawnej kolejności.
set -euo pipefail

DB_NAME="${DB_NAME:-rental_db}"
PSQL="psql -v ON_ERROR_STOP=1 -d ${DB_NAME}"
SQL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../sql" && pwd)"

echo ">> Tworzenie bazy ${DB_NAME} (jeśli nie istnieje)"
createdb "${DB_NAME}" 2>/dev/null || echo "   baza już istnieje, kontynuuję"

echo ">> 01 schemat (tabele)"
${PSQL} -f "${SQL_DIR}/01_schema/01_tables.sql"

echo ">> 02 więzy integralności"
${PSQL} -f "${SQL_DIR}/02_constraints/01_constraints.sql"

echo ">> 03 widoki"
${PSQL} -f "${SQL_DIR}/03_views/01_views.sql"

echo ">> 04 funkcje i procedury"
${PSQL} -f "${SQL_DIR}/04_functions/01_functions.sql"

echo ">> 05 wyzwalacze"
${PSQL} -f "${SQL_DIR}/05_triggers/01_triggers.sql"

echo ">> 06 role i uprawnienia"
${PSQL} -f "${SQL_DIR}/06_security/01_roles.sql"

echo ">> 07 dane testowe"
${PSQL} -f "${SQL_DIR}/07_seed/01_seed.sql"

echo ">> Gotowe. Baza ${DB_NAME} jest skonfigurowana."
echo "   Przykłady zapytań: sql/08_queries/"
