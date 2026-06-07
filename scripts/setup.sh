# Podział pracy na sekcje

Cztery sekcje wg obszarów prac. Każda osoba prowadzi swoją sekcję w Claude Code na osobnym branchu. Ten dokument to **kontrakt** — jeśli wszyscy trzymają się nazw tabel i kolumn opisanych niżej, sekcje połączą się bez konfliktów.

## Kolejność i zależności

```
SEKCJA 1 (analiza) ──> SEKCJA 2 (schemat) ──> SEKCJA 3 (implementacja)
                                          └──> SEKCJA 4 (bezpieczeństwo + dokumentacja)
```

- Sekcja 1 nie zależy od nikogo — startuje pierwsza, ustala encje i reguły biznesowe.
- Sekcja 2 bierze encje z sekcji 1 i tworzy fizyczny schemat. **To ona "zamraża" nazwy tabel/kolumn.**
- Sekcje 3 i 4 budują na gotowym schemacie. Mogą pracować równolegle po skończeniu sekcji 2.
- Dopóki schemat nie jest gotowy, sekcje 3 i 4 pracują na **kontrakcie nazw** opisanym w `docs/02_projekt.md` (model logiczny) — patrz sekcja "Model danych — kontrakt" niżej.

---

## SEKCJA 1 — Analiza wymagań

**Osoba:** _________
**Branch:** `sekcja-1`
**Pliki:** `docs/01_analiza_wymagan.md`

Zadania:
1. Opis dziedziny i celu systemu (wynajem mieszkań).
2. Lista aktorów (najemca, wynajmujący/właściciel, administrator).
3. Wymagania funkcjonalne — co system musi robić (np. „rejestracja ogłoszenia", „podpisanie umowy", „rejestracja płatności", „naliczanie zaległości").
4. Wymagania niefunkcjonalne (spójność danych, bezpieczeństwo, integralność).
5. Reguły biznesowe — to jest kluczowe dla sekcji 3 (wyzwalacze/funkcje), np.:
   - mieszkanie z aktywną umową nie może mieć drugiej aktywnej umowy,
   - data końca umowy musi być późniejsza niż data początku,
   - płatność nie może przekroczyć kwoty należnej za okres,
   - status ogłoszenia zmienia się automatycznie po podpisaniu umowy.
6. Słownik pojęć.
7. Wstępna lista encji (wejście dla sekcji 2).

Deliverable: kompletny `docs/01_analiza_wymagan.md`.

---

## SEKCJA 2 — Projekt logiczny i fizyczny

**Osoba:** _________
**Branch:** `sekcja-2`
**Pliki:** `docs/02_projekt.md`, `sql/01_schema/01_tables.sql`, `sql/02_constraints/01_constraints.sql`

Zadania:
1. Model konceptualny → logiczny → fizyczny.
2. Diagram ERD (zob. `docs/02_projekt.md` — jest tam gotowy diagram w Mermaid do edycji).
3. **Normalizacja do 3NF** — udokumentuj, że każda tabela spełnia 1NF, 2NF, 3NF. To wymóg na 4.5, musi być opisane wprost.
4. Implementacja tabel w `sql/01_schema/01_tables.sql` (szkielet już jest — uzupełnij/popraw wg analizy).
5. Więzy integralności w `sql/02_constraints/01_constraints.sql` (FK, CHECK, UNIQUE).
6. Indeksy na kluczach obcych (dla poprawności i czytelności — nie mylić z optymalizacją na 5.0).

Deliverable: działający `psql -f` dla obu plików + opis 3NF w dokumencie.

---

## SEKCJA 3 — Implementacja

**Osoba:** _________
**Branch:** `sekcja-3`
**Pliki:** `sql/03_views/`, `sql/04_functions/`, `sql/05_triggers/`, `sql/08_queries/`

