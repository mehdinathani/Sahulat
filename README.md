# Sahulat-AI — Agentic Service Orchestrator for the Informal Economy

> **Hackathon Challenge 2** — AI Service Orchestrator for the Informal Economy.
> Plumbers, electricians, AC technicians, tutors and other home-service providers
> in Pakistan operate through WhatsApp, calls, and word of mouth. Sahulat-AI is
> an agentic assistant that takes a request in **Urdu / Roman Urdu / English**,
> reasons through provider discovery, ranking, booking, and follow-up, and shows
> the user every step of its thinking.

---

## Judge's Quick Start (≈ 5 minutes)

If you can run code:

```bash
# 1. Backend (FastAPI + Gemini)
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
echo "GOOGLE_API_KEY=<your-gemini-key>" > .env       # required for live NLU
python main.py                                       # starts on :8080

# 2. Mobile app (Flutter)
cd ../mobile
echo "MAPS_API_KEY=<your-maps-key>" >> android/local.properties   # for the Map screen
flutter pub get
flutter run                                          # device or emulator
```

If you can't run it, the **agent traces from a live dry-run are committed to
[`logs/dry_run_output.json`](logs/dry_run_output.json)** — they prove the
end-to-end loop closes and show exactly what the agent thought, called, and
observed at every step.

You can also hit the live backend directly:

```bash
curl -X POST https://sahulat-backend-118267129512.us-central1.run.app/api/chat \
  -H "Content-Type: application/json" \
  -d '{"role":"user","content":"Mujhe kal subah G-13 mein AC technician chahiye"}'
```

The response includes a `trace[]` array — the per-step reasoning the rubric asks for.

---

## What it does (the golden example)

**Input:** `"Mujhe kal subah G-13 mein AC technician chahiye"` (Roman Urdu)

**The agent's reasoning, end-to-end:**

| Step | Action | Observation |
|---|---|---|
| 1. Intent Extraction | Gemini 2.5 Flash + Google Cloud NL | `service=AC Repair`, `location=G-13`, `time=kal subah`, `language=roman_ur`, `confidence=0.87` |
| 2. Provider Discovery | Query mock DB filtered by service + availability | 3 candidates for AC Repair |
| 3. Ranking & Recommendation | Composite score (rating 0.55 + distance 0.35 + price 0.10) with a +0.05 neighbourhood-match boost | **Ali AC Services** (4.8★, 1.2 km, G-13) — composite=0.91 |
| 4. Booking Simulation | `time_parser.parse_time_preference("kal subah")` → tomorrow 10:00 AM; UUID booking created and persisted | `BOOKED` in mock Firestore |
| 5. Follow-up | `BackgroundTasks` scheduled reminder | Booking status flips to `REMINDER_SENT` |

Every row above is captured as an `AgentTrace(step, thought, action, observation)`,
streamed to the mobile app, and rendered live in the **Agent Brain Console**.

---

## Architecture

```mermaid
flowchart LR
    U([User<br/>UR / EN / Roman UR]) --> M[Flutter App<br/>Chat + Voice + Map]
    M -->|POST /api/chat<br/>POST /api/stt<br/>POST /api/booking| F[FastAPI Backend]
    F --> O{Orchestrator<br/>5-step pipeline}
    O -->|1. extract| N[NLP Service<br/>Gemini 2.5 Flash<br/>+ Google Cloud NL]
    O -->|2-3. match + rank| MS[Matching Service<br/>weighted composite score]
    O -->|4. simulate| B[Booking Service<br/>time_parser → slot]
    O -->|5. schedule| FU[Follow-up<br/>BackgroundTasks]
    MS --> DB[(Mock Firestore<br/>mock_db.json)]
    B --> DB
    FU --> DB
    O -->|AgentTrace[]| M
    M -->|render| AC[Agent Brain Console]
```

- **Mobile (Flutter)** — `mobile/lib/`. Chat UI with voice STT, the Agent Brain
  Console that visualises reasoning, a bookings list with live status, and a
  provider map. State managed with `provider`. Urdu UI flips to RTL automatically.
- **Backend (FastAPI)** — `backend/`. Single source of orchestration logic.
  Stateless services for NLU / matching / booking / follow-up. Mock Firestore so
  no PII or live cloud dependency is required.
- **Persistence (Mock Firestore)** — `backend/mock_db.json`. Mimics the document
  layout of real Firestore; swappable for live Firebase via
  `GOOGLE_APPLICATION_CREDENTIALS`.

---

## How Google Antigravity is used

**Transparent disclosure:** the **orchestrator implements an
Antigravity-style multi-step reasoning pipeline** (`backend/src/services/orchestrator.py`)
driven by the spec in [`antigravity_prompt.txt`](antigravity_prompt.txt). The
underlying LLM is **Gemini 2.5 Flash** (Google's foundation model that powers
Antigravity); orchestration, tool routing, and trace capture are implemented in
our own service code rather than via the Antigravity hosted runtime.

What this means concretely:

- The five workflow steps (Intent → Discovery → Ranking → Action → Follow-up)
  are defined declaratively in `antigravity_prompt.txt` and executed by the
  Python orchestrator.
