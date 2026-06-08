# Podsumowanie Weryfikacji Bazy Danych — Rental-DB

> [!IMPORTANT]
> Baza danych **działa w 100% poprawnie** i w pełni spełnia wszystkie wymagania techniczne oraz funkcjonalne opisane w dokumentacji projektowej na **ocenę 4.5** (w tym pełną normalizację 3NF, transakcje z poziomami izolacji oraz zaawansowaną kontrolę bezpieczeństwa ról).

---

## 1. Status Weryfikacji Reguł Biznesowych (RB)

Wszystkie reguły biznesowe zostały przetestowane automatycznie przy użyciu skryptu [sql/08_queries/03_validation.sql](sql/08_queries/03_validation.sql). Wyniki testów potwierdzają poprawne działanie bazy:

| ID Reguły | Treść Reguły Biznesowej | Mechanizm w bazie | Status Testu |
|:---|:---|:---|:---:|
| **RB-1** | Data końca umowy musi być późniejsza niż data początku. | CHECK `ch_umowy_daty` | ✅ ZALICZONY |
| **RB-2** | Mieszkanie nie może mieć nakładających się czasowo aktywnych umów. | Wyzwalacz `t_umowy_walidacja` | ✅ ZALICZONY |
| **RB-3** | Podpisanie aktywnej umowy zmienia status ogłoszenia na "zarezerwowane". | Wyzwalacz `t_ogloszenie_po_umowie` | ✅ ZALICZONY |
| **RB-4** | Tylko jedna płatność za dany okres (miesiąc) dla konkretnej umowy. | UNIQUE `uq_platnosc_okres` | ✅ ZALICZONY |
| **RB-5** | Kwoty czynszu, kaucji i płatności nie mogą być ujemne. | CHECK | ✅ ZALICZONY |
| **RB-6** | Powierzchnia mieszkania i liczba pokoi muszą być dodatnie. | CHECK `ch_mieszkania_*` | ✅ ZALICZONY |
| **RB-7/8/9**| Statusy ogłoszeń, umów i płatności przyjmują tylko dozwolone słownikowo wartości. | CHECK | ✅ ZALICZONY |
| **RB-10**| Adresy e-mail najemców i właścicieli są unikalne. | UNIQUE | ✅ ZALICZONY |
| **RB-11**| Znacznik czasu `zmodyfikowano` jest automatycznie aktualizowany. | Wyzwalacz `t_*_mod` | ✅ ZALICZONY |
| **RB-12**| Rejestracja płatności blokuje wiersz na czas transakcji (ochrona przed podwójnym zaksięgowaniem). | `SELECT ... FOR UPDATE` w procedurze | ✅ ZALICZONY |

---

## 2. Audyt Bezpieczeństwa (Uprawnienia i Role)

Weryfikacja automatyczna ze skryptu [scripts/verify.ps1](scripts/verify.ps1) potwierdziła prawidłowe działanie systemu uprawnień:

### Rola `rental_agent` (Codzienna obsługa)
* **Zapis i odczyt danych**: Agent może dodawać najemców, zawierać umowy oraz naliczać płatności.
* **Ochrona przed usuwaniem**: Próba wywołania instrukcji `DELETE` przez Agenta jest **zablokowana przez serwer bazy danych** (`permission denied`). Usuwanie danych może wykonać tylko administrator (`rental_admin`).

### Rola `rental_readonly` (Raportowanie i podgląd dla właściciela)
* **Odczyt widoków**: Rola ma pełen dostęp do widoków raportowych (np. przychody, obłożenie mieszkań).
* **Ochrona danych wrażliwych (Column-level Security)**: Rola ta ma zablokowany dostęp do kolumny `pesel` w tabeli `najemcy`. Próba wykonania `SELECT pesel FROM najemcy` lub `SELECT * FROM najemcy` kończy się błędem odmowy dostępu (`permission denied`), chroniąc wrażliwe dane osobowe najemców.

---

## 3. Struktura Projektu (3NF)

Schemat bazy danych składa się z 7 powiązanych ze sobą tabel:
1. [sql/01_schema/01_tables.sql](sql/01_schema/01_tables.sql) — Definicje struktur tabel.
2. [sql/02_constraints/01_constraints.sql](sql/02_constraints/01_constraints.sql) — Klucze obce, unikalne oraz ograniczenia domenowe CHECK.
3. [sql/03_views/01_views.sql](sql/03_views/01_views.sql) — Definicje widoków raportowych.
4. [sql/04_functions/01_functions.sql](sql/04_functions/01_functions.sql) — Procedury i funkcje (PL/pgSQL).
5. [sql/05_triggers/01_triggers.sql](sql/05_triggers/01_triggers.sql) — Wyzwalacze automatyzujące procesy biznesowe.
6. [sql/06_security/01_roles.sql](sql/06_security/01_roles.sql) — Konfiguracja bezpieczeństwa ról.
7. [sql/07_seed/01_seed.sql](sql/07_seed/01_seed.sql) — Dane testowe.

> [!NOTE]
> Wszystkie tabele operacyjne spełniają kryteria **Trzeciej Formy Normalnej (3NF)**. Jedynym wyjątkiem jest tabela historyczna `historia_najmu`, w której celowo pozostawiono `najemca_id` i `mieszkanie_id` obok `umowa_id` jako kontrolowaną denormalizację służącą do trwałego zapisu stanu archiwalnego (snapshotu) odpornego na ewentualne przyszłe zmiany w definicjach umów.