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

  @HiveField(4)
  int rewardedAdWatchCount;

  @HiveField(5)
  int cooldownEndTime;

  // YENİ ALAN: Hangi konuların püf noktalarının açıldığını tutar.
  @HiveField(6)
  List<String> unlockedTipsTopicIds;

  UserData({
    required this.diamondCount,
    this.isPremium = false,
    this.isLifetimePremium = false,
    this.completedTopicIds = const [],
    this.rewardedAdWatchCount = 0,
    this.cooldownEndTime = 0,
    this.unlockedTipsTopicIds = const [], // Başlangıçta boş liste
  });
}
