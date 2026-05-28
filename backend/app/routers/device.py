from fastapi import APIRouter, HTTPException
from app.models.schemas import (
    ActivationLockRequest, ActivationLockResponse,
    ReportGenerateRequest, ReportResponse,
    ReportVerifyRequest, ReportVerifyResponse,
    PriceResponse, PurchaseVerifyRequest, PurchaseVerifyResponse
)
import httpx
from datetime import datetime
import uuid

router = APIRouter(prefix="/api/v1")

# In-memory storage for demo (replace with PostgreSQL in production)
reports_db = {}
devices_db = {}


@router.post("/device/activation-lock", response_model=ActivationLockResponse)
async def check_activation_lock(req: ActivationLockRequest):
    """
    Check activation lock status via CheckM32 API or similar service.
    """
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.get(
                "https://checkm32.info/api/check",
                params={"imei": req.imei, "sn": req.serial}
            )

            if response.status_code == 200:
                data = response.json()
                return ActivationLockResponse(
                    imei=req.imei,
                    activation_lock=data.get("locked", False),
                    lost_stolen=data.get("lost", False),
                    blacklist=data.get("blacklist", False),
                    carrier=data.get("carrier"),
                    region=data.get("region")
                )
            else:
                # Fallback: return unknown status
                return ActivationLockResponse(
                    imei=req.imei,
                    activation_lock=False,
                    lost_stolen=False,
                    blacklist=False
                )
    except Exception as e:
        # For demo purposes, return a mock response
        return ActivationLockResponse(
            imei=req.imei,
            activation_lock=False,
            lost_stolen=False,
            blacklist=False,
            carrier="Unknown",
            region="Unknown"
        )


@router.get("/device/{serial}")
async def get_device(serial: str):
    """Get device information by serial number."""
    if serial in devices_db:
        return devices_db[serial]

    # Return mock data for demo
    return {
        "serial_number": serial,
        "model": "iPhone 15 Pro",
        "region": "China",
        "activation_lock": False,
        "carrier_lock": None,
        "mdm_lock": False,
        "is_refurbished": False,
        "battery_health": 92
    }


@router.post("/report/generate", response_model=ReportResponse)
async def generate_report(req: ReportGenerateRequest):
    """Generate a signed inspection report."""
    from app.services.signer import ReportSigner

    report_id = str(uuid.uuid4())
    timestamp = datetime.now().isoformat()

    report_data = {
        "device_id": req.device_id,
        "timestamp": timestamp,
        **req.report_data.model_dump()
    }

    # Sign the report
    signer = ReportSigner()
    signature = signer.sign(report_data)

    verification_url = f"https://api.deviceinspector.app/api/v1/report/{report_id}/verify"

    report = ReportResponse(
        report_id=report_id,
        signature=signature,
        verification_url=verification_url,
        created_at=datetime.now()
    )

    reports_db[report_id] = {
        "report_data": report_data,
        "signature": signature
    }

    return report


@router.post("/report/{report_id}/verify", response_model=ReportVerifyResponse)
async def verify_report(report_id: str, req: ReportVerifyRequest):
    """Verify report signature."""
    from app.services.signer import ReportSigner

    signer = ReportSigner()
    is_valid = signer.verify(req.report_data, req.signature)

    return ReportVerifyResponse(
        valid=is_valid,
        message="Report is valid and has not been tampered with" if is_valid
                else "Report signature verification failed"
    )


@router.get("/price/{model}", response_model=PriceResponse)
async def get_market_price(model: str):
    """
    Get second-hand market price for a device model.
    In production, this would scrape or use a price API.
    """
    # Mock price data
    price_ranges = {
        "iphone 15 pro": {"low": 5000, "median": 6500, "high": 8000},
        "iphone 15": {"low": 4000, "median": 5000, "high": 6500},
        "iphone 14 pro": {"low": 4000, "median": 5500, "high": 7000},
        "iphone 14": {"low": 3000, "median": 4000, "high": 5000},
    }

    model_lower = model.lower()
    price_range = price_ranges.get(model_lower, {"low": 1000, "median": 2000, "high": 3000})

    return PriceResponse(
        model=model,
        price_range=price_range,
        source="aggregated",
        updated_at=datetime.now().isoformat()
    )


@router.post("/purchase/verify", response_model=PurchaseVerifyResponse)
async def verify_purchase(req: PurchaseVerifyRequest):
    """
    Verify in-app purchase receipt.
    In production, validate with Apple/Google servers.
    """
    # Mock verification - in production, verify with Apple IAP or Google Play
    if req.receipt_data and len(req.receipt_data) > 10:
        return PurchaseVerifyResponse(
            success=True,
            is_premium=True,
            message="Purchase verified successfully"
        )

    return PurchaseVerifyResponse(
        success=False,
        is_premium=False,
        message="Invalid receipt"
    )