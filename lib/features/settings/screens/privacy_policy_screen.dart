import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '''
Gizlilik Politikası
Son Güncelleme: 21 Temmuz 2025

Bu gizlilik politikası, [KPSS Tarih] ("uygulama", "biz", "bizim") tarafından geliştirilen ve yayınlanan KPSS Tarih mobil uygulamasının kullanımında geçerlidir.

1. Toplanan Veriler
Uygulamamızda kullanıcı girişi bulunmamaktadır ve sizden doğrudan hiçbir kişisel bilgi (ad, e-posta, telefon numarası vb.) talep edilmez veya toplanmaz.

Ancak, uygulama bazı anonim verileri otomatik olarak toplayabilir:

Cihaz türü, işletim sistemi

Uygulama sürümü ve kullanım istatistikleri

Reklam etkileşimleri (sadece reklam destekli sürümde)

Bu bilgiler sadece uygulamanın performansını iyileştirmek, hataları tespit etmek ve kullanıcı deneyimini geliştirmek amacıyla anonim olarak işlenmektedir.

2. Reklam ve Analiz
Uygulama, Google AdMob gibi üçüncü taraf reklam sağlayıcılarını kullanabilir. Bu servisler, çerezler veya benzeri teknolojiler aracılığıyla anonim kullanım verilerini toplayabilir.

Detaylı bilgi için:
Google’ın Reklam Gizlilik Politikası

3. Uygulama İçi Satın Alımlar
Uygulamada sunulan:

Reklamsız abonelik seçenekleri (Aylık, Yıllık, Ömür Boyu)

Elmas paketleri (sanal içerik)

Google Play ve Apple App Store aracılığıyla güvenli bir şekilde gerçekleşmektedir. Satın alma işlemleri sırasında ödeme sağlayıcıları kullanıcıdan bazı finansal bilgiler talep edebilir. Bu bilgiler bizim tarafımızdan erişilemez ve saklanmaz.

4. Veri Saklama ve Güvenlik
Uygulama içi veriler (elmas bakiyesi, test ilerlemesi vb.) cihazınızda yerel olarak saklanır. Bulut tabanlı kimlik ya da veri senkronizasyonu kullanılmaz.

Her türlü veri, modern güvenlik standartları çerçevesinde korunmaktadır.

5. Çocukların Gizliliği
Uygulama, genel KPSS hazırlık kitlesine yönelik olup 13 yaş altı çocuklara özel içerik barındırmaz. Ancak kullanıcıdan yaş doğrulaması yapılmaz.

6. Politika Değişiklikleri
Gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikler uygulama üzerinden veya mağaza sayfası yoluyla duyurulacaktır.

7. İletişim
Gizliliğe dair herhangi bir sorunuz varsa bizimle iletişime geçebilirsiniz:

E-posta: [app@dundarc.com.tr]
Geliştirici: [dundarc]
          ''',
        ),
      ),
    );
  }
}
