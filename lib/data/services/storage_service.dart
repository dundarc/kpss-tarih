import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_data_model.dart';

class StorageService {
  late Box<UserData> _userDataBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserDataAdapter());
    _userDataBox = await Hive.openBox<UserData>('userDataBox');

    if (_userDataBox.isEmpty) {
      // Uygulama ilk kez yüklendiğinde varsayılan kullanıcı verilerini oluştur
      _userDataBox.put('user', UserData(diamondCount: 10, hasSeenWelcomePopup: false));
    }
  }

  UserData getUserData() {
    final data = _userDataBox.get('user');
    if (data != null) {
      data.completedTopicIds ??= [];
      // Yeniden adlandırılmış ve yeni alanları varsayılan değerlerle başlat
      data.storeRewardedAdWatchCount ??= 0;
      data.storeAdCooldownEndTime ??= 0;
      data.unlockedTipsTopicIds ??= [];
      data.hasSeenWelcomePopup ??= false;
      data.timeSpentMinutesToday ??= 0;
      data.lastTimeSpentUpdateDay ??= 0;
      data.dailyTimeRewardClaimed ??= false;
      data.randomTestCorrectAnswersToday ??= 0;
      data.lastRandomTestUpdateDay ??= 0;
      data.dailyRandomTestRewardClaimed ??= false;
      data.dailyPremiumRewardClaimed ??= false;
      data.lastPremiumRewardDay ??= 0;
      data.randomTestEntryAdWatchCount ??= 0; // Yeni alan
      data.randomTestEntryAdCooldownEndTime ??= 0; // Yeni alan
      return data;
    }
    // Her ihtimale karşı varsayılan bir veri döndür.
    return UserData(diamondCount: 10, hasSeenWelcomePopup: false);
  }

  Future<void> updateUserData(UserData data) async {
    await _userDataBox.put('user', data);
  }
}
