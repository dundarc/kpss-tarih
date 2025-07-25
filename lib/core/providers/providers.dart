import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/data/models/user_data_model.dart';
import 'package:kpss_tarih_app/data/services/storage_service.dart';
import 'package:kpss_tarih_app/data/services/content_service.dart';
import 'package:kpss_tarih_app/data/services/pcs.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/material.dart';

import 'package:kpss_tarih_app/main.dart';


final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final contentServiceProvider = Provider<ContentService>((ref) => ContentService());

final mainNavigationSelectedIndexProvider = StateProvider<int>((ref) => 0);

class UserDataNotifier extends StateNotifier<UserData> {
  final StorageService _storageService;
  final Ref _ref;

  UserDataNotifier(this._storageService, this._ref) : super(_storageService.getUserData()) {
    // EKLEME: Ekran görüntüsü almak için premium durumu geçici olarak etkinleştirme
    // Bu satırları ekran görüntülerini aldıktan sonra SİLMEYİ UNUTMAYIN!
   // state = state.copyWith(isPremium: true, isLifetimePremium: true);
    // Veya sadece isPremium yapmak isterseniz:
    // state = state.copyWith(isPremium: true);

    // Bu değişikliği kalıcı hale getirmek isterseniz (genellikle test için tavsiye edilmez):
    // _storageService.updateUserData(state);
  }

  UserData _newState({
    int? diamondCount,
    bool? isPremium,
    bool? isLifetimePremium,
    List<String>? completedTopicIds,
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

  bool _isNewDay(int lastUpdateDay) {
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day).dayOfYear;
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

  bool useStoreRewardedAd() {
    if (DateTime.fromMillisecondsSinceEpoch(state.storeAdCooldownEndTime).isBefore(DateTime.now())) {
      state = _newState(storeRewardedAdWatchCount: 0, storeAdCooldownEndTime: 0);
      _storageService.updateUserData(state);
    }

    if (state.storeRewardedAdWatchCount == 0) {
      state = _newState(
        storeRewardedAdWatchCount: 1,
        diamondCount: state.diamondCount + 5,
        storeAdCooldownEndTime: DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      _storageService.updateUserData(state);
      return true;
    }
    return false;
  }

  bool useRandomTestEntryAd() {
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

  void resetAdCount() {
    if (DateTime.fromMillisecondsSinceEpoch(state.storeAdCooldownEndTime).isBefore(DateTime.now())) {
      state = _newState(storeRewardedAdWatchCount: 0, storeAdCooldownEndTime: 0);
      _storageService.updateUserData(state);
    }
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

  void handlePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
      String successMessage = '';
      switch (purchaseDetails.productID) {
        case aylikAbonelikId:
          state = _newState(isPremium: true, isLifetimePremium: false);
          successMessage = 'Tebrikler! Aylık Premium aboneliğiniz aktif edildi.';
          break;
        case yillikAbonelikId:
          state = _newState(isPremium: true, isLifetimePremium: false);
          successMessage = 'Tebrikler! Yıllık Premium aboneliğiniz aktif edildi.';
          break;
        case omurBoyuId:
          state = _newState(isPremium: true, isLifetimePremium: true);
          successMessage = 'Tebrikler! Ömür Boyu Premium aboneliğiniz aktif edildi.';
          break;
        case elmas100Id:
          addDiamonds(100);
          successMessage = 'Tebrikler! 100 Elmas hesabınıza eklendi.';
          break;
        case elmas250Id:
          addDiamonds(250);
          successMessage = 'Tebrikler! 250 Elmas hesabınıza eklendi.';
          break;
        case elmas500Id:
          addDiamonds(500);
          successMessage = 'Tebrikler! 500 Elmas hesabınıza eklendi.';
          break;
        default:
          successMessage = 'Geçmiş işlemleri kontrol edildi!';
      }
      _storageService.updateUserData(state);
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
      _ref.read(mainNavigationSelectedIndexProvider.notifier).state = 0;
    }
  }

  void handlePurchaseError(String errorMessage) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      String userFriendlyMessage = 'Satın alma işleminde bir hata oluştu: $errorMessage. Lütfen daha sonra tekrar deneyin.';

      if (errorMessage.contains('kullanıcı tarafından iptal edildi')) {
        userFriendlyMessage = 'Satın alma işlemi iptal edildi. Ürün satın alınmadı.';
      } else if (errorMessage.contains('Mağazada ürün bulunamadı')) {
        userFriendlyMessage = 'Satın almak istediğiniz ürün mağazada bulunamadı. Lütfen daha sonra tekrar deneyin.';
      } else if (errorMessage.contains('DEVELOPER_ERROR')) {
        userFriendlyMessage = 'Satın alma işlemi tamamlanamadı. Lütfen Google Play Store ayarlarınızı kontrol edin veya daha sonra tekrar deneyin.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage)),
      );
    }
  }
}

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UserDataNotifier(storageService, ref);
});

extension DateExtension on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays;
  }
}

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
