/*
KargoAnaliz - Veri genisletme scripti
Ne yapar:
  - 5 yeni sube ekler (toplam 10)
  - 200 yeni musteri ekler (toplam 208)
  - Her subeye 3 kurye + 1 sube personeli ekler
  - Her subeye 2 yeni arac ekler
  - 1500 yeni gonderi + teslimat + kargo hareketi uretir (2026-01-01 / 2026-10-15)
  - Subeler.PersonelSayisi degerini Personeller tablosundan yeniden hesaplar
Not:
  - Mevcut 20 gonderi silinmez, yeni kayitlar bunlarin uzerine eklenir.
  - Veriler rastgele uretilir (kurgusaldir). Script iki kez calistirilirsa
    ikinci seferde hicbir sey yapmaz.
  - Sube 3, 5 ve 9 bilerek daha cok gecikme uretir; analizde fark bulunabilsin diye.
Kullanim: SSMS'de ac, F5 ile calistir.
*/

USE KargoAnaliz;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF (SELECT COUNT(*) FROM dbo.Gonderiler) > 100
BEGIN
    PRINT N'Veritabani zaten genisletilmis. Islem yapilmadi.';
    RETURN;
END;

/* ---------- Yardimci isim listeleri ---------- */
DECLARE @Adlar TABLE (rn INT, Ad NVARCHAR(40));
INSERT @Adlar
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), v FROM (VALUES
 (N'Ahmet'),(N'Mehmet'),(N'Mustafa'),(N'Ali'),(N'Huseyin'),(N'Hasan'),(N'Ibrahim'),(N'Murat'),(N'Emre'),(N'Burak'),
 (N'Ayse'),(N'Fatma'),(N'Emine'),(N'Hatice'),(N'Zeynep'),(N'Elif'),(N'Merve'),(N'Esra'),(N'Derya'),(N'Seda'),
 (N'Can'),(N'Cem'),(N'Deniz'),(N'Kerem'),(N'Onur'),(N'Selin'),(N'Gizem'),(N'Berk'),(N'Ece'),(N'Tolga')
) t(v);

DECLARE @Soyadlar TABLE (rn INT, Soyad NVARCHAR(40));
INSERT @Soyadlar
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), v FROM (VALUES
 (N'Yilmaz'),(N'Kaya'),(N'Demir'),(N'Sahin'),(N'Celik'),(N'Yildiz'),(N'Yildirim'),(N'Ozturk'),(N'Aydin'),(N'Ozdemir'),
 (N'Arslan'),(N'Dogan'),(N'Kilic'),(N'Aslan'),(N'Cetin'),(N'Kara'),(N'Koc'),(N'Kurt'),(N'Ozkan'),(N'Simsek'),
 (N'Polat'),(N'Korkmaz'),(N'Ozer'),(N'Acar'),(N'Gunes'),(N'Tekin'),(N'Aksoy'),(N'Erdogan'),(N'Bulut'),(N'Avci')
) t(v);

DECLARE @Kurum1 TABLE (rn INT, Ad NVARCHAR(40));
INSERT @Kurum1
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), v FROM (VALUES
 (N'Baskent'),(N'Anadolu'),(N'Kizilay'),(N'Atlas'),(N'Merkez'),(N'Yildiz'),(N'Ulusal'),(N'Akdeniz'),(N'Ankara'),(N'Mavi')
) t(v);

DECLARE @Kurum2 TABLE (rn INT, Ad NVARCHAR(40));
INSERT @Kurum2
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), v FROM (VALUES
 (N'Lojistik'),(N'Tekstil'),(N'Yazilim'),(N'Gida'),(N'Insaat'),(N'Medikal'),(N'Kirtasiye'),(N'Elektronik'),(N'Mobilya'),(N'Otomotiv')
) t(v);

DECLARE @Ilceler TABLE (rn INT, Ilce NVARCHAR(80));
INSERT @Ilceler
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), v FROM (VALUES
 (N'Cankaya'),(N'Kecioren'),(N'Yenimahalle'),(N'Mamak'),(N'Etimesgut'),(N'Sincan'),(N'Altindag'),
 (N'Pursaklar'),(N'Golbasi'),(N'Polatli'),(N'Gudul'),(N'Kazan'),(N'Akyurt'),(N'Beypazari')
) t(v);

BEGIN TRAN;

