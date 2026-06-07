# Analiza wymagań — System Obsługi Wynajmu Mieszkań

> SEKCJA 1. Ten dokument jest punktem wyjścia dla całego projektu. Reguły biznesowe stąd są implementowane jako więzy integralności, funkcje i wyzwalacze w sekcjach 2–3.

## 1. Cel i zakres systemu

System wspiera kompleksowe zarządzanie procesem wynajmu mieszkań — od momentu wystawienia oferty, przez zawarcie umowy, aż po rozliczenia finansowe i archiwizację zakończonych najmów. Odbiorcą jest niewielkie biuro pośrednictwa lub zarządca prywatnych nieruchomości, który obsługuje wiele mieszkań należących do różnych właścicieli i potrzebuje jednego, spójnego źródła prawdy o stanie każdego z nich.

Główny problem, który system rozwiązuje, to rozproszenie informacji: dane o ogłoszeniach, umowach i płatnościach prowadzone osobno (np. w arkuszach) szybko się rozjeżdżają — trudno stwierdzić, które mieszkanie jest faktycznie wolne, kto zalega z czynszem i jaka jest historia danego najemcy. System centralizuje te dane i pilnuje ich spójności za pomocą reguł wymuszanych na poziomie bazy.

Zakres obejmuje: ewidencję właścicieli, mieszkań i najemców; publikację ogłoszeń; zawieranie i ewidencję umów najmu; naliczanie oraz rejestrację miesięcznych płatności; śledzenie zaległości; prowadzenie historii najmu. Poza zakresem pozostają: obsługa płatności online, komunikacja z najemcami (powiadomienia), moduł rezerwacji oraz integracje zewnętrzne — system odpowiada wyłącznie za warstwę danych.

## 2. Aktorzy

| Aktor | Opis | Przykładowe operacje |
|-------|------|----------------------|
| Najemca | Osoba wynajmująca mieszkanie. W systemie reprezentowana profilem, nie loguje się bezpośrednio. | jest stroną umowy, dokonuje płatności (rejestrowanych przez agenta) |
| Właściciel | Właściciel jednego lub wielu mieszkań, w imieniu którego działa biuro. | powierza mieszkania, odbiera podgląd rozliczeń |
| Agent / operator | Pracownik biura obsługujący system na co dzień. Główny użytkownik. | rejestruje najemców i mieszkania, wystawia ogłoszenia, zawiera umowy, księguje płatności |
| Administrator | Osoba odpowiedzialna za system i poprawność danych. | pełen dostęp, korekty błędnych zapisów, usuwanie, zarządzanie strukturą |

Mapowanie aktorów na role bazodanowe (sekcja 4): agent → `rental_agent`, administrator → `rental_admin`, podgląd właściciela/raporty → `rental_readonly`.

## 3. Wymagania funkcjonalne

| ID | Wymaganie | Aktor |
|----|-----------|-------|
| WF-1 | System umożliwia rejestrację i edycję profilu najemcy (dane osobowe, kontakt, PESEL). | agent |
| WF-2 | System umożliwia rejestrację właściciela oraz powiązanych z nim mieszkań. | agent |
| WF-3 | System umożliwia wystawienie ogłoszenia dla mieszkania wraz z ceną miesięczną i opisem. | agent |
| WF-4 | System umożliwia zawarcie umowy najmu powiązanej z ogłoszeniem i najemcą, z określeniem okresu, czynszu i kaucji. | agent |
| WF-5 | Po zawarciu aktywnej umowy system automatycznie oznacza powiązane ogłoszenie jako niedostępne (zarezerwowane). | system |
| WF-6 | System nalicza miesięczne płatności dla aktywnej umowy i pozwala zarejestrować ich opłacenie. | agent / system |
| WF-7 | System rozróżnia status płatności (oczekująca, opłacona, zaległa) i pozwala wskazać należności przeterminowane. | agent |
| WF-8 | System udostępnia listę aktualnie dostępnych mieszkań (ogłoszenia aktywne). | wszyscy |
| WF-9 | System wylicza saldo umowy — kwotę pozostałą do zapłaty. | agent |
| WF-10 | System wskazuje najemców posiadających zaległości. | agent |
| WF-11 | System prowadzi historię najmu (kto, gdzie, w jakim okresie, z jakiego powodu zakończono). | system |
| WF-12 | System pozwala sprawdzić, czy dane mieszkanie jest wolne w zadanym przedziale dat. | agent |

## 4. Wymagania niefunkcjonalne

| ID | Wymaganie |
|----|-----------|
| WNF-1 | **Integralność danych** — niespójne stany (np. umowa bez najemcy, płatność bez umowy) są niemożliwe dzięki więzom kluczy obcych. |
| WNF-2 | **Spójność reguł biznesowych** — reguły są egzekwowane w bazie (CHECK, UNIQUE, wyzwalacze), a nie wyłącznie w aplikacji, więc obowiązują niezależnie od kanału dostępu. |
| WNF-3 | **Bezpieczeństwo** — rozdział uprawnień przez role wg zasady najmniejszych przywilejów; usuwanie danych zarezerwowane dla administratora. |
| WNF-4 | **Atomowość operacji** — operacje wielokrokowe (np. zawarcie umowy wraz z naliczeniem płatności) wykonywane w transakcji: albo w całości, albo wcale. |
| WNF-5 | **Odporność na współbieżność** — równoległe operacje na tych samych danych (np. dwie próby zaksięgowania tej samej płatności) nie prowadzą do błędnych stanów, dzięki odpowiednim poziomom izolacji i blokadom. |
| WNF-6 | **Precyzja finansowa** — kwoty przechowywane jako `NUMERIC`, nigdy jako typy zmiennoprzecinkowe, aby uniknąć błędów zaokrągleń. |
| WNF-7 | **Audytowalność** — każdy rekord zawiera znaczniki `utworzono`/`zmodyfikowano` aktualizowane automatycznie. |

