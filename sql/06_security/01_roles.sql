-- =============================================================
-- SEKCJA 4 — Bezpieczeństwo: role i uprawnienia
-- =============================================================
-- Wymóg na ocenę 4.5. Model oparty na zasadzie najmniejszych
-- uprawnień: każda rola dostaje dokładnie tyle praw, ile wynika
-- z jej zadań (patrz analiza wymagań, p. 2 — aktorzy).
--
-- UWAGA: hasła poniżej są przykładowe (placeholdery). W realnym
-- wdrożeniu należy ustawić bezpieczne hasła i NIE trzymać ich
-- w repozytorium.

-- ---- Usunięcie ról przy ponownym uruchomieniu --------------------
-- Najpierw odbieramy prawa, potem usuwamy (rola z nadaniami nie da się DROP).
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rental_readonly') THEN
        EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM rental_readonly';
        EXECUTE 'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rental_readonly';
        EXECUTE 'REVOKE ALL ON SCHEMA public FROM rental_readonly';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rental_agent') THEN
        EXECUTE 'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rental_agent';
        EXECUTE 'REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM rental_agent';
        EXECUTE 'REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM rental_agent';
        EXECUTE 'REVOKE ALL ON ALL PROCEDURES IN SCHEMA public FROM rental_agent';
        EXECUTE 'REVOKE ALL ON SCHEMA public FROM rental_agent';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rental_admin') THEN
        EXECUTE 'REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rental_admin';
        EXECUTE 'REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM rental_admin';
        EXECUTE 'REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM rental_admin';
        EXECUTE 'REVOKE ALL ON ALL PROCEDURES IN SCHEMA public FROM rental_admin';
        EXECUTE 'REVOKE ALL ON SCHEMA public FROM rental_admin';
    END IF;
END $$;

DROP ROLE IF EXISTS rental_admin;
DROP ROLE IF EXISTS rental_agent;
DROP ROLE IF EXISTS rental_readonly;

-- ---- Role logowania ----------------------------------------------
CREATE ROLE rental_admin    LOGIN PASSWORD 'zmien_mnie_admin';
CREATE ROLE rental_agent    LOGIN PASSWORD 'zmien_mnie_agent';
CREATE ROLE rental_readonly LOGIN PASSWORD 'zmien_mnie_ro';

-- Każda rola musi mieć dostęp do schematu, by w ogóle widzieć obiekty.
GRANT USAGE ON SCHEMA public TO rental_admin, rental_agent, rental_readonly;

-- ==================================================================
-- ADMIN — pełne prawa do danych (DML + DDL na obiektach schematu)
-- ==================================================================
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO rental_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rental_admin;
GRANT EXECUTE ON ALL FUNCTIONS        IN SCHEMA public TO rental_admin;
GRANT EXECUTE ON ALL PROCEDURES       IN SCHEMA public TO rental_admin;

-- ==================================================================
-- AGENT — obsługa codzienna: odczyt i modyfikacja danych operacyjnych,
-- bez prawa usuwania (DELETE) i bez zmian struktury (DDL).
-- ==================================================================
GRANT SELECT, INSERT, UPDATE ON
    najemcy, wlasciciele, mieszkania, ogloszenia,
    umowy_najmu, platnosci, historia_najmu
TO rental_agent;

-- Sekwencje IDENTITY potrzebne do INSERT-ów.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rental_agent;

-- Wykonywanie logiki biznesowej.
GRANT EXECUTE ON FUNCTION
    czy_mieszkanie_wolne(BIGINT, DATE, DATE),
    saldo_umowy(BIGINT),
    nalicz_platnosc(BIGINT, DATE)
TO rental_agent;
GRANT EXECUTE ON PROCEDURE
    zarejestruj_platnosc(BIGINT, DATE, DATE),
    oznacz_zaleglosci(DATE),
    zakoncz_umowe(BIGINT, VARCHAR, DATE)
TO rental_agent;

-- Świadomie NIE nadajemy DELETE — usuwanie rekordów to operacja
-- nieodwracalna, zarezerwowana dla administratora.
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM rental_agent;

-- ==================================================================
-- READONLY — wyłącznie odczyt (raporty, podgląd właściciela).
-- ==================================================================
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rental_readonly;

-- Ochrona danych wrażliwych: readonly NIE widzi numeru PESEL.
-- Odbieramy SELECT na całej tabeli i nadajemy tylko na wybranych kolumnach.
REVOKE SELECT ON najemcy FROM rental_readonly;
GRANT  SELECT (id, imie, nazwisko, email, telefon, utworzono, zmodyfikowano)
       ON najemcy TO rental_readonly;

-- readonly korzysta z widoków raportowych.
GRANT SELECT ON
    v_dostepne_mieszkania, v_saldo_umow, v_najemcy_zalegli,
    v_aktywne_umowy, v_przychod_miesieczny, v_oblozenie_mieszkan
TO rental_readonly;

-- ---- Domyślne uprawnienia dla przyszłych obiektów ----------------
-- Nowe tabele tworzone przez właściciela schematu automatycznie
-- dostaną SELECT dla readonly (wygoda utrzymania).
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO rental_readonly;
