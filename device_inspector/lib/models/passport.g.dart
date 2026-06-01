// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passport.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Passport _$PassportFromJson(Map<String, dynamic> json) => Passport(
      passportId: json['passportId'] as String,
      userId: json['userId'] as String,
      platform: json['platform'] as String,
      purchasedApps: (json['purchasedApps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      purchaseTime: json['purchaseTime'] == null
          ? null
          : DateTime.parse(json['purchaseTime'] as String),
      expireTime: json['expireTime'] == null
          ? null
          : DateTime.parse(json['expireTime'] as String),
      status: json['status'] as String,
    );

Map<String, dynamic> _$PassportToJson(Passport instance) => <String, dynamic>{
      'passportId': instance.passportId,
      'userId': instance.userId,
      'platform': instance.platform,
      'purchasedApps': instance.purchasedApps,
      'purchaseTime': instance.purchaseTime?.toIso8601String(),
      'expireTime': instance.expireTime?.toIso8601String(),
      'status': instance.status,
    };
