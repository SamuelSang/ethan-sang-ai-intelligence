import hmac
import hashlib
import time
from typing import Optional


class SignatureService:
    SECRET_KEY = "your-secret-key"  # 从环境变量读取

    @classmethod
    def generate_report_signature(cls, report_id: str, timestamp: int) -> str:
        """生成报告签名"""
        message = f"{report_id}:{timestamp}"
        return hmac.new(
            cls.SECRET_KEY.encode(),
            message.encode(),
            hashlib.sha256
        ).hexdigest()

    @classmethod
    def verify_report_signature(cls, report_id: str, timestamp: int, signature: str) -> bool:
        """验证报告签名"""
        expected = cls.generate_report_signature(report_id, timestamp)
        return hmac.compare_digest(expected, signature)

    @classmethod
    def generate_qr_token(cls, report_id: str) -> dict:
        """生成二维码Token"""
        timestamp = int(time.time())
        signature = cls.generate_report_signature(report_id, timestamp)
        return {
            "report_id": report_id,
            "timestamp": timestamp,
            "signature": signature,
        }