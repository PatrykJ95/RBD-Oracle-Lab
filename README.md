# RBD-Oracle-Lab

Laboratorium z przedmiotu **Rozproszone Bazy Danych** — Oracle 19c.

## Środowisko

Zadanie wykonane lokalnie na Oracle Database 19c (Windows).  
Ponieważ dostępna była jedna instancja `ORCL`, rozproszenie zasymulowano przez **dwa schematy**:

| Schema | Odpowiednik | Opis |
|--------|-------------|------|
| `SIEDZIBA` | baza11a | Baza główna / siedziba |
| `FILIA` | baza11b | Baza zdalna / filia |

- Klient: Oracle SQL Developer
- Usługi Windows: `OracleServiceORCL`, `OracleOraDB19Home1TNSListener`
- Hasło obu użytkowników: `start123`

---

## Krok 1 — Utworzenie użytkowników (jako SYS/SYSDBA)

```sql
ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;

CREATE USER siedziba IDENTIFIED BY start123;
CREATE USER filia IDENTIFIED BY start123;

GRANT CONNECT, RESOURCE TO siedziba;
GRANT CONNECT, RESOURCE TO filia;
GRANT CREATE DATABASE LINK TO siedziba;
GRANT CREATE SYNONYM TO siedziba;
GRANT CREATE VIEW TO siedziba;
GRANT CREATE MATERIALIZED VIEW TO siedziba;

ALTER USER siedziba QUOTA UNLIMITED ON USERS;
ALTER USER filia QUOTA UNLIMITED ON USERS;
```

---

## Krok 2 — Załadowanie danych

- Do schematu `SIEDZIBA` załadowano skrypt `_kursySiedziba.sql`  
  Tabele: `WYKLADOWCY`, `KURSANCI`, `RODZAJE`, `KURSY`, `UMOWY`

- Do schematu `FILIA` załadowano skrypt `_kursyFilia.sql`  
  Tabele: `WYKLADOWCY`, `KURSANCI`, `RODZAJE`, `KURSY`

---

## Krok 3 — Database Link (jako SIEDZIBA)

```sql
CREATE DATABASE LINK dblinkFilia
CONNECT TO filia
IDENTIFIED BY start123
USING 'ORCL';
```

> **Uwaga:** Po załadowaniu danych do FILIA konieczne było wykonanie `COMMIT` w sesji FILIA,  
> aby dane były widoczne przez database link (zapytanie zwracało 0 bez COMMIT).

Test: `SELECT COUNT(*) FROM kursanci@dblinkFilia;` → **81 rekordów**

---

## Krok 4 — Synonimy (jako SIEDZIBA)

```sql
-- Synonimy dla tabel lokalnych (siedziba)
CREATE SYNONYM kursanciSiedziba FOR kursanci;
CREATE SYNONYM wykladowcySiedziba FOR wykladowcy;
CREATE SYNONYM rodzajeSiedziba FOR rodzaje;
CREATE SYNONYM kursySiedziba FOR kursy;

-- Synonimy dla tabel zdalnych (filia przez database link)
CREATE SYNONYM kursanciFilia FOR kursanci@dblinkFilia;
CREATE SYNONYM wykladowcyFilia FOR wykladowcy@dblinkFilia;
CREATE SYNONYM rodzajeFilia FOR rodzaje@dblinkFilia;
CREATE SYNONYM kursyFilia FOR kursy@dblinkFilia;
```

Wyniki testów:

| Synonim | COUNT(*) |
|---------|----------|
| kursanciSiedziba | 85 |
| kursanciFilia | 81 |

---

## Krok 5 — Widoki łączące dane z obu baz (jako SIEDZIBA)

```sql
CREATE VIEW kursanciAll AS
SELECT imie, nazwisko FROM kursanciSiedziba
UNION
SELECT imie, nazwisko FROM kursanciFilia;

CREATE VIEW wykladowcyAll AS
SELECT imie, nazwisko FROM wykladowcySiedziba
UNION
SELECT imie, nazwisko FROM wykladowcyFilia;

CREATE VIEW kursyAll AS
SELECT kurs_id, rodzaj_id, wykladowca_id FROM kursySiedziba
UNION
SELECT kurs_id, rodzaj_id, wykladowca_id FROM kursyFilia;
```

Wyniki testów:

| Widok | COUNT(*) |
|-------|----------|
| kursanciAll | 166 |
| wykladowcyAll | 33 |
| kursyAll | 15 |

---

## Krok 6 — Migawki / Materialized Views (jako SIEDZIBA)

### mv_wykladowcy_all — odświeżanie ręczne (ON DEMAND)
```sql
CREATE MATERIALIZED VIEW mv_wykladowcy_all
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS SELECT * FROM wykladowcyAll;
```
Ręczne odświeżenie: `EXECUTE DBMS_MVIEW.REFRESH('MV_WYKLADOWCY_ALL', 'C');`

### mv_kursy_all — odświeżanie automatyczne co godzinę
```sql
CREATE MATERIALIZED VIEW mv_kursy_all
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH SYSDATE
NEXT SYSDATE + 1/24
AS SELECT * FROM kursyAll;
```

### mv_kursanci_all — odświeżanie automatyczne co 7 dni
```sql
CREATE MATERIALIZED VIEW mv_kursanci_all
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH SYSDATE
NEXT SYSDATE + 7
AS SELECT * FROM kursanciAll;
```

Wyniki testów migawek:

| Migawka | COUNT(*) | Odświeżanie |
|---------|----------|-------------|
| mv_wykladowcy_all | 33 | ręczne (ON DEMAND) |
| mv_kursy_all | 15 | co godzinę (SYSDATE + 1/24) |
| mv_kursanci_all | 166 | co 7 dni (SYSDATE + 7) |

Sprawdzenie harmonogramu:
```sql
SELECT name, last_refresh, refresh_method, next
FROM user_snapshots;
```

---

## Struktura repozytorium

```
RBD-Oracle-Lab/
├── README.md
└── sql/
    └── oracle_rbd_lab.sql   -- wszystkie skrypty (użytkownicy, link, synonimy, widoki, migawki, testy)
```

---

## Uwagi

- Projekt wykonany lokalnie na jednej instancji Oracle (`ORCL`).  
  Rozproszenie zasymulowano przez dwa schematy (`SIEDZIBA` / `FILIA`) i database link między nimi.
- W środowisku uczelnianym używane są fizycznie oddzielne bazy `baza11a` i `baza11b`.
