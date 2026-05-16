from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class RequestStatus(str, Enum):
    PENDING = "PENDING"
    MATCHED = "MATCHED"
    BOOKED = "BOOKED"
    COMPLETED = "COMPLETED"

class BookingStatus(str, Enum):
    BOOKED = "BOOKED"
    CONFIRMED = "CONFIRMED"
    REMINDED = "REMINDED"
    IN_PROGRESS = "IN_PROGRESS"
    DONE = "DONE"

class Location(BaseModel):
    lat: float
    lng: float
    sector: str

class Slot(BaseModel):
    start: datetime
    end: datetime

class Provider(BaseModel):
    id: str
    name: str
    category: str
    location: Location
    rating: float = Field(ge=0.0, le=5.0)
    availability: List[Slot]
    phone: str

class ServiceRequest(BaseModel):
    id: str
    userId: str
    serviceType: str
    locationText: str
    timePreference: str
    status: RequestStatus = RequestStatus.PENDING

class Booking(BaseModel):
    id: str
    requestId: str
    providerId: str
    scheduledTime: datetime
    status: BookingStatus = BookingStatus.BOOKED
    reasoning: str

class ChatMessage(BaseModel):
    role: str # "user" or "assistant"
    content: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class AgentTrace(BaseModel):
    step: str
    thought: str
    action: Optional[str] = None
    observation: Optional[str] = None

class ChatResponse(BaseModel):
    content: str
    trace: List[AgentTrace]
    suggested_actions: Optional[List[str]] = None
    providers: Optional[List[Dict[str, Any]]] = None
    booking_id: Optional[str] = None
