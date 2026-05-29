from pydantic import BaseModel
from typing import Optional, Literal

# What the user is trying to do. Gemini classifies every message into one of
# these buckets so the orchestrator can decide what to do without keyword
# matching on the raw text.
#
#   "greeting"      → "hi", "salam", "hello" — open the conversation
#   "service_request" → user wants a service ("I need a carpenter in DHA")
#   "conversational" → small talk, help, status, thanks, anything else
#                     that is NOT a service request
IntentKind = Literal["greeting", "service_request", "conversational"]


class ExtractedIntent(BaseModel):
    service_type: str
    location: Optional[str] = None
    time_preference: Optional[str] = None
    original_text: str
    confidence: float
    language: str  # "en", "ur", "roman_ur"

    # Defaults to "service_request" so existing call-sites that construct an
    # intent directly (keyword fallback, booking flow) keep working unchanged.
    intent_kind: IntentKind = "service_request"
