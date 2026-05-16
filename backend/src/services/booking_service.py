from typing import Dict, Any, Optional
from datetime import datetime
from .firebase_service import firebase_service
from ..models.schemas import Booking, BookingStatus

class BookingService:
    def __init__(self):
        self.collection = "bookings"

    def create_booking(self, provider_id: str, request_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Create a new booking for a provider.
        """
        import uuid
        booking_id = str(uuid.uuid4())
        
        # In a real app, we'd fetch the user ID from the session/token
        booking_data = {
            "id": booking_id,
            "requestId": request_id or "manual",
            "providerId": provider_id,
            "scheduledTime": datetime.utcnow().isoformat(),
            "status": BookingStatus.CONFIRMED.value,
            "reasoning": "User selected the recommended provider.",
            "createdAt": datetime.utcnow().isoformat()
        }
        
        firebase_service.add_document(self.collection, booking_data, booking_id)
        return booking_data

    def update_booking(self, booking_id: str, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Update an existing booking.
        """
        booking = firebase_service.get_document(self.collection, booking_id)
        if booking:
            booking.update(update_data)
            firebase_service.add_document(self.collection, booking, booking_id) # Mock client uses add_document for both create/update
            return booking
        return None

booking_service = BookingService()
