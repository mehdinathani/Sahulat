# Feature Specification: Sahulat-AI Orchestrator

**Feature Branch**: `001-sahulat-ai`  
**Created**: 2026-05-16  
**Status**: Draft  
**Input**: User description: "I have saved 'problem_statement.md' in the root directory for 'Sahulat-AI' (Challenge 2). Please prepare the workspace, ingest this problem statement, and establish the initial project structure. Our stack will be: Google Antigravity (Orchestrator), FastAPI (Backend), Firebase (Mock DB/State), and Flutter (Mobile UI)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Natural Language Service Request (Priority: P1)

As a user, I want to describe my service need in my preferred language (Urdu, Roman Urdu, or English) so that I don't have to navigate complex menus.

**Why this priority**: Essential for the "informal economy" context where users communicate via chat/voice.

**Independent Test**: Can be tested by sending sample messages in all three languages and verifying extraction of intent.

**Acceptance Scenarios**:

1. **Given** a user message "Mujhe kal subah G-13 mein AC technician chahiye", **When** processed by the orchestrator, **Then** intent is extracted as (Service: AC Technician, Location: G-13, Time: Tomorrow morning).
2. **Given** an English message "Need a plumber in F-11 at 5pm today", **When** processed, **Then** intent is extracted as (Service: Plumber, Location: F-11, Time: Today 5pm).

---

### User Story 2 - Provider Matching & Recommendation (Priority: P1)

As a user, I want the system to find the best available provider nearby so that I can get the service done efficiently.

**Why this priority**: Core value proposition of matching users with service providers.

**Independent Test**: Can be tested by simulating a set of providers and checking if the ranking logic selects the "best" one based on criteria.

**Acceptance Scenarios**:

1. **Given** multiple available AC technicians, **When** ranked, **Then** the one with the highest rating and closest distance is recommended with a clear explanation.

---

### User Story 3 - End-to-End Booking Simulation (Priority: P1)

As a user, I want to receive a booking confirmation and know that the service is scheduled so that I have peace of mind.

**Why this priority**: Mandatory requirement for the challenge (Action Simulation).

**Independent Test**: Can be tested by following the workflow from recommendation to "Book" action and verifying the state change in the mock DB.

**Acceptance Scenarios**:

1. **Given** a recommended provider, **When** the "Book" action is triggered, **Then** a slot is reserved in the mock system, a confirmation is generated, and a receipt is shown.

---

### User Story 4 - Agentic Reasoning & Follow-up (Priority: P2)

As a user, I want the system to keep me updated and remind me of my appointment so that I don't miss it.

**Why this priority**: Demonstrates the "Agentic" nature and follow-up automation.

**Independent Test**: Can be tested by checking the scheduled tasks in the orchestrator after a booking.

**Acceptance Scenarios**:

1. **Given** a confirmed booking, **When** 1 hour before the appointment, **Then** a simulated reminder notification is logged/sent.

---

### Edge Cases

- **Service Not Found**: How does the system handle requests for services it doesn't support or recognize?
- **No Available Providers**: What is the fallback when no providers are found in the requested location?
- **Ambiguous Location**: How does the system handle "Islamabad" instead of a specific sector like "G-13"?
- **Offline Mode**: How does the system handle network failures during the agentic workflow?

---

### User Story 5 - Automatic Location & Nearby Services (Priority: P1)

As a user, I want the app to automatically detect my location on startup and show me nearby service providers, so that I immediately see value and relevant services without having to type anything.

**Why this priority**: Reduces friction for new users and demonstrates the immediate capability of finding nearby help.

**Independent Test**: Can be tested by opening the app with a fresh chat history and verifying that a welcome message with a horizontal list of 4 clustered nearby providers appears automatically.

**Acceptance Scenarios**:

1. **Given** the app is started with an empty chat, **When** the home screen loads, **Then** location permissions are requested, coordinates are mapped to a known neighborhood, and a welcome message appears with 4 nearby service providers plotted around that neighborhood.


## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Support natural language input in Urdu, Roman Urdu, and English.
- **FR-002**: Extract service type, location, and time context from user input.
- **FR-003**: Integrate with a mock provider dataset or real Places API for discovery.
- **FR-004**: Implement ranking logic based on Distance, Availability, and Rating.
- **FR-005**: Generate natural language reasoning for provider selection.
- **FR-006**: Simulate booking lifecycle: Assignment -> Confirmation -> Scheduling.
- **FR-007**: Automate follow-up interactions (reminders, status checks).
- **FR-008**: Log all agent reasoning steps and tool usage for audit/demo purposes.
- **FR-009**: Implement dynamic Light and Dark theme toggling on the mobile frontend with local configuration state.
- **FR-010**: Provide a Voice Settings configuration panel for choosing transcription language constraints (Auto, English, Urdu) and voice presets (AC, Plumber, Electrician, Tutor) for simulation/demonstration.
- **FR-011**: Backend STT API must parse optional language codes and simulation preset parameters from the request payload.
- **FR-012**: Ensure backend mock fallback supports preset translation return values corresponding to the selected frontend preset parameter.

### Key Entities

- **User**: Represents the person requesting service (ID, Name, Preferences).
- **Provider**: Represents the service professional (ID, Category, Location, Rating, Availability).
- **Service Request**: Represents the intent (UserID, ServiceType, Location, PreferredTime).
- **Booking**: Represents the confirmed transaction (ID, RequestID, ProviderID, ScheduledTime, Status).
- **Settings**: Represents user UI/voice configurations (ThemeMode, LanguageCode, SelectedPreset).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Successfully simulate at least one end-to-end service request (Intent -> Matching -> Booking -> Follow-up).
- **SC-002**: Extraction of Service, Location, and Time is accurate for 90% of test inputs in all 3 languages.
- **SC-003**: System response time for recommendation is under 5 seconds (orchestration overhead).
- **SC-004**: 100% of recommendations include a valid "Reasoning" field explaining the choice.
- **SC-005**: Visible trace/logs of agent decisions available for the demo.
- **SC-006**: Theme toggle correctly switches between Light and Dark visual system modes without resetting the current chat session.
- **SC-007**: Selecting a voice simulation preset transcribes correctly on the backend and initiates the corresponding service orchestrator flow.
