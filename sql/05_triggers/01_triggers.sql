-- =============================================================
-- SEKCJA 3 — Wyzwalacze (triggers)
-- =============================================================

-- -------------------------------------------------------------
-- 1) Automatyczna aktualizacja kolumny 'zmodyfikowano' (RB-11)
--    Jedna funkcja używana przez wiele tabel.
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_set_zmodyfikowano()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.zmodyfikowano := now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER t_najemcy_mod      BEFORE UPDATE ON najemcy
    FOR EACH ROW EXECUTE FUNCTION trg_set_zmodyfikowano();
CREATE OR REPLACE TRIGGER t_wlasciciele_mod  BEFORE UPDATE ON wlasciciele
    FOR EACH ROW EXECUTE FUNCTION trg_set_zmodyfikowano();
CREATE OR REPLACE TRIGGER t_mieszkania_mod   BEFORE UPDATE ON mieszkania
    FOR EACH ROW EXECUTE FUNCTION trg_set_zmodyfikowano();
CREATE OR REPLACE TRIGGER t_ogloszenia_mod   BEFORE UPDATE ON ogloszenia
    FOR EACH ROW EXECUTE FUNCTION trg_set_zmodyfikowano();
CREATE OR REPLACE TRIGGER t_umowy_mod        BEFORE UPDATE ON umowy_najmu
    FOR EACH ROW EXECUTE FUNCTION trg_set_zmodyfikowano();
CREATE OR REPLACE TRIGGER t_platnosci_mod    BEFORE UPDATE ON platnosci
    FOR EACH ROW EXECUTE FUNCTION trg_set_zmodyfikowano();

-- -------------------------------------------------------------
-- 2) Walidacja: brak nakładających się aktywnych umów (RB-2)
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_waliduj_umowe()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_mieszkanie_id BIGINT;
    v_kolizje INT;
BEGIN
    SELECT mieszkanie_id INTO v_mieszkanie_id
    FROM   ogloszenia WHERE id = NEW.ogloszenie_id;

    IF NEW.status = 'aktywna' THEN
        SELECT COUNT(*) INTO v_kolizje
        FROM   umowy_najmu u
        JOIN   ogloszenia  o ON o.id = u.ogloszenie_id
        WHERE  o.mieszkanie_id = v_mieszkanie_id
          AND  u.status = 'aktywna'
          AND  u.id <> COALESCE(NEW.id, -1)
          AND  u.data_poczatku <= NEW.data_konca
          AND  u.data_konca   >= NEW.data_poczatku;

        IF v_kolizje > 0 THEN
            RAISE EXCEPTION
              'Mieszkanie ma już aktywną umowę nakładającą się na okres % – %',
              NEW.data_poczatku, NEW.data_konca;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER t_umowy_walidacja
    BEFORE INSERT OR UPDATE ON umowy_najmu
    FOR EACH ROW EXECUTE FUNCTION trg_waliduj_umowe();

-- -------------------------------------------------------------
-- 3) Po zawarciu aktywnej umowy ogłoszenie -> 'zarezerwowane' (RB-3)
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_status_ogloszenia()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'aktywna' THEN
        UPDATE ogloszenia
        SET    status = 'zarezerwowane'
        WHERE  id = NEW.ogloszenie_id
          AND  status = 'aktywne';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER t_ogloszenie_po_umowie
    AFTER INSERT ON umowy_najmu
    FOR EACH ROW EXECUTE FUNCTION trg_status_ogloszenia();

-- -------------------------------------------------------------
-- 4) Automatyczny wpis do historii najmu przy zawarciu umowy
--    Tworzy otwarty wpis (data_do = NULL), który procedura
--    zakoncz_umowe później domyka. Spójność danych historycznych.
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_historia_przy_umowie()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_mieszkanie_id BIGINT;
BEGIN
    SELECT mieszkanie_id INTO v_mieszkanie_id
    FROM   ogloszenia WHERE id = NEW.ogloszenie_id;

    INSERT INTO historia_najmu (umowa_id, najemca_id, mieszkanie_id, data_od)
    VALUES (NEW.id, NEW.najemca_id, v_mieszkanie_id, NEW.data_poczatku);

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER t_historia_po_umowie
    AFTER INSERT ON umowy_najmu
    FOR EACH ROW EXECUTE FUNCTION trg_historia_przy_umowie();
