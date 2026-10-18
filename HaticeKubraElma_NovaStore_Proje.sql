-- ============================================================
-- NovaStore E-Ticaret Veri Yönetim Sistemi
-- Hazırlayan : Hatice Kübra Elma
-- Veritabanı: NovaStoreDB
-- Konu      : DDL, DML, JOIN, GROUP BY, VIEW, BACKUP
-- ============================================================
-- Tablolar yabancı anahtar bağımlılığına göre oluşturulur:
--   1) Categories, Customers   (ana tablolar)
--   2) Products, Orders        (ana tablolara bağlı)
--   3) OrderDetails            (Products ve Orders'a bağlı)
-- ============================================================

USE master;
GO

-- Tekrar çalıştırılabilmesi için mevcut veritabanı varsa kapatılıp silinir.
IF DB_ID(N'NovaStoreDB') IS NOT NULL
BEGIN
    ALTER DATABASE NovaStoreDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE NovaStoreDB;
END
GO

-- ============================================================
-- BÖLÜM 1: VERİ TABANI TASARIMI (LOGICAL DESIGN VE DDL)
-- ============================================================

-- 1. Veri tabanı oluşturma
-- Turkish_CI_AS, varchar sütunlarda Türkçe karakterlerin doğru saklanması içindir.
CREATE DATABASE NovaStoreDB
COLLATE Turkish_CI_AS;
GO

USE NovaStoreDB;
GO

-- ------------------------------------------------------------
-- 2.A Tablo: Categories (Kategoriler)
-- CategoryID   : otomatik artan birincil anahtar
-- CategoryName : boş geçilemez
-- ------------------------------------------------------------
CREATE TABLE Categories
(
    CategoryID   INT IDENTITY(1,1) NOT NULL,
    CategoryName VARCHAR(50)       NOT NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID)
);
GO

-- ------------------------------------------------------------
-- 2.C Tablo: Customers (Müşteriler)
-- Ana tablodur; Orders bu tabloya bağlanacağı için Products'tan
-- önce değil, bağımlı tablolardan önce oluşturulur.
-- Email benzersiz olmak zorundadır.
-- ------------------------------------------------------------
CREATE TABLE Customers
(
    CustomerID INT IDENTITY(1,1) NOT NULL,
    FullName   VARCHAR(50)       NULL,
    City       VARCHAR(20)       NULL,
    Email      VARCHAR(100)      NULL,
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerID),
    CONSTRAINT UQ_Customers_Email UNIQUE (Email)
);
GO

-- ------------------------------------------------------------
-- 2.B Tablo: Products (Ürünler)
-- CategoryID, Categories tablosuna yabancı anahtar ile bağlanır.
-- Stock için varsayılan değer 0'dır.
-- ------------------------------------------------------------
CREATE TABLE Products
(
    ProductID   INT IDENTITY(1,1) NOT NULL,
    ProductName VARCHAR(100)      NOT NULL,
    Price       DECIMAL(10,2)     NULL,
    Stock       INT               NULL CONSTRAINT DF_Products_Stock DEFAULT (0),
    CategoryID  INT               NOT NULL,
    CONSTRAINT PK_Products PRIMARY KEY (ProductID),
    CONSTRAINT FK_Products_Categories
        FOREIGN KEY (CategoryID) REFERENCES Categories (CategoryID)
);
GO

-- ------------------------------------------------------------
-- 2.D Tablo: Orders (Siparişler)
-- CustomerID, Customers tablosuna bağlanır.
-- OrderDate varsayılanı siparişin kaydedildiği andır (GETDATE).
-- ------------------------------------------------------------
CREATE TABLE Orders
(
    OrderID     INT IDENTITY(1,1) NOT NULL,
    CustomerID  INT               NOT NULL,
    OrderDate   DATETIME          NULL CONSTRAINT DF_Orders_OrderDate DEFAULT (GETDATE()),
    TotalAmount DECIMAL(10,2)     NULL,
    CONSTRAINT PK_Orders PRIMARY KEY (OrderID),
    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
);
GO

