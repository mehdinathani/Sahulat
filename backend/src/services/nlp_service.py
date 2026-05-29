from google import genai
from google.genai import types
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
        self.client = genai.Client(api_key=self.api_key)
        self.model_id = "gemini-2.5-flash"  # Using modern model ID

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
                print("Google Cloud Natural Language client initialized.")
            except Exception as e:
                print(f"Cloud NLP client init failed ({e}). Entity extraction will be skipped.")

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
            print("Cloud NLP unavailable - skipping entity extraction.")
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
            print(f"Cloud NLP analyze_entities failed ({e}). Returning empty list.")
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
        LLM-first intent extraction. Gemini owns the entire decision of
        *what kind of message* this is and *what service* (if any) is being
        requested. The previous hardcoded greeting set, nav-keyword list,
        and "if 'electrician' in text" cascade have all been removed —
        they short-circuited Gemini for messages it would have handled
        correctly, and they broke for any service or phrasing not
        anticipated by the author of the regex.

        Pipeline:
          1. Cloud NLP entity extraction (supplementary, non-blocking)
          2. Gemini structured JSON extraction — classifies intent_kind
             AND extracts service/location/time/language in one call
          3. Keyword fallback (only when Gemini API itself fails)
        """
        # Step 1: Cloud NLP entity extraction runs first (non-blocking on failure)
        entities = self.analyze_entities(text)

        prompt = f"""Classify the user's message and extract structured fields.
Return ONLY a JSON object.

Decide intent_kind FIRST:
- "greeting": a pure greeting with no other content — "hi", "salam", "hello there", "AOA bhai"
- "service_request": user wants ANY home/professional service — carpenter, painter,
  pest control, gardener, mechanic, mover, tutor, plumber, electrician, AC tech,
  cook, masseuse, anything. Do NOT restrict to a fixed list.
- "conversational": anything else — small talk, thanks, booking status, help,
  cancel, "how does this work", "what can you do", etc.

Fields:
- "intent_kind": "greeting" | "service_request" | "conversational"
- "service_type": If intent_kind="service_request", the service in English
  Title Case (e.g. "Carpenter", "AC Repair", "Plumber", "Electrician", "Tutor",
  "Painter", "Pest Control", "Mover", "Cook"). Normalize Roman Urdu / Urdu
  synonyms — "barhai" → "Carpenter", "nal wala" → "Plumber", "bijli wala" →
  "Electrician", "AC wala" → "AC Repair", "rang saaz" → "Painter". For
  non-service messages, return null.
- "location": Any area/sector/city mentioned (e.g. "G-13", "DHA", "Gulshan-e-Iqbal",
  "Clifton", "Lahore"). null if not mentioned.
- "time_preference": Any time hint ("kal subah", "tomorrow morning", "5 baje",
  "ASAP", "abhi"). null if not mentioned.
- "language": "ur" for Arabic-script Urdu, "roman_ur" for Latin-script
  Urdu/mixed, "en" for English only.
- "confidence": float 0.0–1.0.

User message: "{text}"

Return ONLY this JSON:
{{
    "intent_kind": "greeting | service_request | conversational",
    "service_type": "string or null",
    "location": "string or null",
    "time_preference": "string or null",
    "language": "en | ur | roman_ur",
    "confidence": float
}}"""

        try:
            response = self.client.models.generate_content(
                model=self.model_id,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=_NLP_SYSTEM_INSTRUCTION,
                    response_mime_type="application/json",
                ),
            )
            data = json.loads(response.text)

            kind = data.get("intent_kind") or "service_request"
            if kind not in ("greeting", "service_request", "conversational"):
                kind = "service_request"

            # For non-service intents we don't need a service_type; pick a
            # sentinel string so downstream Pydantic validation is happy
            # without leaking the keyword-routing pattern back in.
            raw_service = data.get("service_type")
            if kind == "greeting":
                service_type = "Greeting"
            elif kind == "conversational":
                service_type = "Conversational"
            else:
                service_type = raw_service or "Unknown"

            intent = ExtractedIntent(
                service_type=service_type,
                location=data.get("location"),
                time_preference=data.get("time_preference"),
                original_text=text,
                confidence=(
                    data.get("confidence")
                    if data.get("confidence") is not None
                    else 0.0
                ),
                language=data.get("language") or "en",
                intent_kind=kind,
            )

            # Step 2: Enrich with Cloud NLP entities (fill gaps only)
            return self._enrich_intent_from_entities(intent, entities)

        except Exception as e:
            print(f"NLP Service failed ({e}). Using keyword fallback.")
            return self._keyword_fallback(text, entities)

    def _keyword_fallback(
        self,
        text: str,
        entities: List[Dict[str, Any]],
    ) -> ExtractedIntent:
        """
        Last-resort keyword mapper used ONLY when Gemini is unreachable.
        Deliberately narrow: classifies the obvious greetings + a few
        common services so the demo doesn't go dark when the LLM API
        fails. Anything not matched falls through to "Conversational"
        so the orchestrator can still produce a graceful reply.
        """
        text_lower = text.lower().strip()

        greetings = {"hi", "hello", "hey", "salam", "assalam", "aoa", "hola", "yo"}
        if text_lower in greetings or text_lower.startswith(
            ("hi ", "hello ", "hey ", "salam ", "aoa ")
        ):
            return ExtractedIntent(
                service_type="Greeting",
                location=None,
                time_preference=None,
                original_text=text,
                confidence=0.6,
                language="en",
                intent_kind="greeting",
            )

        service_type: Optional[str] = None
        if "electrician" in text_lower or "bijli" in text_lower:
            service_type = "Electrician"
        elif "plumber" in text_lower or "nal" in text_lower:
            service_type = "Plumber"
        elif "ac " in text_lower or text_lower.startswith("ac") or "air condition" in text_lower:
            service_type = "AC Repair"
        elif "tutor" in text_lower or "teacher" in text_lower or "ustad" in text_lower:
            service_type = "Tutor"
        elif "carpenter" in text_lower or "barhai" in text_lower or "lakdi" in text_lower:
            service_type = "Carpenter"
        elif "painter" in text_lower or "rang" in text_lower:
            service_type = "Painter"

        location = None
        for loc_kw, loc_name in (
            ("gulshan", "Gulshan-e-Iqbal"),
            ("johar", "Johar Town"),
            ("dha", "DHA"),
            ("g-13", "G-13"),
            ("g13", "G-13"),
            ("clifton", "Clifton"),
            ("karachi", "Karachi"),
            ("lahore", "Lahore"),
        ):
            if loc_kw in text_lower:
                location = loc_name
                break

        if service_type is None:
            # Couldn't classify as a service — treat as conversational so
            # the orchestrator gives a graceful reply rather than 500.
            intent = ExtractedIntent(
                service_type="Conversational",
                location=location,
                time_preference=None,
                original_text=text,
                confidence=0.4,
                language="en",
                intent_kind="conversational",
            )
        else:
            intent = ExtractedIntent(
                service_type=service_type,
                location=location,
                time_preference="ASAP",
                original_text=text,
                confidence=0.6,
                language="en",
                intent_kind="service_request",
            )
        return self._enrich_intent_from_entities(intent, entities)


# Singleton instance
nlp_service = NLPService()
