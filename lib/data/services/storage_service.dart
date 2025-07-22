import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_data_model.dart';

class StorageService {
  late Box<UserData> _userDataBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserDataAdapter());
    _userDataBox = await Hive.openBox<UserData>('userDataBox');

    if (_userDataBox.isEmpty) {
      _userDataBox.put('user', UserData(diamondCount: 10));
    }
  }

  UserData getUserData() {
    final data = _userDataBox.get('user');
    if (data != null) {
      // DÜZELTME: Eski veriye sahip kullanıcılar için
      // tamamlanan konular listesinin null (boş) olmasını engelle.
      data.completedTopicIds ??= [];
      data.rewardedAdWatchCount ??= 0;
      data.cooldownEndTime ??= 0;
      return data;
    }
    // Her ihtimale karşı varsayılan bir veri döndür.
    return UserData(diamondCount: 10);
  }

  Future<void> updateUserData(UserData data) async {
    await _userDataBox.put('user', data);
  }
}
