import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/data/models/user_data_model.dart';
import 'package:kpss_tarih_app/data/services/storage_service.dart';
import 'package:kpss_tarih_app/data/services/content_service.dart';
import 'package:kpss_tarih_app/data/services/purchase_service.dart'; // PurchaseService için eklendi
import 'package:in_app_purchase/in_app_purchase.dart'; // PurchaseDetails için eklendi
import 'package:flutter/material.dart'; // ChangeNotifier ve SnackBar için

// main.dart'tan gelen GlobalKey'e erişim için
import 'package:kpss_tarih_app/main.dart';


final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final contentServiceProvider = Provider<ContentService>((ref) => ContentService());

// Ana navigasyonun seçili sekme indeksini yöneten provider
final mainNavigationSelectedIndexProvider = StateProvider<int>((ref) => 0);

class UserDataNotifier extends StateNotifier<UserData> {
  final StorageService _storageService;
  // Ref'i sadece provider'lara erişim için tutuyoruz, context için değil.
  final Ref _ref;

  UserDataNotifier(this._storageService, this._ref) : super(_storageService.getUserData());

  // State'i güncellemeyi kolaylaştıran yardımcı fonksiyon
  UserData _newState({
    int? diamondCount,
    bool? isPremium,
    bool? isLifetimePremium,
    List<String>? completedTopicIds,
    // Yeniden adlandırılmış ve yeni alanlar
    int? storeRewardedAdWatchCount,
    int? storeAdCooldownEndTime,
    List<String>? unlockedTipsTopicIds,
    bool? hasSeenWelcomePopup,
    int? timeSpentMinutesToday,
    int? lastTimeSpentUpdateDay,
    bool? dailyTimeRewardClaimed,
    int? randomTestCorrectAnswersToday,
    int? lastRandomTestUpdateDay,
    bool? dailyRandomTestRewardClaimed,
    bool? dailyPremiumRewardClaimed,
    int? lastPremiumRewardDay,
    int? randomTestEntryAdWatchCount,
    int? randomTestEntryAdCooldownEndTime,
  }) {
    return UserData(
      diamondCount: diamondCount ?? state.diamondCount,
      isPremium: isPremium ?? state.isPremium,
      isLifetimePremium: isLifetimePremium ?? state.isLifetimePremium,
      completedTopicIds: completedTopicIds ?? state.completedTopicIds,
      // Yeniden adlandırılmış ve yeni alanlar
      storeRewardedAdWatchCount: storeRewardedAdWatchCount ?? state.storeRewardedAdWatchCount,
      storeAdCooldownEndTime: storeAdCooldownEndTime ?? state.storeAdCooldownEndTime,
      unlockedTipsTopicIds: unlockedTipsTopicIds ?? state.unlockedTipsTopicIds,
      hasSeenWelcomePopup: hasSeenWelcomePopup ?? state.hasSeenWelcomePopup,
      timeSpentMinutesToday: timeSpentMinutesToday ?? state.timeSpentMinutesToday,
      lastTimeSpentUpdateDay: lastTimeSpentUpdateDay ?? state.lastTimeSpentUpdateDay,
      dailyTimeRewardClaimed: dailyTimeRewardClaimed ?? state.dailyTimeRewardClaimed,
      randomTestCorrectAnswersToday: randomTestCorrectAnswersToday ?? state.randomTestCorrectAnswersToday,
      lastRandomTestUpdateDay: lastRandomTestUpdateDay ?? state.lastRandomTestUpdateDay,
      dailyRandomTestRewardClaimed: dailyRandomTestRewardClaimed ?? state.dailyRandomTestRewardClaimed,
      dailyPremiumRewardClaimed: dailyPremiumRewardClaimed ?? state.dailyPremiumRewardClaimed,
      lastPremiumRewardDay: lastPremiumRewardDay ?? state.lastPremiumRewardDay,
      randomTestEntryAdWatchCount: randomTestEntryAdWatchCount ?? state.randomTestEntryAdWatchCount,
      randomTestEntryAdCooldownEndTime: randomTestEntryAdCooldownEndTime ?? state.randomTestEntryAdCooldownEndTime,
    );
  }

