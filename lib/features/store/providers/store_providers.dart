// lib/features/store/providers/store_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kpss_tarih_app/features/store/services/purchase_service.dart';
import 'package:kpss_tarih_app/features/store/models/user_plan.dart';

// 1. PurchaseService için ChangeNotifierProvider
// Bu provider, PurchaseService'i başlatır ve uygulama genelinde erişilebilir kılar.
final purchaseServiceProvider = ChangeNotifierProvider<PurchaseService>((ref) {
  final service = PurchaseService();
  service.initialize();
  return service;
});

// 2. Kullanıcı Planı için Provider
// Bu provider, PurchaseService'i dinler ve güncel kullanıcı planını (free, premium, fullPremium) döndürür.
// Uygulamanın herhangi bir yerinde reklam gösterme gibi kararlar için bu provider kullanılır.
final userPlanProvider = Provider<UserPlan>((ref) {
  // purchaseServiceProvider'daki değişiklikleri izler.
  final purchaseService = ref.watch(purchaseServiceProvider);
  // Servisten güncel kullanıcı planını alır ve döndürür.
  return purchaseService.userPlan;
});

// 3. Elmas Sayısı için StateNotifierProvider
// Bu provider, kullanıcının elmas sayısını yönetir ve değişiklikleri SharedPreferences'e kaydeder.
final diamondNotifierProvider = StateNotifierProvider<DiamondNotifier, int>((ref) {
  return DiamondNotifier(ref);
});

class DiamondNotifier extends StateNotifier<int> {
  final Ref _ref;
  static const _diamondKey = 'user_diamond_count';

  DiamondNotifier(this._ref) : super(0) {
    _loadDiamonds();
  }

  // Cihaz hafızasından elmas sayısını yükler
  Future<void> _loadDiamonds() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_diamondKey) ?? 0; // Başlangıçta 0 elmas
  }

  // Elmas ekler ve hafızaya kaydeder
  Future<void> addDiamonds(int amount) async {
    state += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_diamondKey, state);
  }

  // Elmas harcar ve hafızaya kaydeder
  Future<bool> spendDiamonds(int amount) async {
    if (state >= amount) {
      state -= amount;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_diamondKey, state);
      return true; // İşlem başarılı
    }
    return false; // Yetersiz elmas
  }
}
