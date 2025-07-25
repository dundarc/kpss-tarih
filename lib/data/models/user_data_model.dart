import 'package:hive/hive.dart';

part 'user_data_model.g.dart';

@HiveType(typeId: 0)
class UserData extends HiveObject {
  @HiveField(0)
  int diamondCount;

  @HiveField(1)
  bool isPremium;

  @HiveField(2)
  bool isLifetimePremium;

  @HiveField(3)
  List<String> completedTopicIds;

  // Ödüllü reklam sayaçları ve cooldown süreleri güncellendi
  @HiveField(4)
  int storeRewardedAdWatchCount; // Mağaza ödüllü reklam izleme sayısı
  @HiveField(5)
  int storeAdCooldownEndTime; // Mağaza ödüllü reklam cooldown süresi

  @HiveField(6)
  List<String> unlockedTipsTopicIds;

  @HiveField(7)
  bool hasSeenWelcomePopup;

  @HiveField(8)
  int timeSpentMinutesToday; // Bugün uygulamada geçirilen dakika
  @HiveField(9)
  int lastTimeSpentUpdateDay; // Son dakika güncellemesinin yapıldığı gün (yılın günü)
  @HiveField(10)
  bool dailyTimeRewardClaimed; // Günlük süre ödülü alındı mı

  @HiveField(11)
  int randomTestCorrectAnswersToday; // Bugün rastgele testlerde verilen doğru cevap sayısı
  @HiveField(12)
  int lastRandomTestUpdateDay; // Son rastgele test güncellemesinin yapıldığı gün (yılın günü)
  @HiveField(13)
  bool dailyRandomTestRewardClaimed; // Günlük rastgele test ödülü alındı mı

  @HiveField(14)
  bool dailyPremiumRewardClaimed; // Premium günlük ödül alındı mı
  @HiveField(15)
  int lastPremiumRewardDay; // Son premium ödülün alındığı gün (yılın günü)

  // YENİ ALANLAR: Rastgele test girişi için ödüllü reklam sayaçları
  @HiveField(16)
  int randomTestEntryAdWatchCount; // Rastgele test girişi ödüllü reklam izleme sayısı
  @HiveField(17)
  int randomTestEntryAdCooldownEndTime; // Rastgele test girişi ödüllü reklam cooldown süresi


  UserData({
    required this.diamondCount,
    this.isPremium = false,
    this.isLifetimePremium = false,
    this.completedTopicIds = const [],
    // Varsayılan değerler güncellendi
    this.storeRewardedAdWatchCount = 0,
    this.storeAdCooldownEndTime = 0,
    this.unlockedTipsTopicIds = const [],
    this.hasSeenWelcomePopup = false,
    this.timeSpentMinutesToday = 0,
    this.lastTimeSpentUpdateDay = 0,
    this.dailyTimeRewardClaimed = false,
    this.randomTestCorrectAnswersToday = 0,
    this.lastRandomTestUpdateDay = 0,
    this.dailyRandomTestRewardClaimed = false,
    this.dailyPremiumRewardClaimed = false,
    this.lastPremiumRewardDay = 0,
    // Yeni alanlar için varsayılan değerler
    this.randomTestEntryAdWatchCount = 0,
    this.randomTestEntryAdCooldownEndTime = 0,
  });

  // copyWith metodunu ekliyoruz
  UserData copyWith({
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
      diamondCount: diamondCount ?? this.diamondCount,
      isPremium: isPremium ?? this.isPremium,
      isLifetimePremium: isLifetimePremium ?? this.isLifetimePremium,
      completedTopicIds: completedTopicIds ?? this.completedTopicIds,
      storeRewardedAdWatchCount: storeRewardedAdWatchCount ?? this.storeRewardedAdWatchCount,
      storeAdCooldownEndTime: storeAdCooldownEndTime ?? this.storeAdCooldownEndTime,
      unlockedTipsTopicIds: unlockedTipsTopicIds ?? this.unlockedTipsTopicIds,
      hasSeenWelcomePopup: hasSeenWelcomePopup ?? this.hasSeenWelcomePopup,
      timeSpentMinutesToday: timeSpentMinutesToday ?? this.timeSpentMinutesToday,
      lastTimeSpentUpdateDay: lastTimeSpentUpdateDay ?? this.lastTimeSpentUpdateDay,
      dailyTimeRewardClaimed: dailyTimeRewardClaimed ?? this.dailyTimeRewardClaimed,
      randomTestCorrectAnswersToday: randomTestCorrectAnswersToday ?? this.randomTestCorrectAnswersToday,
      lastRandomTestUpdateDay: lastRandomTestUpdateDay ?? this.lastRandomTestUpdateDay,
      dailyRandomTestRewardClaimed: dailyRandomTestRewardClaimed ?? this.dailyRandomTestRewardClaimed,
      dailyPremiumRewardClaimed: dailyPremiumRewardClaimed ?? this.dailyPremiumRewardClaimed,
      lastPremiumRewardDay: lastPremiumRewardDay ?? this.lastPremiumRewardDay,
      randomTestEntryAdWatchCount: randomTestEntryAdWatchCount ?? this.randomTestEntryAdWatchCount,
      randomTestEntryAdCooldownEndTime: randomTestEntryAdCooldownEndTime ?? this.randomTestEntryAdCooldownEndTime,
    );
  }
}