/* ---------- 1. Subeler ---------- */
INSERT dbo.Subeler (SubeID, SubeAdi, Il, Ilce, PersonelSayisi, AcilisTarihi)
VALUES
(6,  N'Sincan',    N'Ankara', N'Sincan',    0, '2017-05-22'),
(7,  N'Pursaklar', N'Ankara', N'Pursaklar', 0, '2022-01-17'),
(8,  N'Golbasi',   N'Ankara', N'Golbasi',   0, '2019-04-08'),
(9,  N'Altindag',  N'Ankara', N'Altindag',  0, '2015-10-05'),
(10, N'Polatli',   N'Ankara', N'Polatli',   0, '2023-03-14');

/* ---------- 2. Musteriler (ID 9-208) ---------- */
SELECT TOP (200)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n,
    ABS(CHECKSUM(NEWID())) % 30 + 1 AS a,
    ABS(CHECKSUM(NEWID())) % 30 + 1 AS b,
    ABS(CHECKSUM(NEWID())) % 10 + 1 AS c,
    ABS(CHECKSUM(NEWID())) % 10 + 1 AS d,
    ABS(CHECKSUM(NEWID())) % 2      AS e,
    ABS(CHECKSUM(NEWID())) % 14 + 1 AS f
INTO #M
FROM sys.all_objects;

INSERT dbo.Musteriler (MusteriID, AdSoyad, Il, Ilce, MusteriTipi)
SELECT 8 + m.n,
       CASE WHEN m.n % 5 = 0
            THEN k1.Ad + N' ' + k2.Ad + CASE WHEN m.e = 0 THEN N' Ltd.' ELSE N' A.S.' END
            ELSE ad.Ad + N' ' + so.Soyad END,
       N'Ankara',
       il.Ilce,
       CASE WHEN m.n % 5 = 0 THEN N'Kurumsal' ELSE N'Bireysel' END
FROM #M m
JOIN @Adlar    ad ON ad.rn = m.a
JOIN @Soyadlar so ON so.rn = m.b
JOIN @Kurum1   k1 ON k1.rn = m.c
JOIN @Kurum2   k2 ON k2.rn = m.d
JOIN @Ilceler  il ON il.rn = m.f;

/* ---------- 3. Personeller ---------- */
SELECT s.SubeID, k.k,
       ABS(CHECKSUM(NEWID())) % 30 + 1 AS a,
       ABS(CHECKSUM(NEWID())) % 30 + 1 AS b,
       ABS(CHECKSUM(NEWID())) % 2600   AS d
INTO #P
FROM dbo.Subeler s
CROSS JOIN (VALUES (1),(2),(3),(4)) k(k);

INSERT dbo.Personeller (PersonelID, AdSoyad, SubeID, Gorev, IseGirisTarihi)
SELECT 200 + (p.SubeID - 1) * 10 + p.k,
       ad.Ad + N' ' + so.Soyad,
       p.SubeID,
       CASE WHEN p.k = 4 THEN N'Sube personeli' ELSE N'Kurye' END,
       DATEADD(DAY, p.d, CAST('2018-01-01' AS DATE))
FROM #P p
JOIN @Adlar    ad ON ad.rn = p.a
JOIN @Soyadlar so ON so.rn = p.b;

/* ---------- 4. Dagitim araclari ---------- */
INSERT dbo.DagitimAraclari (AracID, SubeID, AracTipi, Plaka, Kapasite, AktifMi)
SELECT 300 + (s.SubeID - 1) * 2 + k.k,
       s.SubeID,
       CASE WHEN k.k = 1 THEN N'Motosiklet' ELSE N'Panelvan' END,
       N'06 KRG ' + CAST(600 + 300 + (s.SubeID - 1) * 2 + k.k AS NVARCHAR(10)),
       CASE WHEN k.k = 1 THEN 40 ELSE 200 END,
       CASE WHEN s.SubeID = 9 AND k.k = 2 THEN 0 ELSE 1 END
FROM dbo.Subeler s
CROSS JOIN (VALUES (1),(2)) k(k);

