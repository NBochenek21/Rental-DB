# Dokumentacja techniczna — System Obsługi Wynajmu Mieszkań

> SEKCJA 4. Spaja całość: architektura, opis obiektów bazy, model bezpieczeństwa, instrukcja uruchomienia. Stan opisany w tym dokumencie odpowiada faktycznej, przetestowanej zawartości bazy.

## 1. Architektura i technologia

- **SZBD:** PostgreSQL 14+ (testowano na 16).
- **Język proceduralny:** PL/pgSQL.
- **Organizacja kodu:** katalog `sql/` z numerowanymi etapami uruchamianymi w kolejności:
  schemat → więzy → widoki → funkcje → wyzwalacze → bezpieczeństwo → dane.
- **Zasada przewodnia:** reguły biznesowe egzekwowane na poziomie bazy (więzy, wyzwalacze, procedury), nie wyłącznie w warstwie aplikacji. Dzięki temu obowiązują niezależnie od kanału dostępu.

## 2. Schemat bazy danych

Pełny diagram ERD oraz uzasadnienie normalizacji do 3NF: `docs/02_projekt.md`. Poniżej skrótowy przegląd siedmiu tabel.

| Tabela | Przeznaczenie |
|--------|---------------|
| najemcy | profile osób wynajmujących |
| wlasciciele | właściciele mieszkań |
| mieszkania | nieruchomości (FK → wlasciciele) |
| ogloszenia | oferty najmu (FK → mieszkania) |
| umowy_najmu | zawarte umowy (FK → ogloszenia, najemcy) |
| platnosci | miesięczne należności (FK → umowy_najmu) |
| historia_najmu | rejestr najmów (FK → umowy_najmu, najemcy, mieszkania) |

Integralność zapewniają: klucze obce, ograniczenia CHECK (dozwolone statusy, nieujemne kwoty, poprawność dat), UNIQUE (unikalne adresy e-mail, jedna płatność na umowę za okres) oraz indeksy na kluczach obcych.

## 3. Widoki

Sześć widoków raportowych (`sql/03_views/01_views.sql`):

| Widok | Opis | Technika |
|-------|------|----------|
| `v_dostepne_mieszkania` | aktywne ogłoszenia z danymi mieszkania i właściciela | JOIN |
| `v_saldo_umow` | suma naliczona / opłacona / zaległa per umowa | agregacja + FILTER |
| `v_najemcy_zalegli` | najemcy mający zaległe płatności | podzapytanie IN |
| `v_aktywne_umowy` | aktywne umowy z liczbą dni do końca | wielokrotny JOIN |
| `v_przychod_miesieczny` | przychód z opłaconych płatności wg miesiąca | agregacja czasowa |
| `v_oblozenie_mieszkan` | stan każdego mieszkania (wolne / wynajęte) | CASE + EXISTS |

## 4. Funkcje i procedury

Logika biznesowa w PL/pgSQL (`sql/04_functions/01_functions.sql`). Funkcje wykonują obliczenia bez efektów ubocznych; procedury modyfikują stan, często wieloetapowo.

| Obiekt | Typ | Sygnatura | Opis |
|--------|-----|-----------|------|
| `czy_mieszkanie_wolne` | funkcja | `(mieszkanie_id, od, do) → bool` | czy brak nakładającej się aktywnej umowy (RB-2) |
| `saldo_umowy` | funkcja | `(umowa_id) → numeric` | kwota pozostała do zapłaty |
| `nalicz_platnosc` | funkcja | `(umowa_id, okres) → bigint` | tworzy należność (kwota z czynszu), zwraca id |
| `zarejestruj_platnosc` | procedura | `(umowa_id, okres, data)` | oznacza płatność jako opłaconą; blokada FOR UPDATE (RB-12) |
| `oznacz_zaleglosci` | procedura | `(na_dzien)` | masowo zmienia przeterminowane „oczekujące" na „zaległe" |
| `zakoncz_umowe` | procedura | `(umowa_id, powod, data)` | wieloetapowo: zamyka umowę, domyka historię, zwalnia ogłoszenie |

## 5. Wyzwalacze

Cztery reguły zautomatyzowane wyzwalaczami (`sql/05_triggers/01_triggers.sql`):

| Wyzwalacz | Tabela | Zdarzenie | Działanie |
|-----------|--------|-----------|-----------|
| `t_*_mod` (6 szt.) | wszystkie z `zmodyfikowano` | BEFORE UPDATE | aktualizacja znacznika czasu (RB-11) |
| `t_umowy_walidacja` | umowy_najmu | BEFORE INSERT/UPDATE | blokuje nakładające się aktywne umowy (RB-2) |
| `t_ogloszenie_po_umowie` | umowy_najmu | AFTER INSERT | zmienia status ogłoszenia na „zarezerwowane" (RB-3) |
| `t_historia_po_umowie` | umowy_najmu | AFTER INSERT | tworzy otwarty wpis w historii najmu |

Współdziałanie: `t_historia_po_umowie` tworzy wpis historii przy zawarciu umowy, który procedura `zakoncz_umowe` później domyka (data zakończenia + powód). Dzięki temu historia jest spójna niezależnie od ścieżki.

