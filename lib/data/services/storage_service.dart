import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_data_model.dart'; // UserData modelini import et

class StorageService {
  late Box<UserData> _userDataBox; // UserData tipinde bir Hive kutusu

  // Depolama servisini başlatır
  Future<void> init() async {
    await Hive.initFlutter(); // Hive'ı Flutter için başlat
    Hive.registerAdapter(UserDataAdapter()); // UserData adaptörünü kaydet
    _userDataBox = await Hive.openBox<UserData>('userDataBox'); // 'userDataBox' adında bir kutu aç

    // Eğer kutu boşsa, varsayılan kullanıcı verilerini oluştur
    if (_userDataBox.isEmpty) {
      _userDataBox.put('user', UserData(diamondCount: 10, hasSeenWelcomePopup: false));
    }
  }

  // Kullanıcı verilerini getirir
  UserData getUserData() {
    final data = _userDataBox.get('user'); // 'user' anahtarıyla veriyi al
    if (data != null) {
      // Nullable alanlar için varsayılan değerleri ata (uygulama güncellemelerinde oluşabilecek sorunları önler)
      data.completedTopicIds ??= [];
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
      data.randomTestEntryAdWatchCount ??= 0;
      data.randomTestEntryAdCooldownEndTime ??= 0;
      return data;
    }
    // Eğer veri yoksa veya null ise, varsayılan bir UserData nesnesi döndür
    return UserData(diamondCount: 10, hasSeenWelcomePopup: false);
  }

  // Kullanıcı verilerini günceller
  Future<void> updateUserData(UserData data) async {
    await _userDataBox.put('user', data); // 'user' anahtarıyla veriyi güncelle
  }
}