-- ------------------------------------------------------------
-- 2.E Tablo: OrderDetails (Sipariş Detayları - ara tablo)
-- Bir sipariş birden çok ürün satırı içerir.
-- OrderID -> Orders, ProductID -> Products
-- ------------------------------------------------------------
CREATE TABLE OrderDetails
(
    DetailID  INT IDENTITY(1,1) NOT NULL,
    OrderID   INT               NOT NULL,
    ProductID INT               NOT NULL,
    Quantity  INT               NULL,
    CONSTRAINT PK_OrderDetails PRIMARY KEY (DetailID),
    CONSTRAINT FK_OrderDetails_Orders
        FOREIGN KEY (OrderID) REFERENCES Orders (OrderID),
    CONSTRAINT FK_OrderDetails_Products
        FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
);
GO

-- ============================================================
-- BÖLÜM 2: VERİ GİRİŞİ (DML - INSERT)
-- ============================================================

-- ------------------------------------------------------------
-- Görev 1: 5 kategori
-- Identity sırası sonraki ürün kayıtlarında CategoryID olarak kullanılır.
--   1 Elektronik | 2 Giyim | 3 Kitap | 4 Kozmetik | 5 Ev ve Yaşam
-- ------------------------------------------------------------
INSERT INTO Categories (CategoryName)
VALUES
    (N'Elektronik'),
    (N'Giyim'),
    (N'Kitap'),
    (N'Kozmetik'),
    (N'Ev ve Yaşam');
GO

-- ------------------------------------------------------------
-- Görev 2: 12 ürün (her kategoride en az iki ürün)
-- Stok değeri 20'nin altında olanlar Bölüm 3 / Soru 1 raporuna düşer.
-- ------------------------------------------------------------
INSERT INTO Products (ProductName, Price, Stock, CategoryID)
VALUES
    (N'Kablosuz Kulaklık',       1299.90,  15, 1),
    (N'Akıllı Saat',             3499.00,  42, 1),
    (N'Bluetooth Hoparlör',       899.50,   8, 1),
    (N'Pamuklu Tişört',           249.90, 120, 2),
    (N'Kot Pantolon',             799.00,  35, 2),
    (N'Spor Ayakkabı',           1599.00,  12, 2),
    (N'Veri Tabanı Yönetimi',     320.00,  55, 3),
    (N'Sessiz Bahçe',             145.50,   6, 3),
    (N'Nemlendirici Krem',        289.90,  70, 4),
    (N'Ruj Seti',                 199.00,   4, 4),
    (N'Filtre Kahve Makinesi',   1899.00,  22, 5),
    (N'Dekoratif Yastık',         179.90,   9, 5);
GO

-- ------------------------------------------------------------
-- Görev 3: 6 müşteri
-- E-posta adresleri benzersiz kısıtını sağlayacak şekilde farklıdır.
-- ------------------------------------------------------------
INSERT INTO Customers (FullName, City, Email)
VALUES
    (N'Ahmet Yılmaz',  N'İstanbul', N'ahmet.yilmaz@novastore.com'),
    (N'Elif Demir',    N'Ankara',   N'elif.demir@novastore.com'),
    (N'Mehmet Kaya',   N'İzmir',    N'mehmet.kaya@novastore.com'),
    (N'Zeynep Arslan', N'Bursa',    N'zeynep.arslan@novastore.com'),
    (N'Can Öztürk',    N'Antalya',  N'can.ozturk@novastore.com'),
    (N'Ayşe Koç',      N'İstanbul', N'ayse.koc@novastore.com');
GO

-- ------------------------------------------------------------
-- Görev 4: 10 sipariş
-- Tarihler bilinçli olarak farklı aylara yayılmıştır (zaman analizi).
-- TotalAmount, ilgili sipariş satırlarındaki Quantity * Price toplamıdır.
-- Tarih biçimi (YYYYMMDD) dil ayarından bağımsızdır.
-- ------------------------------------------------------------
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
VALUES
    (1, '20261001 11:20:00', 4798.90),  -- Ahmet Yılmaz
    (1, '20260915 16:45:00', 3497.00),  -- Ahmet Yılmaz
    (1, '20261016 09:05:00', 1890.00),  -- Ahmet Yılmaz
    (2, '20261010 13:10:00', 1528.50),  -- Elif Demir
    (2, '20260618 15:40:00', 1039.60),  -- Elif Demir
    (3, '20260820 10:25:00', 5298.00),  -- Mehmet Kaya
    (3, '20260928 18:05:00',  799.00),  -- Mehmet Kaya
    (4, '20261012 12:30:00', 2188.90),  -- Zeynep Arslan
    (5, '20260705 14:15:00',  844.30),  -- Can Öztürk
    (6, '20261014 17:50:00', 3258.70);  -- Ayşe Koç
