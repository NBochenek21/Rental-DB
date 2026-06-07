# Dokumentacja techniczna — System Obsługi Wynajmu Mieszkań

> SEKCJA 4. Spaja całość: architektura, opis obiektów bazy, model bezpieczeństwa, instrukcja uruchomienia.

## 1. Architektura i technologia

- SZBD: PostgreSQL (14+).
- Język proceduralny: PL/pgSQL.
- Organizacja kodu: katalog `sql/` z numerowanymi etapami (schemat → więzy → widoki → funkcje → wyzwalacze → bezpieczeństwo → dane).

## 2. Schemat bazy danych

Diagram ERD: patrz `docs/02_projekt.md` (sekcja 1). _(Skopiuj tu finalny diagram lub odwołaj się do niego.)_

### Tabele

_(do uzupełnienia — dla każdej tabeli: przeznaczenie, kluczowe kolumny, relacje)_

| Tabela | Przeznaczenie |
|--------|---------------|
| najemcy | profile najemców |
| wlasciciele | właściciele mieszkań |
| mieszkania | nieruchomości |
| ogloszenia | oferty najmu |
| umowy_najmu | zawarte umowy |
| platnosci | miesięczne należności |
| historia_najmu | rejestr najmów |

## 3. Widoki

_(opisz: `v_dostepne_mieszkania`, `v_saldo_umow`, `v_najemcy_zalegli` — co zwracają i do czego służą)_

## 4. Funkcje i procedury

| Obiekt | Typ | Opis |
|--------|-----|------|
| `czy_mieszkanie_wolne` | funkcja | sprawdza dostępność mieszkania w okresie |
| `saldo_umowy` | funkcja | zwraca kwotę pozostałą do zapłaty |
| `zarejestruj_platnosc` | procedura | księguje płatność jako opłaconą |

## 5. Wyzwalacze

| Wyzwalacz | Tabela | Działanie |
|-----------|--------|-----------|
| `t_*_mod` | wiele | automatyczna aktualizacja `zmodyfikowano` |
| `t_umowy_walidacja` | umowy_najmu | blokuje nakładające się aktywne umowy |
| `t_ogloszenie_po_umowie` | umowy_najmu | zmienia status ogłoszenia na „zarezerwowane" |

## 6. Model bezpieczeństwa (role i uprawnienia)

Plik: `sql/06_security/01_roles.sql`. Zasada najmniejszych uprawnień.

| Rola | Uprawnienia | Zastosowanie |
|------|-------------|--------------|
| `rental_admin` | pełne (DML + DDL na danych) | administracja, korekty |
| `rental_agent` | SELECT/INSERT/UPDATE, brak DELETE, EXECUTE wybranych procedur | obsługa codzienna |
| `rental_readonly` | tylko SELECT (tabele + widoki) | raporty, podgląd |

_(opisz logikę nadań i dlaczego agent nie ma DELETE itd.)_

## 7. Transakcje i poziomy izolacji

Plik: `sql/08_queries/02_transactions.sql`. _(opisz: które operacje są transakcyjne, jakie poziomy izolacji zastosowano i dlaczego — w szczególności scenariusz SERIALIZABLE)_

## 8. Instrukcja uruchomienia

```bash
./scripts/setup.sh        # tworzy bazę rental_db i ładuje wszystko
```

lub ręcznie — kolejność w `README.md`.

## 9. Dokumentacja użytkowa (prosta)

_(krótko, dla użytkownika końcowego operującego przez SQL: jak dodać najemcę, wystawić ogłoszenie, zawrzeć umowę, zaksięgować płatność — z 2–3 przykładowymi poleceniami)_
