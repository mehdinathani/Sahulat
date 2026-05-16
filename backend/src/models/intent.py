from pydantic import BaseModel
from typing import Optional

class ExtractedIntent(BaseModel):
    service_type: str
    location: Optional[str] = None
    time_preference: Optional[str] = None
    original_text: str
    confidence: float
    language: str # "en", "ur", "roman_ur"
