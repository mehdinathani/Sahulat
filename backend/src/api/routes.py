from fastapi import APIRouter, HTTPException
from ..models.schemas import ChatMessage, ChatResponse, Booking
from ..services.orchestrator import orchestrator
from typing import List

from . import chat, booking

router = APIRouter()
router.include_router(chat.router, prefix="/chat", tags=["chat"])
router.include_router(booking.router, prefix="/booking", tags=["booking"])

@router.get("/providers")
async def get_providers(category: str = None):
    """
    Retrieve mock providers.
    """
    # This will be implemented in Phase 4
    return {"providers": []}

@router.post("/booking/confirm")
async def confirm_booking(booking: Booking):
    """
    Confirm a simulated booking.
    """
    # This will be implemented in Phase 5
    return {"status": "CONFIRMED", "booking_id": booking.id}
