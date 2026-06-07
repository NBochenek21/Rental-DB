-- =============================================================
-- SEKCJA 3 — Funkcje i procedury (PL/pgSQL)
-- =============================================================
-- Funkcje (RETURNS) — obliczenia bez efektów ubocznych.
-- Procedury (CALL)   — operacje modyfikujące stan, często wieloetapowe.

-- -------------------------------------------------------------
-- 1) Czy mieszkanie jest wolne w zadanym okresie? (funkcja)
--    Reguła RB-2: brak nakładających się aktywnych umów.
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION czy_mieszkanie_wolne(
    p_mieszkanie_id BIGINT,
    p_od            DATE,
    p_do            DATE
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_kolizje INT;
BEGIN
    SELECT COUNT(*)
    INTO   v_kolizje
    FROM   umowy_najmu u
    JOIN   ogloszenia  o ON o.id = u.ogloszenie_id
    WHERE  o.mieszkanie_id = p_mieszkanie_id
      AND  u.status = 'aktywna'
      AND  u.data_poczatku <= p_do
      AND  u.data_konca   >= p_od;

    RETURN v_kolizje = 0;
END;
$$;

-- -------------------------------------------------------------
-- 2) Saldo umowy — kwota pozostała do zapłaty (funkcja)
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION saldo_umowy(p_umowa_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo NUMERIC(12,2);
BEGIN
    SELECT COALESCE(SUM(kwota) FILTER (WHERE status <> 'oplacona'), 0)
    INTO   v_saldo
    FROM   platnosci
    WHERE  umowa_id = p_umowa_id;

    RETURN v_saldo;
END;
$$;

-- -------------------------------------------------------------
-- 3) Rejestracja płatności jako opłaconej (procedura)
--    Reguła RB-12: blokada wiersza FOR UPDATE na czas transakcji.
-- -------------------------------------------------------------
CREATE OR REPLACE PROCEDURE zarejestruj_platnosc(
    p_umowa_id BIGINT,
    p_okres    DATE,
    p_data     DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id BIGINT;
BEGIN
    SELECT id INTO v_id
    FROM   platnosci
    WHERE  umowa_id = p_umowa_id AND okres = p_okres
    FOR UPDATE;

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'Brak naliczonej płatności dla umowy % za okres %',
            p_umowa_id, p_okres;
    END IF;

    UPDATE platnosci
    SET    status         = 'oplacona',
           data_platnosci = p_data,
           zmodyfikowano  = now()
    WHERE  id = v_id;
END;
$$;

-- -------------------------------------------------------------
-- 4) Naliczenie płatności za pojedynczy miesiąc (funkcja zwracająca id)
--    Tworzy rekord należności. UNIQUE(umowa_id, okres) chroni
--    przed duplikatem (RB-4). Kwota brana z czynszu umowy.
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION nalicz_platnosc(
    p_umowa_id BIGINT,
    p_okres    DATE
) RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_czynsz NUMERIC(12,2);
    v_id     BIGINT;
BEGIN
    SELECT czynsz INTO v_czynsz
    FROM   umowy_najmu WHERE id = p_umowa_id;

    IF v_czynsz IS NULL THEN
        RAISE EXCEPTION 'Umowa % nie istnieje', p_umowa_id;
    END IF;

    INSERT INTO platnosci (umowa_id, okres, kwota, status)
    VALUES (p_umowa_id, date_trunc('month', p_okres)::date, v_czynsz, 'oczekujaca')
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;

-- -------------------------------------------------------------
-- 5) Oznaczenie przeterminowanych płatności jako zaległych (procedura)
--    Wszystkie 'oczekujaca' z okresem starszym niż podana data
--    stają się 'zalegla'. Zwraca liczbę zmienionych przez RAISE NOTICE.
-- -------------------------------------------------------------
CREATE OR REPLACE PROCEDURE oznacz_zaleglosci(
    p_na_dzien DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_liczba INT;
BEGIN
    UPDATE platnosci
    SET    status = 'zalegla', zmodyfikowano = now()
    WHERE  status = 'oczekujaca'
      AND  okres < date_trunc('month', p_na_dzien)::date;

    GET DIAGNOSTICS v_liczba = ROW_COUNT;
    RAISE NOTICE 'Oznaczono % zaległych płatności', v_liczba;
END;
$$;

-- -------------------------------------------------------------
-- 6) Zakończenie umowy (procedura wieloetapowa)
--    Zmienia status umowy, domyka wpis historii i zwalnia ogłoszenie.
--    Cała operacja jako jedna transakcja (RB-3, spójność historii).
-- -------------------------------------------------------------
CREATE OR REPLACE PROCEDURE zakoncz_umowe(
    p_umowa_id BIGINT,
    p_powod    VARCHAR DEFAULT NULL,
    p_data     DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ogloszenie_id BIGINT;
BEGIN
    -- zmiana statusu umowy
    UPDATE umowy_najmu
    SET    status = 'zakonczona', zmodyfikowano = now()
    WHERE  id = p_umowa_id AND status = 'aktywna';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Umowa % nie istnieje lub nie jest aktywna', p_umowa_id;
    END IF;

    -- domknięcie wpisu historii
    UPDATE historia_najmu
    SET    data_do = p_data, powod_zakonczenia = p_powod
    WHERE  umowa_id = p_umowa_id AND data_do IS NULL;

    -- zwolnienie ogłoszenia
    SELECT ogloszenie_id INTO v_ogloszenie_id
    FROM   umowy_najmu WHERE id = p_umowa_id;

    UPDATE ogloszenia
    SET    status = 'zakonczone', zmodyfikowano = now()
    WHERE  id = v_ogloszenie_id;
END;
$$;
