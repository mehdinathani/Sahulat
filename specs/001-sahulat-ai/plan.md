# Implementation Plan: Sahulat-AI Orchestrator

**Branch**: `main` | **Date**: 2026-05-16 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-sahulat-ai/spec.md`

## Summary

Build an Agentic AI system ("Sahulat-AI") that automates the end-to-end lifecycle of service requests in the informal economy. The system will use Google Antigravity for orchestration, FastAPI for the backend service, Firebase for mock data and state management, and Flutter for the mobile interface.

The mobile app will automatically fetch the user's location on startup (with graceful fallbacks) to suggest nearby mock providers clustered around their resolved neighborhood.

## Technical Context

**Language/Version**: Python 3.10+ (FastAPI), Dart/Flutter (Latest)  
**Primary Dependencies**: FastAPI, Firebase Admin SDK, Google Antigravity SDK, Flutter SDK  
**Storage**: Firebase Realtime Database / Firestore (Mocked)  
**Testing**: pytest (Backend), Flutter Test (Mobile)  
**Target Platform**: Mobile (Android/iOS), Server (Linux/Docker)  
**Project Type**: Mobile + API  
**Performance Goals**: Orchestration overhead < 5 seconds  
**Constraints**: Support for multilingual input (Urdu, Roman Urdu, English), traceable logs  
**Scale/Scope**: MVP for Google Hackathon (Challenge 2)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] No constitution file found, using standard best practices.
- [x] Tech stack matches user requirements exactly.

## Project Structure

### Documentation (this feature)

```text
specs/001-sahulat-ai/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
backend/
├── src/
│   ├── models/          # Data schemas
│   ├── services/        # Business logic & Antigravity orchestration
│   └── api/             # FastAPI routes
└── tests/

mobile/
├── lib/
│   ├── models/          # Data models
│   ├── screens/         # Flutter UI
│   └── services/        # API communication
└── test/
```

**Structure Decision**: Selected "Mobile + API" structure to separate concerns between the orchestrator/backend and the user interface.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Multi-repo/Multi-folder | Frontend/Backend separation | Single repo would make deployment and testing harder |
