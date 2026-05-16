import google.generativeai as genai
import os
import json
from dotenv import load_dotenv
from typing import Optional
from ..models.intent import ExtractedIntent

load_dotenv()

_NLP_SYSTEM_INSTRUCTION = (
    "You are a structured intent extractor for a Pakistani service marketplace. "
    "Your ONLY job is to parse user messages and return a valid JSON object. "
    "You understand English, Urdu (اردو), and Roman Urdu (Urdu written in Latin script). "
    "Never return anything other than the JSON object — no markdown, no explanation."
)

class NLPService:
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_API_KEY")
        if self.api_key:
            genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            system_instruction=_NLP_SYSTEM_INSTRUCTION,
        )

    async def extract_intent(self, text: str) -> ExtractedIntent:
        """
        Extract service type, location, and time from natural language.
        Supports English, Urdu, and Roman Urdu.
        """
        prompt = f"""Extract the following fields from the user's service request and return ONLY a JSON object:

Fields:
- "service_type": The service needed in English (e.g., "AC Repair", "Plumber", "Electrician", "Tutor", "Carpenter"). Normalize synonyms: "AC wala" → "AC Repair", "nal wala" → "Plumber", "bijli wala" → "Electrician".
- "location": Any area/sector mentioned (e.g., "G-13", "DHA", "Gulshan-e-Iqbal", "Johar", "Clifton"). Return null if not mentioned.
- "time_preference": Any time hint (e.g., "kal subah", "tomorrow morning", "5 baje", "ASAP"). Return null if not mentioned.
- "language": Detect the language — return "ur" if Arabic-script Urdu, "roman_ur" if Latin-script Urdu/mixed, "en" if English only.
- "confidence": A float 0.0–1.0 reflecting extraction confidence.

User Request: "{text}"

Return ONLY this JSON structure, nothing else:
{{
    "service_type": "string",
    "location": "string or null",
    "time_preference": "string or null",
    "language": "en | ur | roman_ur",
    "confidence": float
}}"""
        
        # Using simple generation + manual JSON parsing for robustness across Gemini versions
        # unless response_mime_type is supported in the environment's version
        try:
            try:
                response = self.model.generate_content(
                    prompt,
                    generation_config=genai.types.GenerationConfig(
                        response_mime_type="application/json"
                    )
                )
                data = json.loads(response.text)
            except Exception as e:
                # Fallback for older versions or parsing errors
                response = self.model.generate_content(prompt)
                # Find JSON block in response
                text_content = response.text
                start = text_content.find("{")
                end = text_content.rfind("}") + 1
                data = json.loads(text_content[start:end])

            return ExtractedIntent(
                service_type=data.get("service_type", "Unknown"),
                location=data.get("location"),
                time_preference=data.get("time_preference"),
                original_text=text,
                confidence=data.get("confidence", 0.0),
                language=data.get("language", "en")
            )
        except Exception as e:
            print(f"Warning: NLP Service failed ({e}). Returning mock intent.")
            text_lower = text.lower()
            
            # Smart keyword-based fallback for hackathon demo
            service_type = "General Service"
            location = "Karachi" # Default for mock data
            
            if "electrician" in text_lower or "bijli" in text_lower:
                service_type = "electrician"
            elif "plumber" in text_lower or "nal" in text_lower:
                service_type = "plumber"
            elif "ac" in text_lower:
                service_type = "ac_repair"
            
            if "gulshan" in text_lower:
                location = "Gulshan-e-Iqbal"
            elif "johar" in text_lower:
                location = "Johar"
            elif "dha" in text_lower:
                location = "DHA"

            return ExtractedIntent(
                service_type=service_type,
                location=location,
                time_preference="ASAP",
                original_text=text,
                confidence=0.7,
                language="en"
            )

# Singleton instance
nlp_service = NLPService()
