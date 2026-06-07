# System Obsługi Wynajmu Mieszkań — projekt z baz danych

System bazodanowy obsługujący wynajem mieszkań: ogłoszenia, umowy, płatności, historię najmu i profile najemców.

- **SZBD:** PostgreSQL (zalecane 14+)
- **Cel oceny:** 4.5 (3NF, transakcje + poziomy izolacji, bezpieczeństwo: role i uprawnienia)
- **Zespół:** 4 osoby, podział wg obszarów prac

---

## Zakres na ocenę 4.5

Projekt celowo realizuje wymagania **do poziomu 4.5 włącznie**:

| Poziom | Wymaganie | Status w projekcie |
|--------|-----------|--------------------|
| 3.0 | Podstawowe funkcjonalności, 2NF, prosta dokumentacja | ✅ |
| 3.5–4.0 | Zaawansowane zapytania (zagnieżdżone, widoki), wyzwalacze + procedury/funkcje (PL/pgSQL), ERD | ✅ |
| 4.5 | **3NF**, **transakcje + poziomy izolacji**, **role i uprawnienia** | ✅ |
| 5.0 | EXPLAIN/optymalizacja, studium przypadku, prezentacja | ❌ poza zakresem (świadomie) |

---

## Podział pracy — 4 sekcje wg obszarów

Każda osoba pracuje w swoim katalogu/obszarze. Szczegóły zadań w `docs/SEKCJE.md`.

| Sekcja | Obszar | Osoba | Główne pliki |
|--------|--------|-------|--------------|
| **1** | Analiza wymagań | Wspólnie | `docs/01_analiza_wymagan.md` |
| **2** | Projekt logiczny i fizyczny (ERD + schemat + 3NF) | Jakub + Norbert | `docs/02_projekt.md`, `sql/01_schema/`, `sql/02_constraints/` |
| **3** | Implementacja (widoki, funkcje, wyzwalacze, transakcje, zapytania) | Kacper + Mati | `sql/03_views/`, `sql/04_functions/`, `sql/05_triggers/`, `sql/08_queries/` |
| **4** | Dokumentacja techniczna + bezpieczeństwo (role/uprawnienia) | Wspólnie | `docs/03_dokumentacja_techniczna.md`, `sql/06_security/` |

> Sekcje 2, 3 i 4 zależą od siebie w tej kolejności. Sekcja 1 jest punktem wyjścia dla wszystkich. Zob. `docs/SEKCJE.md` po opis zależności i kontrakt między sekcjami (nazwy tabel/kolumn).

---

## Struktura repozytorium

```
rental-db/
├── README.md                  # ten plik
├── docs/
│   ├── SEKCJE.md              # szczegółowy podział pracy + zależności
│   ├── 01_analiza_wymagan.md  # SEKCJA 1
│   ├── 02_projekt.md          # SEKCJA 2 (ERD, model logiczny, 3NF)
│   └── 03_dokumentacja_techniczna.md  # SEKCJA 4
├── sql/
│   ├── 01_schema/            # tabele (SEKCJA 2)
│   ├── 02_constraints/       # klucze obce, CHECK, UNIQUE (SEKCJA 2)
│   ├── 03_views/             # widoki (SEKCJA 3)
│   ├── 04_functions/         # funkcje i procedury PL/pgSQL (SEKCJA 3)
│   ├── 05_triggers/          # wyzwalacze (SEKCJA 3)
│   ├── 06_security/          # role i uprawnienia (SEKCJA 4)
│   ├── 07_seed/              # dane testowe (wspólne)
│   └── 08_queries/           # przykładowe zapytania + transakcje (SEKCJA 3)
└── scripts/
    ├── setup.sh              # tworzy bazę i uruchamia wszystko po kolei
    └── reset.sh              # usuwa i odtwarza bazę
```

---

## Uruchomienie

Wymagany działający PostgreSQL i `psql` w PATH.

```bash
# pełna instalacja od zera (tworzy bazę 'rental_db' i ładuje wszystko)
./scripts/setup.sh

# wyczyszczenie i ponowne utworzenie
./scripts/reset.sh
```

Ręcznie, plik po pliku, w kolejności:

```bash
createdb rental_db
psql -d rental_db -f sql/01_schema/01_tables.sql
psql -d rental_db -f sql/02_constraints/01_constraints.sql
psql -d rental_db -f sql/03_views/01_views.sql
psql -d rental_db -f sql/04_functions/01_functions.sql
psql -d rental_db -f sql/05_triggers/01_triggers.sql
psql -d rental_db -f sql/06_security/01_roles.sql
psql -d rental_db -f sql/07_seed/01_seed.sql
```

---

## Konwencje (obowiązują wszystkich)

- Nazwy tabel: liczba mnoga, snake_case (`ogloszenia`, `umowy_najmu`).
- Klucze główne: `id` typu `BIGINT GENERATED ALWAYS AS IDENTITY`.
- Klucze obce: `<tabela_w_lp>_id` (np. `najemca_id`, `mieszkanie_id`).
- Znaczniki czasu: `utworzono`/`zmodyfikowano` typu `TIMESTAMPTZ`.
- Kwoty: `NUMERIC(12,2)`. Nigdy `FLOAT`/`REAL` dla pieniędzy.
- Każdy plik SQL zaczyna się komentarzem nagłówkowym: za co odpowiada, która sekcja.
- Praca na osobnych branchach `sekcja-1`, …, `sekcja-4`; merge przez PR.
