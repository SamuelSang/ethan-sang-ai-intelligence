from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class SubscriptionPlan(str, Enum):
    FREE = "free"
    PREMIUM = "premium"


class DeviceBase(BaseModel):
    serial_number: str
    imei: Optional[str] = None


class DeviceInfo(DeviceBase):
    id: str
    model: Optional[str] = None
    region: Optional[str] = None
    activation_lock: bool = False
    carrier_lock: Optional[str] = None
    mdm_lock: bool = False
    is_refurbished: bool = False
    parts_history: Optional[List[dict]] = None
    battery_health: Optional[int] = None
    created_at: datetime


class ActivationLockRequest(BaseModel):
    imei: str
    serial: Optional[str] = None


class ActivationLockResponse(BaseModel):
    imei: str
    activation_lock: bool
    lost_stolen: bool = False
    blacklist: bool = False
    carrier: Optional[str] = None
    region: Optional[str] = None


class ReportData(BaseModel):
    device_id: str
    timestamp: str
    device_info: dict
    activation_lock: bool
    carrier_lock: Optional[str] = None
    mdm_lock: bool
    battery_health: Optional[int] = None
    parts_history: Optional[List[dict]] = None
    is_refurbished: bool = False


class ReportGenerateRequest(BaseModel):
    device_id: str
    report_data: ReportData


class ReportResponse(BaseModel):
    report_id: str
    signature: str
    verification_url: str
    created_at: datetime


class ReportVerifyRequest(BaseModel):
    report_id: str
    report_data: dict
    signature: str


class ReportVerifyResponse(BaseModel):
    valid: bool
    message: str


class PriceRequest(BaseModel):
    model: str


class PriceResponse(BaseModel):
    model: str
    price_range: dict
    source: str
    updated_at: str


class UserResponse(BaseModel):
    id: str
    device_id: str
    is_premium: bool
    created_at: datetime


class PurchaseVerifyRequest(BaseModel):
    receipt_data: str
    platform: str  # "ios" or "android"


class PurchaseVerifyResponse(BaseModel):
    success: bool
    is_premium: bool
    message: str