from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import time

router = APIRouter(prefix="/passport", tags=["passport"])

class PassportRequest(BaseModel):
    union_id: str
    platform: str  # 'miniprogram' | 'windows' | 'macos'
    app_name: str

class PassportResponse(BaseModel):
    passport_id: str
    is_valid: bool
    purchased_apps: list[str]

# 通行证数据结构
_passports = {}  # 生产环境应使用数据库

@router.post("/verify", response_model=PassportResponse)
async def verify_passport(request: PassportRequest):
    """验证用户通行证"""
    passport = _passports.get(request.union_id)

    if not passport:
        # 创建新通行证（2元买断）
        passport = {
            "passport_id": f"PP-{request.union_id[:8]}",
            "union_id": request.union_id,
            "platform": request.platform,
            "purchased_apps": [request.app_name],
            "purchase_time": int(time.time()),
            "expire_time": None,  # 永久有效
            "status": "active",
        }
        _passports[request.union_id] = passport

    return PassportResponse(
        passport_id=passport["passport_id"],
        is_valid=passport["status"] == "active",
        purchased_apps=passport["purchased_apps"],
    )

@router.post("/pairing/scan")
async def pairing_scan(token: str, desktop_id: str):
    """处理小程序扫码"""
    # 存储token用于后续验证
    return {"success": True}

@router.post("/pairing/confirm")
async def pairing_confirm(token: str, union_id: str):
    """确认配对授权"""
    # 验证token并绑定用户
    return {"success": True, "union_id": union_id}