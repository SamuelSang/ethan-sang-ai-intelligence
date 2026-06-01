import 'package:json_annotation/json_annotation.dart';

part 'passport.g.dart';

@JsonSerializable()
class Passport {
  final String passportId;
  final String userId;           // UnionID或设备指纹
  final String platform;         // 'miniprogram' | 'windows' | 'macos'
  final List<String> purchasedApps;
  final DateTime? purchaseTime;
  final DateTime? expireTime;
  final String status;           // 'active' | 'expired'

  Passport({
    required this.passportId,
    required this.userId,
    required this.platform,
    required this.purchasedApps,
    this.purchaseTime,
    this.expireTime,
    required this.status,
  });

  bool get isValid => status == 'active' && expireTime == null;

  factory Passport.fromJson(Map<String, dynamic> json) =>
      _$PassportFromJson(json);
  Map<String, dynamic> toJson() => _$PassportToJson(this);
}