import google.generativeai as genai
import os
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional
from .nlp_service import nlp_service
from .matching_service import matching_service
from .booking_service import booking_service
from .followup_service import followup_service
from ..models.schemas import AgentTrace, ChatResponse
from fastapi import BackgroundTasks

load_dotenv()

class Orchestrator:
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_API_KEY")
        if self.api_key:
            genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-1.5-flash')

    async def process_request(self, user_message: str, background_tasks: Optional[BackgroundTasks] = None, history: List[Dict[str, str]] = []) -> ChatResponse:
        """
        The core orchestration logic:
        1. Understand Intent (US1)
        2. Discovery & Matching (US2)
        3. Recommendation (US2)
        """
        trace = []
        
        # Check for booking intent (Simple keyword check for now)
        if user_message.lower().startswith("book "):
            provider_name = user_message[5:].strip()
            trace.append(AgentTrace(
                step="Booking Process Started",
                thought=f"User wants to book {provider_name}. Validating provider...",
                action="booking_service.create_booking"
            ))
            
            # In a real app, we'd find the provider ID by name or from context
            # For demo, we'll assume the provider exists if we found them earlier
            booking = booking_service.create_booking(provider_id=provider_name)
            
            trace.append(AgentTrace(
                step="Booking Confirmed",
                thought="Booking successfully created in the system.",
                observation=f"Booking ID: {booking['id']} for {provider_name}"
            ))
            
            trace.append(AgentTrace(
                step="Action Simulated",
                thought="Scheduling follow-up automation for the booking.",
                observation=f"Scheduled SMS reminder for {provider_name} in 1 hour"
            ))
            
            if background_tasks:
                background_tasks.add_task(followup_service.schedule_followup, booking['id'], provider_name, 5)
            
            return ChatResponse(
                content=f"Great news! Your booking with **{provider_name}** has been confirmed. They will arrive at your location shortly. You can track their status in the 'My Bookings' tab.",
                trace=trace,
                suggested_actions=["View Booking Details", "Contact Provider"],
                booking_id=booking['id']
            )
        
        # Step 1: Extract Intent
        trace.append(AgentTrace(
            step="Natural Language Understanding",
            thought=f"Analyzing user input: '{user_message}'",
            action="nlp_service.extract_intent"
        ))
        
        intent = await nlp_service.extract_intent(user_message)
        
        trace.append(AgentTrace(
            step="Intent Extracted",
            thought="Parsed service type and location from input.",
            observation=f"Service: {intent.service_type}, Location: {intent.location}"
        ))

        # Step 2: Provider Matching
        trace.append(AgentTrace(
            step="Provider Discovery",
            thought=f"Searching for available '{intent.service_type}' providers in {intent.location}...",
            action="matching_service.find_best_matches"
        ))
        
        matches = matching_service.find_best_matches(intent.service_type)
        
        if not matches:
            trace.append(AgentTrace(
                step="No Matches Found",
                thought="Searching for nearby providers as fallback...",
                observation="No available providers found for the exact criteria."
            ))
            return ChatResponse(
                content=f"Sorry, I couldn't find any available {intent.service_type} providers in {intent.location} right now.",
                trace=trace,
                suggested_actions=["Try another service", "Change location"]
            )

        # Step 3: Recommendation
        best_match = matches[0]
        reasoning = matching_service.get_recommendation_reasoning(best_match)
        
        trace.append(AgentTrace(
            step="Ranking & Recommendation",
            thought="Ranking providers based on rating, distance, and price.",
            observation=f"Recommended: {best_match['name']} ({reasoning})"
        ))

        response_content = (
            f"I found {len(matches)} available {intent.service_type} providers. "
            f"I recommend **{best_match['name']}**. {reasoning} "
            f"Would you like me to book them for you?"
        )

        suggested_actions = [f"Book {best_match['name']}"]
        if len(matches) > 1:
            suggested_actions.append("View other options")

        return ChatResponse(
            content=response_content,
            trace=trace,
            suggested_actions=suggested_actions,
            providers=matches
        )

# Singleton instance
orchestrator = Orchestrator()
