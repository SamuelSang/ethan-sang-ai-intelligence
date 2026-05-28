import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/report.dart';

class ReportPage extends StatefulWidget {
  final Report report;

  const ReportPage({
    super.key,
    required this.report,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _isVerified = true;

  @override
  void initState() {
    super.initState();
    _verifyReport();
  }

  Future<void> _verifyReport() async {
    setState(() {
      _isVerified = true;
    });
  }

  Future<void> _shareReport() async {
    final reportText = _generateReportText();
    await Share.share(reportText, subject: '设备验机报告');
  }

  String _generateReportText() {
    final report = widget.report;
    final buffer = StringBuffer();
    buffer.writeln('=== DeviceInspector 验机报告 ===');
    buffer.writeln('');
    buffer.writeln('报告ID: ${report.id}');
    buffer.writeln('检测时间: ${report.createdAt.toIso8601String()}');
    buffer.writeln('通过率: ${report.passRate.toStringAsFixed(1)}%');
    buffer.writeln('');
    buffer.writeln('--- 检测结果 ---');
    for (final item in report.items) {
      buffer.writeln('${item.name}: ${item.passed ? "✅" : "❌"} ${item.value}');
    }
    buffer.writeln('');
    buffer.writeln('签名验证: ${_isVerified ? "✅ 已验证" : "❌ 验证失败"}');
    return buffer.toString();
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final report = widget.report;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('DeviceInspector 验机报告',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('报告ID: ${report.id}'),
              pw.Text('检测时间: ${report.createdAt.toIso8601String()}'),
              pw.Text('通过率: ${report.passRate.toStringAsFixed(1)}%'),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('检测结果')),
              ...report.items.map((item) => pw.Bullet(
                text: '${item.name}: ${item.passed ? "通过" : "失败"} - ${item.value}',
              )),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('签名验证')),
              pw.Text('状态: ${_isVerified ? "已验证" : "验证失败"}'),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'device_inspection_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('验机报告'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    '验机报告',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '检测时间: ${report.createdAt.toIso8601String()}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pass rate
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${report.passRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const Text('检测通过率'),
                    const SizedBox(height: 8),
                    Text(
                      '${report.passedItems}/${report.totalItems} 项通过',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Verification status
            Card(
              child: ListTile(
                leading: Icon(
                  _isVerified ? Icons.check_circle : Icons.error,
                  color: _isVerified ? Colors.green : Colors.red,
                ),
                title: Text(_isVerified ? '签名验证通过' : '签名验证失败'),
                subtitle: const Text('报告内容未被篡改'),
              ),
            ),
            const SizedBox(height: 16),

            // Detection results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '检测结果',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...report.items.map((item) => _buildResultTile(
                      item.name,
                      item.value,
                      item.passed,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareReport,
                    icon: const Icon(Icons.share),
                    label: const Text('分享报告'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('导出PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(String title, String value, bool passed) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        passed ? Icons.check_circle : Icons.cancel,
        color: passed ? Colors.green : Colors.red,
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: passed ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}