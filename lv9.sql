-- U svojoj bazi podataka kreirati dvije relacije koje opisuju diplomske ispite
CREATE TABLE diplom 
(
  mbrStud     INTEGER   NOT NULL,   -- Maticni broj studenta
  datPrijava  DATE      NOT NULL,   -- Datum prijave ispita
  sifMentor   INTEGER,              -- Mentor (nastavnik)
  ocjenaRad   SMALLINT,             -- Ocjena pismenog rada
  datObrana   DATE,                 -- Datum odbrane 
  ukupOcjena  SMALLINT,             -- Ukupna ocjena diplomskog ispita
  PRIMARY KEY (mbrStud, datPrijava), 
  FOREIGN KEY (mbrStud)     REFERENCES stud       (mbrStud), 
  FOREIGN KEY (sifMentor)   REFERENCES nastavnik  (sifNastavnik)
);

CREATE TABLE dipkom 
(
  mbrStud       INTEGER   NOT NULL,    
  datPrijava    DATE      NOT NULL,   -- Datum prijave
  sifNastavnik  INTEGER   NOT NULL, 
  oznUloga      CHAR(1),              -- Uloga clana komisije
  ocjenaUsm     SMALLINT,             -- Ocjena usmenog ispita
  PRIMARY KEY (mbrStud, datPrijava, sifNastavnik), 
  FOREIGN KEY (mbrStud, datPrijava)   REFERENCES diplom (mbrStud, datPrijava), 
  FOREIGN KEY (mbrStud)               REFERENCES stud (mbrStud), 
  FOREIGN KEY (sifNastavnik)          REFERENCES nastavnik (sifNastavnik)
);
-- Napuniti relacije podacima iz datoteka diplom.unl i dipkom.unl
-- RELACIJA diplom
-- Relacija sadrži podatke o studentovoj prijavi diplomskog ispita (datum 
-- prijave) i ostalim podacima vezanim za diplomski ispit (mentor, ocjene rada i 
-- usmenog dijela obrane, datum obrane). Za svakog studenta može postojati više 
-- zapisa o diplomskom ispitu (ali ne s istim datumom prijave). Mentor ocjenjuje 
-- pismeni dio rada. Ta se ocjena upisuje u ocjenaRad. Vrijednost za atribut 
-- ukupOcjena ovog trenutka nije upisana, ali će sadržavati ukupnu ocjenu 
-- dobivenu na diplomskom ispitu. Ta se ocjena izračunava prema posebnom 
-- algoritmu opisanom u nastavku.
-- RELACIJA dipkom
-- Za svaki diplomski ispit formira se komisija od tri ispitivača. Za svakog 
-- ispitivača unosi se u relaciju jedna n-torka. Komisija se sastoji od 
-- predsjednika i dva člana: predsjednik ima oznaku uloge (oznUloga) "P", 
-- članovi imaju oznaku uloge "C". Svaki ispitivač na usmenom ispitu daje svoju 
-- ocjenu koja se upisuje u ocjenaUsm.
-- NAČIN IZRAČUNAVANJA UKUPNE OCJENE DIPLOMSKOG ISPITA
-- • ukoliko je mentorova ocjena iz rada jednaka 1, ili je ocjena bilo kojeg 
-- ispitivača na usmenom dijelu ispita jednaka 1, ukupna ocjena je 1.
-- • ukoliko nisu upisane sve ocjene, te niti jedna od upisanih ocjena nije 
-- jednaka 1, ukupna ocjena je 0.
-- • u ostalim slučajevima ukupna ocjena obrane se izračunava tako da se 
-- cjelobrojno zaokruži prosjek svih dobivenih ocjena NA USMENOM DIJELU ISPITA 
-- (3 ocjene), što znači da se mentorova ocjena iz rada zanemaruje.

-- 1. Napisati pohranjenu proceduru orgjedNast koja za zadati matični broj 
-- nastavnika ispisuje informaciju o nastavniku u obliku
-- ime prezime: nazOrgjed, nazNadOrgjed.
-- Npr. EXECUTE PROCEDURE orgjedNast(244) ispisuje
-- Zlatko Tomašek: Zavod za primijenjenu matematiku, Fakultet elektrotehnike i 
-- računarstva
DELEMITER // 
CREATE FUNCTION orgjedNast (nastavnik INTEGER) 
  RETURNS NCHAR(175)
  BEGIN 
    DECLARE povrat NCHAR(175);
    SELECT CONCAT(imeNastavnik, ' ', prezNastavnik, ': ', 
    o.nazOrgjed, ', ', n.nazOrgjed) INTO povrat FROM nastavnik 
    INNER JOIN orgjed AS n ON o.sifNadorgjed = n.sifOrgjed 
    WHERE sifNastavnik = snastavnik;
  RETURN povrat;