## 5. Reguły biznesowe (kluczowe dla sekcji 2–3)

To jest najważniejsza część dla implementacji. Każda reguła ma wskazane miejsce egzekwowania w bazie.

| ID | Reguła | Mechanizm | Plik |
|----|--------|-----------|------|
| RB-1 | Data końca umowy musi być późniejsza niż data początku. | CHECK `ch_umowy_daty` | `02_constraints` |
| RB-2 | Mieszkanie nie może mieć dwóch nakładających się czasowo aktywnych umów. | wyzwalacz `t_umowy_walidacja` | `05_triggers` |
| RB-3 | Po zawarciu aktywnej umowy ogłoszenie zmienia status z „aktywne" na „zarezerwowane". | wyzwalacz `t_ogloszenie_po_umowie` | `05_triggers` |
| RB-4 | Dla danej umowy może istnieć tylko jedna płatność za dany miesiąc (okres). | UNIQUE `uq_platnosc_okres` | `02_constraints` |
| RB-5 | Kwoty czynszu, kaucji i płatności nie mogą być ujemne. | CHECK | `02_constraints` |
| RB-6 | Powierzchnia mieszkania i liczba pokoi muszą być dodatnie. | CHECK `ch_mieszkania_*` | `02_constraints` |
| RB-7 | Status ogłoszenia może przyjmować wyłącznie wartości: aktywne / zarezerwowane / zakończone. | CHECK `ch_ogloszenia_status` | `02_constraints` |
| RB-8 | Status umowy może przyjmować wyłącznie wartości: aktywna / zakończona / rozwiązana. | CHECK `ch_umowy_status` | `02_constraints` |
| RB-9 | Status płatności może przyjmować wyłącznie: oczekująca / opłacona / zaległa. | CHECK `ch_platnosci_status` | `02_constraints` |
| RB-10 | Adres e-mail najemcy oraz właściciela jest unikalny. | UNIQUE | `02_constraints` |
| RB-11 | Znacznik `zmodyfikowano` jest aktualizowany automatycznie przy każdej zmianie rekordu. | wyzwalacz `t_*_mod` | `05_triggers` |
| RB-12 | Rejestracja płatności blokuje wiersz na czas transakcji, by uniknąć podwójnego zaksięgowania. | `SELECT ... FOR UPDATE` w procedurze `zarejestruj_platnosc` | `04_functions` |

Zależność dla sekcji 3: reguły RB-2, RB-3, RB-11 to wyzwalacze; RB-12 to logika proceduralna; pozostałe to deklaratywne więzy z sekcji 2.

## 6. Słownik pojęć

- **Właściciel** — osoba posiadająca tytuł prawny do mieszkania, powierzająca je biuru do wynajmu.
- **Mieszkanie** — konkretna nieruchomość (adres, powierzchnia, liczba pokoi) przypisana do właściciela.
- **Ogłoszenie** — oferta wynajmu konkretnego mieszkania z ceną miesięczną; ma status określający dostępność.
- **Najemca** — osoba wynajmująca mieszkanie, będąca stroną umowy.
- **Umowa najmu** — wiążące porozumienie między najemcą a właścicielem na określony okres, z ustalonym czynszem i kaucją.
- **Czynsz** — miesięczna opłata za najem ustalona w umowie.
- **Kaucja** — zwrotne zabezpieczenie wpłacane przy zawarciu umowy.
- **Płatność** — miesięczna należność powiązana z umową, dotycząca konkretnego okresu (miesiąca).
- **Okres (płatności)** — miesiąc, którego dotyczy dana płatność (reprezentowany pierwszym dniem miesiąca).
- **Saldo umowy** — suma kwot nieopłaconych (oczekujących i zaległych) dla danej umowy.
- **Zaległość** — płatność o statusie „zaległa", tj. nieopłacona po terminie.
- **Historia najmu** — rejestr trwających i zakończonych najmów wraz z powodem zakończenia.

## 7. Lista encji (wejście dla sekcji 2)

Siedem encji wynikających z analizy: **najemcy**, **wlasciciele**, **mieszkania**, **ogloszenia**, **umowy_najmu**, **platnosci**, **historia_najmu**.

Zależności między encjami (relacje):
- właściciel **posiada** wiele mieszkań (1:N),
- mieszkanie **ma** wiele ogłoszeń w czasie (1:N),
- ogłoszenie **dotyczy** wielu umów w czasie (1:N),
- najemca **zawiera** wiele umów (1:N),
- umowa **generuje** wiele płatności (1:N),
- umowa, najemca i mieszkanie **są rejestrowane** w historii najmu (1:N).

Szczegółowe atrybuty, typy i diagram ERD: patrz `docs/02_projekt.md`. Wiążący kontrakt nazw tabel i kolumn: `docs/SEKCJE.md`.
