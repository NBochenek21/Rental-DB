-- =============================================================
-- SEKCJA 3 — Transakcje i poziomy izolacji
-- =============================================================
-- Wymóg na ocenę 4.5. Plik pokazuje:
--  (a) transakcję jako jednostkę pracy,
--  (b) różne poziomy izolacji,
--  (c) scenariusz, w którym poziom izolacji ma znaczenie.
--
-- W PostgreSQL dostępne poziomy: READ COMMITTED (domyślny),
-- REPEATABLE READ, SERIALIZABLE. (READ UNCOMMITTED działa jak
-- READ COMMITTED — Postgres nie pozwala na brudne odczyty.)

-- -------------------------------------------------------------
-- PRZYKŁAD 1: Atomowe podpisanie umowy + naliczenie płatności
-- Albo wszystko, albo nic. Gdyby naliczenie płatności się nie
-- powiodło, umowa również nie zostanie zapisana.
-- -------------------------------------------------------------
BEGIN;
    INSERT INTO umowy_najmu (ogloszenie_id, najemca_id, data_poczatku, data_konca, czynsz, kaucja)
    VALUES (2, 2, '2025-04-01', '2026-03-31', 2200.00, 2200.00);

    -- naliczenie pierwszej płatności dla właśnie utworzonej umowy
    INSERT INTO platnosci (umowa_id, okres, kwota, status)
    VALUES (currval(pg_get_serial_sequence('umowy_najmu','id')), '2025-04-01', 2200.00, 'oczekujaca');
COMMIT;
-- W razie błędu w którejkolwiek instrukcji: ROLLBACK przywróci stan sprzed BEGIN.

-- -------------------------------------------------------------
-- PRZYKŁAD 2: READ COMMITTED (domyślny) — rejestracja płatności
-- Procedura zarejestruj_platnosc używa SELECT ... FOR UPDATE,
-- więc wiersz płatności jest zablokowany do końca transakcji.
-- -------------------------------------------------------------
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
    CALL zarejestruj_platnosc(1, '2025-02-01');
COMMIT;

-- -------------------------------------------------------------
-- PRZYKŁAD 3: SERIALIZABLE — ochrona przed zjawiskami współbieżnymi
-- Scenariusz: dwie sesje próbują policzyć i naliczyć płatność za
-- ten sam okres. Na SERIALIZABLE jedna z transakcji zostanie
-- wycofana z błędem serializacji (SQLSTATE 40001) i należy ją
-- ponowić. To pokazuje znaczenie poziomu izolacji.
--
-- Aby zademonstrować na żywo, otwórz DWIE sesje psql i wykonaj
-- naprzemiennie kroki [S1]/[S2]:
--
--   [S1] BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--   [S2] BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--   [S1] SELECT COUNT(*) FROM platnosci WHERE umowa_id=1 AND okres='2025-05-01';
--   [S2] SELECT COUNT(*) FROM platnosci WHERE umowa_id=1 AND okres='2025-05-01';
--   [S1] INSERT INTO platnosci(umowa_id,okres,kwota,status)
--            VALUES (1,'2025-05-01',2800,'oczekujaca');
--   [S2] INSERT INTO platnosci(umowa_id,okres,kwota,status)
--            VALUES (1,'2025-05-01',2800,'oczekujaca');
--   [S1] COMMIT;   -- przejdzie
--   [S2] COMMIT;   -- błąd 40001 (could not serialize access) -> ponów transakcję
--
-- Dodatkowo chroni nas UNIQUE(umowa_id, okres) — nawet bez
-- SERIALIZABLE druga wstawka dostanie błąd unikalności. Oba
-- mechanizmy warto opisać w dokumentacji jako komplementarne.

-- -------------------------------------------------------------
-- PRZYKŁAD 4: REPEATABLE READ — spójny raport
-- W obrębie transakcji wszystkie odczyty widzą ten sam snapshot,
-- nawet jeśli ktoś równolegle zmienia dane.
-- -------------------------------------------------------------
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    SELECT * FROM v_saldo_umow WHERE umowa_id = 1;
    -- ... inne odczyty w tym samym, niezmiennym widoku danych ...
COMMIT;
