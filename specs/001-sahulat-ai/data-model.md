# Data Model: Sahulat-AI

## Entities

### Provider
- `id`: String (UUID)
- `name`: String
- `category`: String (e.g., "AC Technician", "Plumber")
- `location`: Map { `lat`: Float, `lng`: Float, `sector`: String }
- `rating`: Float (0.0 - 5.0)
- `availability`: List of Slots { `start`: DateTime, `end`: DateTime }
- `phone`: String

### ServiceRequest
- `id`: String (UUID)
- `userId`: String
- `serviceType`: String
- `locationText`: String
- `timePreference`: String
- `status`: Enum { "PENDING", "MATCHED", "BOOKED", "COMPLETED" }

### Booking
- `id`: String (UUID)
- `requestId`: String (FK)
- `providerId`: String (FK)
- `scheduledTime`: DateTime
- `status`: Enum { "CONFIRMED", "REMINDED", "IN_PROGRESS", "DONE" }
- `reasoning`: String (The "Why" from the orchestrator)

## Relationships
- **ServiceRequest** has many **Bookings** (in case of retries, though usually 1:1).
- **Provider** has many **Bookings**.

## State Transitions
- **ServiceRequest**: `PENDING` -> `MATCHED` (after orchestrator ranks) -> `BOOKED` (after user confirmation).
- **Booking**: `CONFIRMED` -> `REMINDED` (follow-up agent) -> `DONE`.
