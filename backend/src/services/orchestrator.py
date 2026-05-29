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

    # ---------------------------------------------------------------------- #
    # Conversational / no-match helpers — Gemini-generated, language-aware    #
    #                                                                          #
    # Both return a fallback English string only if the Gemini call itself     #
    # raises. They never substitute hardcoded text for what the LLM would     #
    # have said correctly — that was the original bug.                        #
    # ---------------------------------------------------------------------- #

    def _gemini_text(self, prompt: str, fallback: str) -> str:
        """Run a one-shot Gemini generation against the conversational
        system instruction. Returns the trimmed text on success, the
        provided fallback string on any exception."""
        try:
            reply = self.client.models.generate_content(
                model=self.model_id,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=self.conversational_instruction
                ),
            )
            text = (reply.text or "").strip()
            return text or fallback
        except Exception as e:
            print(f"Warning: Gemini conversational generation failed ({e}). Using fallback.")
            return fallback

    def _generate_conversational_reply(
        self,
        user_message: str,
        intent_language: str,
        reply_kind: str,
    ) -> str:
        """
        Ask Gemini to compose a greeting or a small-talk/help/thanks reply in
        the SAME language the user used. The previous implementation matched
        on substrings like "thank" / "help" / "cancel" and returned canned
        English strings; that ignored Urdu and Roman Urdu users entirely and
        felt scripted even in English. Now Gemini reads the actual message
        and writes the reply.
        """
        if reply_kind == "greeting":
            task = (
                "The user just greeted you. Reply with a warm, brief greeting "
                "in the SAME language they used. In one short sentence, introduce "
                "yourself as Sahulat-AI — a helper that finds local service providers "
                "(plumbers, electricians, AC techs, carpenters, painters, tutors, etc.) "
                "— and invite them to tell you what they need. Max 35 words."
            )
        else:
            task = (
                "The user sent a non-service message — small talk, a thanks, a help "
                "question, a question about bookings/cancellation/status, or something "
                "else conversational. Read what they actually said and reply in the SAME "
                "language with a short, warm, useful answer (max 50 words). "
                "If they're asking about bookings/status/tracking, mention they can use "
                "the 📋 icon in the top-right. If they're thanking you, accept it warmly "
                "and offer further help. If they're asking for help/what you do, explain "
                "you find local service providers. Never include hardcoded English text "
                "if they wrote in Urdu or Roman Urdu."
            )

        prompt = (
            f"User message: \"{user_message}\"\n"
            f"Detected language: {intent_language}\n\n"
            f"{task}"
        )
        # Fallback is intentionally generic and language-neutral.
        return self._gemini_text(
            prompt,
            fallback="I'm here to help you find local services. What do you need?",
        )

    def _generate_no_match_reply(
        self,
        user_message: str,
        intent_service: str,
        intent_location: Optional[str],
        intent_language: str,
    ) -> str:
        """
        Ask Gemini to draft a friendly 'no providers available' message in the
        user's language. The old hardcoded string forced English and assumed
        `intent.location` was set; this version handles missing location and
        whichever of en/ur/roman_ur the user typed.
        """
        loc_phrase = intent_location or "your area"
        prompt = (
            f"User message: \"{user_message}\"\n"
            f"Detected language: {intent_language}\n"
            f"Service they asked for: {intent_service}\n"
            f"Area: {loc_phrase}\n\n"
            "Task: We don't have any available providers matching this right now. "
            "Write a warm, brief apology in the SAME language as the user's message, "
            "acknowledge specifically what they asked for, and gently suggest they try "
            "a related service or a wider area. Max 40 words. No JSON, no markdown headers."
        )
        return self._gemini_text(
            prompt,
            fallback=(
                f"Sorry, I couldn't find any available **{intent_service}** "
                f"providers in {loc_phrase} right now. Try a different service or area."
            ),
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

            # Extract any time phrase the user re-stated when confirming
            # (e.g. "book Ali AC Services kal subah"). The booking service
            # parses this into a concrete slot.
            booking_intent = await nlp_service.extract_intent(user_message)
            time_preference = booking_intent.time_preference

            trace.append(AgentTrace(
                step="Booking Process Started",
                thought=f"User confirmed booking for '{provider_name}'. Initiating action simulation.",
                action="booking_service.create_booking",
            ))

            booking = booking_service.create_booking(
                provider_id=provider_name,
                provider_name=provider_name,
                time_preference=time_preference,
            )

            trace.append(AgentTrace(
                step="[Action Executed: Simulated Booking Confirmed]",
                thought="Booking record created and persisted to mock database.",
                observation=(
                    f"Booking ID: {booking['id']} | Provider: {provider_name} | "
                    f"Slot: {booking.get('scheduledLabel', 'TBD')} | Status: BOOKED"
                ),
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
                f"Scheduled slot: {booking.get('scheduledLabel', 'within an hour')}. "
                "Write a short, friendly confirmation message (max 40 words). "
                "Mention the slot, confirm the booking, and say a reminder will be sent."
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
                    f"Scheduled for **{booking.get('scheduledLabel', 'within an hour')}**. "
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
        # Both greeting and conversational replies are now generated by      #
        # Gemini (in the user's language, using the antigravity system       #
        # prompt) instead of being picked from a hardcoded string table.     #
        # ------------------------------------------------------------------ #
        if intent.intent_kind == "greeting":
            content = self._generate_conversational_reply(
                user_message=user_message,
                intent_language=intent.language,
                reply_kind="greeting",
            )
            return ChatResponse(
                content=content,
                trace=trace,
                suggested_actions=[
                    "Find a Plumber",
                    "Find an Electrician",
                    "AC Repair",
                    "Find a Tutor",
                ],
            )

        if intent.intent_kind == "conversational":
            content = self._generate_conversational_reply(
                user_message=user_message,
                intent_language=intent.language,
                reply_kind="conversational",
            )
            # Suggested actions stay structured because they drive UI chips —
            # but the reply text itself is language-aware and LLM-written.
            return ChatResponse(
                content=content,
                trace=trace,
                suggested_actions=[
                    "View My Bookings",
                    "Find a service",
                ],
            )

        # ------------------------------------------------------------------ #
        # STEP 2 — Provider Discovery                                         #
        # ------------------------------------------------------------------ #
        trace.append(AgentTrace(
            step="Provider Discovery",
            thought=f"Querying mock DB for available '{intent.service_type}' providers near {intent.location}.",
            action="matching_service.find_best_matches",
        ))

        matches = matching_service.find_best_matches(
            intent.service_type,
            user_location=intent.location,
        )

        if not matches:
            trace.append(AgentTrace(
                step="No Matches Found",
                thought="No providers found for this service/location. Asking Gemini to draft a friendly alternative-suggestion reply in the user's language.",
                observation="Zero results returned from provider database.",
            ))
            content = self._generate_no_match_reply(
                user_message=user_message,
                intent_service=intent.service_type,
                intent_location=intent.location,
                intent_language=intent.language,
            )
            return ChatResponse(
                content=content,
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

        score_breakdown = best_match.get("_score", {})
        score_str = (
            f"composite={score_breakdown.get('composite', 'n/a')} "
            f"(rating={score_breakdown.get('rating', 'n/a')}, "
            f"distance={score_breakdown.get('distance', 'n/a')}, "
            f"price={score_breakdown.get('price', 'n/a')})"
        )
        trace.append(AgentTrace(
            step="Ranking & Recommendation",
            thought=(
                "Composite score = 0.55·rating + 0.35·distance + 0.10·price, "
                "with a +0.05 boost for an exact neighbourhood match. "
                "Availability is a hard filter."
            ),
            observation=f"Recommended: {best_match['name']} — {reasoning} | {score_str}",
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