GO

-- Sipariş detayları
-- OrderID kimlik sırası yukarıdaki INSERT ile 1..10 arasındadır.
-- ProductID kimlik sırası ürün INSERT'i ile 1..12 arasındadır.
INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
VALUES
    -- Sipariş 1 | Ahmet | 3499.00 + 1299.90 = 4798.90
    (1,  2, 1),  -- Akıllı Saat
    (1,  1, 1),  -- Kablosuz Kulaklık
    -- Sipariş 2 | Ahmet | 1899.00 + (799.00 * 2) = 3497.00
    (2, 11, 1),  -- Filtre Kahve Makinesi
    (2,  5, 2),  -- Kot Pantolon
    -- Sipariş 3 | Ahmet | 1599.00 + (145.50 * 2) = 1890.00
    (3,  6, 1),  -- Spor Ayakkabı
    (3,  8, 2),  -- Sessiz Bahçe
    -- Sipariş 4 | Elif | (289.90 * 2) + 199.00 + (249.90 * 3) = 1528.50
    (4,  9, 2),  -- Nemlendirici Krem
    (4, 10, 1),  -- Ruj Seti
    (4,  4, 3),  -- Pamuklu Tişört
    -- Sipariş 5 | Elif | (179.90 * 4) + 320.00 = 1039.60
    (5, 12, 4),  -- Dekoratif Yastık
    (5,  7, 1),  -- Veri Tabanı Yönetimi
    -- Sipariş 6 | Mehmet | (899.50 * 2) + 3499.00 = 5298.00
    (6,  3, 2),  -- Bluetooth Hoparlör
    (6,  2, 1),  -- Akıllı Saat
    -- Sipariş 7 | Mehmet | 799.00
    (7,  5, 1),  -- Kot Pantolon
    -- Sipariş 8 | Zeynep | 1899.00 + 289.90 = 2188.90
    (8, 11, 1),  -- Filtre Kahve Makinesi
    (8,  9, 1),  -- Nemlendirici Krem
    -- Sipariş 9 | Can | (249.90 * 2) + 145.50 + 199.00 = 844.30
    (9,  4, 2),  -- Pamuklu Tişört
    (9,  8, 1),  -- Sessiz Bahçe
    (9, 10, 1),  -- Ruj Seti
    -- Sipariş 10 | Ayşe | 1299.90 + 1599.00 + (179.90 * 2) = 3258.70
    (10, 1, 1),  -- Kablosuz Kulaklık
    (10, 6, 1),  -- Spor Ayakkabı
    (10, 12, 2); -- Dekoratif Yastık
GO

-- ============================================================
-- BÖLÜM 3: SORGULAMA VE ANALİZ (DQL - SELECT VE JOIN)
-- ============================================================

-- ------------------------------------------------------------
-- Soru 1: Temel listeleme
-- Stok miktarı 20'den az olan ürünler, stok miktarına göre azalan.
-- Kullanılanlar: SELECT, WHERE, ORDER BY
-- ------------------------------------------------------------
SELECT
    ProductName AS UrunAdi,
    Stock       AS StokMiktari
FROM Products
WHERE Stock < 20
ORDER BY Stock DESC;
GO

-- ------------------------------------------------------------
-- Soru 2: Veri birleştirme
-- Hangi müşteri hangi tarihte sipariş vermiş?
-- Kullanılanlar: INNER JOIN (Customers, Orders)
-- ------------------------------------------------------------
SELECT
    c.FullName    AS MusteriAdi,
    c.City        AS Sehir,
    o.OrderDate   AS SiparisTarihi,
    o.TotalAmount AS ToplamTutar
FROM Customers AS c
INNER JOIN Orders AS o
    ON c.CustomerID = o.CustomerID
ORDER BY o.OrderDate;
GO

