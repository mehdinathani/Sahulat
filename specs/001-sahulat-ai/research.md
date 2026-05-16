# Research: Sahulat-AI Orchestrator Integration

## Decision: Core Stack Implementation

**Rationale**: The user has explicitly defined the stack. The research focuses on how these components will interact.

- **Orchestrator**: Google Antigravity will handle the "Agentic" logic. It will process the natural language intent and manage the multi-step reasoning (Discovery -> Ranking -> Booking).
- **Backend**: FastAPI will act as a wrapper around Antigravity, providing endpoints for the Mobile UI and interacting with Firebase.
- **State/Storage**: Firebase will store provider data (mock) and booking states.
- **Frontend**: Flutter will provide the mobile interface, communicating with the FastAPI backend.

## Decision: Natural Language Processing (NLP)

**Rationale**: Support for Urdu and Roman Urdu is mandatory.

- **Selected Approach**: Use Google Gemini API (integrated via Antigravity) for intent extraction. Gemini has strong support for multilingual inputs, including Roman Urdu.
- **Alternatives Considered**: 
  - Custom spaCy/NLTK models: Rejected due to complexity in supporting Urdu/Roman Urdu with high accuracy in a hackathon timeframe.

## Decision: Provider Discovery & Ranking

**Rationale**: Needs to be "Agentic" and traceable.

- **Discovery**: A mock dataset will be stored in Firebase. Tools will be defined in Antigravity to query this dataset.
- **Ranking**: Logic will consider distance (simulated coords), rating, and availability. Antigravity will be instructed to provide the "Reasoning" for its choice.

## Decision: Action Simulation

**Rationale**: Critical requirement.

- **Booking**: When a user confirms, the system will update a `bookings` collection in Firebase. 
- **Follow-up**: A background task (FastAPI BackgroundTasks or a separate agent loop) will simulate sending a reminder 1 hour before.

## Alternatives Considered (Architecture)

| Alternative | Rationale for Rejection |
|-------------|-------------------------|
| Direct Flutter to Firebase | Bypasses the Orchestrator/Backend requirement; makes multi-step reasoning logs harder to manage. |
| Single-agent system | Doesn't meet the "Agentic Workflow" requirement for multi-step reasoning and autonomy. |
