import google.generativeai as genai
import os
import json
from dotenv import load_dotenv
from typing import Optional, List, Dict, Any

# Google Cloud Natural Language API
try:
    from google.cloud import language_v1
    _CLOUD_NLP_AVAILABLE = True
except ImportError:
    _CLOUD_NLP_AVAILABLE = False

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

        # Initialize the Cloud Natural Language client.
        # It will use GOOGLE_APPLICATION_CREDENTIALS env var or service-account.json.
        self._cloud_nlp_client: Optional[Any] = None
        if _CLOUD_NLP_AVAILABLE:
            try:
                # Respect explicit credential path if set; otherwise use ADC
                creds_path = os.getenv(
                    "GOOGLE_APPLICATION_CREDENTIALS",
                    os.path.join(os.path.dirname(__file__), "..", "..", "..", "service-account.json"),
                )
                if os.path.exists(creds_path):
                    os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", creds_path)
                self._cloud_nlp_client = language_v1.LanguageServiceClient()
                print("✅ Google Cloud Natural Language client initialized.")
            except Exception as e:
                print(f"⚠️  Cloud NLP client init failed ({e}). Entity extraction will be skipped.")

    # ---------------------------------------------------------------------- #
    # Public: Cloud NLP Entity Extraction                                     #
    # ---------------------------------------------------------------------- #

    def analyze_entities(self, text: str) -> List[Dict[str, Any]]:
        """
        Call the Google Cloud Natural Language API to extract named entities.

        Returns a list of dicts:
          [{"name": str, "type": str, "salience": float, "metadata": dict}]

        Relevant entity types for Sahulat-AI:
          - LOCATION  → maps to intent.location
          - PERSON    → may indicate preferred provider names
          - OTHER     → free-form (e.g., "AC repair", "bijli ka masla")

        Falls back to an empty list if the Cloud NLP client is unavailable.
        """
        if not self._cloud_nlp_client:
            print("⚠️  Cloud NLP unavailable — skipping entity extraction.")
            return []

        try:
            document = language_v1.Document(
                content=text,
                type_=language_v1.Document.Type.PLAIN_TEXT,
                language="en",  # API auto-detects Urdu/Roman Urdu with "en" as hint
            )
            response = self._cloud_nlp_client.analyze_entities(
                request={"document": document, "encoding_type": language_v1.EncodingType.UTF8}
            )
            entities = []
            for entity in response.entities:
                entities.append({
                    "name": entity.name,
                    "type": language_v1.Entity.Type(entity.type_).name,
                    "salience": round(entity.salience, 3),
                    "metadata": dict(entity.metadata),
                })
            return entities
        except Exception as e:
            print(f"⚠️  Cloud NLP analyze_entities failed ({e}). Returning empty list.")
            return []

    def _enrich_intent_from_entities(
        self,
        intent: ExtractedIntent,
        entities: List[Dict[str, Any]],
    ) -> ExtractedIntent:
        """
        Supplement Gemini-extracted intent with Cloud NLP entity data.
        - If intent.location is None but a LOCATION entity exists → fill it in.
        - Does NOT override Gemini's result; only fills gaps.
        """
        if not entities:
            return intent

        if intent.location is None:
            location_entities = [e for e in entities if e["type"] == "LOCATION"]
            if location_entities:
                # Pick the most salient location entity
                best = max(location_entities, key=lambda e: e["salience"])
                intent = intent.model_copy(update={"location": best["name"]})

        return intent

    # ---------------------------------------------------------------------- #
    # Public: Gemini Intent Extraction (primary pipeline)                     #
    # ---------------------------------------------------------------------- #

    async def extract_intent(self, text: str) -> ExtractedIntent:
        """
        Full intent extraction pipeline:
          1. Cloud NLP entity extraction (supplementary / enrichment layer)
          2. Gemini structured JSON extraction (primary)
          3. Keyword fallback (demo safety net)
        """
        # Step 1: Cloud NLP entity extraction runs first (non-blocking on failure)
        entities = self.analyze_entities(text)

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

        try:
            try:
                response = self.model.generate_content(
                    prompt,
                    generation_config=genai.types.GenerationConfig(
                        response_mime_type="application/json"
                    ),
                )
                data = json.loads(response.text)
            except Exception:
                # Fallback for older SDK versions or JSON parsing edge-cases
                response = self.model.generate_content(prompt)
                text_content = response.text
                start = text_content.find("{")
                end = text_content.rfind("}") + 1
                data = json.loads(text_content[start:end])

            intent = ExtractedIntent(
                service_type=data.get("service_type", "Unknown"),
                location=data.get("location"),
                time_preference=data.get("time_preference"),
                original_text=text,
                confidence=data.get("confidence", 0.0),
                language=data.get("language", "en"),
            )

            # Step 2: Enrich with Cloud NLP entities (fill gaps only)
            return self._enrich_intent_from_entities(intent, entities)

        except Exception as e:
            print(f"⚠️  NLP Service failed ({e}). Using keyword fallback.")
            text_lower = text.lower()

            service_type = "General Service"
            location = "Karachi"

            if "electrician" in text_lower or "bijli" in text_lower:
                service_type = "Electrician"
            elif "plumber" in text_lower or "nal" in text_lower:
                service_type = "Plumber"
            elif "ac" in text_lower:
                service_type = "AC Repair"
            elif "tutor" in text_lower or "teacher" in text_lower:
                service_type = "Tutor"
            elif "carpenter" in text_lower or "barhai" in text_lower:
                service_type = "Carpenter"

            if "gulshan" in text_lower:
                location = "Gulshan-e-Iqbal"
            elif "johar" in text_lower:
                location = "Johar Town"
            elif "dha" in text_lower:
                location = "DHA"
            elif "g-13" in text_lower or "g13" in text_lower:
                location = "G-13"
            elif "clifton" in text_lower:
                location = "Clifton"

            # Still try to enrich fallback with Cloud NLP location data
            intent = ExtractedIntent(
                service_type=service_type,
                location=location,
                time_preference="ASAP",
                original_text=text,
                confidence=0.7,
                language="en",
            )
            return self._enrich_intent_from_entities(intent, entities)


# Singleton instance
nlp_service = NLPService()
