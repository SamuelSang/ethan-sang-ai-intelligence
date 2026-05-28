/// 订阅计划枚举
enum SubscriptionPlan {
  free,    // 免费版
  pro,     // 专业版
  enterprise, // 企业版
}

/// 用户数据模型
class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final SubscriptionPlan plan;
  final DateTime? planExpiresAt;
  final int reportQuotaTotal;
  final int reportQuotaUsed;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  /// 剩余报告配额
  int get reportQuotaRemaining =>
      (reportQuotaTotal - reportQuotaUsed).clamp(0, reportQuotaTotal);

  /// 是否为付费用户
  bool get isPro =>
      plan == SubscriptionPlan.pro || plan == SubscriptionPlan.enterprise;

  /// 订阅是否有效
  bool get isSubscriptionActive {
    if (plan == SubscriptionPlan.free) return true;
    if (planExpiresAt == null) return false;
    return planExpiresAt!.isAfter(DateTime.now());
  }

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.plan,
    this.planExpiresAt,
    required this.reportQuotaTotal,
    required this.reportQuotaUsed,
    required this.isAnonymous,
    required this.createdAt,
    this.lastSignInAt,
  });

  /// 创建匿名免费用户
  factory User.anonymous() {
    return User(
      id: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
      plan: SubscriptionPlan.free,
      reportQuotaTotal: 3,
      reportQuotaUsed: 0,
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      planExpiresAt: json['planExpiresAt'] != null
          ? DateTime.parse(json['planExpiresAt'] as String)
          : null,
      reportQuotaTotal: json['reportQuotaTotal'] as int? ?? 3,
      reportQuotaUsed: json['reportQuotaUsed'] as int? ?? 0,
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastSignInAt: json['lastSignInAt'] != null
          ? DateTime.parse(json['lastSignInAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'plan': plan.name,
      if (planExpiresAt != null)
        'planExpiresAt': planExpiresAt!.toIso8601String(),
      'reportQuotaTotal': reportQuotaTotal,
      'reportQuotaUsed': reportQuotaUsed,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      if (lastSignInAt != null)
        'lastSignInAt': lastSignInAt!.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    SubscriptionPlan? plan,
    DateTime? planExpiresAt,
    int? reportQuotaTotal,
    int? reportQuotaUsed,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      plan: plan ?? this.plan,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      reportQuotaTotal: reportQuotaTotal ?? this.reportQuotaTotal,
      reportQuotaUsed: reportQuotaUsed ?? this.reportQuotaUsed,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }

  @override
  String toString() =>
      'User(id: $id, plan: ${plan.name}, quota: $reportQuotaRemaining/$reportQuotaTotal)';
}
