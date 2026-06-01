import base64
import time
from .signature_service import SignatureService

class WatermarkService:
    @staticmethod
    def generate_watermark_text(user_id: str, timestamp: int) -> str:
        """生成水印文本"""
        return f"两元店认证 · 用户ID: {user_id} · {timestamp}"

    @staticmethod
    def embed_watermark_in_html(html: str, user_id: str, timestamp: int) -> str:
        """将水印嵌入HTML报告"""
        watermark = WatermarkService.generate_watermark_text(user_id, timestamp)

        # 在</body>前插入水印div
        watermark_html = f'''
        <div class="watermark" style="
            position: fixed;
            bottom: 10px;
            right: 10px;
            font-size: 10px;
            opacity: 0.3;
            color: #999;
        ">
            {watermark}
        </div>
        '''

        return html.replace('</body>', f'{watermark_html}</body>')

    @staticmethod
    def generate_qr_code_data(report_id: str) -> dict:
        """生成二维码数据"""
        token = SignatureService.generate_qr_token(report_id)
        return {
            "verify_url": f"https://api.example.com/verify/{report_id}?token={token['signature']}",
            "token": token,
        }