import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../services/platform_navigation.dart';
import '../../widgets/common_widgets.dart';
import '../report/report_page.dart';

class DeviceInfoPage extends ConsumerStatefulWidget {
  final String serialNumber;

  const DeviceInfoPage({super.key, required this.serialNumber});

  @override
  ConsumerState<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends ConsumerState<DeviceInfoPage> {
  @override
  void initState() {
    super.initState();
    // 如果尚未查询，自动发起
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(deviceQueryProvider);
      if (state.activationLockResult == null && !state.isLoading) {
        ref.read(deviceQueryProvider.notifier).queryBySerial(widget.serialNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(deviceQueryProvider);
    final isPurchased = ref.watch(isPurchasedProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('设备信息'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(
              label: isPurchased ? '进阶版' : '免费版',
              color: isPurchased ? AppTheme.success : AppTheme.textMuted,
              icon: isPurchased ? Icons.star_rounded : Icons.star_border_rounded,
            ),
          ),
        ],
      ),
      body: queryState.isLoading
          ? const _LoadingView()
          : queryState.error != null
              ? _ErrorView(error: queryState.error!, serial: widget.serialNumber)
              : _ContentView(
                  serialNumber: widget.serialNumber,
                  queryResult: queryState.activationLockResult ?? {},
                  isPurchased: isPurchased,
                ),
      bottomNavigationBar: queryState.isLoading || queryState.error != null
          ? null
          : _BottomBar(serialNumber: widget.serialNumber),
    );
  }
}

// ———— Loading ————

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          const Text('正在查询设备信息…',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('连接苹果服务器中，请稍候',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ———— Error ————

class _ErrorView extends ConsumerWidget {
  final String error;
  final String serial;

  const _ErrorView({required this.error, required this.serial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppTheme.danger, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('查询失败',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 28),
            GradientButton(
              label: '重新查询',
              icon: Icons.refresh_rounded,
              onPressed: () {
                ref.read(deviceQueryProvider.notifier).queryBySerial(serial);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ———— 主内容 ————

class _ContentView extends StatelessWidget {
  final String serialNumber;
  final Map<String, dynamic> queryResult;
  final bool isPurchased;

  const _ContentView({
    required this.serialNumber,
    required this.queryResult,
    required this.isPurchased,
  });

  @override
  Widget build(BuildContext context) {
    // 从查询结果中解析数据（按后端返回字段）
    final model = queryResult['model'] as String? ?? '未知型号';
    final capacity = queryResult['capacity'] as String? ?? '-';
    final color = queryResult['color'] as String? ?? '-';
    final region = queryResult['region'] as String? ?? '-';
    final activationLocked = queryResult['activationLocked'] as bool? ?? false;
    final activationStatus = queryResult['activationStatus'] as String? ?? '未知';
    final isMdmLocked = queryResult['mdmLocked'] as bool?;
    final isRefurbished = queryResult['isRefurbished'] as bool?;
    final parts = queryResult['parts'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // 设备头部卡片
        _DeviceHeaderCard(
          model: model,
          serialNumber: serialNumber,
          capacity: capacity,
          color: color,
          region: region,
        ),
        const SizedBox(height: 16),

        // ① 激活锁状态
        const SectionHeader(title: '激活锁状态'),
        _ActivationLockCard(
          isLocked: activationLocked,
          status: activationStatus,
          serialNumber: serialNumber,
        ),
        const SizedBox(height: 16),

        // ② 运营商锁检测
        const SectionHeader(title: '运营商锁检测'),
        _CarrierLockCard(),
        const SizedBox(height: 16),

        // ③ 零件更换历史（付费）
        const SectionHeader(title: '零件更换历史'),
        _PartsHistoryCard(isPurchased: isPurchased, parts: parts),
        const SizedBox(height: 16),

        // ④ MDM 配置锁（付费）
        const SectionHeader(title: 'MDM 企业配置锁'),
        _MdmCard(isPurchased: isPurchased, isMdmLocked: isMdmLocked),
        const SizedBox(height: 16),

        // ⑤ 翻新机识别（付费）
        const SectionHeader(title: '翻新机识别'),
        _RefurbishedCard(
            isPurchased: isPurchased, isRefurbished: isRefurbished),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ———— 设备头部卡片 ————

class _DeviceHeaderCard extends StatelessWidget {
  final String model;
  final String serialNumber;
  final String capacity;
  final String color;
  final String region;

  const _DeviceHeaderCard({
    required this.model,
    required this.serialNumber,
    required this.capacity,
    required this.color,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1B35), Color(0xFF12132A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 手机图标
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.phone_iphone_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _MiniInfoChip(label: capacity),
                const SizedBox(height: 4),
                _MiniInfoChip(label: color),
                const SizedBox(height: 4),
                _MiniInfoChip(label: '版本: $region'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;

  const _MiniInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
    );
  }
}

// ———— 激活锁卡片 ————

class _ActivationLockCard extends StatelessWidget {
  final bool isLocked;
  final String status;
  final String serialNumber;

  const _ActivationLockCard({
    required this.isLocked,
    required this.status,
    required this.serialNumber,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocked ? AppTheme.danger : AppTheme.success;
    final icon =
        isLocked ? Icons.lock_rounded : Icons.lock_open_rounded;
    final label = isLocked ? '已开启激活锁' : '未开启激活锁';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: isLocked ? '风险' : '安全',
                color: color,
                icon: isLocked ? Icons.warning_rounded : Icons.check_circle_rounded,
              ),
            ],
          ),
          if (isLocked) ...[
            const SizedBox(height: 12),
            const Text(
              '⚠️ 该设备已绑定 Apple ID，购买前请要求卖家解除激活锁，否则无法正常使用。',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.6),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              '✅ 设备未绑定激活锁，可正常激活使用。',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '序列号：$serialNumber',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ———— 运营商锁卡片 ————

class _CarrierLockCard extends StatelessWidget {
  const _CarrierLockCard();

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      icon: Icons.sim_card_rounded,
      iconColor: AppTheme.info,
      title: '运营商锁定检测',
      subtitle: '通过系统设置页验证',
      children: [
        const Text(
          '插入非原运营商 SIM 卡，进入「蜂窝数据」设置，观察是否提示"此 SIM 卡不适用于本机"。',
          style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DeepLinkButton(
                label: '查看蜂窝数据',
                icon: Icons.signal_cellular_alt_rounded,
                color: AppTheme.info,
                onTap: () => PlatformNavigationService.openIosSettings('cellular'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DeepLinkButton(
                label: 'Apple ID 设置',
                icon: Icons.account_circle_rounded,
                color: AppTheme.primary,
                onTap: () =>
                    PlatformNavigationService.openIosSettings('appleAccount'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeepLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DeepLinkButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.open_in_new_rounded, color: color.withOpacity(0.6), size: 12),
          ],
        ),
      ),
    );
  }
}

// ———— 零件历史卡片 ————

class _PartsHistoryCard extends ConsumerWidget {
  final bool isPurchased;
  final List<dynamic> parts;

  const _PartsHistoryCard({required this.isPurchased, required this.parts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isPurchased) {
      return _LockedFeatureCard(
        icon: Icons.build_circle_outlined,
        iconColor: AppTheme.secondary,
        title: '零件更换历史（iOS 17+）',
        description: '解锁进阶版，查看屏幕、电池、Face ID 等核心零件是否为原厂更换。',
      );
    }
    if (parts.isEmpty) {
      return InfoCard(
        icon: Icons.build_circle_outlined,
        iconColor: AppTheme.secondary,
        title: '零件更换历史',
        trailing: StatusBadge(
            label: '全部原装', color: AppTheme.success, icon: Icons.check_circle),
      );
    }
    return InfoCard(
      icon: Icons.build_circle_outlined,
      iconColor: AppTheme.secondary,
      title: '零件更换历史',
      children: [
        ...parts.map((p) {
          final part = p as Map<String, dynamic>;
          final passed = part['genuine'] as bool? ?? true;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: passed ? AppTheme.success : AppTheme.danger,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(part['name'] as String? ?? '未知零件',
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 13)),
                ),
                Text(
                  passed ? '原装' : '非原装',
                  style: TextStyle(
                    color: passed ? AppTheme.success : AppTheme.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ———— MDM 卡片 ————

class _MdmCard extends StatelessWidget {
  final bool isPurchased;
  final bool? isMdmLocked;

  const _MdmCard({required this.isPurchased, required this.isMdmLocked});

  @override
  Widget build(BuildContext context) {
    if (!isPurchased) {
      return _LockedFeatureCard(
        icon: Icons.corporate_fare_rounded,
        iconColor: AppTheme.warning,
        title: 'MDM 配置锁检测',
        description: '解锁进阶版，检测是否存在企业 MDM 配置，避免购入受企业管控的设备。',
      );
    }
    final locked = isMdmLocked ?? false;
    return InfoCard(
      icon: Icons.corporate_fare_rounded,
      iconColor: AppTheme.warning,
      title: 'MDM 企业配置锁',
      trailing: StatusBadge(
        label: locked ? '有 MDM' : '无 MDM',
        color: locked ? AppTheme.danger : AppTheme.success,
        icon: locked ? Icons.warning_rounded : Icons.check_circle_rounded,
      ),
      children: [
        Text(
          locked
              ? '⚠️ 该设备存在 MDM 企业配置，可能受到限制，无法安装非企业应用，建议谨慎购买。'
              : '✅ 未检测到 MDM 企业配置，设备可正常使用。',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.6),
        ),
        if (locked) ...[
          const SizedBox(height: 10),
          _DeepLinkButton(
            label: '查看设备管理',
            icon: Icons.admin_panel_settings_rounded,
            color: AppTheme.warning,
            onTap: () => PlatformNavigationService.openIosSettings('general'),
          ),
        ],
      ],
    );
  }
}

// ———— 翻新机卡片 ————

class _RefurbishedCard extends StatelessWidget {
  final bool isPurchased;
  final bool? isRefurbished;

  const _RefurbishedCard(
      {required this.isPurchased, required this.isRefurbished});

  @override
  Widget build(BuildContext context) {
    if (!isPurchased) {
      return _LockedFeatureCard(
        icon: Icons.recycling_rounded,
        iconColor: AppTheme.danger,
        title: '翻新机识别',
        description: '解锁进阶版，综合检测序列号规律、零件状态等，判断是否为翻新机。',
      );
    }
    final refurb = isRefurbished ?? false;
    return InfoCard(
      icon: Icons.recycling_rounded,
      iconColor: refurb ? AppTheme.danger : AppTheme.success,
      title: '翻新机识别',
      trailing: StatusBadge(
        label: refurb ? '疑似翻新' : '原装正品',
        color: refurb ? AppTheme.danger : AppTheme.success,
      ),
      children: [
        Text(
          refurb
              ? '⚠️ 该设备序列号前缀或零件记录显示可能经过翻新处理，建议核实后再购买。'
              : '✅ 未发现翻新机特征，设备序列号与零件记录正常。',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.6),
        ),
      ],
    );
  }
}

// ———— 锁定功能卡片 ————

class _LockedFeatureCard extends ConsumerWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _LockedFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('¥1 解锁',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // TODO: 跳转内购
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('即将开启内购流程…')),
              );
            },
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '¥1 解锁进阶版全部功能',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ———— 底部操作栏 ————

class _BottomBar extends ConsumerWidget {
  final String serialNumber;

  const _BottomBar({required this.serialNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: GradientButton(
        label: '生成验机报告',
        icon: Icons.description_rounded,
        isLoading: reportState.isGenerating,
        onPressed: () async {
          await ref.read(reportProvider.notifier).generateReport(serialNumber);
          final state = ref.read(reportProvider);
          if (state.report != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportPage(report: state.report!),
              ),
            );
          } else if (state.error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
      ),
    );
  }
}
