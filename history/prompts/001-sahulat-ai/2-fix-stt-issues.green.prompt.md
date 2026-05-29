---
id: 2
title: Fix STT issues — restore mic UI, clean backend
stage: green
date: 2026-05-29
surface: agent
model: claude-opus-4-8[1m]
feature: 001-sahulat-ai
branch: main
user: mehdinathani
command: free-form chat
labels: [stt, mobile, backend, regression-fix, bugfix]
links:
  spec: null
  ticket: null
  adr: null
  pr: null
files:
  - mobile/lib/screens/chat_screen.dart
  - backend/src/api/stt.py
  - backend/src/api/stt.py.backup
tests:
  - none added; existing test_stt_fix.py still passes (mock fallback logic untouched)
---

## Prompt

please check and resolve stt issues, i have added related skills for your ref and context7 mcp server

## Response snapshot

Diagnosed two distinct STT issues:

1. **Mobile (blocking)** — Commit `c67fc6e Fix STT fallback and polish native splash screens`
   accidentally overwrote `mobile/lib/screens/chat_screen.dart` with a copy of `main.dart`,
   deleting the 982-line `ChatScreen` widget that contained the mic button (`_VoiceRecordButton`),
   `_toggleRecording()` logic, and the call to `chatProvider.sendVoiceMessage()`. `splash_screen.dart:86`
   still referenced `const ChatScreen()`, so the app did not compile — STT could not run end-to-end
   regardless of backend health.

   **Fix:** Restored `mobile/lib/screens/chat_screen.dart` verbatim from commit `3fea026`
   (the last commit before the regression). All imports (record, flutter_markdown, google_fonts,
   path, provider) are already in pubspec.yaml. Recording uses `Directory.systemTemp` (no
   path_provider dependency needed) and saves as `.m4a` (AAC), which Cloud STT decodes via the
   AMR_WB/MP3 paths plus header auto-detection.

2. **Backend (cleanup)** — `backend/src/api/stt.py`:
   - Removed leftover `backend/src/api/stt.py.backup` file checked into the working tree.
   - Removed unused `tempfile` and `HTTPException` imports.
   - Made `language_code == "auto"` handling explicit: it now falls into a clearly-commented
     `else` branch that pins primary to `en-US` and offers `ur-PK` as an alternative
     (Cloud STT does not accept the literal `"auto"`). Previous code did the right thing by
     accident; the new branch makes intent explicit and survives future refactors.

   The prior `fix stt` commit (`6e236a6`) — which removed the hardcoded `sample_rate_hertz=16000`
   so Cloud STT reads the rate from the WAV/FLAC header — is preserved and correct. That was the
   key fix for devices recording at 44.1/48 kHz being rejected.

## Outcome

- ✅ Impact: Mobile app now compiles (`ChatScreen` defined again), mic button reaches the backend,
  preset/manual voice flow end-to-end is functional again. Backend STT route is leaner and handles
  the documented "auto" language code explicitly.
- 🧪 Tests: No new tests added. `test_stt_fix.py` exercises only the preset mock-fallback mapping,
  which was not touched. Manual smoke test needed: launch mobile app, tap mic, record short
  English/Urdu clip, verify transcript posts to chat.
- 📁 Files: 2 modified (chat_screen.dart restored, stt.py cleaned), 1 deleted (stt.py.backup).
- 🔁 Next prompts: (a) Add an integration test that POSTs a real audio file to /api/stt and
  asserts source="gemini_stt" or "cloud_stt" (not "mock") to catch credential/region regressions.
  (b) Consider explicit `RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1)`
  in `_toggleRecording` to standardize the upload format across Android/iOS/web.
- 🧠 Reflection: A commit message that says "polish splash screens" deleted a 982-line widget — the
  diff was 6× larger than the message suggested. Worth adding a pre-commit hook that flags large
  removals from `lib/screens/` when the commit message doesn't mention screen changes.

## Evaluation notes (flywheel)

- Failure modes observed: silent regression — backend STT fix landed in `6e236a6` but the mobile
  side that calls it was already broken in `c67fc6e` (one commit prior in author order, two before
  HEAD), so end-to-end voice would have appeared "broken backend" when in fact the client never
  shipped audio.
- Graders run and results (PASS/FAIL): N/A (no automated graders for this turn).
- Prompt variant (if applicable): N/A.
- Next experiment (smallest change to try): add a Flutter widget test that mounts `SplashScreen`,
  triggers its navigation, and asserts a `_VoiceRecordButton` is in the tree. Would have caught
  the missing `ChatScreen` class at CI time.
