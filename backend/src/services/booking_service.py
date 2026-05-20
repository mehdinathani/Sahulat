from typing import Dict, Any, Optional
from datetime import datetime
from .firebase_service import firebase_service
from .time_parser import parse_time_preference
from ..models.schemas import Booking, BookingStatus

class BookingService:
    def __init__(self):
        self.collection = "bookings"

    def create_booking(
        self,
        provider_id: str,
        request_id: Optional[str] = None,
        provider_name: Optional[str] = None,
        time_preference: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Create a new booking, honouring the user's natural-language time slot.

        provider_id is the stable provider identifier from the mock DB.
        provider_name is stored alongside for display so the UI doesn't need to
        re-fetch the provider just to render a confirmation.
        time_preference is the raw phrase extracted from the user message
        (e.g. "kal subah", "tomorrow 5pm"); it is parsed via time_parser.
        """
        import uuid
        booking_id = str(uuid.uuid4())

        scheduled_dt, scheduled_label = parse_time_preference(time_preference)

        booking_data = {
            "id": booking_id,
            "requestId": request_id or "manual",
            "providerId": provider_id,
            "providerName": provider_name or provider_id,
            "scheduledTime": scheduled_dt.isoformat(),
            "scheduledLabel": scheduled_label,
            "timePreference": time_preference,
            "status": BookingStatus.BOOKED.value,
            "reasoning": "User selected the recommended provider.",
            "createdAt": datetime.utcnow().isoformat(),
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
