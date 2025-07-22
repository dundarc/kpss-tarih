// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 0;

  @override
  UserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserData(
      diamondCount: fields[0] as int,
      isPremium: fields[1] as bool,
      isLifetimePremium: fields[2] as bool,
      completedTopicIds: (fields[3] as List).cast<String>(),
      storeRewardedAdWatchCount: fields[4] as int,
      storeAdCooldownEndTime: fields[5] as int,
      unlockedTipsTopicIds: (fields[6] as List).cast<String>(),
      hasSeenWelcomePopup: fields[7] as bool,
      timeSpentMinutesToday: fields[8] as int,
      lastTimeSpentUpdateDay: fields[9] as int,
      dailyTimeRewardClaimed: fields[10] as bool,
      randomTestCorrectAnswersToday: fields[11] as int,
      lastRandomTestUpdateDay: fields[12] as int,
      dailyRandomTestRewardClaimed: fields[13] as bool,
      dailyPremiumRewardClaimed: fields[14] as bool,
      lastPremiumRewardDay: fields[15] as int,
      randomTestEntryAdWatchCount: fields[16] as int,
      randomTestEntryAdCooldownEndTime: fields[17] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.diamondCount)
      ..writeByte(1)
      ..write(obj.isPremium)
      ..writeByte(2)
      ..write(obj.isLifetimePremium)
      ..writeByte(3)
      ..write(obj.completedTopicIds)
      ..writeByte(4)
      ..write(obj.storeRewardedAdWatchCount)
      ..writeByte(5)
      ..write(obj.storeAdCooldownEndTime)
      ..writeByte(6)
      ..write(obj.unlockedTipsTopicIds)
      ..writeByte(7)
      ..write(obj.hasSeenWelcomePopup)
      ..writeByte(8)
      ..write(obj.timeSpentMinutesToday)
      ..writeByte(9)
      ..write(obj.lastTimeSpentUpdateDay)
      ..writeByte(10)
      ..write(obj.dailyTimeRewardClaimed)
      ..writeByte(11)
      ..write(obj.randomTestCorrectAnswersToday)
      ..writeByte(12)
      ..write(obj.lastRandomTestUpdateDay)
      ..writeByte(13)
      ..write(obj.dailyRandomTestRewardClaimed)
      ..writeByte(14)
      ..write(obj.dailyPremiumRewardClaimed)
      ..writeByte(15)
      ..write(obj.lastPremiumRewardDay)
      ..writeByte(16)
      ..write(obj.randomTestEntryAdWatchCount)
      ..writeByte(17)
      ..write(obj.randomTestEntryAdCooldownEndTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
