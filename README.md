# NovaStore E-Ticaret Veri Yönetim Sistemi

NovaStore, yeni kurulan bir e-ticaret sitesidir. Bu depo, sitenin ürün, müşteri ve sipariş kayıtlarını tutan SQL Server veritabanını ve yönetim raporlarını içerir.

Hazırlayan: Hatice Kübra Elma

## Teslim dosyaları

| Dosya | İçerik |
| --- | --- |
| `HaticeKubraElma_NovaStore_Proje.sql` | Veritabanını kuran, veriyi ekleyen, raporları çalıştıran, görünümü oluşturan ve yedeği alan betik |
| `HaticeKubraElma_NovaStore_Proje.docx` | Kodlar, sorgu sonuçları ve açıklamalar |
| `HaticeKubraElma_NovaStore_Proje.png` | Beş tablonun ilişkisel şeması |

## Veritabanı

Sunucu: `localhost\SQLEXPRESS`  
Veritabanı: `NovaStoreDB`  
Sıralama: `Turkish_CI_AS`

Betik aynı adlı veritabanı varsa onu kapatıp siler ve baştan kurar. Bu yüzden betiğin tamamını çalıştırmak mevcut `NovaStoreDB` kayıtlarını yeniler.

### Tablolar

Tablolar yabancı anahtar sırasına göre kurulur.

| Tablo | Görevi | Önemli kural |
| --- | --- | --- |
| `Categories` | Ürün kategorileri | `CategoryName` boş geçilemez |
| `Customers` | Müşteriler | `Email` benzersizdir |
| `Products` | Ürünler | `CategoryID`, `Categories` tablosuna bağlıdır. `Stock` varsayılanı 0'dır |
| `Orders` | Sipariş başlıkları | `CustomerID`, `Customers` tablosuna bağlıdır. `OrderDate` varsayılanı `GETDATE()` değeridir |
| `OrderDetails` | Sipariş kalemleri | Hem `Orders` hem `Products` tablosuna bağlı ara tablodur |

İlişkiler:

- Bir kategoride birden fazla ürün bulunur.
- Bir müşterinin birden fazla siparişi olabilir.
- Bir siparişte birden fazla ürün satırı bulunur.
- Bir ürün birden fazla siparişte geçebilir.

## Örnek veri

| Kayıt | Adet |
| --- | --- |
| Kategori | 5 |
| Ürün | 12 |
| Müşteri | 6 |
| Sipariş | 10 |
| Sipariş kalemi | 22 |

Kategoriler: Elektronik, Giyim, Kitap, Kozmetik, Ev ve Yaşam.  
Sipariş tarihleri 18 Haziran 2026 ile 16 Ekim 2026 arasındadır.  
`Orders.TotalAmount`, ilgili satırların adet çarpı birim fiyat toplamına eşittir.

## Raporlar

Betikteki her sorgu yorum satırıyla işaretlidir.

1. Stoğu 20'den az olan ürünler, stok miktarına göre azalan sırada.
2. Hangi müşterinin hangi tarihte, hangi tutarda sipariş verdiği.
3. Ahmet Yılmaz'ın aldığı ürünler, birim fiyatları ve kategorileri.
4. Her kategorideki ürün sayısı.
5. Müşteri bazında toplam ciro, en yüksekten en düşüğe.
6. Her siparişin üzerinden geçen gün (`DATEDIFF` ve `GETDATE`). Gün sayısı, sorgunun çalıştığı tarihe göre değişir.

`vw_SiparisOzet` görünümü müşteri adını, sipariş tarihini, ürün adını ve adedi tek sonuçta getirir.

Yedek komutu veritabanını `C:\Yedek\NovaStoreDB.bak` dosyasına yazar. Komutun çalışması için `C:\Yedek` klasörünün diskte hazır olması gerekir.

## Çalıştırma

### SQL Server Management Studio

1. Sunucu adı: `localhost\SQLEXPRESS`
2. Kimlik doğrulama: Windows Kimlik Doğrulaması
3. Şifreleme zorunluysa **Sunucu Sertifikasına Güven** kutusunu işaretle.
4. `HaticeKubraElma_NovaStore_Proje.sql` dosyasını açıp **Yürüt** de.

### sqlcmd

Proje klasöründe:

```powershell
sqlcmd -S "localhost\SQLEXPRESS" -E -C -f 65001 -i ".\HaticeKubraElma_NovaStore_Proje.sql"
```

`-C` yerel sunucunun sertifikasını kabul eder. `-f 65001` betiği UTF-8 olarak okur; Türkçe karakterler bu sayede bozulmaz.

## Ortam

- Microsoft SQL Server 2025 Express
- SQL Server Management Studio 22
- Windows kimlik doğrulaması
