-- 1. Obrisati organizacijsku jedinicu s nazivom 'Zavod za primijenjenu fiziku' 
-- Prije toga, kao dio operacije brisanja ciljne n-torke, vrijednosti stranih 
-- ključeva u pozivajućim n-torkama postaviti na NULL vrijednost
UPDATE nastavnik 
SET sifOrgjed = NULL 
WHERE sifOrgjed = 
(
  SELECT sifOrgjed FROM orgjed 
  WHERE nazOrgjed = 'Zavod za primijenjenu fiziku'
);
UPDATE pred 
SET sifOrgjed = NULL 
WHERE sifOrgjed = 
(
  SELECT sifOrgjed FROM orgjed 
  WHERE orgjed = 'Zavod za primijenjenu fiziku'
);
CREATE TEMPORARY TABLE orgjedTemp AS SELECT * FROM orgjed;
UPDATE orgjed SET sifNadOrgjed = NULL 
WHERE sifNadOrgjed = 
(
  SELECT sifOrgjed FROM orgjedTemp 
  WHERE nazOrgjed = 'Zavod za primijenjenu fiziku'
);
DELETE FROM orgjed WHERE nazOrgjed = 'Zavod za primijenjenu fiziku';

-- 2. Nastavniku čije prezime počinje slovom J i ime počinje slovom D postaviti 
-- vrijednost poštanskog broja stanovanja na NULL vrijednost
UPDATE nastavnik 
SET pbrStan = NULL 
WHERE SUBSTRING(prezNastavnik, 1, 1) = 'J' AND
SUBSTRING(imeNastavnik, 1, 1) = 'D';

-- 3. Ispisati broj nastavnika kojima ili poštanski broj stanovanja ili šifra 
-- organizacijske jedinice ima NULL vrijednost
SELECT COUNT(*) FROM nastavnik 
WHERE sifOrgjed IS NULL OR pbrStan IS NULL;

-- 4. a) Ispisati broj predmeta koji pripadaju organizacijskoj jedinici čija JE 
-- šifra 100002
SELECT COUNT(*) FROM pred WHERE sifOrgjed = 100002;
-- b) Ispisati broj predmeta koji pripadaju organizacijskoj jedinici čija NIJE 
-- šifra 100002
SELECT COUNT(*) FROM pred WHERE sifOrgjed <> 100002;
-- c) Ispisati ukupni broj predmeta. Zašto a) + b) nije jednako c)?
SELECT COUNT(*) FROM pred;
SELECT COUNT(*) FROM pred WHERE sifOrgjed IS NULL;
-- a + b <> c zato sto je iz b iskljuceno 12 zapisa sa sifOrgjed = NULL

-- 5. Ispisati sve podatke o predmetima kojima vrijednost šifre organizacijske 
-- jedinice nije NULL vrijednost
SELECT * FROM pred WHERE sifOrgjed IS NOT NULL;

-- 6. Ispisati sve podatke o predmetima kojima je vrijednost šifre 
-- organizacijske jedinice NULL vrijednost
SELECT * FROM pred WHERE sifOrgjed IS NULL;

-- 7. Ispisati broj predmeta kojima vrijednost šifre organizacijske jedinice 
-- nije NULL vrijednost
SELECT COUNT(*) FROM pred WHERE sifOrgjed IS NOT NULL;

-- 8. Ispisati broj različitih organizacijskih jedinica u kojima su zaposleni 
-- nastavnici
SELECT COUNT(DISTINCT sifOrgjed) FROM nastavnik;

-- 9. Za svaku kombinaciju tjednog broja sati i šifre organizacijske jedinice 
-- koja postoji u relaciji pred, ispisati broj sati tjedno, šifru 
-- organizacijske jedinice i pripadajući broj predmeta
SELECT DISTINCT brojSatiTjedno, sifOrgjed, COUNT(sifPred) FROM pred 
GROPUP BY 1, 2;

-- 10. Ispisati sve podatke studenata koji stanuju u mjestima u kojima nije 
-- rođen niti jedan student.
SELECT (*) FROM stud WHERE pbrStan NOT IN 
(
  SELECT pbrRod FROM stud 
  WHERE pbrRod IS NOT NULL;
)