-- ------------------------------------------------------------
-- Soru 3: Çoklu birleştirme ve detay raporu
-- Ahmet Yılmaz'ın aldığı ürünler, fiyatları ve kategorileri.
-- Zincir: Customers -> Orders -> OrderDetails -> Products -> Categories
-- ------------------------------------------------------------
SELECT
    c.FullName     AS MusteriAdi,
    p.ProductName  AS UrunAdi,
    p.Price        AS Fiyat,
    cat.CategoryName AS Kategori
FROM Customers AS c
INNER JOIN Orders AS o
    ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails AS od
    ON o.OrderID = od.OrderID
INNER JOIN Products AS p
    ON od.ProductID = p.ProductID
INNER JOIN Categories AS cat
    ON p.CategoryID = cat.CategoryID
WHERE c.FullName = N'Ahmet Yılmaz'
ORDER BY cat.CategoryName, p.ProductName;
GO

-- ------------------------------------------------------------
-- Soru 4: Gruplama
-- Her kategoride toplam kaç ürün var?
-- COUNT(p.ProductID), ürünü olmayan kategoriyi 0 sayar.
-- COUNT(*) yazılsaydı, eşleşmeyen kategori satırı da 1 sayılırdı.
-- Kullanılanlar: GROUP BY, COUNT, LEFT JOIN
-- ------------------------------------------------------------
SELECT
    cat.CategoryName      AS Kategori,
    COUNT(p.ProductID)    AS UrunSayisi
FROM Categories AS cat
LEFT JOIN Products AS p
    ON cat.CategoryID = p.CategoryID
GROUP BY cat.CategoryName
ORDER BY UrunSayisi DESC, cat.CategoryName;
GO

-- ------------------------------------------------------------
-- Soru 5: Ciro analizi
-- Her müşterinin şirkete kazandırdığı toplam ciro.
-- En çok harcayandan en aza doğru sıralanır.
-- Kullanılanlar: SUM, GROUP BY, ORDER BY
-- ------------------------------------------------------------
SELECT
    c.FullName          AS MusteriAdi,
    SUM(o.TotalAmount)  AS ToplamCiro
FROM Customers AS c
INNER JOIN Orders AS o
    ON c.CustomerID = o.CustomerID
GROUP BY c.FullName
ORDER BY ToplamCiro DESC;
GO

-- ------------------------------------------------------------
-- Soru 6: Zaman analizi
-- Bugüne göre her siparişin üzerinden kaç gün geçtiği.
-- Kullanılanlar: DATEDIFF, GETDATE
-- ------------------------------------------------------------
SELECT
    o.OrderID AS SiparisNo,
    c.FullName AS MusteriAdi,
    o.OrderDate AS SiparisTarihi,
    DATEDIFF(DAY, o.OrderDate, GETDATE()) AS GecenGun
FROM Orders AS o
INNER JOIN Customers AS c
    ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate;
GO

-- ============================================================
-- BÖLÜM 4: İLERİ SEVİYE VERİ TABANI NESNELERİ
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 View: vw_SiparisOzet
-- Müşteri adı, sipariş tarihi, ürün adı ve adet tek sonuçta.
-- CREATE VIEW kendi batch'inin ilk ifadesi olmalıdır.
-- ------------------------------------------------------------
CREATE VIEW vw_SiparisOzet
AS
SELECT
    c.FullName   AS MusteriAdi,
    o.OrderDate  AS SiparisTarihi,
    p.ProductName AS UrunAdi,
    od.Quantity  AS Adet
FROM Customers AS c
INNER JOIN Orders AS o
    ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails AS od
    ON o.OrderID = od.OrderID
INNER JOIN Products AS p
    ON od.ProductID = p.ProductID;
GO

-- View doğrulama sorgusu
SELECT
    MusteriAdi,
    SiparisTarihi,
    UrunAdi,
    Adet
FROM vw_SiparisOzet
ORDER BY SiparisTarihi, MusteriAdi, UrunAdi;
GO

-- ------------------------------------------------------------
-- 4.2 Yedekleme
-- NovaStoreDB tam yedeği C:\Yedek klasörüne alınır.
-- Bu komutun çalışması için C:\Yedek klasörünün önceden var olması gerekir.
-- ------------------------------------------------------------
BACKUP DATABASE NovaStoreDB
TO DISK = N'C:\Yedek\NovaStoreDB.bak'
WITH
    FORMAT,
    INIT,
    NAME = N'NovaStoreDB Tam Yedek',
    STATS = 10;
GO