END// 
SELECT orgjedNast (203);

-- 2. Napisati pohranjenu funkciju noviKoef koja za zadanu šifru nastavnika 
-- izračunava novi koeficijent za platu prema sljedećim pravilima:
-- • koeficijent se povećava za 10% ukoliko je broj pozitivno ocijenjenih 
-- ispita tog nastavnika veći od broja negativno ocijenjenih ispita istog 
-- nastavnika i ako je prosječna ocjena pozitivno ocjenjenih ispita veća od 
-- ukupne prosječne ocjene svih pozitivno ocijenjenih ispita
-- • koeficijent se umanjuje za 10% ukoliko je broj negativno ocjenjenih ispita 
-- tog nastavnika veći od broja pozitivno ocjenjenih ispita istog nastavnika i 
-- ako je prosječna ocjena pozitivno ocijenjenih ispita manja od ukupne 
-- prosječne ocjene svih pozitivno ocijenjenih ispita
-- • u suprotnom koeficijent ostaje isti
DELIMITER // 
CREATE FUNCTION noviKoef(sifNast INTEGER)
  RETURNS DECIMAL(3, 2)
  BEGIN
    DECLARE nkoef, procn, procu DECIMAL(3, 2)
    DECLARE brpoz, brneg INTEGER 
    SELECT koef INTO nkoef FROM nastavnik WHERE sifNastavnik = sifNast;
    SELECT COUNT(*), AVG(ocjena) INTO brpoz, procn FROM ispit 
    WHERE ocjena > 1 AND sifNastavnik = sifNast
    SELECT COUNT(*) INTO brneg FROM ispit 
    WHERE ocjena = 1 AND sifNastavnik = sifNast;
    SELECT AVG(ocjena) INTO procu FROM ispit WHERE ocjena > 1;
    if(brpoz > brneg AND procn > procu) THEN 
      SET nkoef = nkoef * 1.1;
    ELSEIF(brneg > brpoz AND procn < procu) THEN 
      SET nkoef = koef * 0.9;
    END IF;
    RETURN nkoef;
  END//

-- 3. Napisati pohranjenu proceduru ocjObrane sa sljedećim svojstvima:
-- • ulazni argumenti su matični broj studenta i datum prijave
-- • rezultat procedure je ukupna ocjena obrane (cijeli broj) izračunat prema 
-- gore opisanim pravilima, osim u slučaju da za zadane ulazne podatke (matični 
-- broj studenta i datum prijave) ne postoji prijava diplomskog ispita. U 
-- takvom slučaju rezultat procedure je NULL vrijednost.
-- Uputa: za zaokruživanje možete koristiti funkciju ROUND(broj, 0) ili 
-- ROUND(broj) koja obavlja zaokruživanje broja na cijeli broj
CREATE FUNCTION ocjObrane (mbrS INTEGER, datP DATE)
  RETURNS SMALLINT
  BEGIN
    DECLARE uocjena SMALLINT;
    IF NOT EXISTS (SELECT mbrStud FROM diplom 
    WHERE mbrStud = mbrS AND datPrijava = datp) THEN 
    SET uocjena = NULL;
  ELSE
    SELECT ocjenarod INTO uocjena FROM diplom 
    WHERE mbrStud = mbrS AND datPrijava = datp;
    IF uocjena IS NULL THEN 
      SET uocjena = 0;
    ELSEIF uocjena <> 1 THEN 
      IF(SELECT COUNT(*) FROM dipkom 
      WHERE mbrStud = mbrS AND datPrijava = datp AND ocjenaUsm = 1) > 0 THEN
      SET uocjena = 1;
    ELSEIF (SELECT COUNT(*) FROM dipkom 
    WHERE mbrStud = mbrS AND datPrijava = datp) < 3 THEN 
    SET uocjena = 0;
  ELSE 
    SELECT AVG(ocjenaUsm) INTO uocjena FROM dipkom 
    WHERE mbrStud = mbrS AND datPrijava = datp;
    SET uocjena = ROUND(uocjena, 0);
    END IF;
    END IF;
    END IF;
    RETURN uocjena;
    END//
