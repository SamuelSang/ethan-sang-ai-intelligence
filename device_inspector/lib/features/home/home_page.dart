import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../scan/scan_page.dart';
import '../settings/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景装饰
          const _BackgroundDecoration(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // 顶部 AppBar 区域
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DeviceInspector',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              '专业设备验机工具',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsPage()),
                          ),
                          icon: const Icon(Icons.settings_outlined,
                              color: AppTheme.textSecondary, size: 22),
                          tooltip: '设置',
                        ),
                      ],
                    ),
                  ),
                ),

                // Hero 区域
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: Column(
                      children: [
                        // 主图标
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.phonelink_rounded,
                                  color: Colors.white, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: const Text(
                            '全面验机，一键掌握',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '激活锁 · 零件历史 · MDM · 翻新识别\n专业级验机报告，保障二手交易安全',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // 开始验机按钮
                        GradientButton(
                          label: '开始验机',
                          icon: Icons.qr_code_scanner_rounded,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScanPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 功能卡片标题
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 40, 20, 16),
                    child: SectionHeader(title: '核心功能'),
                  ),
                ),

                // 功能卡片列表
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _FeatureCard(
                        icon: Icons.lock_open_rounded,
                        iconColor: AppTheme.success,
                        title: '激活锁检测',
                        description: '查询苹果官方激活锁状态，防止购入被锁设备',
                        tag: '免费',
                        tagColor: AppTheme.success,
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.build_circle_outlined,
                        iconColor: AppTheme.secondary,
                        title: '零件更换历史',
                        description: 'iOS 17+ 官方零件验证，检测屏幕/电池是否为原装',
                        tag: '付费',
                        tagColor: AppTheme.warning,
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.assignment_rounded,
                        iconColor: AppTheme.accent,
                        title: '报告生成与分享',
                        description: 'SHA-256 签名验机报告，PDF 导出，安心分享',
                        tag: '免费',
                        tagColor: AppTheme.success,
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.corporate_fare_rounded,
                        iconColor: AppTheme.warning,
                        title: 'MDM 配置锁检测',
                        description: '识别企业管理配置，避免购入受限设备',
                        tag: '付费',
                        tagColor: AppTheme.warning,
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.recycling_rounded,
                        iconColor: AppTheme.danger,
                        title: '翻新机识别',
                        description: '综合判断设备是否经过翻新处理，揭露真实状况',
                        tag: '付费',
                        tagColor: AppTheme.warning,
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 顶部光晕
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // 左下光晕
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.secondary.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String tag;
  final Color tagColor;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: tag, color: tagColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
