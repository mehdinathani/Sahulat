from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any, Optional
from ..services.firebase_service import firebase_service
from ..models.schemas import Booking

router = APIRouter()

@router.get("/list")
async def list_bookings():
    """
    List all bookings from the mock database.
    """
    try:
        bookings = firebase_service.query_collection("bookings", [])
        return bookings
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{booking_id}")
async def get_booking(booking_id: str):
    """
    Get details of a specific booking.
    """
    booking = firebase_service.get_document("bookings", booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking

from pydantic import BaseModel
from ..services.booking_service import booking_service

class BookingConfirmRequest(BaseModel):
    provider_id: str
    request_id: Optional[str] = None

@router.post("/confirm")
async def confirm_booking(request: BookingConfirmRequest):
    """
    Simulate booking confirmation.
    """
    try:
        booking = booking_service.create_booking(
            provider_id=request.provider_id,
            request_id=request.request_id
        )
        return {"status": "success", "message": "Booking confirmed successfully", "booking": booking}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
