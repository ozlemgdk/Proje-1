/*
KargoAnaliz - SQL Server proje veritabani
Kullanim:
1. SQL Server ve SSMS kurulu bilgisayarda bu dosyayi SSMS ile acin.
2. SQL Server instance'iniza baglanin.
3. Bu dosyanin tamamini Execute (F5) ile calistirin.
Not: Script tekrar calistirilabilir; mevcut kayitlari silmez.
*/

USE master;
GO

IF DB_ID(N'KargoAnaliz') IS NULL
BEGIN
    CREATE DATABASE KargoAnaliz;
END;
GO

USE KargoAnaliz;
GO

/* 1. Subeler */
IF OBJECT_ID(N'dbo.Subeler', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Subeler
    (
        SubeID       INT           NOT NULL PRIMARY KEY,
        SubeAdi      NVARCHAR(100) NOT NULL,
        Il           NVARCHAR(50)  NOT NULL,
        Ilce         NVARCHAR(80)  NOT NULL,
        PersonelSayisi INT         NOT NULL,
        AcilisTarihi DATE          NULL
    );
END;
GO

/* 2. Musteriler */
IF OBJECT_ID(N'dbo.Musteriler', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Musteriler
    (
        MusteriID    INT           NOT NULL PRIMARY KEY,
        AdSoyad      NVARCHAR(120) NOT NULL,
        Il           NVARCHAR(50)  NOT NULL,
        Ilce         NVARCHAR(80)  NOT NULL,
        MusteriTipi  NVARCHAR(30)  NOT NULL
            CHECK (MusteriTipi IN (N'Bireysel', N'Kurumsal'))
    );
END;
GO

/* 3. Personeller */
IF OBJECT_ID(N'dbo.Personeller', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Personeller
    (
        PersonelID   INT           NOT NULL PRIMARY KEY,
        AdSoyad      NVARCHAR(120) NOT NULL,
        SubeID       INT           NOT NULL,
        Gorev        NVARCHAR(50)  NOT NULL,
        IseGirisTarihi DATE         NULL,
        CONSTRAINT FK_Personeller_Subeler
            FOREIGN KEY (SubeID) REFERENCES dbo.Subeler(SubeID)
    );
END;
GO

/* 4. Dagitim araclari */
IF OBJECT_ID(N'dbo.DagitimAraclari', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DagitimAraclari
    (
        AracID       INT           NOT NULL PRIMARY KEY,
        SubeID       INT           NOT NULL,
        AracTipi     NVARCHAR(40)  NOT NULL,
        Plaka        NVARCHAR(15)  NOT NULL UNIQUE,
        Kapasite     INT           NOT NULL,
        AktifMi      BIT           NOT NULL DEFAULT (1),
        CONSTRAINT FK_DagitimAraclari_Subeler
            FOREIGN KEY (SubeID) REFERENCES dbo.Subeler(SubeID)
    );
END;
GO

/* 5. Gonderiler */
IF OBJECT_ID(N'dbo.Gonderiler', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Gonderiler
    (
        GonderiID      INT           NOT NULL PRIMARY KEY,
        MusteriID      INT           NOT NULL,
        CikisSubeID    INT           NOT NULL,
        VarisIl        NVARCHAR(50)  NOT NULL,
        VarisIlce      NVARCHAR(80)  NOT NULL,
        PersonelID     INT           NULL,
        GonderiTarihi  DATETIME2(0)  NOT NULL,
        KargoUcreti    DECIMAL(10,2) NOT NULL,
        AgirlikKg      DECIMAL(8,2)  NOT NULL,
        Durum          NVARCHAR(30)  NOT NULL
            CHECK (Durum IN (N'Kabul edildi', N'Dagitimda', N'Teslim edildi', N'Iade', N'Gecikti')),
        CONSTRAINT FK_Gonderiler_Musteriler
            FOREIGN KEY (MusteriID) REFERENCES dbo.Musteriler(MusteriID),
        CONSTRAINT FK_Gonderiler_Subeler
            FOREIGN KEY (CikisSubeID) REFERENCES dbo.Subeler(SubeID),
        CONSTRAINT FK_Gonderiler_Personeller
            FOREIGN KEY (PersonelID) REFERENCES dbo.Personeller(PersonelID)
    );
END;
GO

/* 6. Kargo hareketleri */
IF OBJECT_ID(N'dbo.KargoHareketleri', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.KargoHareketleri
    (
        HareketID      INT           NOT NULL PRIMARY KEY,
        GonderiID      INT           NOT NULL,
        HareketTarihi  DATETIME2(0)  NOT NULL,
        HareketDurumu  NVARCHAR(50)  NOT NULL,
        Aciklama       NVARCHAR(250) NULL,
        SubeID         INT           NULL,
        CONSTRAINT FK_KargoHareketleri_Gonderiler
            FOREIGN KEY (GonderiID) REFERENCES dbo.Gonderiler(GonderiID),
        CONSTRAINT FK_KargoHareketleri_Subeler
            FOREIGN KEY (SubeID) REFERENCES dbo.Subeler(SubeID)
    );
END;
GO

/* 7. Teslimatlar */
IF OBJECT_ID(N'dbo.Teslimatlar', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Teslimatlar
    (
        TeslimatID       INT          NOT NULL PRIMARY KEY,
        GonderiID        INT          NOT NULL UNIQUE,
        TeslimatPersonelID INT        NULL,
        AracID           INT          NULL,
        PlanlananTeslimat DATETIME2(0) NULL,
        GercekTeslimat   DATETIME2(0) NULL,
        TeslimatSonucu   NVARCHAR(40) NOT NULL,
        CONSTRAINT FK_Teslimatlar_Gonderiler
            FOREIGN KEY (GonderiID) REFERENCES dbo.Gonderiler(GonderiID),
        CONSTRAINT FK_Teslimatlar_Personeller
            FOREIGN KEY (TeslimatPersonelID) REFERENCES dbo.Personeller(PersonelID),
        CONSTRAINT FK_Teslimatlar_Araclar
            FOREIGN KEY (AracID) REFERENCES dbo.DagitimAraclari(AracID)
    );
END;
GO

/* Ornek veriler: yalnizca tablo bos ise eklenir. */
IF NOT EXISTS (SELECT 1 FROM dbo.Subeler)
BEGIN
    INSERT INTO dbo.Subeler (SubeID, SubeAdi, Il, Ilce, PersonelSayisi, AcilisTarihi)
    VALUES
    (1, N'Kecioren Merkez', N'Ankara', N'Kecioren', 8, '2018-03-12'),
    (2, N'Cankaya', N'Ankara', N'Cankaya', 12, '2016-06-01'),
    (3, N'Yenimahalle', N'Ankara', N'Yenimahalle', 6, '2020-09-15'),
    (4, N'Mamak', N'Ankara', N'Mamak', 5, '2021-02-10'),
    (5, N'Etimesgut', N'Ankara', N'Etimesgut', 7, '2019-11-20');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Musteriler)
BEGIN
    INSERT INTO dbo.Musteriler (MusteriID, AdSoyad, Il, Ilce, MusteriTipi)
    VALUES
    (1, N'Aylin Demir', N'Ankara', N'Kecioren', N'Bireysel'),
    (2, N'Mert Kaya', N'Ankara', N'Cankaya', N'Bireysel'),
    (3, N'Anadolu Ofis Ltd.', N'Ankara', N'Yenimahalle', N'Kurumsal'),
    (4, N'Zeynep Arslan', N'Ankara', N'Mamak', N'Bireysel'),
    (5, N'Baskent Kitap A.S.', N'Ankara', N'Cankaya', N'Kurumsal'),
    (6, N'Emre Yilmaz', N'Ankara', N'Etimesgut', N'Bireysel'),
    (7, N'Deniz Cetin', N'Ankara', N'Kecioren', N'Bireysel'),
    (8, N'Ankara Tasarim Ltd.', N'Ankara', N'Etimesgut', N'Kurumsal');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Personeller)
BEGIN
    INSERT INTO dbo.Personeller (PersonelID, AdSoyad, SubeID, Gorev, IseGirisTarihi)
    VALUES
    (101, N'Burak Aydin', 1, N'Kurye', '2022-04-11'),
    (102, N'Elif Sari', 1, N'Sube personeli', '2021-08-02'),
    (103, N'Can Yildiz', 2, N'Kurye', '2020-01-20'),
    (104, N'Derya Aksoy', 2, N'Kurye', '2023-05-08'),
    (105, N'Onur Kaplan', 3, N'Kurye', '2022-10-17'),
    (106, N'Esra Koc', 4, N'Kurye', '2024-02-05'),
    (107, N'Bora Sahin', 5, N'Kurye', '2021-12-13'),
    (108, N'Asli Yuce', 2, N'Sube personeli', '2019-07-01');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DagitimAraclari)
BEGIN
    INSERT INTO dbo.DagitimAraclari (AracID, SubeID, AracTipi, Plaka, Kapasite, AktifMi)
    VALUES
    (201, 1, N'Motosiklet', N'06 KRG 101', 40, 1),
    (202, 1, N'Panelvan', N'06 KRG 102', 180, 1),
    (203, 2, N'Panelvan', N'06 KRG 203', 220, 1),
    (204, 3, N'Motosiklet', N'06 KRG 304', 35, 1),
    (205, 4, N'Panelvan', N'06 KRG 405', 160, 0),
    (206, 5, N'Motosiklet', N'06 KRG 506', 45, 1);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Gonderiler)
BEGIN
    INSERT INTO dbo.Gonderiler
        (GonderiID, MusteriID, CikisSubeID, VarisIl, VarisIlce, PersonelID,
         GonderiTarihi, KargoUcreti, AgirlikKg, Durum)
    VALUES
    (1001, 1, 1, N'Ankara', N'Cankaya', 101, '2026-09-01 09:10', 85.00, 1.20, N'Teslim edildi'),
    (1002, 2, 2, N'Ankara', N'Kecioren', 103, '2026-09-01 10:30', 120.00, 3.50, N'Dagitimda'),
    (1003, 3, 3, N'Ankara', N'Etimesgut', 105, '2026-09-02 11:15', 95.00, 2.00, N'Teslim edildi'),
    (1004, 4, 4, N'Ankara', N'Mamak', 106, '2026-09-02 13:20', 70.00, 0.80, N'Iade'),
    (1005, 5, 2, N'Ankara', N'Yenimahalle', 104, '2026-09-03 08:45', 150.00, 5.20, N'Teslim edildi'),
    (1006, 6, 5, N'Ankara', N'Kecioren', 107, '2026-09-03 14:05', 110.00, 4.00, N'Gecikti'),
    (1007, 7, 1, N'Ankara', N'Mamak', 101, '2026-09-04 09:00', 65.00, 0.60, N'Teslim edildi'),
    (1008, 8, 5, N'Ankara', N'Cankaya', 107, '2026-09-04 15:40', 180.00, 7.80, N'Dagitimda'),
    (1009, 1, 1, N'Ankara', N'Yenimahalle', 102, '2026-09-05 12:25', 90.00, 1.50, N'Kabul edildi'),
    (1010, 2, 2, N'Ankara', N'Etimesgut', 103, '2026-09-05 16:10', 135.00, 3.10, N'Teslim edildi'),
    (1011, 3, 3, N'Ankara', N'Cankaya', 105, '2026-09-06 10:05', 210.00, 9.40, N'Gecikti'),
    (1012, 6, 5, N'Ankara', N'Mamak', 107, '2026-09-06 11:50', 75.00, 1.00, N'Teslim edildi'),
    (1013, 4, 4, N'Ankara', N'Kecioren', 106, '2026-09-07 08:35', 105.00, 2.60, N'Dagitimda'),
    (1014, 7, 1, N'Ankara', N'Etimesgut', 101, '2026-09-07 14:45', 125.00, 4.30, N'Teslim edildi'),
    (1015, 8, 2, N'Ankara', N'Yenimahalle', 104, '2026-09-08 09:25', 160.00, 6.10, N'Iade'),
    (1016, 5, 2, N'Ankara', N'Mamak', 103, '2026-09-08 13:55', 88.00, 1.70, N'Teslim edildi'),
    (1017, 1, 1, N'Ankara', N'Cankaya', 101, '2026-09-09 10:40', 99.00, 2.10, N'Teslim edildi'),
    (1018, 6, 5, N'Ankara', N'Kecioren', 107, '2026-09-09 16:20', 145.00, 5.50, N'Gecikti'),
    (1019, 2, 2, N'Ankara', N'Mamak', 104, '2026-09-10 11:35', 115.00, 3.00, N'Dagitimda'),
    (1020, 7, 1, N'Ankara', N'Yenimahalle', 102, '2026-09-10 15:15', 80.00, 1.10, N'Teslim edildi');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.KargoHareketleri)
BEGIN
    INSERT INTO dbo.KargoHareketleri
        (HareketID, GonderiID, HareketTarihi, HareketDurumu, Aciklama, SubeID)
    VALUES
    (1, 1001, '2026-09-01 09:10', N'Kabul edildi', N'Gonderi subeye kabul edildi', 1),
    (2, 1001, '2026-09-01 13:30', N'Dagitimda', N'Kurye dagitima cikti', 1),
    (3, 1001, '2026-09-01 16:10', N'Teslim edildi', N'Aliciya teslim edildi', 1),
    (4, 1002, '2026-09-01 10:30', N'Kabul edildi', N'Gonderi subeye kabul edildi', 2),
    (5, 1002, '2026-09-02 09:00', N'Dagitimda', N'Kurye dagitima cikti', 2),
    (6, 1004, '2026-09-02 13:20', N'Kabul edildi', N'Gonderi subeye kabul edildi', 4),
    (7, 1004, '2026-09-04 15:00', N'Iade', N'Aliciya ulasilamadi', 4),
    (8, 1006, '2026-09-03 14:05', N'Kabul edildi', N'Gonderi subeye kabul edildi', 5),
    (9, 1006, '2026-09-05 17:30', N'Gecikti', N'Tahmini teslimat suresi asildi', 5),
    (10, 1007, '2026-09-04 09:00', N'Kabul edildi', N'Gonderi subeye kabul edildi', 1),
    (11, 1007, '2026-09-04 14:20', N'Teslim edildi', N'Aliciya teslim edildi', 1),
    (12, 1011, '2026-09-06 10:05', N'Kabul edildi', N'Gonderi subeye kabul edildi', 3),
    (13, 1011, '2026-09-08 12:00', N'Gecikti', N'Aktarma noktasinda bekleme', 3);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Teslimatlar)
BEGIN
    INSERT INTO dbo.Teslimatlar
        (TeslimatID, GonderiID, TeslimatPersonelID, AracID, PlanlananTeslimat, GercekTeslimat, TeslimatSonucu)
    VALUES
    (501, 1001, 101, 201, '2026-09-01 17:00', '2026-09-01 16:10', N'Zamaninda'),
    (502, 1002, 103, 203, '2026-09-02 17:00', NULL, N'Bekliyor'),
    (503, 1003, 105, 204, '2026-09-03 17:00', '2026-09-03 15:20', N'Zamaninda'),
    (504, 1004, 106, 205, '2026-09-03 17:00', NULL, N'Iade'),
    (505, 1005, 104, 203, '2026-09-04 17:00', '2026-09-04 18:25', N'Gec'),
    (506, 1006, 107, 206, '2026-09-04 17:00', NULL, N'Gecikmis'),
    (507, 1007, 101, 201, '2026-09-05 17:00', '2026-09-05 14:20', N'Zamaninda'),
    (508, 1008, 107, 206, '2026-09-05 17:00', NULL, N'Bekliyor'),
    (509, 1009, 102, 202, '2026-09-06 17:00', NULL, N'Bekliyor'),
    (510, 1010, 103, 203, '2026-09-06 17:00', '2026-09-06 16:00', N'Zamaninda'),
    (511, 1011, 105, 204, '2026-09-07 17:00', NULL, N'Gecikmis'),
    (512, 1012, 107, 206, '2026-09-07 17:00', '2026-09-07 15:45', N'Zamaninda'),
    (513, 1013, 106, 205, '2026-09-08 17:00', NULL, N'Bekliyor'),
    (514, 1014, 101, 201, '2026-09-08 17:00', '2026-09-08 16:30', N'Zamaninda'),
    (515, 1015, 104, 203, '2026-09-09 17:00', NULL, N'Iade'),
    (516, 1016, 103, 203, '2026-09-09 17:00', '2026-09-09 14:55', N'Zamaninda'),
    (517, 1017, 101, 201, '2026-09-10 17:00', '2026-09-10 16:10', N'Zamaninda'),
    (518, 1018, 107, 206, '2026-09-10 17:00', NULL, N'Gecikmis'),
    (519, 1019, 104, 203, '2026-09-11 17:00', NULL, N'Bekliyor'),
    (520, 1020, 102, 202, '2026-09-11 17:00', '2026-09-11 15:30', N'Zamaninda');
END;
GO

/* Kurulum kontrolu */
SELECT N'Subeler' AS Tablo, COUNT(*) AS KayitSayisi FROM dbo.Subeler
UNION ALL SELECT N'Musteriler', COUNT(*) FROM dbo.Musteriler
UNION ALL SELECT N'Personeller', COUNT(*) FROM dbo.Personeller
UNION ALL SELECT N'DagitimAraclari', COUNT(*) FROM dbo.DagitimAraclari
UNION ALL SELECT N'Gonderiler', COUNT(*) FROM dbo.Gonderiler
UNION ALL SELECT N'KargoHareketleri', COUNT(*) FROM dbo.KargoHareketleri
UNION ALL SELECT N'Teslimatlar', COUNT(*) FROM dbo.Teslimatlar;
GO
