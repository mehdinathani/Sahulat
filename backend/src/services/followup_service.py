import asyncio
from datetime import datetime
from .booking_service import booking_service
from ..models.schemas import BookingStatus

class FollowupService:
    async def schedule_followup(self, booking_id: str, provider_name: str, delay_seconds: int = 5):
        """
        Simulates a background task that sends a follow-up notification.
        """
        # Wait for the specified delay
        await asyncio.sleep(delay_seconds)
        
        # Simulate sending a notification
        notification_message = f"Reminder: {provider_name} will arrive in 1 hour."
        print(f"\n[FOLLOW-UP AUTOMATION TRIGGERED] Booking ID: {booking_id} - {notification_message}\n")
        
        # Update the booking status in the database to reflect the follow-up
        booking_service.update_booking(
            booking_id=booking_id, 
            update_data={
                "status": BookingStatus.REMINDED.value,
                "latest_notification": notification_message,
                "notification_sent_at": datetime.utcnow().isoformat()
            }
        )

followup_service = FollowupService()
