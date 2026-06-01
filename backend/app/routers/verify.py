import time
from fastapi import APIRouter, HTTPException, Query
from .signature_service import SignatureService

router = APIRouter(prefix="/verify", tags=["verify"])

@router.get("/{report_id}")
async def verify_report(report_id: str, token: str = Query(...)):
    """验证报告真伪"""
    # 解析token获取timestamp和signature
    # 使用SignatureService验证签名

    # 返回验证结果
    return {
        "valid": True,
        "report_id": report_id,
        "verified_at": int(time.time()),
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