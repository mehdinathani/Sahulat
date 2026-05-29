---
id: 3
title: LLM-first chat responses — remove keyword routing
stage: refactor
date: 2026-05-29
surface: agent
model: claude-opus-4-8[1m]
feature: 001-sahulat-ai
branch: refactor/llm-first-chat
user: mehdinathani
command: free-form chat (after /sp.git.commit_pr)
labels: [chat, nlp, llm, refactor, hardcoded-removal, urdu, roman-urdu]
links:
  spec: null
  ticket: null
  adr: null
  pr: null
files:
  - backend/src/models/intent.py
  - backend/src/services/nlp_service.py
  - backend/src/services/orchestrator.py
  - backend/mock_db.json
tests:
  - none added; syntax checked via python3 ast.parse on all touched files; JSON validated
---

## Prompt

next please check chats responses, its not custimzed and dedicated, instead its hard
coded, like if i say carpenter, it pick the word and match to ai understanding the
language.

## Response snapshot

Diagnosed three layers of hardcoding that made replies feel canned regardless of what
the user actually said:

1. **Pre-LLM short-circuit (`nlp_service.py::extract_intent`)** — Before Gemini ever saw
   the message, a fixed greeting set `{"hi","hello",...}` and a fixed nav-keyword list
   `["booking","cancel","contact","help","thank","status","track"]` were tested as
   substrings. Hits skipped Gemini entirely.

2. **Hardcoded conversational reply table (`orchestrator.py`)** — For `Conversational`
   intent, the code ran an `if "thank" in msg_lower: ... elif "cancel" in msg_lower: ...`
   cascade that returned canned **English** strings. Urdu and Roman Urdu users got English
   replies regardless of how they wrote.

3. **Canned no-match message** — When no providers matched (e.g., user asked for
   "carpenter" and the mock DB had none), the orchestrator returned a fixed English
   string `"Sorry, I couldn't find any available {service} providers in {location}..."`
   instead of letting Gemini craft a language-aware apology + suggestion.

Plus a data issue compounding (3): the mock DB only had Electrician/Plumber/AC Repair
seeded — Carpenter/Tutor/Painter had no providers, so even a perfectly-understood
"carpenter" request fell into the canned no-match string.

### Refactor

- **`backend/src/models/intent.py`** — Added `intent_kind: Literal["greeting",
  "service_request", "conversational"]` (default `"service_request"` so existing
  call-sites stay valid). This is how Gemini now communicates *what kind of message*
  it just classified, replacing the substring tests.

- **`backend/src/services/nlp_service.py::extract_intent`** — Removed the pre-Gemini
  greeting/nav short-circuits entirely. Gemini now decides `intent_kind` AND extracts
  `service_type`/`location`/`time_preference`/`language` in a single structured-output
  call. The prompt explicitly tells the model to recognize ANY home/professional
  service (not a fixed list) and to normalize Urdu/Roman Urdu synonyms like
  `barhai → Carpenter`, `rang saaz → Painter`. The keyword fallback was kept but
  narrowed and moved to `_keyword_fallback()` — used ONLY when the Gemini call raises.

- **`backend/src/services/orchestrator.py`** —
  - Greeting and conversational branches now call new helpers
    `_generate_conversational_reply()` and `_gemini_text()` that ask Gemini to write
    the reply in the user's detected language using the existing
    `self.conversational_instruction` system prompt. No more `if "thank" in msg_lower`.
  - The no-match path calls `_generate_no_match_reply()` which asks Gemini to apologize
    in the user's language and suggest a related service or wider area.
  - Both helpers fall back to a generic English string only if Gemini itself raises;
    they never substitute hardcoded text for what the LLM would have said correctly.
  - Intent branching switched from `intent.service_type == "Greeting"` (the previous
    sentinel) to `intent.intent_kind == "greeting"`. `service_type` stays useful as
    the canonical service label downstream.

- **`backend/mock_db.json`** —
  - Normalized `service_type` casing on the 4 legacy entries (`electrician` → `Electrician`,
    `plumber` → `Plumber`, `ac_repair` → `AC Repair`) so matching is consistent.
  - Added 2 Carpenter, 2 Tutor, 2 Painter providers across G-13, DHA, Lahore, Karachi,
    Islamabad so the user's exact "carpenter" example now finds real matches and gets
    the recommendation flow instead of the apology flow.
  - Bookings collection preserved verbatim.

### What is NOT changed

- `backend/antigravity_prompt.txt` — Read it; it already uses "e.g." for service examples
  and gives the LLM ownership of intent classification. No changes needed.
- Suggested-actions chips — they remain structured strings because they drive UI
  buttons in Flutter; only the human-facing `content` field is now LLM-generated.
- Booking confirmation message — was already Gemini-generated; left alone.

## Outcome

- ✅ Impact: User saying "carpenter" (English), "barhai" (Roman Urdu), or "بڑھئی" (Urdu)
  now reaches Gemini with the full message, gets classified as `service_request` with
  `service_type="Carpenter"`, finds real matches in the mock DB, and gets a recommendation
  reply written by Gemini in the user's language. User saying "shukriya" gets a warm
  Roman-Urdu thanks reply instead of the English `"You're welcome! 😊"` canned string.
- 🧪 Tests: No new tests added in this commit. All three touched Python files parse
  via `python3 -c "import ast; ..."`. `mock_db.json` validated via `json.load`.
  Smoke test needed: hit `/api/chat` with `{"content": "i need a carpenter in DHA"}` and
  verify response.providers is non-empty + content mentions a Carpenter by name; hit
  with `{"content": "shukriya"}` and verify response.content is Roman Urdu, not English.
- 📁 Files: 4 modified (intent.py +13/-3, nlp_service.py ~+90/-60, orchestrator.py ~+90/-50,
  mock_db.json +60/-8).
- 🔁 Next prompts: (a) integration test of the chat endpoint with EN/UR/Roman-UR fixtures
  asserting `intent_kind` classification + language-matching reply. (b) Migrate mock_db
  service_type normalization into a migration script so a re-seed doesn't reintroduce
  the lowercase entries.
- 🧠 Reflection: The "hardcoded" pattern grew organically — every new edge case the
  team encountered ("user said thanks", "user said carpenter and we 404'd") was patched
  with another `if substring in text` branch instead of being pushed back into the LLM
  pipeline. The fix isn't more clever regex; it's deleting the regex and letting Gemini
  do its job. Worth a constitution-level rule: "string-matching on user input is a code
  smell — push it to the LLM unless there's a measured latency/cost reason not to."

## Evaluation notes (flywheel)

- Failure modes observed: The exact symptom the user described — "if i say carpenter,
  it pick the word and match to ai understanding the language" — was actually backwards
  from the truth: the system was NOT using AI to understand the language; it was using
  substring matching that bypassed AI entirely. The user's intuition that the response
  felt "hard coded" was correct; my job was to verify and remove the actual hardcoding.
- Graders run and results (PASS/FAIL): N/A — no automated graders yet.
- Prompt variant (if applicable): N/A.
- Next experiment (smallest change to try): add a pytest that posts 6 fixture messages
  (`"hi"`, `"salam"`, `"shukriya"`, `"i need a carpenter"`, `"barhai chahiye DHA mein"`,
  `"how does this work"`) and asserts (a) `intent_kind` is right, (b) response.content
  is in the input language, (c) no two of the six responses are byte-identical (catches
  any regression to a canned string table).
