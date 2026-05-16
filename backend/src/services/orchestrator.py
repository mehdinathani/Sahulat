import google.generativeai as genai
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

# Load the Antigravity system prompt from the project root
_PROMPT_PATH = Path(__file__).resolve().parents[5] / "antigravity_prompt.txt"

def _load_system_prompt() -> Optional[str]:
    try:
        return _PROMPT_PATH.read_text(encoding="utf-8")
    except FileNotFoundError:
        print(f"Warning: antigravity_prompt.txt not found at {_PROMPT_PATH}. Running without system instruction.")
        return None


class Orchestrator:
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_API_KEY")
        if self.api_key:
            genai.configure(api_key=self.api_key)

        system_prompt = _load_system_prompt()

        # Inject the Antigravity prompt as the model's system instruction
        # so every Gemini call is grounded in the full 5-step agentic workflow.
        model_kwargs: Dict[str, Any] = {"model_name": "gemini-1.5-flash"}
        if system_prompt:
            model_kwargs["system_instruction"] = system_prompt

        self.model = genai.GenerativeModel(**model_kwargs)
        self._system_prompt_loaded = system_prompt is not None

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
                gemini_reply = self.model.generate_content(confirmation_prompt)
                content = gemini_reply.text.strip()
            except Exception as e:
                print(f"Warning: Gemini confirmation generation failed ({e}). Using fallback.")
                content = (
                    f"✅ Your booking with **{provider_name}** is confirmed (ID: `{booking['id']}`). "
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
            gemini_reply = self.model.generate_content(rec_prompt)
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
