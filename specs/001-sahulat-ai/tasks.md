# Tasks: Sahulat-AI Orchestrator

**Input**: Design documents from `/specs/001-sahulat-ai/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 [P] Create project structure for backend/ and mobile/ directories
- [x] T002 [P] Initialize FastAPI project in backend/ and add dependencies (fastapi, uvicorn, firebase-admin)
- [x] T003 [P] Initialize Flutter project in mobile/ and add dependencies (http, provider/riverpod)
- [x] T004 [P] Setup Firebase project and download service account key to backend/service-account.json (mock)
- [x] T005 [P] Configure environment variables in backend/.env

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [x] T006 [P] Implement base models in backend/src/models/schemas.py (Provider, Request, Booking)
- [x] T007 [P] Implement Firebase utility service in backend/src/services/firebase_service.py
- [x] T008 [P] Initialize Antigravity orchestrator configuration in backend/src/services/orchestrator.py
- [x] T009 [P] Setup FastAPI router and base endpoints in backend/src/api/routes.py

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Natural Language Service Request (Priority: P1) 🎯 MVP

**Goal**: Extract service intent, location, and time from user messages in English/Urdu/Roman Urdu.

**Independent Test**: Send a POST to `/chat` with a Roman Urdu message and verify the extracted intent in the response.

### Implementation for User Story 1

- [x] T010 [P] [US1] Create Intent model in backend/src/models/intent.py
- [x] T011 [US1] Implement NLP/LLM tool in backend/src/services/nlp_service.py using Antigravity
- [x] T012 [US1] Implement `/chat` endpoint in backend/src/api/chat.py
- [x] T013 [P] [US1] Create chat screen in mobile/lib/screens/chat_screen.dart
- [x] T014 [US1] Integrate chat service in mobile/lib/services/api_service.dart

**Checkpoint**: User Story 1 functional - intent extraction working end-to-end.

---

## Phase 4: User Story 2 - Provider Matching & Recommendation (Priority: P1)

**Goal**: Match intent with the best available provider based on rating and distance.

**Independent Test**: Mock 3 providers in Firebase and verify the orchestrator selects the correct one with reasoning.

### Implementation for User Story 2

- [x] T015 [P] [US2] Populate mock provider data in Firebase using backend/scripts/seed_providers.py
- [x] T016 [US2] Implement provider matching tool in backend/src/services/matching_service.py
- [x] T017 [US2] Update Antigravity workflow in backend/src/services/orchestrator.py to include matching step
- [x] T018 [P] [US2] Create provider recommendation card UI in mobile/lib/components/provider_card.dart
- [x] T019 [US2] Display recommendations in mobile/lib/screens/chat_screen.dart

**Checkpoint**: User Story 2 functional - recommendations appearing with reasoning.

---

## Phase 5: User Story 3 - End-to-End Booking Simulation (Priority: P1)

**Goal**: Simulate booking confirmation and state update.

**Independent Test**: Trigger a booking and verify the status changes to "BOOKED" in Firebase.

### Implementation for User Story 3

- [x] T020 [P] [US3] Implement booking logic in backend/src/services/booking_service.py
- [x] T021 [US3] Implement `/booking/confirm` endpoint in backend/src/api/booking.py
- [x] T022 [P] [US3] Create booking confirmation screen in mobile/lib/screens/booking_summary.dart
- [x] T023 [US3] Connect "Book Now" action to backend in mobile/lib/services/api_service.dart

**Checkpoint**: User Story 3 functional - bookings successfully simulated.

---

## Phase 6: User Story 4 - Agentic Reasoning & Follow-up (Priority: P2)

**Goal**: Automate reminders and follow-up updates.

**Independent Test**: Check logs/Firebase for a "REMINDED" status update after a simulated booking.

### Implementation for User Story 4

- [x] T024 [US4] Implement follow-up agent in backend/src/services/followup_service.py
- [x] T025 [US4] Integrate follow-up scheduling in backend/src/services/booking_service.py (FastAPI BackgroundTasks)
- [x] T026 [P] [US4] Add "My Bookings" screen to view status in mobile/lib/screens/bookings_list.dart

**Checkpoint**: User Story 4 functional - follow-up automation working.

---

## Phase 7: Polish & Demo Readiness

**Purpose**: Final touches for the hackathon demo.

- [x] T027 [P] Implement execution trace logger in backend/src/services/logger.py
- [x] T028 [P] Create admin/log view for demo in backend/src/api/logs.py
- [x] T029 [P] Final UI styling for "Premium" look (mobile/lib/theme.dart)
- [x] T030 Perform end-to-end dry run and record logs

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Phase 1.
- **US1-US3**: Must be completed in order for MVP.
- **US4**: Can be added after US3.

### Parallel Opportunities

- T001-T005 can be done in parallel.
- T010 can start while T011 is in progress.
- T013 (Mobile UI) can start once T012 (API) is defined.
- T015 (Seeding) can happen anytime after Phase 1.

## Implementation Strategy

### MVP First (US1 + US2 + US3)

1. Setup + Foundation.
2. Complete US1 (Intent).
3. Complete US2 (Matching).
4. Complete US3 (Booking).
5. Validate end-to-end flow.

## Notes

- All tasks follow the `[ID] [P] [Story] Description` format.
- Mobile UI should use a premium theme (vibrant colors, smooth transitions).
- Antigravity logs are essential for the 25% evaluation criteria.

---

## Phase 8: GCP Cloud Integration (Bonus — $5 Credits)

**Purpose**: Elevate prototype with real Google Cloud APIs to impress judges.

- [x] T031 [P] Add `google-cloud-language` + `google-cloud-speech` + `python-multipart` to `backend/requirements.txt`
- [x] T032 [US1] Implement `analyze_entities()` in `backend/src/services/nlp_service.py` using Google Cloud Natural Language API (entity enrichment layer over Gemini)
- [x] T033 [US1] Add `[Cloud Integration: Google NLP API used for entity extraction]` trace step to `backend/src/services/orchestrator.py`
- [x] T034 [P] Create `backend/src/api/stt.py` — POST `/api/stt` endpoint using Google Cloud Speech-to-Text v1 (en-US + ur-PK, with mock fallback)
- [x] T035 [P] Register STT router in `backend/src/api/routes.py` under `/stt` prefix
- [x] T036 [P] Add `transcribeAudio(File)` method to `mobile/lib/services/api_service.dart` for multipart audio upload
- [x] T037 [P] Add `record: ^5.2.0` and `permission_handler: ^11.4.0` packages to `mobile/pubspec.yaml`

---

## Phase 9: User Story 5 - Automatic Location & Nearby Services On Startup (Priority: P1)

**Purpose**: Fetch the user's location automatically on startup and plot nearby service providers clustered around their resolved neighborhood to demonstrate immediate value.

- [x] T038 [US5] Implement `getClosestNeighborhood` and Haversine distance logic in `mobile/lib/models/provider.dart`
- [x] T039 [US5] Implement `fetchLocationAndLoadNearbyServices` in `mobile/lib/providers/chat_provider.dart` to orchestrate location and generate mock nearby providers
- [x] T040 [P] [US5] Update `mobile/lib/screens/chat_screen.dart` to trigger `fetchLocationAndLoadNearbyServices` inside `initState()` using `addPostFrameCallback`

---

## Phase 10: Splash Screen & UX Polish (Priority: P1)

**Purpose**: Implement a professional, premium splash screen with "System Initializing" effect that matches our Dark Tech Theme.

- [x] T041 [P] Implement Native Splash Screen with 2.5s delay and initialization tracing in `mobile/lib/main.dart`

---

## Phase 11: Robust Speech-to-Text Preset Simulation & Verification

**Purpose**: Fix STT simulation preset bypass where empty/silent audio returns empty strings. Add preset fallback logic and perform deep live tests.

- [ ] T042 [US1] Fix live STT empty transcription preset bypass in `backend/src/api/stt.py`



