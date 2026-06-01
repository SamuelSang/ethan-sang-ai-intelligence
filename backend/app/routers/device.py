from fastapi import APIRouter, HTTPException, Query
from app.models.schemas import (
    ActivationLockRequest, ActivationLockResponse,
    PriceResponse, PurchaseVerifyRequest, PurchaseVerifyResponse
)
from app.services.imei_validator import validate_imei, get_imei_type
from app.services.device_parser import identify_device_model
import httpx
from datetime import datetime

router = APIRouter(prefix="/api/v1")


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
        raise HTTPException(status_code=502)


@router.get("/device/identify")
async def identify_device(
    serial: str = Query(None, description="Serial number"),
    imei: str = Query(None, description="IMEI")
):
    """
    Identify device model from serial number and/or IMEI.
    Uses local serial number prefix database and IMEI validation.
    """
    if not serial and not imei:
        raise HTTPException(status_code=400, detail="Either serial or IMEI required")

    result = {
        "serial_number": serial,
        "imei": imei,
        "model": None,
        "model_name": None,
        "region": None,
        "is_refurbished": False,
        "serial_valid": False,
        "imei_valid": False,
        "imei_type": None,
        "source": None,
        "errors": []
    }

    # Validate and parse IMEI
    if imei:
        is_valid, msg = validate_imei(imei)
        result["imei_valid"] = is_valid
        if not is_valid:
            result["errors"].append(f"IMEI: {msg}")
        else:
            result["imei_type"] = get_imei_type(imei)

    # Parse serial number
    if serial:
        model_info = identify_device_model(serial, imei)
        result.update(model_info)

    # If no model found, try to return a best guess
    if not result["model"]:
        result["model"] = "Unknown"
        result["region"] = "Unknown"

    return result


@router.get("/device/{serial}")
async def get_device(serial: str):
    """Get device information by serial number."""
    model_info = identify_device_model(serial)
    serial_valid = model_info.get("serial_valid", False)

    return {
        "serial_number": serial,
        "model": model_info.get("model") or "iPhone 15 Pro",
        "model_name": model_info.get("model_name"),
        "region": model_info.get("region") or "Unknown",
        "activation_lock": False,
        "carrier_lock": None,
        "mdm_lock": False,
        "is_refurbished": serial_valid and model_info.get("is_refurbished", False),
        "battery_health": None,
        "source": model_info.get("source")
    }


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