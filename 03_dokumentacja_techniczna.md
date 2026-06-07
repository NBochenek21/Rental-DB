# Analiza wymagań — System Obsługi Wynajmu Mieszkań

> SEKCJA 1. Ten dokument jest punktem wyjścia dla całego projektu. Reguły biznesowe stąd są implementowane jako wyzwalacze/funkcje w sekcji 3.

## 1. Cel i zakres systemu

_(do uzupełnienia — 1–2 akapity: po co system, kogo obsługuje, jakie problemy rozwiązuje)_

System wspiera zarządzanie wynajmem mieszkań: prowadzenie bazy ogłoszeń, zawieranie i ewidencję umów najmu, rejestrację płatności, śledzenie zaległości oraz utrzymanie historii najmu i profili najemców.

## 2. Aktorzy

| Aktor | Opis | Przykładowe operacje |
|-------|------|----------------------|
| Najemca | Osoba wynajmująca mieszkanie | przeglądanie ogłoszeń, podpisanie umowy, opłacanie czynszu |
| Właściciel | Właściciel mieszkania | wystawianie ogłoszeń, podgląd płatności |
| Agent / operator | Obsługuje system na co dzień | rejestracja umów, księgowanie płatności |
| Administrator | Zarządza systemem i danymi | pełen dostęp, korekty, usuwanie |

## 3. Wymagania funkcjonalne

_(do uzupełnienia — lista WF-1, WF-2, …)_

- WF-1: System umożliwia rejestrację profilu najemcy.
- WF-2: System umożliwia wystawienie ogłoszenia dla mieszkania.
- WF-3: System umożliwia zawarcie umowy najmu powiązanej z ogłoszeniem i najemcą.
- WF-4: System nalicza i rejestruje miesięczne płatności.
- WF-5: System śledzi zaległości i status płatności.
- WF-6: System prowadzi historię najmu.
- _(dodaj kolejne)_

## 4. Wymagania niefunkcjonalne

- WNF-1: Spójność danych zapewniona więzami integralności i wyzwalaczami.
- WNF-2: Bezpieczeństwo — rozdział uprawnień przez role (admin/agent/readonly).
- WNF-3: Operacje wielokrokowe wykonywane transakcyjnie.
- _(dodaj kolejne)_

## 5. Reguły biznesowe (kluczowe dla sekcji 3)

| ID | Reguła | Gdzie egzekwowana |
|----|--------|-------------------|
| RB-1 | Data końca umowy musi być późniejsza niż data początku | CHECK `ch_umowy_daty` |
| RB-2 | Mieszkanie nie może mieć dwóch nakładających się aktywnych umów | wyzwalacz `t_umowy_walidacja` |
| RB-3 | Po zawarciu aktywnej umowy ogłoszenie zmienia status na „zarezerwowane" | wyzwalacz `t_ogloszenie_po_umowie` |
| RB-4 | Jedna płatność na umowę za dany miesiąc | UNIQUE `uq_platnosc_okres` |
| RB-5 | Kwoty (czynsz, kaucja, płatność) nie mogą być ujemne | CHECK |
| _(dodaj)_ | | |

## 6. Słownik pojęć

- **Ogłoszenie** — oferta wynajmu konkretnego mieszkania.
- **Umowa najmu** — wiążące porozumienie między najemcą a właścicielem na dany okres.
- **Płatność** — miesięczna należność powiązana z umową.
- **Historia najmu** — rejestr zakończonych (i trwających) najmów.
- _(dodaj)_

## 7. Lista encji (wejście dla sekcji 2)

najemcy, wlasciciele, mieszkania, ogloszenia, umowy_najmu, platnosci, historia_najmu.

Szczegółowe atrybuty i typy: patrz `docs/02_projekt.md` oraz `docs/SEKCJE.md` (kontrakt nazw).
