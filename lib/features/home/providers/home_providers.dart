import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kpss_tarih_app/features/home/data/historical_events.dart';

// Bu provider, "Tarihte Bugün" olayını dinamik olarak sağlar.
final todayInHistoryProvider = Provider<String>((ref) {
  final now = DateTime.now();
  // Tarihi "AY-GÜN" formatına çevir (örn: "07-22")
  final String formattedDateKey = DateFormat('MM-dd').format(now);

  // O güne ait bir olay var mı diye kontrol et
  if (historicalEvents.containsKey(formattedDateKey)) {
    // Varsa, o olayı döndür
    return historicalEvents[formattedDateKey]!;
  } else {
    // Yoksa, listeden rastgele bir olay seç
    final random = Random();
    final randomKey = historicalEvents.keys.elementAt(random.nextInt(historicalEvents.length));

    // Rastgele seçilen olayın tarihini de metne ekle
    try {
      final dateParts = randomKey.split('-');
      final month = int.parse(dateParts[0]);
      final day = int.parse(dateParts[1]);
      final date = DateTime(now.year, month, day);
      final formattedDate = DateFormat('d MMMM', 'tr_TR').format(date); // Örn: "22 Temmuz"
      return '$formattedDate: ${historicalEvents[randomKey]!}';
    } catch (e) {
      // Herhangi bir hata olursa, sadece rastgele bir olayı döndür
      return historicalEvents.values.first;
    }
  }
});
