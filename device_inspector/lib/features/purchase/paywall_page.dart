import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'purchase_controller.dart';

/// Paywall page - premium upsell screen
class PaywallPage extends ConsumerStatefulWidget {
  final VoidCallback? onPurchaseComplete;

  const PaywallPage({super.key, this.onPurchaseComplete});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  @override
  void initState() {
    super.initState();
    // Load products when page opens
    Future.microtask(() {
      ref.read(purchaseControllerProvider.notifier).loadProducts();
    });
  }

  /// Available product ID for 1元买断制
  static const String _buyoutProductId = 'device_inspector_buyout';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseControllerProvider);
    final controller = ref.read(purchaseControllerProvider.notifier);

    // Handle success state
    if (state.status == PurchaseStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('解锁全部高级功能'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            _buildHeaderCard(state),
            const SizedBox(height: 24),

            // 1元买断制卡片
            _buildBuyoutCard(state, controller),

            const SizedBox(height: 24),

            // Features list
            _buildFeaturesCard(),
            const SizedBox(height: 24),

            // Action buttons
            if (!state.isPurchased) ...[
              _buildPurchaseButton(state, controller),
              const SizedBox(height: 12),
              _buildRestoreButton(controller),
            ],

            // Error message
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(state.errorMessage!),
            ],

            const SizedBox(height: 20),
            // Terms
            _buildTermsText(),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyoutCard(PurchaseState state, PurchaseController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E88E5), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_badge,
            size: 48,
            color: Color(0xFF1E88E5),
          ),
          const SizedBox(height: 12),
          const Text(
            '一元买断制',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '一次购买，终身解锁全部高级功能',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¥',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B00),
                  ),
                ),
                const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B00),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '终身高级功能',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFF6B00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(PurchaseState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'DeviceInspector Pro',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.isPurchased
                ? '已解锁所有功能'
                : '1元买断，终身高级功能',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withAlpha(230),
            ),
          ),
          if (state.isPurchased) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✓ 已激活',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '进阶功能包含',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.history, '零件更换历史', '查看电池、屏幕等更换记录'),
          _buildFeatureItem(Icons.shield, 'MDM配置锁检测', '识别企业机、租赁机'),
          _buildFeatureItem(Icons.refresh, '翻新机识别', '官方翻新机精准判断'),
          _buildFeatureItem(Icons.description, '可签名报告', '生成防伪验机报告'),
          _buildFeatureItem(Icons.trending_up, '二手行情参考', '实时价格参考'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(PurchaseState state, PurchaseController controller) {
    final isLoading = state.status == PurchaseStatus.purchasing ||
        state.status == PurchaseStatus.verifying;

    return ElevatedButton(
      onPressed: isLoading ? null : () => controller.purchaseBuyout(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('处理中...'),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¥1 立即买断',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }

  Widget _buildRestoreButton(PurchaseController controller) {
    return TextButton(
      onPressed: () => controller.restorePurchases(),
      child: const Text(
        '恢复购买',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => ref.read(purchaseControllerProvider.notifier).clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      '购买即表示同意我们的服务条款和隐私政策。\n所有交易通过 Apple 官方渠道完成。',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey[500], fontSize: 12),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('购买成功'),
          ],
        ),
        content: const Text(
          '感谢您的支持！您已成功以1元买断DeviceInspector Pro，终身解锁全部高级功能。',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onPurchaseComplete?.call();
              Navigator.of(context).pop();
            },
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }
}