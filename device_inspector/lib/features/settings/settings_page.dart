import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../purchase/paywall_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize purchase controller and load products
    Future.microtask(() {
      ref.read(purchaseControllerProvider.notifier).loadProducts();
    });
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_device_info');
    await prefs.remove('cached_reports');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('缓存已清除')),
      );
    }
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaywallPage(
          onPurchaseComplete: () {
            // Refresh purchase state
            ref.read(purchaseControllerProvider.notifier);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPurchased = ref.watch(isPurchasedProvider);
    final purchaseState = ref.watch(purchaseControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Premium section - now uses new purchase system
          _buildPremiumSection(isPurchased, purchaseState),

          const Divider(height: 32),

          // Settings options
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除缓存'),
            onTap: _clearCache,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于我们'),
            subtitle: const Text('DeviceInspector v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'DeviceInspector',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 DeviceInspector',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隐私政策'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('隐私政策：所有数据仅本地处理，不会上传到服务器'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(bool isPurchased, PurchaseState purchaseState) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isPurchased ? Colors.green[50] : const Color(0xFF1E88E5).withAlpha(26),
      child: Column(
        children: [
          Icon(
            isPurchased ? Icons.star : Icons.star_border,
            size: 48,
            color: isPurchased ? Colors.green : const Color(0xFF1E88E5),
          ),
          const SizedBox(height: 12),
          Text(
            isPurchased ? '永久进阶功能已解锁' : '解锁永久进阶功能',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPurchased
                ? '感谢您的支持'
                : '¥1 永久解锁所有高级功能',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (!isPurchased) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openPaywall,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('¥1 立即解锁'),
            ),
          ],
        ],
      ),
    );
  }
}