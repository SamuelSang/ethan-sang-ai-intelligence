from fastapi import APIRouter, HTTPException, Query, Request
from app.models.schemas import (
    ReportVerifyRequest, ReportVerifyResponse, ReportResponse
)
from datetime import datetime
import uuid
import hashlib
import json

router = APIRouter(prefix="/api/v1")

from app.shared_db import reports_db


def hash_report_data(report_data: dict) -> str:
    """Generate a hash for report data."""
    data_str = json.dumps(report_data, sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(data_str.encode()).hexdigest()[:16]


@router.post("/report/verify", response_model=ReportVerifyResponse)
async def verify_report(
    report_id: str = Query(..., description="Report ID"),
    req: ReportVerifyRequest = None
):
    """
    Verify report authenticity by report_id.
    Supports two modes:
    1. Quick verify: just report_id (for scanned QR codes)
    2. Full verify: report_id + report_data + signature
    """
    # Quick verify by report_id only
    if report_id in reports_db:
        stored = reports_db[report_id]
        return ReportVerifyResponse(
            valid=True,
            message="Report exists and is verified",
            report_id=report_id,
            report_data=stored.get("report_data"),
            device_info=stored.get("device_info"),
            verified_at=datetime.now().isoformat()
        )

    # Full verification with signature
    if req and req.report_data and req.signature:
        from app.services.signer import ReportSigner
        signer = ReportSigner()
        is_valid = signer.verify(req.report_data, req.signature)
        return ReportVerifyResponse(
            valid=is_valid,
            message="Report is valid and has not been tampered with" if is_valid
                    else "Report signature verification failed",
            report_id=report_id,
            verified_at=datetime.now().isoformat()
        )

    # Demo reports for testing
    demo_reports = {
        "demo-001": {
            "report_data": {
                "device_id": "DEMO-001",
                "timestamp": datetime.now().isoformat(),
                "model": "iPhone 15 Pro",
                "serial": "DEMO123456",
                "imei": "860123456789012",
            },
            "device_info": {
                "model": "iPhone 15 Pro",
                "serial_number": "DEMO123456",
                "imei": "860123456789012",
                "region": "China",
                "activation_lock": False,
                "carrier_lock": None,
                "mdm_lock": False,
                "is_refurbished": False,
                "battery_health": 95,
                "color": "Natural Titanium",
                "storage": "256GB",
            },
        }
    }

    if report_id in demo_reports:
        stored = demo_reports[report_id]
        return ReportVerifyResponse(
            valid=True,
            message="Report verified successfully",
            report_id=report_id,
            report_data=stored.get("report_data"),
            device_info=stored.get("device_info"),
            verified_at=datetime.now().isoformat()
        )

    raise HTTPException(status_code=404, detail="Report not found")


@router.get("/report/{report_id}")
async def get_report(report_id: str):
    """Get report details by report_id."""
    if report_id in reports_db:
        return reports_db[report_id]

    if report_id.startswith("demo-"):
        return {
            "report_id": report_id,
            "status": "verified",
            "created_at": datetime.now().isoformat(),
            "device_info": {
                "model": "iPhone 15 Pro",
                "serial_number": "DEMO123456",
                "imei": "860123456789012",
                "region": "China",
                "activation_lock": False,
                "carrier_lock": None,
                "mdm_lock": False,
                "is_refurbished": False,
                "battery_health": 95,
            }
        }

    raise HTTPException(status_code=404, detail="Report not found")


@router.post("/report/generate", response_model=ReportResponse)
async def generate_report(req: ReportVerifyRequest, request: Request):
    """Generate a new inspection report."""
    from app.services.signer import ReportSigner

    report_id = str(uuid.uuid4())[:8]
    timestamp = datetime.now().isoformat()

    report_data = req.report_data if req.report_data else {
        "device_id": req.report_id,
        "timestamp": timestamp,
    }

    signer = ReportSigner()
    signature = signer.sign(report_data)

    reports_db[report_id] = {
        "report_data": report_data,
        "device_info": req.report_data.get("device_info") if req.report_data else None,
        "signature": signature
    }

    base_url = str(request.base_url).rstrip("/")
    verification_url = f"{base_url}/api/v1/report/{report_id}/verify"

    return ReportResponse(
        report_id=report_id,
        signature=signature,
        verification_url=verification_url,
        created_at=datetime.now()
    )