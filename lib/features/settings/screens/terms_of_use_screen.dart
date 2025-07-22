import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Koşulları'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '''
Kullanım Koşulları
Son Güncelleme: 21 Temmuz 2025

Bu kullanım koşulları, [KPSS Tarih] ("biz", "bizim", "uygulama") tarafından geliştirilen KPSS Tarih mobil uygulamasının kullanımına ilişkin şartları belirler. Uygulamayı kullanarak bu koşulları kabul etmiş sayılırsınız.

1. Uygulamanın Amacı
KPSS Tarih, Kamu Personeli Seçme Sınavı'na (KPSS) hazırlanan bireyler için tarih konularını anlatan, test çözümleri sunan, dijital içeriklerle desteklenen mobil bir eğitim uygulamasıdır.

2. Hesap Oluşturma ve Kayıt
Bu uygulama kayıt veya kullanıcı hesabı gerektirmez. Tüm kullanım anonim olarak gerçekleşmektedir.

3. İçerik ve Testler
Uygulamadaki tüm konu anlatımları ve test içerikleri yalnızca bilgilendirme ve eğitim amacıyla sunulmaktadır.

İçerikler zamanla güncellenebilir, değiştirilebilir veya kaldırılabilir.

Uygulamada sunulan testler, resmi sınavla birebir örtüşmeyebilir.

4. Elmas Sistemi ve Satın Alımlar
Uygulama içinde "Elmas" adlı sanal birim kullanılmaktadır. Bu birim, test açmak ve bazı içeriklere erişmek için kullanılır.

Elmaslar:

Uygulama içi satın alma yoluyla edinilebilir.

Test çözümlerindeki başarıya bağlı olarak kazanılabilir.

Elmaslar gerçek para karşılığı geri çevrilemez ve başka bir hesaba/cihaza aktarılmaz.

Satın alma işlemleri Apple App Store veya Google Play üzerinden gerçekleşir ve kendi hizmet şartlarına tabidir.

5. Abonelik Sistemi
Kullanıcılara sunulan abonelik seçenekleri:

Aylık Reklamsız Sürüm – 20 TL

Yıllık Reklamsız Sürüm – 200 TL

Ömür Boyu Reklamsız Sürüm – 499 TL

Satın alınan abonelik süresince uygulama içinde reklam gösterilmez. Abonelikler, platformun (Google/Apple) abonelik politikalarına göre yönetilir.

6. Fikri Mülkiyet
Uygulamada yer alan tüm metin, görsel, ikon, test ve yazılım unsurları [Geliştirici Adı/Firma Adı]’na aittir.

İçeriklerin izinsiz kopyalanması, dağıtılması veya ticari amaçlarla kullanılması yasaktır.

7. Reklamlar
Uygulamanın ücretsiz sürümünde reklamlar gösterilir (ör. konu anlatımı sayfalarında banner reklamlar).

Reklamsız sürüm satın alan kullanıcılar bu reklamlardan muaftır.

8. Sorumluluğun Sınırlandırılması
Uygulama "olduğu gibi" sunulmaktadır. Her ne kadar doğru ve güncel içerik sağlamak için çaba gösterilse de, uygulama kullanımı sonucunda ortaya çıkabilecek hatalar, eksikler veya sınav sonuçlarıyla ilgili herhangi bir garanti verilmez.

9. Koşulların Güncellenmesi
Bu kullanım koşulları zaman zaman güncellenebilir. Değişiklikler uygulama içinde veya mağaza sayfasında yayımlandığı anda geçerli olur.

10. İletişim
Herhangi bir sorunuz, öneriniz veya şikayetiniz varsa bizimle iletişime geçebilirsiniz:

E-posta: [app@dundarc.com.tr]
Geliştirici: [dundarc]
          ''',
        ),
      ),
    );
  }
}