## 6. Model bezpieczeństwa (role i uprawnienia)

Plik: `sql/06_security/01_roles.sql`. Model oparty na **zasadzie najmniejszych uprawnień** — każda rola dostaje dokładnie tyle praw, ile wynika z jej zadań. Skrypt jest idempotentny (można go uruchamiać wielokrotnie).

| Rola | Uprawnienia | Mapowanie na aktora |
|------|-------------|---------------------|
| `rental_admin` | pełne: DML + DDL, EXECUTE wszystkich funkcji i procedur | administrator |
| `rental_agent` | SELECT/INSERT/UPDATE na danych, EXECUTE logiki biznesowej, **bez DELETE** | agent / operator |
| `rental_readonly` | wyłącznie SELECT (tabele + widoki), **bez dostępu do PESEL** | podgląd właściciela / raporty |

Kluczowe decyzje bezpieczeństwa:

- **Agent nie ma DELETE.** Usuwanie rekordów jest nieodwracalne i zarezerwowane dla administratora. Próba `DELETE` przez agenta kończy się błędem „permission denied".
- **Readonly nie widzi numeru PESEL.** Zastosowano uprawnienia kolumnowe: na tabeli `najemcy` odebrano `SELECT` na całości i nadano tylko na kolumnach bez PESEL. W efekcie zarówno `SELECT pesel`, jak i `SELECT *` są dla tej roli odrzucane, podczas gdy pozostałe kolumny pozostają dostępne. To przykład ochrony danych wrażliwych.
- **Domyślne uprawnienia.** `ALTER DEFAULT PRIVILEGES` nadaje readonly `SELECT` na przyszłych tabelach, co upraszcza utrzymanie.

Uwaga wdrożeniowa: hasła ról w pliku są przykładowymi placeholderami. W produkcji należy ustawić silne hasła i nie przechowywać ich w repozytorium.

## 7. Transakcje i poziomy izolacji

Plik: `sql/08_queries/02_transactions.sql`. Cztery udokumentowane scenariusze:

1. **Atomowe zawarcie umowy + naliczenie płatności** — operacja wielokrokowa w jednej transakcji (`BEGIN … COMMIT`); błąd w którymkolwiek kroku wycofuje całość.
2. **READ COMMITTED** (domyślny) — rejestracja płatności z blokadą wiersza `FOR UPDATE`.
3. **SERIALIZABLE** — scenariusz dwóch równoległych sesji próbujących naliczyć płatność za ten sam okres; jedna transakcja zostaje wycofana z błędem serializacji (SQLSTATE 40001) i wymaga ponowienia. Komplementarnie chroni nas ograniczenie UNIQUE(umowa_id, okres).
4. **REPEATABLE READ** — spójny raport widzący niezmienny snapshot danych mimo równoległych zmian.

## 8. Instrukcja uruchomienia

Wymagany działający PostgreSQL z poleceniem `psql` w PATH.

```bash
# pełna instalacja od zera (tworzy bazę rental_db i ładuje wszystko)
./scripts/setup.sh

# wyczyszczenie i ponowne utworzenie
./scripts/reset.sh
```

Ręcznie, w kolejności: schemat → więzy → widoki → funkcje → wyzwalacze → role → dane (pełne polecenia w `README.md`).

## 9. Dokumentacja użytkowa (prosta)

Typowe operacje z poziomu SQL (jako rola `rental_agent` lub `rental_admin`):

```sql
-- 1. Dodanie najemcy
INSERT INTO najemcy (imie, nazwisko, email, telefon)
VALUES ('Adam', 'Nowak', 'adam.nowak@example.com', '601234567');

-- 2. Wystawienie ogłoszenia dla mieszkania o id = 2
INSERT INTO ogloszenia (mieszkanie_id, tytul, cena_miesieczna)
VALUES (2, 'Słoneczne 2 pokoje', 2500.00);

-- 3. Sprawdzenie, czy mieszkanie jest wolne w okresie
SELECT czy_mieszkanie_wolne(2, '2025-07-01', '2026-06-30');

-- 4. Zawarcie umowy (wyzwalacze automatycznie: rezerwują ogłoszenie
--    i tworzą wpis historii)
INSERT INTO umowy_najmu (ogloszenie_id, najemca_id, data_poczatku, data_konca, czynsz, kaucja)
VALUES (2, 1, '2025-07-01', '2026-06-30', 2500.00, 2500.00);

-- 5. Naliczenie i zaksięgowanie płatności
SELECT nalicz_platnosc(<umowa_id>, '2025-07-01');
CALL zarejestruj_platnosc(<umowa_id>, '2025-07-01');

-- 6. Podgląd salda i dostępnych mieszkań
SELECT * FROM v_saldo_umow;
SELECT * FROM v_dostepne_mieszkania;

-- 7. Zakończenie umowy (zamyka umowę, historię i zwalnia ogłoszenie)
CALL zakoncz_umowe(<umowa_id>, 'zakończenie najmu', CURRENT_DATE);
```
