CREATE TABLE wykladowcy(
wykladowca_id number(6) primary key,
imie varchar2(20) NOT NULL,   
nazwisko varchar2(30) NOT NULL,
stawka decimal(5,2)
);
CREATE TABLE kursanci(
kursant_id number(6) PRIMARY KEY,
imie varchar2(20) NOT NULL,
nazwisko varchar2(30) NOT NULL
);
CREATE TABLE rodzaje(
rodzaj_id number(3) primary key,
nazwa varchar2(30) NOT NULL,
godz number(3) NOT NULL,
cena decimal(6,2)
);
CREATE TABLE kursy(
kurs_id number(6)primary key,
rodzaj_id number(6) NOT NULL,
wykladowca_id number(6)
);
CREATE TABLE umowy(
umowa_id number(6) primary key,
kursant_id number(6),
kurs_id number(6),
miasto varchar(20)
);