  // Yardımcı fonksiyon: Günün değişip değişmediğini kontrol eder
  bool _isNewDay(int lastUpdateDay) {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day).dayOfYear; // Yılın günü
    return currentDay != lastUpdateDay;
  }

  bool spendDiamonds(int amount) {
    if (state.diamondCount >= amount) {
      state = _newState(diamondCount: state.diamondCount - amount);
      _storageService.updateUserData(state);
      return true;
    }
    return false;
  }

  void addDiamonds(int amount) {
    state = _newState(diamondCount: state.diamondCount + amount);
    _storageService.updateUserData(state);
  }

  void completeTopic(String topicId) {
    if (state.completedTopicIds.contains(topicId)) return;
    final updatedList = List<String>.from(state.completedTopicIds)..add(topicId);
    state = _newState(completedTopicIds: updatedList);
    _storageService.updateUserData(state);
  }

  // YENİ: Mağaza için ödüllü reklam izleme mantığı (5 elmas verir)
  bool useStoreRewardedAd() {
    // Cooldown süresi dolduysa sayacı sıfırla
    if (DateTime.fromMillisecondsSinceEpoch(state.storeAdCooldownEndTime).isBefore(DateTime.now())) {
      state = _newState(storeRewardedAdWatchCount: 0, storeAdCooldownEndTime: 0);
      _storageService.updateUserData(state);
    }

    if (state.storeRewardedAdWatchCount == 0) {
      state = _newState(
        storeRewardedAdWatchCount: 1,
        diamondCount: state.diamondCount + 5, // 5 elmas verir
        storeAdCooldownEndTime: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      _storageService.updateUserData(state);
      return true;
    }
    return false;
  }

  // YENİ: Rastgele test girişi için ödüllü reklam izleme mantığı (elmas vermez)
  bool useRandomTestEntryAd() {
    // Cooldown süresi dolduysa sayacı sıfırla
    if (DateTime.fromMillisecondsSinceEpoch(state.randomTestEntryAdCooldownEndTime).isBefore(DateTime.now())) {
      state = _newState(randomTestEntryAdWatchCount: 0, randomTestEntryAdCooldownEndTime: 0);
      _storageService.updateUserData(state);
    }

    if (state.randomTestEntryAdWatchCount == 0) {
      state = _newState(
        randomTestEntryAdWatchCount: 1,
        randomTestEntryAdCooldownEndTime: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      _storageService.updateUserData(state);
      return true;
    }
    return false;
  }

  // Bu fonksiyon artık kullanılmıyor, yerine useStoreRewardedAd ve useRandomTestEntryAd kullanılıyor.
  // Ancak, diğer yerlerdeki çağrılar için geçici olarak bırakılabilir veya kaldırılabilir.
  void resetAdCount() {
    // Mağaza reklamı cooldown kontrolü
    if (DateTime.fromMillisecondsSinceEpoch(state.storeAdCooldownEndTime).isBefore(DateTime.now())) {
      state = _newState(storeRewardedAdWatchCount: 0, storeAdCooldownEndTime: 0);
      _storageService.updateUserData(state);
    }
    // Rastgele test girişi reklamı cooldown kontrolü
    if (DateTime.fromMillisecondsSinceEpoch(state.randomTestEntryAdCooldownEndTime).isBefore(DateTime.now())) {
      state = _newState(randomTestEntryAdWatchCount: 0, randomTestEntryAdCooldownEndTime: 0);
      _storageService.updateUserData(state);
    }
  }

  void markWelcomePopupSeen() {
    state = _newState(hasSeenWelcomePopup: true);
    _storageService.updateUserData(state);
  }

  void updateTimeSpent(int minutes) {
    final currentDay = DateTime.now().dayOfYear;

    if (_isNewDay(state.lastTimeSpentUpdateDay)) {
      state = _newState(
        timeSpentMinutesToday: 0,
        dailyTimeRewardClaimed: false,
        lastTimeSpentUpdateDay: currentDay,
      );
    }

    int newTimeSpent = state.timeSpentMinutesToday + minutes;
    state = _newState(timeSpentMinutesToday: newTimeSpent, lastTimeSpentUpdateDay: currentDay);
    _storageService.updateUserData(state);

    if (state.timeSpentMinutesToday >= 20 && !state.dailyTimeRewardClaimed) {
      addDiamonds(3);
      state = _newState(dailyTimeRewardClaimed: true);
      _storageService.updateUserData(state);
    }
  }

  void recordRandomTestResult(int correctCount) {
    final currentDay = DateTime.now().dayOfYear;

    if (_isNewDay(state.lastRandomTestUpdateDay)) {
      state = _newState(
        randomTestCorrectAnswersToday: 0,
        dailyRandomTestRewardClaimed: false,
        lastRandomTestUpdateDay: currentDay,
      );
    }

    int newCorrectAnswers = state.randomTestCorrectAnswersToday + correctCount;
    state = _newState(randomTestCorrectAnswersToday: newCorrectAnswers, lastRandomTestUpdateDay: currentDay);
    _storageService.updateUserData(state);

    if (state.randomTestCorrectAnswersToday >= 7 && !state.dailyRandomTestRewardClaimed) {
      addDiamonds(2);
      state = _newState(dailyRandomTestRewardClaimed: true);
      _storageService.updateUserData(state);
    }
  }

  bool claimDailyPremiumReward() {
    final currentDay = DateTime.now().dayOfYear;

    if (_isNewDay(state.lastPremiumRewardDay)) {
      state = _newState(
        dailyPremiumRewardClaimed: false,
        lastPremiumRewardDay: currentDay,
      );
    }

    if ((state.isPremium || state.isLifetimePremium) && !state.dailyPremiumRewardClaimed) {
      addDiamonds(1);
      state = _newState(dailyPremiumRewardClaimed: true);
      _storageService.updateUserData(state);
      return true;
    }
    return false;
  }

  void markDailyTimeRewardClaimed() {
    state = _newState(dailyTimeRewardClaimed: true);
    _storageService.updateUserData(state);
  }

  void markDailyRandomTestRewardClaimed() {
    state = _newState(dailyRandomTestRewardClaimed: true);
    _storageService.updateUserData(state);
  }

  // Püf noktalarını açar (UserDataNotifier'a taşındı)
  bool unlockTips(String topicId) {
    if (state.unlockedTipsTopicIds.contains(topicId) || state.diamondCount < 3) {
      return false;
    }

    final updatedUnlockedList = List<String>.from(state.unlockedTipsTopicIds)..add(topicId);

    state = _newState(
      diamondCount: state.diamondCount - 3,
      unlockedTipsTopicIds: updatedUnlockedList,
    );
    _storageService.updateUserData(state);
    return true;
  }

  // YENİ: Satın alma başarılarını işleyen metot
  void handlePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
      switch (purchaseDetails.productID) {
        case aylikAbonelikId:
        case yillikAbonelikId:
          state = _newState(isPremium: true, isLifetimePremium: false);
          break;
        case omurBoyuId:
          state = _newState(isPremium: true, isLifetimePremium: true);
          break;
        case elmas100Id:
          addDiamonds(100);
          break;
        case elmas250Id:
          addDiamonds(250);
          break;
        case elmas500Id:
          addDiamonds(500);
          break;
      }
      _storageService.updateUserData(state);
      // UI'a bildirim göndermek için SnackBar gösterebiliriz
      // GlobalKey üzerinden context'e erişim
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${purchaseDetails.productID} başarıyla satın alındı/geri yüklendi!')),
        );
      }
      _ref.read(mainNavigationSelectedIndexProvider.notifier).state = 0; // Ana sayfaya dön
    }
  }

  // YENİ: Satın alma hatalarını işleyen metot
  void handlePurchaseError(String errorMessage) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satın alma hatası: $errorMessage')),
      );
    }
  }
}

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UserDataNotifier(storageService, ref); // ref'i de iletiyoruz
});

extension DateExtension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays;
  }
}

// YENİ: PurchaseService'i sağlayan provider
final purchaseServiceProvider = ChangeNotifierProvider<PurchaseService>((ref) {
  final userDataNotifier = ref.read(userDataProvider.notifier);
  return PurchaseService(
    onPurchaseSuccessCallback: (purchaseDetails) {
      userDataNotifier.handlePurchase(purchaseDetails);
    },
    onPurchaseErrorCallback: (errorMessage) {
      userDataNotifier.handlePurchaseError(errorMessage);
    },
  );
});
