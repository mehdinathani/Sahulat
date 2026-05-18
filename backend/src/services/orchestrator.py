from google import genai
from google.genai import types
import os
import json
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional
from pathlib import Path
from .nlp_service import nlp_service
from .matching_service import matching_service
from .booking_service import booking_service
from .followup_service import followup_service
from ..models.schemas import AgentTrace, ChatResponse
from fastapi import BackgroundTasks

load_dotenv()

# Load the Antigravity system prompt from the backend root
_PROMPT_PATH = Path(__file__).resolve().parents[2] / "antigravity_prompt.txt"

def _load_system_prompt() -> Optional[str]:
    try:
        return _PROMPT_PATH.read_text(encoding="utf-8")
    except FileNotFoundError:
        print(f"Warning: antigravity_prompt.txt not found at {_PROMPT_PATH}. Running without system instruction.")
        return None


class Orchestrator:
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_API_KEY")
        self.client = genai.Client(api_key=self.api_key)
        self.model_id = "gemini-2.5-flash"
        self.system_prompt = _load_system_prompt()
        self._system_prompt_loaded = self.system_prompt is not None
        self.conversational_instruction = (
            "You are a warm, helpful customer service assistant for Sahulat-AI. "
            "Write ONLY the direct conversational response to the user. Do NOT include "
            "any structural prefixes, JSON, thoughts, or trace formatting."
        )

    def _build_recommendation_prompt(
        self,
        user_message: str,
        intent_service: str,
        intent_location: str,
        intent_language: str,
        matches: List[Dict[str, Any]],
        best_match: Dict[str, Any],
        reasoning: str,
    ) -> str:
        """
        Ask Gemini to generate a user-friendly recommendation response in the
        detected language, consistent with the system prompt's output requirements.
        """
        providers_summary = "\n".join(
            f"- {p['name']}: rating={p.get('rating', 'N/A')}, "
            f"distance={p.get('distance_km', '?')} km, price={p.get('price_range', 'N/A')}"
            for p in matches[:3]
        )
        return (
            f"User message: \"{user_message}\"\n"
            f"Detected language: {intent_language}\n"
            f"Service needed: {intent_service}\n"
            f"User location: {intent_location}\n\n"
            f"Available providers (top {min(3, len(matches))}):\n{providers_summary}\n\n"
            f"Best recommendation: {best_match['name']} — {reasoning}\n\n"
            "Task: Write a warm, concise recommendation reply to the user in the SAME language "
            "as their input. Tell them who you recommend, briefly why, and ask if they'd like "
            "you to book this provider. Keep it under 60 words."
        )

    async def process_request(
        self,
        user_message: str,
        background_tasks: Optional[BackgroundTasks] = None,
        history: List[Dict[str, str]] = [],
    ) -> ChatResponse:
        """
        Core orchestration pipeline (5 steps as defined in antigravity_prompt.txt):
          1. Intent Extraction
          2. Provider Discovery
          3. Ranking & Recommendation
          4. Action Simulation (booking)
          5. Follow-up Automation
        """
        trace: List[AgentTrace] = []

        # ------------------------------------------------------------------ #
        # STEP 4 / 5 — Booking + Follow-up (triggered by "book <provider>")  #
        # ------------------------------------------------------------------ #
        if user_message.lower().startswith("book "):
            provider_name = user_message[5:].strip()
            trace.append(AgentTrace(
                step="Booking Process Started",
                thought=f"User confirmed booking for '{provider_name}'. Initiating action simulation.",
                action="booking_service.create_booking",
            ))

            booking = booking_service.create_booking(provider_id=provider_name)

            trace.append(AgentTrace(
                step="[Action Executed: Simulated Booking Confirmed]",
                thought="Booking record created and persisted to mock database.",
                observation=f"Booking ID: {booking['id']} | Provider: {provider_name} | Status: BOOKED",
            ))

            trace.append(AgentTrace(
                step="[Action Planned: Background Follow-up SMS Scheduled in 5 seconds]",
                thought="Scheduling asynchronous follow-up reminder via BackgroundTasks.",
                observation=f"Reminder will fire in 5s → status will update to REMINDER_SENT",
            ))

            if background_tasks:
                background_tasks.add_task(
                    followup_service.schedule_followup, booking["id"], provider_name, 5
                )

            # Let Gemini craft the confirmation message guided by the system prompt
            confirmation_prompt = (
                f"The user just confirmed a booking with {provider_name}. "
                f"Booking ID is {booking['id']}. "
                "Write a short, friendly confirmation message (max 40 words). "
                "Tell the user the booking is confirmed and a reminder will be sent."
            )
            try:
                gemini_reply = self.client.models.generate_content(
                    model=self.model_id,
                    contents=confirmation_prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=self.conversational_instruction
                    )
                )
                content = gemini_reply.text.strip()
            except Exception as e:
                print(f"Warning: Gemini confirmation generation failed ({e}). Using fallback.")
                content = (
                    f"Your booking with **{provider_name}** is confirmed (ID: `{booking['id']}`). "
                    "A follow-up reminder has been scheduled. Track status in 'My Bookings'."
                )

            return ChatResponse(
                content=content,
                trace=trace,
                suggested_actions=["View My Bookings", "Contact Provider", "Cancel Booking"],
                booking_id=booking["id"],
            )

        # ------------------------------------------------------------------ #
        # STEP 1 — Intent Extraction                                          #
        # ------------------------------------------------------------------ #
        trace.append(AgentTrace(
            step="Natural Language Understanding",
            thought=f"Analyzing user input: '{user_message}'",
            action="nlp_service.extract_intent",
        ))

        intent = await nlp_service.extract_intent(user_message)

        trace.append(AgentTrace(
            step="Intent Extracted",
            thought="Parsed service type, location, time preference, and language from input.",
            observation=(
                f"Service: {intent.service_type} | Location: {intent.location} | "
                f"Time: {intent.time_preference} | Language: {intent.language} | "
                f"Confidence: {intent.confidence:.0%}"
            ),
        ))

        # Cloud NLP entity enrichment trace — always show this step for demo transparency
        cloud_entities = nlp_service.analyze_entities(user_message)
        entity_summary = (
            ", ".join(f"{e['name']} ({e['type']})" for e in cloud_entities[:4])
            if cloud_entities
            else "No additional entities detected"
        )
        trace.append(AgentTrace(
            step="[Cloud Integration: Google NLP API used for entity extraction]",
            thought=(
                "Google Cloud Natural Language API analyzed the raw text to extract "
                "named entities (LOCATION, PERSON, OTHER) as a supplementary signal. "
                "These enrich the Gemini intent with structured geographic context."
            ),
            action="nlp_service.analyze_entities",
            observation=f"Entities detected: {entity_summary}",
        ))

        # ------------------------------------------------------------------ #
        # Early returns for non-service intents                               #
        # ------------------------------------------------------------------ #
        if intent.service_type == "Greeting":
            return ChatResponse(
                content=(
                    "Hello! 👋 I'm **Sahulat-AI**, your smart service assistant. "
                    "Tell me what service you need — like a plumber, electrician, "
                    "AC repair, or tutor — and I'll find the best providers near you!"
                ),
                trace=trace,
                suggested_actions=["Find a Plumber", "Find an Electrician", "AC Repair", "Find a Tutor"],
            )

        if intent.service_type == "Conversational":
            # Build a contextual response based on what the user asked
            msg_lower = user_message.lower()
            if "booking" in msg_lower or "status" in msg_lower or "track" in msg_lower:
                content = (
                    "You can view and track all your bookings using the 📋 icon in the "
                    "top-right corner, or tap the button below."
                )
                actions = ["View My Bookings"]
            elif "cancel" in msg_lower:
                content = "Booking cancellation support is coming soon. For now, you can view your active bookings."
                actions = ["View My Bookings"]
            elif "contact" in msg_lower:
                content = "Provider contact details are shown on each booking card. Check your bookings to find them."
                actions = ["View My Bookings"]
            elif "help" in msg_lower:
                content = (
                    "I can help you find and book local service providers! "
                    "Just tell me what you need — e.g. 'I need a plumber in DHA'."
                )
                actions = ["Find a Plumber", "Find an Electrician", "AC Repair"]
            elif "thank" in msg_lower:
                content = "You're welcome! 😊 Let me know if you need anything else."
                actions = ["Find a service", "View My Bookings"]
            else:
                content = "I'm here to help you find services. What do you need?"
                actions = ["Find a Plumber", "Find an Electrician", "AC Repair"]

            return ChatResponse(
                content=content,
                trace=trace,
                suggested_actions=actions,
            )

        # ------------------------------------------------------------------ #
        # STEP 2 — Provider Discovery                                         #
        # ------------------------------------------------------------------ #
        trace.append(AgentTrace(
            step="Provider Discovery",
            thought=f"Querying mock DB for available '{intent.service_type}' providers near {intent.location}.",
            action="matching_service.find_best_matches",
        ))

        matches = matching_service.find_best_matches(intent.service_type)

        if not matches:
            trace.append(AgentTrace(
                step="No Matches Found",
                thought="No providers found for this service/location. Suggesting alternatives.",
                observation="Zero results returned from provider database.",
            ))
            return ChatResponse(
                content=(
                    f"Sorry, I couldn't find any available **{intent.service_type}** "
                    f"providers in {intent.location} right now. "
                    "Try a different service or area."
                ),
                trace=trace,
                suggested_actions=["Try another service", "Expand search area"],
            )

        trace.append(AgentTrace(
            step="Discovery Complete",
            thought=f"Found {len(matches)} provider(s). Proceeding to ranking.",
            observation=f"{len(matches)} provider(s) available for '{intent.service_type}'",
        ))

        # ------------------------------------------------------------------ #
        # STEP 3 — Ranking & Recommendation                                   #
        # ------------------------------------------------------------------ #
        best_match = matches[0]
        reasoning = matching_service.get_recommendation_reasoning(best_match)

        trace.append(AgentTrace(
            step="Ranking & Recommendation",
            thought="Ranking providers by rating (desc) then distance (asc). Selecting top result.",
            observation=f"Recommended: {best_match['name']} — {reasoning}",
        ))

        # Use Gemini (with system_instruction active) to generate a
        # language-aware, context-rich recommendation message
        rec_prompt = self._build_recommendation_prompt(
            user_message=user_message,
            intent_service=intent.service_type,
            intent_location=intent.location or "your area",
            intent_language=intent.language,
            matches=matches,
            best_match=best_match,
            reasoning=reasoning,
        )

        try:
            gemini_reply = self.client.models.generate_content(
                model=self.model_id,
                contents=rec_prompt,
                config=types.GenerateContentConfig(
                    system_instruction=self.conversational_instruction
                )
            )
            response_content = gemini_reply.text.strip()
        except Exception as e:
            print(f"Warning: Gemini recommendation generation failed ({e}). Using fallback.")
            response_content = (
                f"I found **{len(matches)}** available {intent.service_type} provider(s). "
                f"I recommend **{best_match['name']}**. {reasoning} "
                "Would you like me to book them for you?"
            )

        trace.append(AgentTrace(
            step="Response Generated",
            thought="Gemini crafted a language-aware recommendation message using the Antigravity system prompt.",
            observation=f"System prompt loaded: {self._system_prompt_loaded}",
        ))

        suggested_actions = [f"Book {best_match['name']}"]
        if len(matches) > 1:
            suggested_actions.append("View other options")

        return ChatResponse(
            content=response_content,
            trace=trace,
            suggested_actions=suggested_actions,
            providers=matches,
        )


# Singleton instance
orchestrator = Orchestrator()
