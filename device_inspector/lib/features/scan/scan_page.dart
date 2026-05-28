import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../widgets/common_widgets.dart';
import '../device_info/device_info_page.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  final TextEditingController _manualController = TextEditingController();
  bool _isManualMode = false;
  bool _isFlashOn = false;
  bool _hasScanned = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final value = barcode!.rawValue!.trim();
    if (value.isEmpty) return;

    setState(() => _hasScanned = true);
    _navigateToDeviceInfo(value);
  }

  void _onManualSubmit() {
    final value = _manualController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入序列号或 IMEI')),
      );
      return;
    }
    _navigateToDeviceInfo(value);
  }

  void _navigateToDeviceInfo(String serial) {
    ref.read(scannedSerialProvider.notifier).state = serial;
    ref.read(deviceQueryProvider.notifier).queryBySerial(serial);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceInfoPage(serialNumber: serial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('扫描序列号 / IMEI'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isManualMode = !_isManualMode),
            child: Text(
              _isManualMode ? '扫码模式' : '手动输入',
              style: const TextStyle(color: AppTheme.primary, fontSize: 14),
            ),
          ),
        ],
      ),
      body: _isManualMode ? _buildManualInput() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // 扫码视图
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),

        // 半透明遮罩 + 扫描框
        _ScanOverlay(pulseAnimation: _pulseAnimation),

        // 底部控制区
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '将序列号或 IMEI 条码对准扫描框',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 闪光灯
                    _ControlButton(
                      icon: _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      label: '闪光灯',
                      color: _isFlashOn ? AppTheme.warning : Colors.white70,
                      onTap: () {
                        setState(() => _isFlashOn = !_isFlashOn);
                        _scannerController.toggleTorch();
                      },
                    ),
                    // 切换摄像头
                    _ControlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: '切换',
                      color: Colors.white70,
                      onTap: () => _scannerController.switchCamera(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图示
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_rounded,
                  color: AppTheme.primary, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '手动输入序列号或 IMEI',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '在「设置 > 通用 > 关于本机」中查看序列号\n或拨号键盘输入 *#06# 获取 IMEI',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 32),
          const SectionHeader(title: '序列号 / IMEI'),
          TextField(
            controller: _manualController,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: '例如：F2LXC2ABCDEF 或 359999012345678',
              prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.textMuted, size: 18),
            ),
            onSubmitted: (_) => _onManualSubmit(),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: '开始查询',
            icon: Icons.search_rounded,
            onPressed: _onManualSubmit,
          ),
          const SizedBox(height: 32),
          // 提示卡片
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.info, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      '如何找到序列号？',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• iPhone：设置 > 通用 > 关于本机\n'
                  '• 包装盒：侧面条形码下方\n'
                  '• iTunes/Finder：连接电脑查看\n'
                  '• IMEI：拨号键盘 *#06#',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.8,
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

class _ScanOverlay extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const _ScanOverlay({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 扫描框
            Container(
              width: 260,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.8),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // 四角高亮
                  _Corner(Alignment.topLeft),
                  _Corner(Alignment.topRight),
                  _Corner(Alignment.bottomLeft),
                  _Corner(Alignment.bottomRight),
                  // 扫描线
                  AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (_, __) => Positioned(
                      top: (pulseAnimation.value * 180).clamp(0, 180),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.primary.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Alignment alignment;

  const _Corner(this.alignment);

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? -1 : null,
      bottom: isTop ? null : -1,
      left: isLeft ? -1 : null,
      right: isLeft ? null : -1,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppTheme.primary, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppTheme.primary, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppTheme.primary, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppTheme.primary, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final frameW = 260.0;
    final frameH = 200.0;
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2;
    final frameRect =
        RRect.fromRectAndRadius(Rect.fromLTWH(left, top, frameW, frameH),
            const Radius.circular(16));

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final framePath = Path()..addRRect(frameRect);
    final overlayPath = Path.combine(PathOperation.difference, fullPath, framePath);
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
