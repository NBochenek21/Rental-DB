-- =============================================================
-- SEKCJA 3 — Widoki
-- =============================================================
-- Sześć widoków pokrywających typowe zapotrzebowania raportowe.
-- Wykorzystane techniki: JOIN, LEFT JOIN, agregacja, FILTER,
-- podzapytania skorelowane i nieskorelowane, CASE.

-- -------------------------------------------------------------
-- 1) Aktualnie dostępne mieszkania (ogłoszenia aktywne) — JOIN
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_dostepne_mieszkania AS
SELECT  o.id              AS ogloszenie_id,
        o.tytul,
        o.cena_miesieczna,
        m.adres,
        m.miasto,
        m.powierzchnia,
        m.liczba_pokoi,
        w.imie || ' ' || w.nazwisko AS wlasciciel
FROM    ogloszenia o
JOIN    mieszkania  m ON m.id = o.mieszkanie_id
JOIN    wlasciciele w ON w.id = m.wlasciciel_id
WHERE   o.status = 'aktywne';

-- -------------------------------------------------------------
-- 2) Saldo płatności per umowa — AGREGACJA + FILTER
--    Suma naliczona, opłacona i zaległa dla każdej umowy.
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_saldo_umow AS
SELECT  u.id AS umowa_id,
        n.imie || ' ' || n.nazwisko AS najemca,
        SUM(p.kwota)                                       AS suma_naliczona,
        SUM(p.kwota) FILTER (WHERE p.status = 'oplacona')  AS suma_oplacona,
        SUM(p.kwota) FILTER (WHERE p.status <> 'oplacona') AS suma_zalegla
FROM    umowy_najmu u
JOIN    najemcy   n ON n.id = u.najemca_id
LEFT JOIN platnosci p ON p.umowa_id = u.id
GROUP BY u.id, n.imie, n.nazwisko;

-- -------------------------------------------------------------
-- 3) Najemcy z zaległościami — PODZAPYTANIE
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_najemcy_zalegli AS
SELECT  n.id, n.imie, n.nazwisko, n.email
FROM    najemcy n
WHERE   n.id IN (
            SELECT u.najemca_id
            FROM   umowy_najmu u
            JOIN   platnosci p ON p.umowa_id = u.id
            WHERE  p.status = 'zalegla'
        );

-- -------------------------------------------------------------
-- 4) Aktywne umowy z pełnym kontekstem — wielokrotny JOIN
--    Łączy najemcę, mieszkanie i właściciela w jednym widoku.
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_aktywne_umowy AS
SELECT  u.id AS umowa_id,
        n.imie || ' ' || n.nazwisko AS najemca,
        m.adres,
        m.miasto,
        u.data_poczatku,
        u.data_konca,
        u.czynsz,
        (u.data_konca - CURRENT_DATE) AS dni_do_konca
FROM    umowy_najmu u
JOIN    najemcy    n ON n.id = u.najemca_id
JOIN    ogloszenia o ON o.id = u.ogloszenie_id
JOIN    mieszkania m ON m.id = o.mieszkanie_id
WHERE   u.status = 'aktywna';

-- -------------------------------------------------------------
-- 5) Przychód miesięczny z opłaconych płatności — AGREGACJA czasowa
--    Grupowanie po miesiącu (okresie) płatności.
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_przychod_miesieczny AS
SELECT  date_trunc('month', okres)::date AS miesiac,
        COUNT(*)      AS liczba_platnosci,
        SUM(kwota)    AS przychod
FROM    platnosci
WHERE   status = 'oplacona'
GROUP BY date_trunc('month', okres)
ORDER BY miesiac;

-- -------------------------------------------------------------
-- 6) Obłożenie mieszkań — CASE + podzapytanie skorelowane
--    Pokazuje, czy mieszkanie ma obecnie aktywną umowę.
-- -------------------------------------------------------------
CREATE OR REPLACE VIEW v_oblozenie_mieszkan AS
SELECT  m.id AS mieszkanie_id,
        m.adres,
        m.miasto,
        CASE WHEN EXISTS (
                 SELECT 1
                 FROM   umowy_najmu u
                 JOIN   ogloszenia o ON o.id = u.ogloszenie_id
                 WHERE  o.mieszkanie_id = m.id
                   AND  u.status = 'aktywna'
             ) THEN 'wynajete'
             ELSE 'wolne'
        END AS stan
FROM    mieszkania m;
