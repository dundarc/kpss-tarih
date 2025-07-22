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
      rewardedAdWatchCount: fields[4] as int,
      cooldownEndTime: fields[5] as int,
      unlockedTipsTopicIds: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.diamondCount)
      ..writeByte(1)
      ..write(obj.isPremium)
      ..writeByte(2)
      ..write(obj.isLifetimePremium)
      ..writeByte(3)
      ..write(obj.completedTopicIds)
      ..writeByte(4)
      ..write(obj.rewardedAdWatchCount)
      ..writeByte(5)
      ..write(obj.cooldownEndTime)
      ..writeByte(6)
      ..write(obj.unlockedTipsTopicIds);
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
