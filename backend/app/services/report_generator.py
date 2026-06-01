from datetime import datetime
from typing import Optional
from .signature_service import SignatureService

class ReportGenerator:
    @staticmethod
    def generate_html_report(report_data: dict) -> str:
        """生成H5报告HTML"""
        device_info = report_data.get("device_info", {})
        hardware_data = report_data.get("hardware_data", {})
        manual_checks = report_data.get("manual_checks", {})

        # 生成报告编号
        report_number = f"RPT-{datetime.now().strftime('%Y%m%d')}-{report_data['report_id'][:4]}"

        html = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>验机侦探报告 - {report_number}</title>
    <style>
        body {{ font-family: -apple-system, sans-serif; padding: 20px; }}
        .header {{ text-align: center; border-bottom: 2px solid #333; padding-bottom: 20px; }}
        .watermark {{ position: fixed; bottom: 10px; right: 10px; font-size: 10px; opacity: 0.3; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>验机侦探</h1>
        <p>两元店认证报告</p>
        <p>报告编号: {report_number}</p>
    </div>

    <div class="device-info">
        <h2>设备信息</h2>
        <ul>
            <li>型号: {device_info.get('modelName', 'N/A')}</li>
            <li>序列号: {device_info.get('serialNumber', 'N/A')}</li>
            <li>IMEI: {device_info.get('imei', 'N/A')}</li>
        </ul>
    </div>

    <div class="hardware-data">
        <h2>硬件检测结果</h2>
        <ul>
            <li>电池循环: {hardware_data.get('batteryCycleCount', 'N/A')}次</li>
            <li>激活锁: {'已开启' if hardware_data.get('activationLockEnabled') else '未开启'}</li>
        </ul>
    </div>

    <div class="watermark">
        两元店认证 · 用户ID: {report_data.get('userId', '')} · {report_data.get('timestamp', '')}
    </div>
</body>
</html>
        """
        return html