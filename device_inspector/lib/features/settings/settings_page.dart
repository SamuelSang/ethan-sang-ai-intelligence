import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isPremium = false;
  bool _isPurchasing = false;

  // Product ID for ¥1 permanent unlock
  static const String _productId = 'device_inspector_premium';

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPremium = prefs.getBool('is_premium') ?? false;
    });
  }

  Future<void> _purchasePremium() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        _showMessage('内购功能不可用');
        return;
      }

      // Query product details
      final productDetails = await InAppPurchase.instance.queryProductDetails({_productId});

      if (productDetails.productDetails.isEmpty) {
        // For demo, simulate purchase success
        await _simulatePurchase();
      } else {
        // Make actual purchase
        final purchaseParam = PurchaseParam(productDetails: productDetails.productDetails.first);
        await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _showMessage('购买失败: $e');
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  Future<void> _simulatePurchase() async {
    // For demo purposes, simulate successful purchase
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    setState(() {
      _isPremium = true;
    });
    _showMessage('购买成功！您已解锁永久进阶功能');
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_device_info');
    await prefs.remove('cached_reports');
    _showMessage('缓存已清除');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Premium section
          Container(
            padding: const EdgeInsets.all(20),
            color: _isPremium ? Colors.green[50] : const Color(0xFF1E88E5).withAlpha(26),
            child: Column(
              children: [
                Icon(
                  _isPremium ? Icons.star : Icons.star_border,
                  size: 48,
                  color: _isPremium ? Colors.green : const Color(0xFF1E88E5),
                ),
                const SizedBox(height: 12),
                Text(
                  _isPremium ? '永久进阶功能已解锁' : '解锁永久进阶功能',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPremium
                      ? '感谢您的支持'
                      : '¥1 永久解锁所有高级功能',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (!_isPremium) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isPurchasing ? null : _purchasePremium,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('¥1 立即解锁'),
                  ),
                ],
              ],
            ),
          ),

          // Premium features list
          if (!_isPremium) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '进阶功能包含',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _buildFeatureTile(Icons.history, '零件更换历史', '查看电池、屏幕等更换记录'),
            _buildFeatureTile(Icons.shield, 'MDM配置锁检测', '识别企业机、租赁机'),
            _buildFeatureTile(Icons.refresh, '翻新机识别', '官方翻新机精准判断'),
            _buildFeatureTile(Icons.description, '可签名报告', '生成防伪验机报告'),
            _buildFeatureTile(Icons.trending_up, '二手行情参考', '实时价格参考'),
          ],

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
              _showMessage('隐私政策：所有数据仅本地处理，不会上传到服务器');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E88E5)),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}