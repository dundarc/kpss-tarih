import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/data/models/user_data_model.dart';
import 'package:kpss_tarih_app/data/services/storage_service.dart';
import 'package:kpss_tarih_app/data/services/content_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final contentServiceProvider = Provider<ContentService>((ref) => ContentService());

class UserDataNotifier extends StateNotifier<UserData> {
  final StorageService _storageService;

  UserDataNotifier(this._storageService) : super(_storageService.getUserData());

  // State'i güncellemeyi kolaylaştıran yardımcı fonksiyon
  UserData _newState({
    int? diamondCount,
    bool? isPremium,
    bool? isLifetimePremium,
    List<String>? completedTopicIds,
    int? rewardedAdWatchCount,
    int? cooldownEndTime,
    List<String>? unlockedTipsTopicIds, // Yeni alan eklendi
  }) {
    return UserData(
      diamondCount: diamondCount ?? state.diamondCount,
      isPremium: isPremium ?? state.isPremium,
      isLifetimePremium: isLifetimePremium ?? state.isLifetimePremium,
      completedTopicIds: completedTopicIds ?? state.completedTopicIds,
      rewardedAdWatchCount: rewardedAdWatchCount ?? state.rewardedAdWatchCount,
      cooldownEndTime: cooldownEndTime ?? state.cooldownEndTime,
      unlockedTipsTopicIds: unlockedTipsTopicIds ?? state.unlockedTipsTopicIds, // Yeni alan eklendi
    );
  }

  // --- YENİ FONKSİYON ---
  // Bir konunun püf noktalarını açar ve 3 elmas harcar.
  bool unlockTips(String topicId) {
    // Zaten açıksa veya yeterli elmas yoksa işlem yapma
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

  // ... (Diğer fonksiyonlar aynı şekilde _newState kullanacak şekilde güncellenmeli)

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

  void useRewardedAd() {
    final newCount = state.rewardedAdWatchCount + 1;
    int newCooldownTime = state.cooldownEndTime;
    if (newCount >= 3) {
      newCooldownTime = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
    }
    state = _newState(rewardedAdWatchCount: newCount, cooldownEndTime: newCooldownTime);
    _storageService.updateUserData(state);
  }

  void resetAdCount() {
    if (DateTime.fromMillisecondsSinceEpoch(state.cooldownEndTime).isBefore(DateTime.now())) {
      state = _newState(rewardedAdWatchCount: 0, cooldownEndTime: 0);
      _storageService.updateUserData(state);
    }
  }
}

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UserDataNotifier(storageService);
});
