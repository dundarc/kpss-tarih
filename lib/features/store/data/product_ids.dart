// lib/features/store/data/product_ids.dart

// Bu set, mağazadan çekilecek tüm ürün ID'lerini içerir.
const Set<String> productIds = {
  ...subscriptionIds,
  ...consumableIds,
};

// Abonelik ve ömür boyu ürün ID'leri
const Set<String> subscriptionIds = {
  'aylik_reklamsiz_39_99tl',
  'yillik_reklamsiz_299_99tl',
  'omur_boyu_reklamsiz_749_99tl',
};

// Tüketilebilir ürünlerin ID'leri
const Set<String> consumableIds = {
  '100_elmas_49_99tl',
  '250_elmas_99_99tl',
  '500_elmas_179_99tl',
};

// Ömür boyu ürün ID'si
const String omurBoyuId = 'omur_boyu_reklamsiz_749_99tl';