Zadania:
1. **Widoki** (`03_views/`) — min. 2–3, w tym jeden z agregacją i jeden z podzapytaniem. Szkielet jest.
2. **Funkcje/procedury PL/pgSQL** (`04_functions/`) — np. `zarejestruj_platnosc(...)`, `saldo_umowy(...)`, `czy_mieszkanie_wolne(...)`. Szkielet jest.
3. **Wyzwalacze** (`05_triggers/`) — np. automatyczne `zmodyfikowano`, walidacja nakładających się umów, automatyczna zmiana statusu ogłoszenia. Szkielet jest.
4. **Zaawansowane zapytania** (`08_queries/`) — zapytania zagnieżdżone, JOIN-y, agregacje.
5. **Transakcje + poziomy izolacji** (`08_queries/02_transactions.sql`) — wymóg na 4.5. Pokaż użycie `BEGIN; ... COMMIT;`, `SET TRANSACTION ISOLATION LEVEL ...` (min. `READ COMMITTED` i `SERIALIZABLE`), oraz scenariusz, gdzie izolacja ma znaczenie (np. dwie równoległe płatności). Szkielet z komentarzami jest.

Deliverable: wszystkie pliki ładują się i działają na schemacie z sekcji 2.

---

## SEKCJA 4 — Dokumentacja techniczna + bezpieczeństwo

**Osoba:** _________
**Branch:** `sekcja-4`
**Pliki:** `docs/03_dokumentacja_techniczna.md`, `sql/06_security/01_roles.sql`

Zadania:
1. **Role i uprawnienia** (`06_security/`) — wymóg na 4.5:
   - role: `rental_admin`, `rental_agent`, `rental_readonly` (przykład),
   - `GRANT`/`REVOKE` na tabelach i widokach,
   - zasada najmniejszych uprawnień (np. readonly tylko `SELECT`).
   Szkielet jest.
2. **Dokumentacja techniczna** (`docs/03_dokumentacja_techniczna.md`):
   - opis architektury i schematu,
   - opis każdej tabeli, widoku, funkcji, wyzwalacza,
   - opis modelu bezpieczeństwa (role),
   - instrukcja uruchomienia,
   - diagram ERD (przeniesiony/zsynchronizowany z sekcją 2).
3. Dokumentacja użytkowa (prosta) — jak korzystać z systemu z poziomu SQL.

Deliverable: kompletny dokument techniczny + działający plik ról.

---

## Model danych — kontrakt (nazwy tabel i kolumn)

Te nazwy są wiążące dla wszystkich sekcji. Zmiana = uzgodnienie z całym zespołem.

- **najemcy** (`id`, `imie`, `nazwisko`, `email`, `telefon`, `pesel`, `utworzono`, `zmodyfikowano`)
- **wlasciciele** (`id`, `imie`, `nazwisko`, `email`, `telefon`, `utworzono`, `zmodyfikowano`)
- **mieszkania** (`id`, `wlasciciel_id` → wlasciciele, `adres`, `miasto`, `kod_pocztowy`, `powierzchnia`, `liczba_pokoi`, `pietro`, `utworzono`, `zmodyfikowano`)
- **ogloszenia** (`id`, `mieszkanie_id` → mieszkania, `tytul`, `opis`, `cena_miesieczna`, `status` [aktywne/zarezerwowane/zakonczone], `data_publikacji`, `utworzono`, `zmodyfikowano`)
- **umowy_najmu** (`id`, `ogloszenie_id` → ogloszenia, `najemca_id` → najemcy, `data_poczatku`, `data_konca`, `czynsz`, `kaucja`, `status` [aktywna/zakonczona/rozwiazana], `utworzono`, `zmodyfikowano`)
- **platnosci** (`id`, `umowa_id` → umowy_najmu, `okres` [DATE — pierwszy dzień miesiąca], `kwota`, `data_platnosci`, `status` [oczekujaca/oplacona/zalegla], `utworzono`, `zmodyfikowano`)
- **historia_najmu** (`id`, `umowa_id` → umowy_najmu, `najemca_id` → najemcy, `mieszkanie_id` → mieszkania, `data_od`, `data_do`, `powod_zakonczenia`, `utworzono`)

Diagram i pełne typy: `docs/02_projekt.md`. Fizyczna definicja: `sql/01_schema/01_tables.sql`.