-- 11. Za svakog nastavnika ispisati šifru, prezime i ime nastavnika, te šifru 
-- i naziv organizacijske jedinice u kojoj je zaposlen. Nastavnicima kojima je 
-- šifra organizacijske jedinice NULL vrijednost, kao naziv organizacijske 
-- jedinice ispisati tekst NULL.
SELECT sifNastavnik, prezNastavnik, imeNastavnik, nastavnik.sifOrgjed, 
IF(nastavnik.sifOrgjed IS NULL, 'NULL', nazOrgjed) AS nazOrgjed FROM nastavnik 
LEFT OUTER JOIN orgjed ON nastavnik.sifOrgjed = orgjed.sifOrgjed;

-- 12. Za svakog nastavnika ispisati šifru, prezime i ime nastavnika, te šifru, 
-- naziv organizacijske jedinice u kojoj je zaposlen, naziv nadređene 
-- organizacijske jedinice. Poznato je da se kao vrijednosti šifri 
-- organizacijskih jedinica pojavljuju NULL vrijednosti, te da se kao 
-- vrijednosti šifri nadređenih organizacijskih jedinica ne mogu pojaviti NULL
-- vrijednosti. Šta bi trebalo promijeniti u upitu kad bi postojale 
-- organizacijske jedinice kojima šifra nadređene organizacijske jedinice nije 
-- upisana?
SELECT sifNastavnik, prezNastavnik, imeNastavnik, o.sifOrgjed, o.nazOrgjed, 
n.nazOrgjed FROM nastavnik 
LEFT OUTER JOIN (orgjed AS o INNER JOIN n ON o.sifNadOrgjed = n.sifOrgjed)
ON nastavnik.sifOrgjed = o.sifOrgjed;

-- 13. Za svakog nastavnika ispisati šifru, prezime i ime nastavnika, poštanski 
-- broj i naziv mjesta stanovanja, šifru i naziv organizacijske jedinice. Zapise 
-- poredati po nazivu mjesta stanovanja, a unutar toga po prezimenu nastavnika
SELECT sifNastavnik, prezNastavnik, imeNastavnik, pbrStan, nazMjesto, 
nastavnik.sifOrgjed, nazOrgjed FROM nastavnik 
LEFT OUTER JOIN mjesto ON nastavnik.pbrStan = mjesto.pbr
LEFT OUTER JOIN orgjed ON nastavnik.sifOrgjed = orgjed.sifOrgjed 
ORDER BY 5, 2;

-- 14. Za svakog nastavnika ispisati šifru, prezime i ime nastavnika, poštanski 
-- broj i naziv mjesta stanovanja i naziv županije stanovanja
SELECT sifNastavnik, prezNastavnik, imeNastavnik, pbrStan, mjesto.nazMjesto, 
nazZupanija FROM nastavnik 
LEFT OUTER JOIN (mjesto INNER JOIN zupanija ON mjesto.sifZupanija = 
zupanija.sifZupanija) ON pbrStan = mjesto.pbr;

-- 15. Za svaki predmet čiji naziv počinje slovom F ispisati kraticu i naziv 
-- predmeta, šifru i naziv organizacijske jedinice
SELECT kratPred, nazPred, pred.sifOrgjed, nazOrgjed FROM pred 
LEFT OUTER JOIN orgjed ON pred.sifOrgjed = orgjed.sifOrgjed 
WHERE SUBSTRING(nazPred, 1, 1) = 'F';

-- 16. Vanjski spojiti relacije predmet i orgjed (predmet je dominantna, orgjed 
-- podređena relacija). Selektirati samo one predmete za koje naziv 
-- organizacijske jedinice počinje slovom Z. Ispisati kraticu i naziv predmeta, 
-- šifru i naziv organizacijske jedinice.
SELECT kratPred, nazPred, pred.sifOrgjed, nazOrgjed FROM pred 
LEFT OUTER JOIN orgjed ON pred.sifOrgjed = orgjed.sifOrgjed 
WHERE SUBSTRING(nazOrgjed, 1, 1) = 'Z' OR nazOrgjed IS NULL;
