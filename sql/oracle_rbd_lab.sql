-- 01. Utworzenie użytkowników
-- Uruchamiane jako SYS / SYSDBA

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


-- 02. Łącznik bazodanowy
-- Uruchamiane jako SIEDZIBA

CREATE DATABASE LINK dblinkFilia
CONNECT TO filia
IDENTIFIED BY start123
USING 'ORCL';


-- 03. Synonimy
-- Uruchamiane jako SIEDZIBA

CREATE SYNONYM kursanciSiedziba FOR kursanci;
CREATE SYNONYM wykladowcySiedziba FOR wykladowcy;
CREATE SYNONYM rodzajeSiedziba FOR rodzaje;
CREATE SYNONYM kursySiedziba FOR kursy;

CREATE SYNONYM kursanciFilia FOR kursanci@dblinkFilia;
CREATE SYNONYM wykladowcyFilia FOR wykladowcy@dblinkFilia;
CREATE SYNONYM rodzajeFilia FOR rodzaje@dblinkFilia;
CREATE SYNONYM kursyFilia FOR kursy@dblinkFilia;


-- 04. Widoki łączące dane z siedziby i filii
-- Uruchamiane jako SIEDZIBA

CREATE VIEW kursanciAll AS
SELECT imie, nazwisko
FROM kursanciSiedziba
UNION
SELECT imie, nazwisko
FROM kursanciFilia;

CREATE VIEW wykladowcyAll AS
SELECT imie, nazwisko
FROM wykladowcySiedziba
UNION
SELECT imie, nazwisko
FROM wykladowcyFilia;

CREATE VIEW kursyAll AS
SELECT kurs_id, rodzaj_id, wykladowca_id
FROM kursySiedziba
UNION
SELECT kurs_id, rodzaj_id, wykladowca_id
FROM kursyFilia;


-- 05. Migawki / materialized views
-- Uruchamiane jako SIEDZIBA

CREATE MATERIALIZED VIEW mv_wykladowcy_all
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT *
FROM wykladowcyAll;

CREATE MATERIALIZED VIEW mv_kursy_all
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH SYSDATE
NEXT SYSDATE + 1/24
AS
SELECT *
FROM kursyAll;

CREATE MATERIALIZED VIEW mv_kursanci_all
BUILD IMMEDIATE
REFRESH COMPLETE
START WITH SYSDATE
NEXT SYSDATE + 7
AS
SELECT *
FROM kursanciAll;


-- 06. Testy działania

SELECT COUNT(*) FROM kursanciSiedziba;
SELECT COUNT(*) FROM kursanciFilia;

SELECT COUNT(*) FROM kursanciAll;
SELECT COUNT(*) FROM wykladowcyAll;
SELECT COUNT(*) FROM kursyAll;

SELECT COUNT(*) FROM mv_wykladowcy_all;
SELECT COUNT(*) FROM mv_kursy_all;
SELECT COUNT(*) FROM mv_kursanci_all;

EXECUTE DBMS_MVIEW.REFRESH('MV_WYKLADOWCY_ALL', 'C');

SELECT name, last_refresh, refresh_method, next
FROM user_snapshots;