/* ---------- 5. Gonderiler icin rastgele ham veri ---------- */
SELECT TOP (1500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #N
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

SELECT n,
       ABS(CHECKSUM(NEWID())) % 100  AS rSube,
       ABS(CHECKSUM(NEWID())) % 208 + 1 AS rMus,
       ABS(CHECKSUM(NEWID())) % 288  AS rGun,
       ABS(CHECKSUM(NEWID())) % 600  AS rDak,
       ABS(CHECKSUM(NEWID())) % 1500 AS rAgirlik,
       ABS(CHECKSUM(NEWID())) % 25   AS rUcret,
       ABS(CHECKSUM(NEWID())) % 100  AS rDurum,
       ABS(CHECKSUM(NEWID())) % 100  AS rVaris,
       ABS(CHECKSUM(NEWID())) % 1000 AS rVarisSecim,
       ABS(CHECKSUM(NEWID())) % 3    AS rPlanGun,
       ABS(CHECKSUM(NEWID())) % 1000 AS rKurye,
       ABS(CHECKSUM(NEWID())) % 1000 AS rSapma,
       ABS(CHECKSUM(NEWID())) % 100  AS rGec
INTO #R
FROM #N;

SELECT r.*,
       2000 + r.n AS GonderiID,
       r.rMus     AS MusteriID,
       CASE WHEN r.rSube < 18 THEN 2
            WHEN r.rSube < 33 THEN 1
            WHEN r.rSube < 45 THEN 3
            WHEN r.rSube < 56 THEN 5
            WHEN r.rSube < 65 THEN 4
            WHEN r.rSube < 74 THEN 6
            WHEN r.rSube < 81 THEN 7
            WHEN r.rSube < 87 THEN 8
            WHEN r.rSube < 94 THEN 9
            ELSE 10 END AS CikisSubeID,
       DATEADD(MINUTE, 480 + r.rDak,
               DATEADD(DAY, r.rGun, CAST('2026-01-01' AS DATETIME2(0)))) AS GonderiTarihi,
       CAST(0.30 + r.rAgirlik / 100.0 AS DECIMAL(8,2)) AS AgirlikKg,
       CAST(NULL AS DECIMAL(10,2)) AS KargoUcreti,
       CAST(NULL AS NVARCHAR(50))  AS VarisIl,
       CAST(NULL AS NVARCHAR(80))  AS VarisIlce,
       CAST(NULL AS NVARCHAR(30))  AS Durum,
       CAST(NULL AS INT)           AS PersonelID,
       CAST(NULL AS INT)           AS AracID,
       CAST(NULL AS DATETIME2(0))  AS Planlanan,
       CAST(NULL AS DATETIME2(0))  AS Gercek,
       CAST(NULL AS NVARCHAR(40))  AS Sonuc
INTO #G
FROM #R r;

/* Ucret: agirliga bagli + kucuk rastgele fark */
UPDATE #G SET KargoUcreti = CAST(35 + AgirlikKg * 11 + rUcret AS DECIMAL(10,2));

/* Varis: %85 Ankara ilceleri, %15 diger iller */
UPDATE g
SET VarisIl = CASE WHEN g.rVaris < 85 THEN N'Ankara'
                   ELSE CHOOSE(g.rVarisSecim % 5 + 1, N'Istanbul', N'Izmir', N'Bursa', N'Konya', N'Eskisehir') END,
    VarisIlce = CASE WHEN g.rVaris < 85 THEN i.Ilce ELSE N'Merkez' END
FROM #G g
JOIN @Ilceler i ON i.rn = g.rVarisSecim % 14 + 1;

/* Durum: sube 3, 5, 9 daha cok gecikir; son 5 gunun gonderileri henuz bitmemis olabilir */
UPDATE #G
SET Durum = CASE
        WHEN GonderiTarihi >= '2026-10-12' THEN
             CASE WHEN rDurum < 30 THEN N'Kabul edildi'
                  WHEN rDurum < 70 THEN N'Dagitimda'
                  ELSE N'Teslim edildi' END
        WHEN rDurum < (78 - CASE WHEN CikisSubeID IN (3, 5, 9) THEN 12 ELSE 0 END) THEN N'Teslim edildi'
        WHEN rDurum < 90 THEN N'Gecikti'
        ELSE N'Iade' END;

/* Kurye: gonderinin cikis subesindeki kuryelerden biri */
;WITH K AS (
    SELECT SubeID, PersonelID,
           ROW_NUMBER() OVER (PARTITION BY SubeID ORDER BY PersonelID) AS rn,
           COUNT(*)     OVER (PARTITION BY SubeID) AS c
    FROM dbo.Personeller
    WHERE Gorev = N'Kurye'
)
UPDATE g SET PersonelID = K.PersonelID
FROM #G g
JOIN K ON K.SubeID = g.CikisSubeID AND K.rn = g.rKurye % K.c + 1;

/* Arac: ayni subenin aktif araclarindan biri */
;WITH A AS (
    SELECT SubeID, AracID,
           ROW_NUMBER() OVER (PARTITION BY SubeID ORDER BY AracID) AS rn,
           COUNT(*)     OVER (PARTITION BY SubeID) AS c
    FROM dbo.DagitimAraclari
    WHERE AktifMi = 1
)
UPDATE g SET AracID = A.AracID
FROM #G g
JOIN A ON A.SubeID = g.CikisSubeID AND A.rn = g.rSapma % A.c + 1;

/* Planlanan teslimat: 1-3 gun sonra saat 17:00 */
UPDATE #G
SET Planlanan = DATEADD(HOUR, 17,
                  DATEADD(DAY, rPlanGun + 1, CAST(CAST(GonderiTarihi AS DATE) AS DATETIME2(0))));

/* Teslimat sonucu ve gercek teslimat zamani */
UPDATE #G
SET Sonuc = CASE Durum
                WHEN N'Teslim edildi' THEN N'Zamaninda'
                WHEN N'Iade'          THEN N'Iade'
                WHEN N'Gecikti'       THEN CASE WHEN rGec < 60 THEN N'Gec' ELSE N'Gecikmis' END
                ELSE N'Bekliyor' END;

UPDATE #G
SET Gercek = CASE Sonuc
                WHEN N'Zamaninda' THEN DATEADD(MINUTE, -(30 + rSapma % 270), Planlanan)
                WHEN N'Gec'       THEN DATEADD(MINUTE, 60 + rSapma % 2820, Planlanan)
                ELSE NULL END;

/* ---------- 6. Tablolara yaz ---------- */
INSERT dbo.Gonderiler
    (GonderiID, MusteriID, CikisSubeID, VarisIl, VarisIlce, PersonelID,
     GonderiTarihi, KargoUcreti, AgirlikKg, Durum)
SELECT GonderiID, MusteriID, CikisSubeID, VarisIl, VarisIlce, PersonelID,
       GonderiTarihi, KargoUcreti, AgirlikKg, Durum
FROM #G;

INSERT dbo.Teslimatlar
    (TeslimatID, GonderiID, TeslimatPersonelID, AracID, PlanlananTeslimat, GercekTeslimat, TeslimatSonucu)
SELECT 5000 + n, GonderiID, PersonelID, AracID, Planlanan, Gercek, Sonuc
FROM #G;

INSERT dbo.KargoHareketleri (HareketID, GonderiID, HareketTarihi, HareketDurumu, Aciklama, SubeID)
SELECT (SELECT MAX(HareketID) FROM dbo.KargoHareketleri)
           + ROW_NUMBER() OVER (ORDER BY x.GonderiID, x.Tarih, x.Sira),
       x.GonderiID, x.Tarih, x.Durum, x.Aciklama, x.SubeID
FROM (
    SELECT GonderiID, GonderiTarihi AS Tarih, 1 AS Sira, N'Kabul edildi' AS Durum,
           N'Gonderi subeye kabul edildi' AS Aciklama, CikisSubeID AS SubeID
    FROM #G
    UNION ALL
    SELECT GonderiID, DATEADD(MINUTE, 120 + rSapma % 240, GonderiTarihi), 2, N'Dagitimda',
           N'Kurye dagitima cikti', CikisSubeID
    FROM #G WHERE Durum <> N'Kabul edildi'
    UNION ALL
    SELECT GonderiID, DATEADD(MINUTE, 1, Planlanan), 3, N'Gecikti',
           N'Tahmini teslimat suresi asildi', CikisSubeID
    FROM #G WHERE Sonuc IN (N'Gec', N'Gecikmis')
    UNION ALL
    SELECT GonderiID, Gercek, 4, N'Teslim edildi', N'Aliciya teslim edildi', CikisSubeID
    FROM #G WHERE Sonuc IN (N'Zamaninda', N'Gec')
    UNION ALL
    SELECT GonderiID, DATEADD(DAY, 2, GonderiTarihi), 3, N'Iade', N'Aliciya ulasilamadi', CikisSubeID
    FROM #G WHERE Sonuc = N'Iade'
) x;

/* ---------- 7. Sube personel sayilarini gercek veriden hesapla ---------- */
UPDATE s
SET PersonelSayisi = (SELECT COUNT(*) FROM dbo.Personeller p WHERE p.SubeID = s.SubeID)
FROM dbo.Subeler s;

COMMIT TRAN;

DROP TABLE #M, #P, #N, #R, #G;

/* ---------- Kontrol ---------- */
SELECT N'Subeler' AS Tablo, COUNT(*) AS KayitSayisi FROM dbo.Subeler
UNION ALL SELECT N'Musteriler',       COUNT(*) FROM dbo.Musteriler
UNION ALL SELECT N'Personeller',      COUNT(*) FROM dbo.Personeller
UNION ALL SELECT N'DagitimAraclari',  COUNT(*) FROM dbo.DagitimAraclari
UNION ALL SELECT N'Gonderiler',       COUNT(*) FROM dbo.Gonderiler
UNION ALL SELECT N'KargoHareketleri', COUNT(*) FROM dbo.KargoHareketleri
UNION ALL SELECT N'Teslimatlar',      COUNT(*) FROM dbo.Teslimatlar;
GO
