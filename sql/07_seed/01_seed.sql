-- =============================================================
-- Dane testowe (seed) — wspólne
-- =============================================================
-- Minimalny zestaw pozwalający uruchomić widoki, funkcje i wyzwalacze.
-- Rozbuduj wedle potrzeb (sekcja 1 może dostarczyć realistyczne scenariusze).

INSERT INTO wlasciciele (imie, nazwisko, email, telefon) VALUES
    ('Anna',   'Kowalska', 'anna.kowalska@example.com', '600100200'),
    ('Marek',  'Nowak',    'marek.nowak@example.com',   '600300400');

INSERT INTO najemcy (imie, nazwisko, email, telefon, pesel) VALUES
    ('Jan',    'Wiśniewski', 'jan.wisniewski@example.com', '700100200', '90010112345'),
    ('Ewa',    'Lewandowska','ewa.lewandowska@example.com','700300400', '92050567890');

INSERT INTO mieszkania (wlasciciel_id, adres, miasto, kod_pocztowy, powierzchnia, liczba_pokoi, pietro) VALUES
    (1, 'ul. Kwiatowa 5/3', 'Kraków',   '30-001', 52.00, 2, 3),
    (2, 'ul. Długa 12/8',   'Warszawa', '00-238', 38.50, 1, 1);

INSERT INTO ogloszenia (mieszkanie_id, tytul, opis, cena_miesieczna) VALUES
    (1, 'Przytulne 2-pokojowe w centrum', 'Po remoncie, umeblowane.', 2800.00),
    (2, 'Kawalerka blisko metra',         'Idealna dla studenta.',     2200.00);

-- Umowa na mieszkanie 1 (wyzwalacz ustawi ogłoszenie 1 na 'zarezerwowane')
INSERT INTO umowy_najmu (ogloszenie_id, najemca_id, data_poczatku, data_konca, czynsz, kaucja) VALUES
    (1, 1, '2025-01-01', '2025-12-31', 2800.00, 2800.00);

-- Naliczone płatności za pierwsze miesiące
INSERT INTO platnosci (umowa_id, okres, kwota, status) VALUES
    (1, '2025-01-01', 2800.00, 'oplacona'),
    (1, '2025-02-01', 2800.00, 'zalegla'),
    (1, '2025-03-01', 2800.00, 'oczekujaca');

UPDATE platnosci SET data_platnosci = '2025-01-05'
WHERE umowa_id = 1 AND okres = '2025-01-01';

-- Uwaga: wpis do historia_najmu NIE jest tworzony ręcznie — powstaje
-- automatycznie przez wyzwalacz t_historia_po_umowie przy INSERT umowy.
