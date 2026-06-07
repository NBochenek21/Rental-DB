-- =============================================================
-- SEKCJA 3 — Zaawansowane zapytania (przykłady)
-- =============================================================
-- Materiał do dokumentacji i demonstracji. Techniki: podzapytania
-- (skorelowane i nie), CTE, funkcje okienkowe, NOT EXISTS, agregacje.

-- 1) Mieszkania bez żadnej umowy (NOT IN / podzapytanie)
SELECT m.id, m.adres, m.miasto
FROM   mieszkania m
WHERE  m.id NOT IN (
           SELECT o.mieszkanie_id
           FROM   ogloszenia o
           JOIN   umowy_najmu u ON u.ogloszenie_id = o.id
       );

-- 2) Ranking właścicieli wg liczby aktywnych umów (JOIN + agregacja + HAVING)
SELECT w.imie || ' ' || w.nazwisko AS wlasciciel,
       COUNT(u.id)                 AS liczba_aktywnych_umow
FROM   wlasciciele w
JOIN   mieszkania  m ON m.wlasciciel_id = w.id
JOIN   ogloszenia  o ON o.mieszkanie_id = m.id
JOIN   umowy_najmu u ON u.ogloszenie_id = o.id AND u.status = 'aktywna'
GROUP  BY w.id, w.imie, w.nazwisko
HAVING COUNT(u.id) > 0
ORDER  BY liczba_aktywnych_umow DESC;

-- 3) Najemcy z zaległą kwotą > 0 (funkcja w warunku)
SELECT n.imie, n.nazwisko, saldo_umowy(u.id) AS zaleglosc
FROM   najemcy n
JOIN   umowy_najmu u ON u.najemca_id = n.id
WHERE  saldo_umowy(u.id) > 0;

-- 4) Średni czynsz wg miasta (agregacja + grupowanie)
SELECT m.miasto, ROUND(AVG(o.cena_miesieczna), 2) AS sredni_czynsz
FROM   mieszkania m
JOIN   ogloszenia o ON o.mieszkanie_id = m.id
GROUP  BY m.miasto;

-- 5) CTE: mieszkania droższe niż średnia w swoim mieście (podzapytanie skorelowane)
WITH srednie AS (
    SELECT m.miasto, AVG(o.cena_miesieczna) AS srednia
    FROM   mieszkania m
    JOIN   ogloszenia o ON o.mieszkanie_id = m.id
    GROUP  BY m.miasto
)
SELECT m.adres, m.miasto, o.cena_miesieczna, ROUND(s.srednia, 2) AS srednia_miasta
FROM   mieszkania m
JOIN   ogloszenia o ON o.mieszkanie_id = m.id
JOIN   srednie    s ON s.miasto = m.miasto
WHERE  o.cena_miesieczna > s.srednia;

-- 6) Funkcja okienkowa: pozycja płatności w czasie dla każdej umowy
SELECT umowa_id,
       okres,
       kwota,
       status,
       ROW_NUMBER() OVER (PARTITION BY umowa_id ORDER BY okres) AS nr_platnosci,
       SUM(kwota)   OVER (PARTITION BY umowa_id ORDER BY okres) AS suma_narastajaco
FROM   platnosci
ORDER  BY umowa_id, okres;

-- 7) NOT EXISTS: najemcy bez żadnej zaległości
SELECT n.id, n.imie, n.nazwisko
FROM   najemcy n
WHERE  NOT EXISTS (
           SELECT 1
           FROM   umowy_najmu u
           JOIN   platnosci p ON p.umowa_id = u.id
           WHERE  u.najemca_id = n.id
             AND  p.status = 'zalegla'
       );

-- 8) Procent opłaconych płatności per umowa (agregacja warunkowa)
SELECT u.id AS umowa_id,
       COUNT(p.id) AS wszystkie,
       COUNT(p.id) FILTER (WHERE p.status = 'oplacona') AS oplacone,
       ROUND(100.0 * COUNT(p.id) FILTER (WHERE p.status = 'oplacona')
             / NULLIF(COUNT(p.id), 0), 1) AS procent_oplaconych
FROM   umowy_najmu u
LEFT JOIN platnosci p ON p.umowa_id = u.id
GROUP  BY u.id;
