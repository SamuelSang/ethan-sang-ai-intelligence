from fastapi import APIRouter, Query
from datetime import datetime
import time as time_module
from .signature_service import SignatureService

router = APIRouter(prefix="/verify", tags=["verify"])

@router.get("/{report_id}")
async def verify_report(report_id: str, timestamp: int = Query(...), signature: str = Query(...)):
    """验证报告真伪"""
    # 验证签名
    if not SignatureService.verify_report_signature(report_id, timestamp, signature):
        return {"valid": False, "reason": "Invalid signature"}

    # 检查时间戳是否在有效期内（如24小时）
    current_time = int(datetime.now().timestamp())
    if current_time - timestamp > 86400:
        return {"valid": False, "reason": "Token expired"}

    return {
        "valid": True,
        "report_id": report_id,
        "verified_at": current_time,
    }

@router.get("/{report_id}/summary")
async def get_report_summary(report_id: str):
    """获取报告摘要（用于扫码展示）"""
    # 仅返回公开信息，不暴露完整报告
    return {
        "device_model": "iPhone 15 Pro",  # 示例
        "report_date": "2026-06-01",
        "status": "已认证",
    }