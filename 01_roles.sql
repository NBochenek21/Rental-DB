-- =============================================================
-- SEKCJA 2 — Projekt fizyczny: definicje tabel
-- System Obsługi Wynajmu Mieszkań (PostgreSQL)
-- =============================================================
-- Uwaga: kolejność tworzenia uwzględnia zależności kluczy obcych.
-- Więzy FK/CHECK/UNIQUE są w sql/02_constraints/01_constraints.sql,
-- żeby oddzielić strukturę od reguł integralności (możesz scalić,
-- jeśli zespół woli — to decyzja sekcji 2).

DROP TABLE IF EXISTS historia_najmu CASCADE;
DROP TABLE IF EXISTS platnosci      CASCADE;
DROP TABLE IF EXISTS umowy_najmu    CASCADE;
DROP TABLE IF EXISTS ogloszenia     CASCADE;
DROP TABLE IF EXISTS mieszkania     CASCADE;
DROP TABLE IF EXISTS wlasciciele    CASCADE;
DROP TABLE IF EXISTS najemcy        CASCADE;

-- -------------------------------------------------------------
-- Najemcy — profile osób wynajmujących
-- -------------------------------------------------------------
CREATE TABLE najemcy (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    imie         VARCHAR(60)  NOT NULL,
    nazwisko     VARCHAR(80)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    telefon      VARCHAR(20),
    pesel        CHAR(11),
    utworzono    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    zmodyfikowano TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Właściciele mieszkań
-- -------------------------------------------------------------
CREATE TABLE wlasciciele (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    imie         VARCHAR(60)  NOT NULL,
    nazwisko     VARCHAR(80)  NOT NULL,
    email        VARCHAR(120) NOT NULL,
    telefon      VARCHAR(20),
    utworzono    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    zmodyfikowano TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Mieszkania
-- -------------------------------------------------------------
CREATE TABLE mieszkania (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    wlasciciel_id BIGINT NOT NULL,
    adres         VARCHAR(200) NOT NULL,
    miasto        VARCHAR(80)  NOT NULL,
    kod_pocztowy  VARCHAR(10),
    powierzchnia  NUMERIC(6,2) NOT NULL,   -- m2
    liczba_pokoi  SMALLINT     NOT NULL,
    pietro        SMALLINT,
    utworzono     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    zmodyfikowano TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Ogłoszenia najmu
-- -------------------------------------------------------------
CREATE TABLE ogloszenia (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mieszkanie_id   BIGINT NOT NULL,
    tytul           VARCHAR(150) NOT NULL,
    opis            TEXT,
    cena_miesieczna NUMERIC(12,2) NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'aktywne',  -- aktywne|zarezerwowane|zakonczone
    data_publikacji DATE         NOT NULL DEFAULT CURRENT_DATE,
    utworzono       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    zmodyfikowano   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Umowy najmu
-- -------------------------------------------------------------
CREATE TABLE umowy_najmu (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ogloszenie_id BIGINT NOT NULL,
    najemca_id    BIGINT NOT NULL,
    data_poczatku DATE   NOT NULL,
    data_konca    DATE   NOT NULL,
    czynsz        NUMERIC(12,2) NOT NULL,
    kaucja        NUMERIC(12,2) NOT NULL DEFAULT 0,
    status        VARCHAR(20)   NOT NULL DEFAULT 'aktywna',  -- aktywna|zakonczona|rozwiazana
    utworzono     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    zmodyfikowano TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Płatności (miesięczne) powiązane z umową
-- -------------------------------------------------------------
CREATE TABLE platnosci (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    umowa_id      BIGINT NOT NULL,
    okres         DATE   NOT NULL,            -- pierwszy dzień miesiąca, którego dotyczy
    kwota         NUMERIC(12,2) NOT NULL,
    data_platnosci DATE,                      -- NULL = jeszcze nieopłacona
    status        VARCHAR(20) NOT NULL DEFAULT 'oczekujaca', -- oczekujaca|oplacona|zalegla
    utworzono     TIMESTAMPTZ NOT NULL DEFAULT now(),
    zmodyfikowano TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -------------------------------------------------------------
-- Historia najmu — wpis zamykany przy zakończeniu umowy
-- -------------------------------------------------------------
CREATE TABLE historia_najmu (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    umowa_id          BIGINT NOT NULL,
    najemca_id        BIGINT NOT NULL,
    mieszkanie_id     BIGINT NOT NULL,
    data_od           DATE   NOT NULL,
    data_do           DATE,
    powod_zakonczenia VARCHAR(200),
    utworzono         TIMESTAMPTZ NOT NULL DEFAULT now()
);
