-- =============================================================
-- SEKCJA 2 — Więzy integralności i indeksy
-- =============================================================
-- Oddzielone od definicji tabel dla czytelności. Uruchamiać PO
-- 01_schema/01_tables.sql.

-- ---- Klucze obce -------------------------------------------------
ALTER TABLE mieszkania
    ADD CONSTRAINT fk_mieszkania_wlasciciel
    FOREIGN KEY (wlasciciel_id) REFERENCES wlasciciele(id);

ALTER TABLE ogloszenia
    ADD CONSTRAINT fk_ogloszenia_mieszkanie
    FOREIGN KEY (mieszkanie_id) REFERENCES mieszkania(id);

ALTER TABLE umowy_najmu
    ADD CONSTRAINT fk_umowy_ogloszenie
    FOREIGN KEY (ogloszenie_id) REFERENCES ogloszenia(id);

ALTER TABLE umowy_najmu
    ADD CONSTRAINT fk_umowy_najemca
    FOREIGN KEY (najemca_id) REFERENCES najemcy(id);

ALTER TABLE platnosci
    ADD CONSTRAINT fk_platnosci_umowa
    FOREIGN KEY (umowa_id) REFERENCES umowy_najmu(id);

ALTER TABLE historia_najmu
    ADD CONSTRAINT fk_historia_umowa
    FOREIGN KEY (umowa_id) REFERENCES umowy_najmu(id);
ALTER TABLE historia_najmu
    ADD CONSTRAINT fk_historia_najemca
    FOREIGN KEY (najemca_id) REFERENCES najemcy(id);
ALTER TABLE historia_najmu
    ADD CONSTRAINT fk_historia_mieszkanie
    FOREIGN KEY (mieszkanie_id) REFERENCES mieszkania(id);

-- ---- Unikalność --------------------------------------------------
ALTER TABLE najemcy      ADD CONSTRAINT uq_najemcy_email      UNIQUE (email);
ALTER TABLE wlasciciele  ADD CONSTRAINT uq_wlasciciele_email  UNIQUE (email);
-- jedna płatność na umowę za dany okres miesięczny
ALTER TABLE platnosci    ADD CONSTRAINT uq_platnosc_okres     UNIQUE (umowa_id, okres);

-- ---- Reguły CHECK ------------------------------------------------
ALTER TABLE mieszkania
    ADD CONSTRAINT ch_mieszkania_powierzchnia CHECK (powierzchnia > 0),
    ADD CONSTRAINT ch_mieszkania_pokoje       CHECK (liczba_pokoi > 0);

ALTER TABLE ogloszenia
    ADD CONSTRAINT ch_ogloszenia_cena   CHECK (cena_miesieczna >= 0),
    ADD CONSTRAINT ch_ogloszenia_status CHECK (status IN ('aktywne','zarezerwowane','zakonczone'));

ALTER TABLE umowy_najmu
    ADD CONSTRAINT ch_umowy_daty   CHECK (data_konca > data_poczatku),
    ADD CONSTRAINT ch_umowy_czynsz CHECK (czynsz >= 0),
    ADD CONSTRAINT ch_umowy_kaucja CHECK (kaucja >= 0),
    ADD CONSTRAINT ch_umowy_status CHECK (status IN ('aktywna','zakonczona','rozwiazana'));

ALTER TABLE platnosci
    ADD CONSTRAINT ch_platnosci_kwota  CHECK (kwota >= 0),
    ADD CONSTRAINT ch_platnosci_status CHECK (status IN ('oczekujaca','oplacona','zalegla'));

-- ---- Indeksy na kluczach obcych ----------------------------------
-- (poprawność/czytelność; zaawansowana optymalizacja = poziom 5.0, poza zakresem)
CREATE INDEX idx_mieszkania_wlasciciel ON mieszkania(wlasciciel_id);
CREATE INDEX idx_ogloszenia_mieszkanie ON ogloszenia(mieszkanie_id);
CREATE INDEX idx_umowy_ogloszenie      ON umowy_najmu(ogloszenie_id);
CREATE INDEX idx_umowy_najemca         ON umowy_najmu(najemca_id);
CREATE INDEX idx_platnosci_umowa       ON platnosci(umowa_id);
CREATE INDEX idx_historia_umowa        ON historia_najmu(umowa_id);