- Each step emits an `AgentTrace(step, thought, action, observation)`
  exposing the same audit surface Antigravity workflows produce.
- Tool integrations match the Antigravity tool model: Google Cloud Natural
  Language (entity extraction), Google Cloud Speech-to-Text (voice), Google
  Maps (provider locations), Firebase (state).

We made this design choice so the system works offline / in the demo without
depending on a hosted runtime — but the prompt, the trace model, and the
tool-orchestration shape are all 1-to-1 with the Antigravity pattern. Swapping
the local executor for the Antigravity runtime would be a transport-layer
change, not an architectural one.

---

## Matching algorithm (the 20% rubric line item)

Defined in `backend/src/services/matching_service.py`:

```
score = 0.55 · rating_normalised
      + 0.35 · distance_normalised   # closer → higher; 0 beyond 10 km
      + 0.10 · price_normalised      # cheaper → higher
      + 0.05 · location_exact_match  # boost if user's neighbourhood matches
```

`availability` is a **hard gate** (unavailable providers are filtered out
before scoring). The orchestrator emits the full factor breakdown in the
ranking trace, so the UI can show *why* the recommendation was made.

---

## API surface

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/chat` | Send user message → returns content, trace, providers, booking_id |
| `POST` | `/api/stt` | Multipart audio upload → transcript (Urdu / Roman Urdu / English) |
| `POST` | `/api/booking/confirm` | Confirm a recommended provider (accepts `provider_id`, `provider_name`, optional `time_preference`) |
| `GET` | `/api/booking/list` | All bookings (demo: no per-user filter) |
| `GET` | `/api/booking/{id}` | One booking |
| `GET` | `/api/logs` | Captured agent traces (the "show your work" endpoint) |

---

## Tools, APIs and tech

- **Google Gemini 2.5 Flash** (`google-genai`) — multilingual NLU + recommendation copy
- **Google Cloud Natural Language API** — supplementary entity extraction
- **Google Cloud Speech-to-Text** — voice input (Urdu `ur-PK`, English `en-US`)
- **Google Maps Flutter + geolocator** — provider map and nearest-neighbourhood inference
- **FastAPI BackgroundTasks** — asynchronous follow-up reminders
- **Flutter + Provider** — mobile client; `flutter_native_splash`, `flutter_markdown`, `google_fonts` (Noto Nastaliq Urdu fallback for Urdu strings)

---

## Repository layout

```
backend/
  main.py                       FastAPI app entry
  antigravity_prompt.txt        5-step workflow spec
  mock_db.json                  Seed providers + booking store
  src/
    api/        chat.py, booking.py, stt.py, logs.py
    services/   orchestrator.py, nlp_service.py, matching_service.py,
                booking_service.py, time_parser.py, followup_service.py,
                firebase_service.py, logger.py
    models/     schemas.py, intent.py
mobile/
  lib/
    main.dart                   Wires RTL, locale, providers
    screens/    chat_screen.dart, booking_summary.dart, bookings_list.dart,
                providers_map_screen.dart
    providers/  chat_provider.dart, settings_provider.dart
    components/ agent_brain_console.dart, provider_card.dart, urdu_text.dart
    services/   api_service.dart, map_service.dart
logs/
  dry_run_output.json           Captured live traces (read this if you can't run)
docs/archive/                   Unrelated artifacts (ignore for grading)
```

---

## Assumptions & limitations

- **Authentication is out of scope.** Bookings aren't scoped to a user; the
  demo assumes a single logged-in account.
- **Distances are mock data.** `mock_db.json` ships provider distances as
  static fields. Wiring `geolocator.position` into the chat payload to compute
  real-time distance is a one-line addition (the field is already optional on
  the model) but isn't done in the demo flow.
- **Follow-up delay is artificially short** (5 s) so the reminder fires during
  the demo. Real deployment would schedule for "1 hour before slot".
- **Mock Firestore.** No PII, no real credentials. `firebase_service.py`
  switches to live Firestore automatically when `GOOGLE_APPLICATION_CREDENTIALS`
  is set.
- **Roman Urdu coverage** depends on Gemini's zero-shot ability; there is no
  transliteration library in the fallback path (keyword matching only).

---

## Demo checklist (for recording)

1. Open app → light/dark toggle visible.
2. Settings → set language `ur-PK` → UI flips to RTL.
3. Voice input: say "Mujhe kal subah G-13 mein AC technician chahiye".
4. Recommendation card appears with reasoning + composite score.
5. Toggle **Show Agent Reasoning** → full trace timeline visible.
6. Tap **Book Ali AC Services** → confirmation includes the parsed slot
   ("Tue 21 May, 10:00 AM UTC").
7. Wait ~5 s → bookings list shows status change to `REMINDED` with the
   notification text.

---

## Production setup (optional)

1. **Firebase**: download Admin SDK key; set `GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json` or `FIREBASE_SERVICE_ACCOUNT` in `.env`.
2. **Maps key**: rotate the demo `MAPS_API_KEY` in `local.properties` for production builds.
3. **gcloud ADC** (when deploying to Cloud Run / Compute Engine):
   ```bash
   gcloud auth application-default login
   ```
